import Foundation

struct Perfume: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String
    let description: String
    let imageURL: String
    let notes: [String]
    let price: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case description
        case imageURL = "image_url"
        case notes
        case price
    }
} 