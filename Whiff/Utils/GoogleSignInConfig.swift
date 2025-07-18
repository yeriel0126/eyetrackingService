import Foundation

/// Google Sign In 활성화/비활성화 설정
struct GoogleSignInConfig {
    
    // MARK: - Google Sign In 활성화 여부
    /// Google Sign In 기능을 활성화할지 여부
    /// 개발 단계에서는 false로 설정, Firebase 설정 완료 후 true로 변경
    static let isEnabled = false
    
    // MARK: - Firebase 정보
    /// Firebase 프로젝트 ID
    static let firebaseProjectID = "whiff-1cd2b"
    
    /// Firebase Web API Key
    static let firebaseAPIKey = "AIzaSyBuyRbKSrmdJRCmbFH43NcExWVSzqSVwMI"
    
    /// Google Client ID (Firebase에서 자동 생성)
    static let googleClientID = "494222107612-4inferv7ml6hoa1mvam1n00463tng972.apps.googleusercontent.com"
    
    // MARK: - Bundle ID 정보
    /// 현재 앱의 Bundle ID
    static let bundleID = "com.sinhuiyeong.whiff"
    
    // MARK: - 설정 검증
    /// Google Sign In이 완전히 설정되었는지 확인
    static var isConfigured: Bool {
        return isEnabled && 
               !googleClientID.isEmpty &&
               !firebaseProjectID.isEmpty
    }
    
    /// 설정 정보 출력
    static func printConfig() {
        print("🔵 === Google Sign In 설정 정보 ===")
        print("🔵 활성화 여부: \(isEnabled ? "✅" : "❌")")
        print("🔵 Firebase 프로젝트 ID: \(firebaseProjectID)")
        print("🔵 Google Client ID: \(googleClientID)")
        print("🔵 Bundle ID: \(bundleID)")
        print("🔵 설정 완료: \(isConfigured ? "✅" : "❌")")
        print("🔵 =================================")
    }
    
    /// 설정 검증 및 경고
    static func validateConfig() {
        if isEnabled && !isConfigured {
            print("⚠️ Google Sign In이 활성화되었지만 설정이 완료되지 않았습니다.")
            print("⚠️ Firebase Console에서 다음 설정을 확인해주세요:")
            print("   - Google Client ID: \(googleClientID)")
            print("   - Bundle ID: \(bundleID)")
        }
    }
} 