import SwiftUI

struct PreferenceRatingStepperView: View {
    let projectName: String
    let perfumes: [Perfume]
    let projectId: UUID
    
    @State private var currentIndex: Int = 0
    @State private var ratings: [UUID: Int] = [:]
    @State private var navigateToFinal = false
    @State private var showScentGuide = false
    @State private var isLoading = false
    @State private var error: Error?
    @State private var errorMessage: String?
    @EnvironmentObject var projectStore: ProjectStore

    let emojiMap: [Int: String] = [
        1: "😖", 2: "😕", 3: "😐", 4: "🙂", 5: "😄"
    ]
    
    var body: some View {
        NavigationStack {
            MainContentView(
                currentIndex: currentIndex,
                perfumes: perfumes,
                ratings: $ratings,
                isLoading: isLoading,
                error: error,
                emojiMap: emojiMap,
                onNext: { currentIndex += 1 },
                onSubmit: submitRatings
            )
            .padding()
            .navigationTitle("선호도 평가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showScentGuide = true }) {
                        Text("노트 가이드")
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToFinal) {
                FinalRecommendationView(
                    projectName: projectName,
                    preferenceRatings: ratings
                )
                .environmentObject(projectStore)
            }
            .sheet(isPresented: $showScentGuide) {
                ScentGuideView(showScentGuide: $showScentGuide)
            }
        }
    }
    
    private func submitRatings() async {
        isLoading = true
        error = nil
        errorMessage = nil
        
        do {
            try await projectStore.submitPreferenceRatings(projectId: projectId, ratings: ratings)
            navigateToFinal = true
        } catch {
            self.error = error
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

private struct MainContentView: View {
    let currentIndex: Int
    let perfumes: [Perfume]
    @Binding var ratings: [UUID: Int]
    let isLoading: Bool
    let error: Error?
    let emojiMap: [Int: String]
    let onNext: () -> Void
    let onSubmit: () async -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            if currentIndex < perfumes.count {
                RatingView(
                    perfume: perfumes[currentIndex],
                    ratings: $ratings,
                    emojiMap: emojiMap,
                    onNext: onNext
                )
            } else {
                CompletionView(
                    isLoading: isLoading,
                    error: error,
                    onSubmit: onSubmit
                )
            }
        }
    }
}

private struct RatingView: View {
    let perfume: Perfume
    @Binding var ratings: [UUID: Int]
    let emojiMap: [Int: String]
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            RecommendationCardView(perfume: perfume, matchScore: Int.random(in: 80...95))
                .padding(.top)
            
            RatingHeaderView()
            RatingEmojiSelector(perfume: perfume, ratings: $ratings, emojiMap: emojiMap)
            NextButton(perfume: perfume, ratings: ratings, onNext: onNext)
        }
    }
}

private struct RatingHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("이 향수는 어땠나요?")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("향조 구성을 보고 이 향수에 대한 선호도를 평가해주세요")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

