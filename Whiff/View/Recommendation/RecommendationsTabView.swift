import SwiftUI

struct RecommendationsTabView: View {
    @EnvironmentObject var projectStore: ProjectStore  // ✅ 선언 추가

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Recommendations")
                    .font(.largeTitle)
                    .bold()

                Text("Start a new project\nand discover your signature scent")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)

                NavigationLink(destination:
                    ProjectCreateView()
                        .environmentObject(projectStore)  // ✅ 전달 추가
                ) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Start New Scent Project")
                            .bold()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}
