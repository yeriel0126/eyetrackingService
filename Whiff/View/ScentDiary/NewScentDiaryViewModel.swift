import Foundation
import SwiftUI
import Combine

class NewScentDiaryViewModel: ObservableObject {
    @Published var selectedPerfume: Perfume?
    @Published var selectedImage: UIImage?
    @Published var content: String = ""
    @Published var tagInput: String = ""
    @Published var tags: [String] = []
    @Published var isPublic: Bool = true
    @Published var error: Error?
    @Published var isLoading = false
    
    private let apiClient = APIClient.shared
    
    func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            tagInput = ""
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func saveDiary() async throws {
        guard !content.isEmpty else {
            throw DiaryError.emptyContent
        }
        
        guard let perfume = selectedPerfume else {
            throw DiaryError.noPerfumeSelected
        }
        
        isLoading = true
        error = nil
        
        do {
            let diary = ScentDiaryModel(
                id: UUID().uuidString,
                userId: UserDefaults.standard.string(forKey: "userId") ?? "",
                userName: UserDefaults.standard.string(forKey: "userName") ?? "사용자",
                perfumeId: perfume.id,
                perfumeName: perfume.name,
                brand: perfume.brand,
                content: content,
                tags: tags,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await apiClient.createDiary(diary: diary)
        } catch {
            self.error = error
            throw error
        }
        
        isLoading = false
    }
}

enum DiaryError: LocalizedError {
    case emptyContent
    case noPerfumeSelected
    case invalidImage
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "일기 내용을 입력해주세요."
        case .noPerfumeSelected:
            return "향수를 선택해주세요."
        case .invalidImage:
            return "이미지 처리 중 오류가 발생했습니다."
        case .saveFailed:
            return "일기 저장에 실패했습니다."
        }
    }
} 