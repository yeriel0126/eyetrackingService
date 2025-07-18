import Foundation
import CryptoKit

class AppleSignInKeyManager {
    
    /// 키 파일 경로 (Bundle에서 찾기)
    private static var keyFileName: String {
        return AppleSignInConfig.keyFileName
    }
    
    /// 키 파일에서 Private Key 읽기
    static func getPrivateKey() -> String? {
        guard let path = Bundle.main.path(forResource: keyFileName.replacingOccurrences(of: ".p8", with: ""), ofType: "p8") else {
            print("❌ Apple Sign In 키 파일을 찾을 수 없습니다: \(keyFileName)")
            return nil
        }
        
        do {
            let privateKey = try String(contentsOfFile: path, encoding: .utf8)
            print("✅ Apple Sign In 키 파일 로드 성공")
            return privateKey
        } catch {
            print("❌ Apple Sign In 키 파일 읽기 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// JWT 토큰 생성 (필요한 경우)
    static func generateJWTToken() -> String? {
        // JWT 토큰 생성 로직
        // 실제 구현에서는 JWT 라이브러리 사용 권장
        return nil
    }
    
    /// 키 파일 존재 여부 확인
    static func isKeyFileExists() -> Bool {
        return Bundle.main.path(forResource: keyFileName.replacingOccurrences(of: ".p8", with: ""), ofType: "p8") != nil
    }
    
    /// 키 파일 정보 출력
    static func printKeyFileInfo() {
        print("🍎 === Apple Sign In 키 파일 정보 ===")
        print("🍎 키 파일 존재: \(isKeyFileExists())")
        print("🍎 예상 키 파일명: \(keyFileName)")
        
        if let privateKey = getPrivateKey() {
            print("🍎 키 파일 로드 성공 (길이: \(privateKey.count) 문자)")
        } else {
            print("🍎 키 파일 로드 실패")
        }
        print("🍎 =================================")
    }
}

// MARK: - Apple Sign In 설정 정보
/// Apple Sign In 설정 정보
/// Apple Developer Console 담당자로부터 받은 정보를 여기에 입력하세요
struct AppleSignInConfig {
    
    // MARK: - Apple Developer Console 정보
    /// Apple Developer Team ID (10자리 영숫자)
    /// 예: ABC123DEF4
    static let teamID = "YOUR_TEAM_ID_HERE"
    
    /// Apple Developer Key ID (10자리 영숫자)
    /// 예: XYZ789ABC1
    static let keyID = "YOUR_KEY_ID_HERE"
    
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
    static let keyFileName = "AuthKey_YOUR_KEY_ID_HERE.p8"
    
    // MARK: - 설정 검증
    /// 모든 필수 정보가 입력되었는지 확인
    static var isConfigured: Bool {
        return teamID != "YOUR_TEAM_ID_HERE" &&
               keyID != "YOUR_KEY_ID_HERE" &&
               keyFileName != "AuthKey_YOUR_KEY_ID_HERE.p8"
    }
    
    /// 설정 정보 출력
    static func printConfig() {
        print("🍎 === Apple Sign In 설정 정보 ===")
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
        if !isConfigured {
            print("⚠️ Apple Sign In 설정이 완료되지 않았습니다!")
            print("⚠️ AppleSignInKeyManager.swift에서 다음 정보를 입력하세요:")
            print("⚠️ - teamID: Apple Developer Team ID")
            print("⚠️ - keyID: Apple Developer Key ID")
            print("⚠️ - keyFileName: Private Key 파일명")
        }
    }
} 