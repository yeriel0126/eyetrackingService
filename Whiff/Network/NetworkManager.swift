import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://perfume-recommendation-api-1.onrender.com"
    
    private init() {}
    
    // MARK: - API Methods
    
    func fetchPerfumes() async throws -> [Perfume] {
        let url = URL(string: "\(baseURL)/perfumes")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Perfume].self, from: data)
    }
    
    func fetchPerfumeDetail(id: String) async throws -> PerfumeDetail {
        let url = URL(string: "\(baseURL)/perfumes/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PerfumeDetail.self, from: data)
    }
    
    func searchPerfumes(query: String) async throws -> [Perfume] {
        let url = URL(string: "\(baseURL)/perfumes/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Perfume].self, from: data)
    }
    
    func getRecommendations(userPreferences: UserPreferences) async throws -> [Perfume] {
        let url = URL(string: "\(baseURL)/recommendations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(userPreferences)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Perfume].self, from: data)
    }
}

// MARK: - Models

struct Perfume: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String
    let imageURL: String
    let price: Double
    let description: String
    let notes: [String]
    let rating: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case imageURL = "image_url"
        case price
        case description
        case notes
        case rating
    }
}

struct PerfumeDetail: Codable {
    let id: String
    let name: String
    let brand: String
    let imageURL: String
    let price: Double
    let description: String
    let notes: [String]
    let rating: Double
    let reviews: [Review]
    let similarPerfumes: [Perfume]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case imageURL = "image_url"
        case price
        case description
        case notes
        case rating
        case reviews
        case similarPerfumes = "similar_perfumes"
    }
}

struct Review: Codable {
    let id: String
    let userId: String
    let userName: String
    let rating: Int
    let comment: String
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case rating
        case comment
        case date
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(preferredNotes, forKey: .preferredNotes)
        try container.encode(preferredBrands, forKey: .preferredBrands)
        try container.encode([priceRange.lowerBound, priceRange.upperBound], forKey: .priceRange)
        try container.encode(preferredGender, forKey: .preferredGender)
    }
} 