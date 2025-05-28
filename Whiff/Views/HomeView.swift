import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var searchText = ""
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 검색바
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    // 추천 섹션
                    if !viewModel.recommendedPerfumes.isEmpty {
                        VStack(alignment: .leading) {
                            Text("추천 향수")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.recommendedPerfumes) { perfume in
                                        NavigationLink(destination: PerfumeDetailView(perfumeId: perfume.id)) {
                                            PerfumeCard(perfume: perfume)
                                                .frame(width: 160)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 전체 향수 목록
                    VStack(alignment: .leading) {
                        Text("전체 향수")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.perfumes) { perfume in
                                NavigationLink(destination: PerfumeDetailView(perfumeId: perfume.id)) {
                                    PerfumeCard(perfume: perfume)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Whiff")
            .refreshable {
                await viewModel.fetchPerfumes()
            }
            .task {
                await viewModel.fetchPerfumes()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("오류", isPresented: $viewModel.showError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - ViewModel
class HomeViewModel: ObservableObject {
    @Published var perfumes: [Perfume] = []
    @Published var recommendedPerfumes: [Perfume] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    func fetchPerfumes() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let fetchedPerfumes = try await NetworkManager.shared.fetchPerfumes()
            await MainActor.run {
                self.perfumes = fetchedPerfumes
                self.recommendedPerfumes = Array(fetchedPerfumes.prefix(5)) // 임시로 처음 5개를 추천으로 표시
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
}

// MARK: - Supporting Views
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("향수 검색", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct PerfumeCard: View {
    let perfume: Perfume
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 이미지
            AsyncImage(url: URL(string: perfume.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 브랜드
            Text(perfume.brand)
                .font(.caption)
                .foregroundColor(.gray)
            
            // 이름
            Text(perfume.name)
                .font(.headline)
                .lineLimit(2)
            
            // 가격
            Text("₩\(Int(perfume.price))")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // 평점
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", perfume.rating))
                    .font(.caption)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    HomeView()
} 