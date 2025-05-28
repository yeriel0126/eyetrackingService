import Foundation

struct PreferenceRating: Codable {
    let perfumeId: String
    let rating: Int
    let notes: String
    
    enum CodingKeys: String, CodingKey {
        case perfumeId = "perfume_id"
        case rating
        case notes
    }
    
    init(perfumeId: String, rating: Int, notes: String = "") {
        self.perfumeId = perfumeId
        self.rating = rating
        self.notes = notes
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
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case userId = "user_id"
        case preferences
        case recommendations
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        userId = try container.decode(String.self, forKey: .userId)
        preferences = try container.decode([PreferenceRating].self, forKey: .preferences)
        recommendations = try container.decode([Perfume].self, forKey: .recommendations)
        tags = try container.decode([String].self, forKey: .tags)
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        guard let createdAtDate = dateFormatter.date(from: createdAtString),
              let updatedAtDate = dateFormatter.date(from: updatedAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format")
        }
        
        createdAt = createdAtDate
        updatedAt = updatedAtDate
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(userId, forKey: .userId)
        try container.encode(preferences, forKey: .preferences)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(tags, forKey: .tags)
        
        let dateFormatter = ISO8601DateFormatter()
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
} 