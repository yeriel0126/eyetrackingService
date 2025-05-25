import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("회원가입")
                .font(.title)
                .bold()
            
            VStack(spacing: 16) {
                TextField("이름", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.name)
                
                TextField("이메일", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("비밀번호", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.newPassword)
                
                SecureField("비밀번호 확인", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.newPassword)
            }
            .padding(.horizontal)
            
            Button(action: {
                Task {
                    await authViewModel.signUp(email: email, password: password, name: name)
                }
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("회원가입")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(authViewModel.isLoading || !isFormValid)
            
            if let error = authViewModel.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("뒤로") {
                    dismiss()
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !name.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
} 