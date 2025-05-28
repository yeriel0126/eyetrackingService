// ✅ ProjectCreateView.swift (iOS 16+ 최신 구조 적용)
import SwiftUI

struct ProjectCreateView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var projectName: String = ""
    @State private var goNext: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("프로젝트 이름을 입력해주세요")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("프로젝트 이름", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                goNext = true
            }) {
                Text("다음")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(projectName.isEmpty)
            
            NavigationLink(destination: SurveyView(), isActive: $goNext) {
                EmptyView()
            }
        }
        .padding()
    }
}
