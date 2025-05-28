import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var error: Error?
    @Published var isLoading = false
    
    private let apiClient = APIClient.shared
    
    init() {
        // 저장된 토큰이 있는지 확인
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            Task {
                await validateToken(token)
            }
        }
    }
    
    private func validateToken(_ token: String) async {
        do {
            let response: AuthResponse = try await apiClient.request("/auth/validate", method: "POST")
            if response.token != token {
                throw APIError.invalidToken
            }
            self.user = response.user
            self.isAuthenticated = true
        } catch {
            UserDefaults.standard.removeObject(forKey: "authToken")
            self.user = nil
            self.isAuthenticated = false
            self.error = error
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
            let response = try await apiClient.login(email: email, password: password)
            UserDefaults.standard.set(response.token, forKey: "authToken")
            self.user = response.user
            self.isAuthenticated = true
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        error = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else { return }
            
            // Google 로그인 정보를 백엔드로 전송
            let response: AuthResponse = try await apiClient.request(
                "/auth/google",
                method: "POST",
                body: try JSONEncoder().encode([
                    "id_token": idToken,
                    "access_token": result.user.accessToken.tokenString
                ])
            )
            
            UserDefaults.standard.set(response.token, forKey: "authToken")
            self.user = response.user
            self.isAuthenticated = true
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.register(email: email, password: password, name: name)
            UserDefaults.standard.set(response.token, forKey: "authToken")
            self.user = response.user
            self.isAuthenticated = true
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            // Firebase 로그아웃
            try Auth.auth().signOut()
            // Google 로그아웃
            GIDSignIn.sharedInstance.signOut()
            // 토큰 삭제
            UserDefaults.standard.removeObject(forKey: "authToken")
            // 상태 초기화
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.error = error
        }
    }
} 