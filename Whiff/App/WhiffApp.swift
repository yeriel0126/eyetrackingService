import SwiftUI
import FirebaseCore
import GoogleSignIn

/*
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
//    func application(_ app: UIApplication,
//                    open url: URL,
//                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
//        return GIDSignIn.sharedInstance.handle(url)
//    }
}
*/

@main
struct WhiffApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
        
        // Apple 로그인 설정 검증
        AppleSignInConfig.validateConfig()
        AppleSignInConfig.printConfig()
        
        // Google 로그인 설정 검증
        GoogleSignInConfig.validateConfig()
        GoogleSignInConfig.printConfig()
        
        // Apple 로그인 디버그 정보 출력
        AppleSignInUtils.printAppleSignInDebugInfo()
        AppleSignInKeyManager.printKeyFileInfo()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    if GIDSignIn.sharedInstance.handle(url) {
                        return
                    }
                }
        }
    }
} 