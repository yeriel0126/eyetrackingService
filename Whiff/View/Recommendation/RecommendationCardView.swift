import SwiftUI

struct RecommendationCardView: View {
    let perfume: Perfume
    let matchScore: Int  // 예: 87

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 웹 이미지 로딩
            AsyncImage(url: URL(string: perfume.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(12)
                case .failure(_):
                    Color.gray
                        .frame(height: 160)
                        .cornerRadius(12)
                case .empty:
                    ProgressView()
                        .frame(height: 160)
                @unknown default:
                    EmptyView()
                }
            }

            Text(perfume.brand)
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(perfume.name)
                .font(.headline)

            Text("Match: \(matchScore)%")
                .font(.caption)
                .foregroundColor(.blue)

            // 노트 정보 섹션
            VStack(alignment: .leading, spacing: 12) {
                Text("향조 구성")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(perfume.notes.top.joined(separator: ", "))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}
