import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Whiff")
                    .font(.largeTitle)
                    .bold()
                
                Text("나만의 향수를 찾아보세요")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                VStack(spacing: 16) {
                    TextField("이메일", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("비밀번호", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await authViewModel.signInWithEmail(email: email, password: password)
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("로그인")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(authViewModel.isLoading)
                
                Text("또는")
                    .foregroundColor(.gray)
                
                GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
                    Task {
                        await authViewModel.signInWithGoogle()
                    }
                }
                .frame(width: 280, height: 50)
                
                // Apple Sign In 버튼 (설정에 따라 표시/숨김)
                if AppleSignInConfig.isEnabled {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task {
                                await authViewModel.signInWithApple(result: result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(width: 280, height: 50)
                }
                
                Button("계정이 없으신가요? 회원가입") {
                    showSignUp = true
                }
                .foregroundColor(.accentColor)
                
                if let error = authViewModel.error {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: error.localizedDescription.contains("서버") ? "network.slash" : "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                                .font(.caption)
                            Spacer()
                        }
                        
                        if error.localizedDescription.contains("502") || error.localizedDescription.contains("일시적") {
                            VStack(spacing: 4) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.orange)
                                    Text("서버가 잠시 후 복구될 예정입니다")
                                        .foregroundColor(.orange)
                                        .font(.caption2)
                                    Spacer()
                                }
                                
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                    Text("무료 서버 사용으로 인한 일시적 지연일 수 있습니다")
                                        .foregroundColor(.blue)
                                        .font(.caption2)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
} 