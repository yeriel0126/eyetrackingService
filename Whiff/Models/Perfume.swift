import Foundation

struct Perfume: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String
    let description: String
    let notes: [String]
    let imageUrl: String
    let price: Double
    let rating: Double
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case description
        case notes
        case imageUrl = "image_url"
        case price
        case rating
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PerfumeDetail: Codable {
    let perfume: Perfume
    let topNotes: [String]
    let middleNotes: [String]
    let baseNotes: [String]
    let longevity: Int
    let sillage: Int
    let seasonality: [String]
    let occasions: [String]
    
    enum CodingKeys: String, CodingKey {
        case perfume
        case topNotes = "top_notes"
        case middleNotes = "middle_notes"
        case baseNotes = "base_notes"
        case longevity
        case sillage
        case seasonality
        case occasions
    }
}
