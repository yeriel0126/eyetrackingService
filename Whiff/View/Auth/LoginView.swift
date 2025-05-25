import SwiftUI
import GoogleSignInSwift

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
                
                Button("계정이 없으신가요? 회원가입") {
                    showSignUp = true
                }
                .foregroundColor(.accentColor)
                
                if let error = authViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
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