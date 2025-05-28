import Foundation

struct ScentDiary: Identifiable, Codable {
    let id: String
    let userId: String
    let content: String
    let imageURL: String?
    let perfumeId: String?
    let createdAt: Date
    var likeCount: Int
    var isLiked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case content
        case imageURL = "image_url"
        case perfumeId = "perfume_id"
        case createdAt = "created_at"
        case likeCount = "like_count"
        case isLiked = "is_liked"
    }
} 