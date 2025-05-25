import Foundation

struct PreferenceRating: Codable {
    let perfumeId: String
    let rating: Int
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case perfumeId = "perfume_id"
        case rating
        case notes
    }
}

struct Project: Codable, Identifiable {
    let id: String
    let name: String
    let userId: String
    let preferences: [PreferenceRating]
    let recommendations: [Perfume]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case userId = "user_id"
        case preferences
        case recommendations
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 