private struct RatingEmojiSelector: View {
    let perfume: Perfume
    @Binding var ratings: [UUID: Int]
    let emojiMap: [Int: String]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(1...5, id: \.self) { value in
                Button(action: {
                    if let uuid = UUID(uuidString: perfume.id) {
                        ratings[uuid] = value
                    }
                }) {
                    Text(emojiMap[value]!)
                        .font(.system(size: 36))
                        .opacity(ratings[UUID(uuidString: perfume.id) ?? UUID()] == value ? 1.0 : 0.5)
                        .scaleEffect(ratings[UUID(uuidString: perfume.id) ?? UUID()] == value ? 1.2 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

private struct NextButton: View {
    let perfume: Perfume
    let ratings: [UUID: Int]
    let onNext: () -> Void
    
    var body: some View {
        Button(action: {
            if let uuid = UUID(uuidString: perfume.id), ratings[uuid] != nil {
                onNext()
            }
        }) {
            Text("다음")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(ratings[UUID(uuidString: perfume.id) ?? UUID()] == nil ? Color.gray.opacity(0.3) : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .contentShape(Rectangle())
        }
        .disabled(ratings[UUID(uuidString: perfume.id) ?? UUID()] == nil)
    }
}

private struct CompletionView: View {
    let isLoading: Bool
    let error: Error?
    let onSubmit: () async -> Void
    @State private var currentEmojiIndex = 0
    @State private var currentMessageIndex = 0
    
    private let loadingEmojis = ["🔍", "👃", "💭", "✨", "🎯", "💫", "🌟", "🎨"]
    private let loadingMessages = [
        "당신의 향수 취향을 분석하고 있어요...",
        "향수 노트를 하나하나 살펴보고 있어요...",
        "최적의 향수 조합을 찾고 있어요...",
        "당신만의 특별한 향수를 찾아볼게요...",
        "향수 데이터베이스를 검색하고 있어요...",
        "맞춤형 추천을 준비하고 있어요..."
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            Text("모든 향수를 평가했어요!")
                .font(.headline)
            
            if isLoading {
                LoadingView(
                    currentEmojiIndex: currentEmojiIndex,
                    currentMessageIndex: currentMessageIndex,
                    loadingEmojis: loadingEmojis,
                    loadingMessages: loadingMessages,
                    startEmojiAnimation: startEmojiAnimation,
                    startMessageAnimation: startMessageAnimation
                )
            } else {
                SubmitButton(onSubmit: onSubmit)
            }
            
            if let error = error {
                ErrorView(error: error)
            }
        }
    }
    
    private func startEmojiAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            withAnimation {
                currentEmojiIndex = (currentEmojiIndex + 1) % loadingEmojis.count
            }
        }
    }
    
    private func startMessageAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            withAnimation {
                currentMessageIndex = (currentMessageIndex + 1) % loadingMessages.count
            }
        }
    }
}

private struct LoadingView: View {
    let currentEmojiIndex: Int
    let currentMessageIndex: Int
    let loadingEmojis: [String]
    let loadingMessages: [String]
    let startEmojiAnimation: () -> Void
    let startMessageAnimation: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text(loadingEmojis[currentEmojiIndex])
                .font(.system(size: 60))
                .onAppear {
                    startEmojiAnimation()
                }
            
            Text(loadingMessages[currentMessageIndex])
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .onAppear {
                    startMessageAnimation()
                }
            
            ProgressView()
                .scaleEffect(1.5)
                .padding(.top, 16)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct SubmitButton: View {
    let onSubmit: () async -> Void
    
    var body: some View {
        Button("최종 추천 보기") {
            Task {
                await onSubmit()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(10)
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

private struct ScentGuideView: View {
    @Binding var showScentGuide: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("향조 가이드")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
                
                ScentCategoryView()
                ScentNoteView()
                
                Spacer()
                
                Button(action: {
                    showScentGuide = false
                }) {
                    Text("닫기")
                        .bold()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            }
            .padding()
        }
    }
}

private struct ScentCategoryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("향조 계열")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            Group {
                ScentCategoryItem(
                    title: "🌸 플로럴 (Floral)",
                    description: "부드럽고 여성스러운 꽃 향기. 봄에 어울리는 화사한 느낌.",
                    examples: "rose, jasmine, peony, lily, freesia, violet, magnolia, cherry blossom",
                    color: .blue
                )
                
                ScentCategoryItem(
                    title: "🌳 우디 (Woody)",
                    description: "따뜻하고 고요한 나무 향. 고급스럽고 안정적인 인상을 줍니다.",
                    examples: "sandalwood, cedar, vetiver, patchouli, oak, pine, guaiac wood, cypress",
                    color: .brown
                )
                
                // ... 나머지 카테고리 아이템들도 같은 방식으로 분리
            }
        }
        .padding(.horizontal)
    }
}

private struct ScentCategoryItem: View {
    let title: String
    let description: String
    let examples: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(color)
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
            Text("예시: \(examples)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

private struct ScentNoteView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("개별 향조 설명")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            Group {
                ForEach(scentNotes, id: \.self) { note in
                    Text("• \(note)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private let scentNotes = [
        "Bergamot: 상큼하고 시트러스한 향으로 향수에 생기를 부여함",
        "Cedar: 건조하고 우디한 느낌으로 베이스 노트에 자주 사용",
        // ... 나머지 노트들
    ]
}

