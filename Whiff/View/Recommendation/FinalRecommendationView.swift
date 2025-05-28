import SwiftUI

struct FinalRecommendationView: View {
    let projectName: String
    let preferenceRatings: [UUID: Int]

    @State private var finalRecommendations: [PerfumeRecommendation] = []
    @State private var emotionSummary: String = ""
    @State private var isSaved = false
    @State private var isLoading = false
    @State private var error: Error?
    @State private var userRatings: [String: Int] = [:]

    @EnvironmentObject var projectStore: ProjectStore
    private let apiClient = APIClient.shared
    private let networkManager = NetworkManager.shared

    var body: some View {
        MainContainerView(
            projectName: projectName,
            isLoading: isLoading,
            error: error,
            finalRecommendations: finalRecommendations,
            emotionSummary: emotionSummary,
            userRatings: $userRatings,
            isSaved: $isSaved,
            onAppear: {
                Task {
                    await loadFinalResults()
                }
            },
            onSave: {
                Task {
                    await saveToCollection()
                }
            }
        )
        .padding()
        .navigationTitle("Final Picks")
    }

    private func loadFinalResults() async {
        isLoading = true
        error = nil
        
        do {
            // 백엔드에서 추천 결과 가져오기
            let recommendations = try await apiClient.getRecommendations(projectId: projectName)
            finalRecommendations = recommendations.map { perfume in
                PerfumeRecommendation(
                    id: perfume.id,
                    name: perfume.name,
                    brand: perfume.brand,
                    notes: perfume.notes.top.joined(separator: ", "),
                    imageUrl: perfume.imageURL,
                    score: perfume.rating,
                    emotionTags: perfume.emotionTags,
                    similarity: String(format: "%.2f", perfume.similarity)
                )
            }
            emotionSummary = generateEmotionSummary(from: preferenceRatings)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func saveToCollection() async {
        isLoading = true
        error = nil
        
        do {
            // 1. 선호도 저장
            let perfumeScores = finalRecommendations.map { recommendation in
                PerfumeScore(
                    id: recommendation.id ?? "",
                    score: Double(userRatings[recommendation.id ?? ""] ?? 0) / 5.0
                )
            }
            
            try await networkManager.saveRecommendations(
                userId: UserDefaults.standard.string(forKey: "userId") ?? "",
                recommendRound: 1,
                recommendations: perfumeScores
            )
            
            // 2. 새로운 추천 결과 받아오기
            let newRecommendations = try await apiClient.getRecommendations(projectId: projectName)
            finalRecommendations = newRecommendations.map { perfume in
                PerfumeRecommendation(
                    id: perfume.id,
                    name: perfume.name,
                    brand: perfume.brand,
                    notes: perfume.notes.top.joined(separator: ", "),
                    imageUrl: perfume.imageURL,
                    score: perfume.rating,
                    emotionTags: perfume.emotionTags,
                    similarity: String(format: "%.2f", perfume.similarity)
                )
            }
            
            // 3. 선호도 초기화
            userRatings.removeAll()
            
            isSaved = true
        } catch {
            self.error = error
        }
        
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

// MARK: - Main Container View
private struct MainContainerView: View {
    let projectName: String
    let isLoading: Bool
    let error: Error?
    let finalRecommendations: [PerfumeRecommendation]
    let emotionSummary: String
    @Binding var userRatings: [String: Int]
    @Binding var isSaved: Bool
    let onAppear: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(projectName: projectName)
            
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(error: error)
            } else if finalRecommendations.isEmpty {
                LoadingView()
                    .onAppear(perform: onAppear)
            } else {
                ContentContainerView(
                    recommendations: finalRecommendations,
                    emotionSummary: emotionSummary,
                    userRatings: $userRatings,
                    isSaved: $isSaved,
                    onSave: onSave
                )
            }
            
            Spacer()
        }
    }
}

// MARK: - Content Container View
private struct ContentContainerView: View {
    let recommendations: [PerfumeRecommendation]
    let emotionSummary: String
    @Binding var userRatings: [String: Int]
    @Binding var isSaved: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            EmotionSummaryView(summary: emotionSummary)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recommendations) { recommendation in
                        RecommendationItemView(
                            recommendation: recommendation,
                            rating: Binding(
                                get: { userRatings[recommendation.id ?? ""] ?? 0 },
                                set: { userRatings[recommendation.id ?? ""] = $0 }
                            )
                        )
                    }
                }
                .padding(.top)
            }
            
            SaveButton(isSaved: isSaved, onSave: onSave)
        }
    }
}

// MARK: - Recommendation List View
private struct RecommendationListView: View {
    let recommendations: [PerfumeRecommendation]
    let emotionSummary: String
    @Binding var userRatings: [String: Int]
    @Binding var isSaved: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            EmotionSummaryView(summary: emotionSummary)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recommendations) { recommendation in
                        RecommendationItemView(
                            recommendation: recommendation,
                            rating: Binding(
                                get: { userRatings[recommendation.id ?? ""] ?? 0 },
                                set: { userRatings[recommendation.id ?? ""] = $0 }
                            )
                        )
                    }
                }
                .padding(.top)
            }
            
            SaveButton(isSaved: isSaved, onSave: onSave)
        }
    }
}

// MARK: - Recommendation Item View
private struct RecommendationItemView: View {
    let recommendation: PerfumeRecommendation
    @Binding var rating: Int
    
    var body: some View {
        VStack(spacing: 8) {
            NavigationLink(destination: PerfumeDetailView(perfume: recommendation)) {
                RecommendationCardView(
                    perfume: createPerfume(from: recommendation),
                    matchScore: Int((recommendation.score ?? 0.0) * 100)
                )
            }
            
            RatingSliderView(rating: $rating)
        }
    }
    
    private func createPerfume(from recommendation: PerfumeRecommendation) -> Perfume {
        Perfume(
            id: recommendation.id ?? "",
            name: recommendation.name,
            brand: recommendation.brand,
            imageURL: recommendation.imageUrl ?? "",
            price: 0.0,
            description: "",
            notes: PerfumeNotes(top: [], middle: [], base: []),
            rating: recommendation.score ?? 0.0,
            emotionTags: recommendation.emotionTags ?? [],
            similarity: Double(recommendation.similarity ?? "0.0") ?? 0.0
        )
    }
}

// MARK: - Rating Slider View
private struct RatingSliderView: View {
    @Binding var rating: Int
    
    var body: some View {
        HStack {
            Text("선호도")
                .font(.caption)
                .foregroundColor(.gray)
            
            Slider(
                value: Binding(
                    get: { Double(rating) },
                    set: { rating = Int($0) }
                ),
                in: 0...5,
                step: 1
            )
            
            Text("\(rating)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

// MARK: - Subviews
private struct HeaderView: View {
    let projectName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(projectName)
                .font(.title)
                .bold()
            
            Text("Your final scent matches ✨")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

private struct LoadingView: View {
    var body: some View {
        ProgressView("Creating your final recommendations...")
    }
}

private struct ErrorView: View {
    let error: Error
    
    var body: some View {
        Text(error.localizedDescription)
            .foregroundColor(.red)
            .font(.caption)
            .padding(.top, 8)
    }
}

private struct EmotionSummaryView: View {
    let summary: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emotional Insight")
                .font(.headline)
                .padding(.top, 12)
            
            Text(summary)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 8)
        }
    }
}

private struct SaveButton: View {
    let isSaved: Bool
    let onSave: () -> Void
    
    var body: some View {
        if !isSaved {
            Button("Save to My Collection", action: onSave)
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
}
