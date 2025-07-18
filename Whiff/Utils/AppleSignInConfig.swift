import Foundation

/// Apple Sign In 활성화/비활성화 설정
struct AppleSignInConfig {
    
    // MARK: - Apple Sign In 활성화 여부
    /// Apple Sign In 기능을 활성화할지 여부
    /// 개발 단계에서는 false로 설정, Apple Developer Program 가입 후 true로 변경
    static let isEnabled = false
    
    // MARK: - Apple Developer Console 정보 (나중에 사용)
    /// Apple Developer Team ID (10자리 영숫자)
    /// 예: ABC123DEF4
    static let teamID = "8BJS54K55Z"
    
    /// Apple Developer Key ID (10자리 영숫자)
    /// 예: XYZ789ABC1
    static let keyID = "43ZM224LTP"
    
    /// 앱의 Bundle ID
    static let bundleID = "com.whiff.main"
    
    /// Apple Developer Service ID
    /// 일반적으로 Bundle ID + .signin 형태
    static let serviceID = "com.whiff.main.signin"
    
    // MARK: - Firebase 정보
    /// Firebase 프로젝트 ID
    static let firebaseProjectID = "whiff-1cd2b"
    
    /// Firebase Web API Key
    static let firebaseAPIKey = "AIzaSyBuyRbKSrmdJRCmbFH43NcExWVSzqSVwMI"
    
    // MARK: - 키 파일 정보
    /// Private Key 파일명 (실제 파일명으로 변경)
    /// 예: AuthKey_XYZ789ABC1.p8
    static let keyFileName = "AuthKey_43ZM224LTP.p8"
    
    // MARK: - 설정 검증
    /// Apple Sign In이 완전히 설정되었는지 확인
    static var isConfigured: Bool {
        return isEnabled && 
               teamID == "8BJS54K55Z" &&
               keyID == "43ZM224LTP" &&
               keyFileName == "AuthKey_43ZM224LTP.p8"
    }
    
    /// 설정 정보 출력
    static func printConfig() {
        print("🍎 === Apple Sign In 설정 정보 ===")
        print("🍎 활성화 여부: \(isEnabled ? "✅" : "❌")")
        print("🍎 Team ID: \(teamID)")
        print("🍎 Key ID: \(keyID)")
        print("🍎 Bundle ID: \(bundleID)")
        print("🍎 Service ID: \(serviceID)")
        print("🍎 Key File: \(keyFileName)")
        print("🍎 설정 완료: \(isConfigured ? "✅" : "❌")")
        print("🍎 =================================")
    }
    
    /// 설정 검증 및 경고
    static func validateConfig() {
        if isEnabled && !isConfigured {
            print("⚠️ Apple Sign In이 활성화되었지만 설정이 완료되지 않았습니다.")
            print("⚠️ Apple Developer Console에서 다음 정보를 설정해주세요:")
            print("   - Team ID: \(teamID)")
            print("   - Key ID: \(keyID)")
            print("   - Key File: \(keyFileName)")
        }
    }
} 