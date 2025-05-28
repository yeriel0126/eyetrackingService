import SwiftUI

struct RecommendationResultView: View {
    let project: ProjectModel
    @StateObject private var viewModel = RecommendationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            RecommendationContentView(
                project: project,
                recommendations: $viewModel.recommendations,
                onDismiss: { dismiss() }
            )
            .task {
                do {
                    try await viewModel.getRecommendations(projectId: project.id)
                } catch {
                    print("Error fetching recommendations: \(error)")
                }
            }
        }
    }
}

private struct RecommendationContentView: View {
    let project: ProjectModel
    @Binding var recommendations: [PerfumeRecommendation]
    let onDismiss: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProjectHeaderView(project: project, recommendationCount: recommendations.count)
                RecommendationListView(recommendations: recommendations)
            }
            .padding(.vertical)
        }
        .navigationTitle("추천 결과")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료", action: onDismiss)
            }
        }
    }
}

private struct ProjectHeaderView: View {
    let project: ProjectModel
    let recommendationCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text("추천된 향수 \(recommendationCount)개")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

private struct RecommendationListView: View {
    let recommendations: [PerfumeRecommendation]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(recommendations) { recommendation in
                PerfumeCard(perfume: Perfume(
                    id: recommendation.id ?? "",
                    name: recommendation.name,
                    brand: recommendation.brand,
                    imageURL: recommendation.imageUrl ?? "",
                    price: 0,
                    description: recommendation.notes ?? "",
                    notes: PerfumeNotes(top: [], middle: [], base: []),
                    rating: recommendation.score ?? 0,
                    emotionTags: recommendation.emotionTags ?? [],
                    similarity: Double(recommendation.similarity ?? "0") ?? 0
                ))
                .onTapGesture {
                    // TODO: 향수 상세 페이지로 이동
                }
            }
        }
        .padding(.horizontal)
    }
}

struct PerfumeCard: View {
    let perfume: Perfume
    
    var body: some View {
        HStack(spacing: 16) {
            // 향수 이미지
            AsyncImage(url: URL(string: perfume.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 향수 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(perfume.name)
                    .font(.headline)
                
                Text(perfume.brand)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(perfume.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 화살표 아이콘
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecommendationResultView_Previews: PreviewProvider {
    static var previews: some View {
        let dateFormatter = ISO8601DateFormatter()
        let now = dateFormatter.string(from: Date())
        
        return RecommendationResultView(project: ProjectModel(
            id: "1",
            name: "샘플 프로젝트",
            userId: "user1",
            preferences: [],
            recommendations: [],
            createdAt: dateFormatter.date(from: now)!,
            updatedAt: dateFormatter.date(from: now)!,
            tags: ["sample"],
            isFavorite: false
        ))
    }
}
