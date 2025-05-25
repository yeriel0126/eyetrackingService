import SwiftUI

struct RecommendationResultView: View {
    let projectName: String
    let gender: String
    let season: String
    let time: String
    let impression: String
    let activity: String
    let weather: String

    @State private var recommendedPerfumes: [Perfume] = []
    @EnvironmentObject var projectStore: ProjectStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(projectName)
                .font(.title)
                .bold()

            Text("Here are your personalized scent matches 🌿")
                .font(.subheadline)
                .foregroundColor(.gray)

            if recommendedPerfumes.isEmpty {
                Spacer()
                ProgressView("Finding your perfect scents...")
                    .onAppear {
                        loadRecommendations()
                    }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(recommendedPerfumes) { perfume in
                            RecommendationCardView(perfume: perfume, matchScore: Int.random(in: 75...95))
                        }
                    }
                }

                NavigationLink(destination:
                    PreferenceRatingStepperView(
                        projectName: projectName,
                        perfumes: recommendedPerfumes
                    )
                    .environmentObject(projectStore)
                ) {
                    Text("Evaluate Preferences")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Recommendations")
    }

    func loadRecommendations() {
        // TODO: 실제 추천 로직 구현
        recommendedPerfumes = samplePerfumes
    }
}
