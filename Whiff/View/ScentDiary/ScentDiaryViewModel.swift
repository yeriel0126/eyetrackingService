import Foundation
import SwiftUI

class ScentDiaryViewModel: ObservableObject {
    @Published var diaries: [ScentDiaryModel] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // 좋아요 상태를 저장하는 딕셔너리
    @Published private var likedDiaries: Set<String> = []
    
    init() {
        // TODO: 실제 데이터 로딩으로 대체
        loadMockData()
    }
    
    // 시간순으로 정렬된 일기 목록
    var sortedDiaries: [ScentDiaryModel] {
        diaries.sorted { $0.createdAt > $1.createdAt }
    }
    
    // 특정 일기의 좋아요 상태 확인
    func isLiked(_ diaryId: String) -> Bool {
        likedDiaries.contains(diaryId)
    }
    
    // 좋아요 토글
    func toggleLike(_ diaryId: String) {
        if likedDiaries.contains(diaryId) {
            likedDiaries.remove(diaryId)
            // 좋아요 수 감소
            if let index = diaries.firstIndex(where: { $0.id == diaryId }) {
                diaries[index].likes -= 1
            }
        } else {
            likedDiaries.insert(diaryId)
            // 좋아요 수 증가
            if let index = diaries.firstIndex(where: { $0.id == diaryId }) {
                diaries[index].likes += 1
            }
        }
    }
    
    // 목업 데이터 로딩
    private func loadMockData() {
        let mockPerfumes = [
            Perfume(id: "1", name: "블루 드 샤넬", brand: "샤넬", imageName: "perfume1", description: "상쾌한 시트러스 노트"),
            Perfume(id: "2", name: "미스 디올", brand: "디올", imageName: "perfume2", description: "우아한 플로럴 노트"),
            Perfume(id: "3", name: "블랙 오피엄", brand: "YSL", imageName: "perfume3", description: "깊이 있는 우드 노트")
        ]
        
        let mockDiaries = [
            ScentDiaryModel(
                id: "1",
                userId: "user1",
                userName: "향수 애호가",
                userProfileImage: "profile1",
                perfume: mockPerfumes[0],
                content: "오늘은 특별한 날이라 블루 드 샤넬을 뿌렸어요. 상쾌한 시트러스 노트가 하루를 시작하는데 좋은 에너지를 줍니다.",
                tags: ["신나는", "상쾌한", "시트러스"],
                likes: 15,
                comments: 3,
                createdAt: Date().addingTimeInterval(-3600) // 1시간 전
            ),
            ScentDiaryModel(
                id: "2",
                userId: "user2",
                userName: "향수 수집가",
                userProfileImage: "profile2",
                perfume: mockPerfumes[1],
                content: "미스 디올의 우아한 플로럴 노트가 오늘의 데이트를 더 특별하게 만들어줬어요.",
                tags: ["로맨틱", "플로럴", "우아한"],
                likes: 23,
                comments: 5,
                createdAt: Date().addingTimeInterval(-7200) // 2시간 전
            ),
            ScentDiaryModel(
                id: "3",
                userId: "user3",
                userName: "향수 매니아",
                userProfileImage: "profile3",
                perfume: mockPerfumes[2],
                content: "블랙 오피엄의 깊이 있는 우드 노트가 밤의 분위기를 더욱 매력적으로 만들어줍니다.",
                tags: ["깊이있는", "우드", "밤"],
                likes: 18,
                comments: 2,
                createdAt: Date().addingTimeInterval(-10800) // 3시간 전
            )
        ]
        
        self.diaries = mockDiaries
    }
} 