import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // 타이틀
                Text("Whiff")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 40)

                // 기능 카드
                VStack(spacing: 20) {
                    NavigationLink(destination: CollectionView()) {
                        HomeCardView(
                            iconName: "archivebox.fill",
                            title: "My Collection",
                            subtitle: "Manage your saved scent projects"
                        )
                    }

                    NavigationLink(destination: RecommendationsTabView()) {
                        HomeCardView(
                            iconName: "sparkles",
                            title: "Recommendations",
                            subtitle: "Get personalized perfume suggestions"
                        )
                    }

                    NavigationLink(destination: ScentDiaryView()) {
                        HomeCardView(
                            iconName: "book.closed.fill",
                            title: "Scent Diary",
                            subtitle: "Write and review your scent memories"
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}
