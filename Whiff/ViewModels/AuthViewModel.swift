import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: UserResponse?
    @Published var isAuthenticated = false
    @Published var error: Error?
    @Published var isLoading = false
    @Published var isInitializing = true
    
    private let apiClient = APIClient.shared
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Firebase Auth 상태 리스너 설정
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            Task { @MainActor in
                guard let self = self else { return }
                
                print("🔍 Firebase Auth 상태 변경: \(user?.email ?? "로그아웃")")
                
                if let firebaseUser = user {
                    // Firebase 사용자가 있으면 ID 토큰 갱신 및 저장
                    do {
                        let idToken = try await firebaseUser.getIDToken()
                        UserDefaults.standard.set(idToken, forKey: "authToken")
                        
                        // 백엔드에서 사용자 정보 가져오기
                        let backendUser = try await self.apiClient.getCurrentUser()
                        self.user = backendUser
                        self.isAuthenticated = true
                        
                                    // 사용자 정보를 UserDefaults에 저장
            UserDefaults.standard.set(backendUser.data.uid, forKey: "userId")
            UserDefaults.standard.set(backendUser.data.name ?? "사용자", forKey: "userName")
            // 시향 일기용 키도 추가로 저장
            UserDefaults.standard.set(backendUser.data.uid, forKey: "currentUserId")
            UserDefaults.standard.set(backendUser.data.name ?? "사용자", forKey: "currentUserName")
            UserDefaults.standard.set(backendUser.data.picture ?? "", forKey: "currentUserProfileImage")
                        
                        print("✅ 자동 로그인 성공: \(backendUser.data.name ?? "사용자")")
                    } catch {
                        print("❌ 사용자 정보 가져오기 실패: \(error)")
                        // 백엔드 오류 시 Firebase 로그아웃
                        try? Auth.auth().signOut()
                        self.user = nil
                        self.isAuthenticated = false
                        UserDefaults.standard.removeObject(forKey: "authToken")
                    }
                } else {
                    // Firebase 사용자가 없으면 로그아웃 상태
                    self.user = nil
                    self.isAuthenticated = false
                    UserDefaults.standard.removeObject(forKey: "authToken")
                    UserDefaults.standard.removeObject(forKey: "userId")
                    UserDefaults.standard.removeObject(forKey: "userName")
                    // 시향 일기용 키도 삭제
                    UserDefaults.standard.removeObject(forKey: "currentUserId")
                    UserDefaults.standard.removeObject(forKey: "currentUserName")
                    UserDefaults.standard.removeObject(forKey: "currentUserProfileImage")
                    print("🔍 로그아웃 상태")
                }
                
                self.isInitializing = false
            }
        }
    }
    
    func signInWithEmail(email: String, password: String) async {
        guard !email.isEmpty && !password.isEmpty else {
            self.error = APIError.invalidInput("이메일과 비밀번호를 입력해주세요.")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Firebase 이메일/비밀번호 로그인
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let idToken = try await authResult.user.getIDToken()
            
            // Firebase ID 토큰 저장
            UserDefaults.standard.set(idToken, forKey: "authToken")
            
            // 사용자 정보 가져오기
            let user = try await apiClient.getCurrentUser()
            self.user = user
            self.isAuthenticated = true
            
            // 사용자 정보를 UserDefaults에 저장
            UserDefaults.standard.set(user.data.uid, forKey: "userId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "userName")
            // 시향 일기용 키도 추가로 저장
            UserDefaults.standard.set(user.data.uid, forKey: "currentUserId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "currentUserName")
            UserDefaults.standard.set(user.data.picture ?? "", forKey: "currentUserProfileImage")
            
        } catch let apiError as APIError {
            print("❌ API 에러: \(apiError.localizedDescription)")
            
            // 502 에러의 경우 더 친화적인 메시지 제공
            if apiError.localizedDescription.contains("502") {
                self.error = APIError.serverError("현재 서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요.")
            } else {
                self.error = apiError
            }
            
            // 502 에러가 아닌 경우에만 토큰 삭제 (일시적 서버 문제로 인한 로그아웃 방지)
            if !apiError.localizedDescription.contains("502") {
                UserDefaults.standard.removeObject(forKey: "authToken")
            }
        } catch {
            self.error = APIError.serverError("로그인 중 오류가 발생했습니다: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        error = nil
        
        print("🔵 구글 로그인 시작")
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ Firebase 설정을 찾을 수 없음")
            self.error = APIError.serverError("Firebase 설정을 찾을 수 없습니다.")
            isLoading = false
            return
        }
        
        print("✅ Firebase 클라이언트 ID: \(clientID)")
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ 뷰 컨트롤러를 찾을 수 없음")
            self.error = APIError.serverError("앱의 뷰 컨트롤러를 찾을 수 없습니다.")
            isLoading = false
            return
        }
        
        do {
            print("🔵 구글 로그인 시도")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ 구글 ID 토큰을 받지 못함")
                self.error = APIError.serverError("구글 로그인 토큰을 받지 못했습니다.")
                isLoading = false
                return
            }
            
            print("✅ 구글 로그인 성공, ID 토큰 획득")
            
            // Firebase 인증
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: result.user.accessToken.tokenString)
            
            print("🔵 Firebase 인증 시도")
            let authResult = try await Auth.auth().signIn(with: credential)
            print("✅ Firebase 인증 성공")
            
            // Firebase ID 토큰 저장
            let firebaseIdToken = try await authResult.user.getIDToken()
            UserDefaults.standard.set(firebaseIdToken, forKey: "authToken")
            print("✅ Firebase ID 토큰 저장 완료")
            
            // 사용자 정보 가져오기
            print("🔵 사용자 정보 가져오기 시도")
            let user = try await apiClient.getCurrentUser()
            self.user = user
            self.isAuthenticated = true
            
            // 사용자 정보를 UserDefaults에 저장
            UserDefaults.standard.set(user.data.uid, forKey: "userId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "userName")
            // 시향 일기용 키도 추가로 저장
            UserDefaults.standard.set(user.data.uid, forKey: "currentUserId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "currentUserName")
            UserDefaults.standard.set(user.data.picture ?? "", forKey: "currentUserProfileImage")
            
            print("✅ 사용자 정보 가져오기 성공")
            
        } catch let error as APIError {
            print("❌ API 에러: \(error.localizedDescription)")
            
            // 502 에러의 경우 더 친화적인 메시지 제공
            if error.localizedDescription.contains("502") {
                self.error = APIError.serverError("현재 서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요.")
            } else {
                self.error = error
            }
            
            // 502 에러가 아닌 경우에만 토큰 삭제 (일시적 서버 문제로 인한 로그아웃 방지)
            if !error.localizedDescription.contains("502") {
                UserDefaults.standard.removeObject(forKey: "authToken")
            }
        } catch {
            print("❌ 구글 로그인 에러: \(error.localizedDescription)")
            self.error = APIError.serverError("구글 로그인 중 오류가 발생했습니다: \(error.localizedDescription)")
            // 인증 실패 시 토큰 삭제
            UserDefaults.standard.removeObject(forKey: "authToken")
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, name: String) async {
        guard !email.isEmpty && !password.isEmpty && !name.isEmpty else {
            self.error = APIError.invalidInput("모든 필드를 입력해주세요.")
            return
        }
        
        guard password.count >= 6 else {
            self.error = APIError.invalidInput("비밀번호는 6자 이상이어야 합니다.")
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            self.error = APIError.invalidInput("올바른 이메일 형식이 아닙니다.")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Firebase 이메일/비밀번호 회원가입
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // 사용자 프로필 업데이트
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Firebase ID 토큰 가져오기
            let idToken = try await authResult.user.getIDToken()
            
            // Firebase ID 토큰 저장
            UserDefaults.standard.set(idToken, forKey: "authToken")
            
            // 사용자 정보 가져오기
            let user = try await apiClient.getCurrentUser()
            self.user = user
            self.isAuthenticated = true
            
            // 사용자 정보를 UserDefaults에 저장
            UserDefaults.standard.set(user.data.uid, forKey: "userId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "userName")
            // 시향 일기용 키도 추가로 저장
            UserDefaults.standard.set(user.data.uid, forKey: "currentUserId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "currentUserName")
            UserDefaults.standard.set(user.data.picture ?? "", forKey: "currentUserProfileImage")
            
        } catch let apiError as APIError {
            self.error = apiError
        } catch {
            self.error = APIError.serverError("회원가입 중 오류가 발생했습니다.")
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            // Firebase 로그아웃
            try Auth.auth().signOut()
            // Google 로그아웃
            GIDSignIn.sharedInstance.signOut()
            // 토큰 및 사용자 정보 삭제
            UserDefaults.standard.removeObject(forKey: "authToken")
            UserDefaults.standard.removeObject(forKey: "userId")
            UserDefaults.standard.removeObject(forKey: "userName")
            // 시향 일기용 키도 삭제
            UserDefaults.standard.removeObject(forKey: "currentUserId")
            UserDefaults.standard.removeObject(forKey: "currentUserName")
            UserDefaults.standard.removeObject(forKey: "currentUserProfileImage")
            // 상태 초기화
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.error = error
        }
    }
    
    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil
        do {
            let authorization = try result.get()
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                self.error = APIError.invalidInput("Apple 인증 토큰을 가져올 수 없습니다.")
                isLoading = false
                return
            }
            // Firebase 인증
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: "")
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseIdToken = try await authResult.user.getIDToken()
            UserDefaults.standard.set(firebaseIdToken, forKey: "authToken")
            // 백엔드에 Apple 로그인 요청
            let url = URL(string: "https://whiff-api-9nd8.onrender.com/auth/apple-login")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["id_token": tokenString]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let msg = String(data: data, encoding: .utf8) ?? "Apple 로그인 실패"
                self.error = APIError.serverError(msg)
                isLoading = false
                return
            }
            // 사용자 정보 가져오기
            let user = try await apiClient.getCurrentUser()
            self.user = user
            self.isAuthenticated = true
            UserDefaults.standard.set(user.data.uid, forKey: "userId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "userName")
            UserDefaults.standard.set(user.data.uid, forKey: "currentUserId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "currentUserName")
            UserDefaults.standard.set(user.data.picture ?? "", forKey: "currentUserProfileImage")
        } catch {
            self.error = APIError.serverError("Apple 로그인 중 오류가 발생했습니다: \(error.localizedDescription)")
        }
        isLoading = false
    }
} 