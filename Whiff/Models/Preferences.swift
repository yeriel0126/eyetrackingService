import Foundation

struct PerfumePreferences: Codable {
    let gender: String
    let season: String
    let time: String
    let impression: String
    let activity: String
    let weather: String
    
    enum CodingKeys: String, CodingKey {
        case gender
        case season
        case time
        case impression
        case activity
        case weather
    }
}

struct UserPreferences: Codable {
    let preferredNotes: [String]
    let preferredBrands: [String]
    let priceRange: ClosedRange<Double>
    let preferredGender: String
    
    enum CodingKeys: String, CodingKey {
        case preferredNotes = "preferred_notes"
        case preferredBrands = "preferred_brands"
        case priceRange = "price_range"
        case preferredGender = "preferred_gender"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preferredNotes = try container.decode([String].self, forKey: .preferredNotes)
        preferredBrands = try container.decode([String].self, forKey: .preferredBrands)
        let priceRangeArray = try container.decode([Double].self, forKey: .priceRange)
        guard priceRangeArray.count == 2 else {
            throw DecodingError.dataCorruptedError(forKey: .priceRange, in: container, debugDescription: "Price range must contain exactly two values")
        }
        priceRange = priceRangeArray[0]...priceRangeArray[1]
        preferredGender = try container.decode(String.self, forKey: .preferredGender)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(preferredNotes, forKey: .preferredNotes)
        try container.encode(preferredBrands, forKey: .preferredBrands)
        try container.encode([priceRange.lowerBound, priceRange.upperBound], forKey: .priceRange)
        try container.encode(preferredGender, forKey: .preferredGender)
    }
} 