import Foundation
import AuthenticationServices

class AppleSignInUtils {
    
    /// Apple Sign In이 사용 가능한지 확인
    static func isAppleSignInAvailable() -> Bool {
        if #available(iOS 13.0, *) {
            // iOS 13.0+에서는 Apple Sign In 사용 가능
            return true
        }
        return false
    }
    
    /// 현재 Apple ID 상태 확인
    static func checkAppleIDState(completion: @escaping (ASAuthorizationAppleIDProvider.CredentialState, Error?) -> Void) {
        let provider = ASAuthorizationAppleIDProvider()
        
        // UserDefaults에서 저장된 Apple ID 가져오기
        if let appleUserID = UserDefaults.standard.string(forKey: "appleUserID") {
            provider.getCredentialState(forUserID: appleUserID) { state, error in
                DispatchQueue.main.async {
                    completion(state, error)
                }
            }
        } else {
            // 저장된 Apple ID가 없으면 .notFound 상태
            DispatchQueue.main.async {
                completion(.notFound, nil)
            }
        }
    }
    
    /// Apple ID 상태를 한국어로 변환
    static func getAppleIDStateDescription(_ state: ASAuthorizationAppleIDProvider.CredentialState) -> String {
        switch state {
        case .authorized:
            return "인증됨"
        case .revoked:
            return "취소됨"
        case .notFound:
            return "찾을 수 없음"
        case .transferred:
            return "이전됨"
        @unknown default:
            return "알 수 없음"
        }
    }
    
    /// Apple 로그인 요청 생성
    static func createAppleIDRequest() -> ASAuthorizationAppleIDRequest {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        return request
    }
    
    /// Apple ID 사용자 정보 저장
    static func saveAppleUserInfo(userID: String, fullName: PersonNameComponents?, email: String?) {
        UserDefaults.standard.set(userID, forKey: "appleUserID")
        
        if let fullName = fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .long
            let name = formatter.string(from: fullName)
            UserDefaults.standard.set(name, forKey: "appleUserName")
        }
        
        if let email = email {
            UserDefaults.standard.set(email, forKey: "appleUserEmail")
        }
    }
    
    /// 저장된 Apple 사용자 정보 가져오기
    static func getSavedAppleUserInfo() -> (userID: String?, name: String?, email: String?) {
        let userID = UserDefaults.standard.string(forKey: "appleUserID")
        let name = UserDefaults.standard.string(forKey: "appleUserName")
        let email = UserDefaults.standard.string(forKey: "appleUserEmail")
        return (userID, name, email)
    }
    
    /// Apple 사용자 정보 삭제
    static func clearAppleUserInfo() {
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
    }
    
    /// Apple 로그인 상태 디버그 정보 출력
    static func printAppleSignInDebugInfo() {
        print("🍎 === Apple Sign In 디버그 정보 ===")
        print("🍎 사용 가능 여부: \(isAppleSignInAvailable())")
        
        let savedInfo = getSavedAppleUserInfo()
        print("🍎 저장된 Apple ID: \(savedInfo.userID ?? "없음")")
        print("🍎 저장된 이름: \(savedInfo.name ?? "없음")")
        print("🍎 저장된 이메일: \(savedInfo.email ?? "없음")")
        
        checkAppleIDState { state, error in
            if let error = error {
                print("🍎 Apple ID 상태 확인 오류: \(error.localizedDescription)")
            } else {
                print("🍎 Apple ID 상태: \(getAppleIDStateDescription(state))")
            }
        }
        print("🍎 =================================")
    }
} 