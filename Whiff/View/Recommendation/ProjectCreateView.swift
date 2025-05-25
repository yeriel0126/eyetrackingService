// ✅ ProjectCreateView.swift (iOS 16+ 최신 구조 적용)
import SwiftUI

struct ProjectCreateView: View {
    @State private var projectName: String = ""
    @State private var goNext = false
    @EnvironmentObject var projectStore: ProjectStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("새로운 추천 프로젝트의 이름을 입력해주세요")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top, 60)

                TextField("프로젝트 이름", text: $projectName)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)

                Spacer()

                Button(action: {
                    goNext = true
                }) {
                    Text("다음")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(projectName.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(projectName.isEmpty)
                .padding(.horizontal, 24)
            }
            .padding()
            .navigationDestination(isPresented: $goNext) {
                SurveyView(projectName: projectName)
                    .environmentObject(projectStore)
            }
        }
    }
}
