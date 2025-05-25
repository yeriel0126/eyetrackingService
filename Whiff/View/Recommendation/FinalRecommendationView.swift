import SwiftUI

struct FinalRecommendationView: View {
    let projectName: String
    let preferenceRatings: [UUID: Int]

    @State private var finalRecommendations: [Perfume] = []
    @State private var emotionSummary: String = ""
    @State private var isSaved = false
    @State private var isLoading = false
    @State private var error: Error?

    @EnvironmentObject var projectStore: ProjectStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(projectName)
                .font(.title)
                .bold()

            Text("Your final scent matches ✨")
                .font(.subheadline)
                .foregroundColor(.gray)

            if isLoading {
                ProgressView("Creating your final recommendations...")
            } else if let error = error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            } else if finalRecommendations.isEmpty {
                ProgressView("Creating your final recommendations...")
                    .onAppear {
                        Task {
                            await loadFinalResults()
                        }
                    }
            } else {
                // 감정 해석 문구
                Text("Emotional Insight")
                    .font(.headline)
                    .padding(.top, 12)

                Text(emotionSummary)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(finalRecommendations) { perfume in
                            NavigationLink(destination: PerfumeDetailView(perfume: perfume)) {
                                RecommendationCardView(perfume: perfume, matchScore: Int.random(in: 85...99))
                            }
                        }
                    }
                    .padding(.top)
                }

                // ✅ 저장 버튼
                if !isSaved {
                    Button("Save to My Collection") {
                        Task {
                            await saveToCollection()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    Label("Saved!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .padding(.top, 8)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Final Picks")
    }

    private func loadFinalResults() async {
        isLoading = true
        error = nil
        finalRecommendations = samplePerfumes
        emotionSummary = generateEmotionSummary(from: preferenceRatings)
        isLoading = false
    }
    
    private func saveToCollection() async {
        isLoading = true
        error = nil
        isSaved = true
        isLoading = false
    }

    private func generateEmotionSummary(from ratings: [UUID: Int]) -> String {
        let avg = Double(ratings.values.reduce(0, +)) / Double(ratings.count)
        switch avg {
        case 4.5...5: return "You love calm, elegant, and comforting scents."
        case 3.5..<4.5: return "You enjoy subtle, balanced fragrances with personality."
        case 2..<3.5: return "You may prefer bolder or more experimental scents."
        default: return "You're still exploring your scent journey."
        }
    }
}
