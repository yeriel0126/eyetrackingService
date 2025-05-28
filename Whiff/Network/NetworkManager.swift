import Foundation

// MARK: - Models

// Perfume 타입은 Models/Perfume.swift에서 가져옴

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

// MARK: - Network Models

struct PerfumeScoreRequest: Codable {
    let perfumeName: String
    let perfumeBrand: String
    let score: Int?
    
    enum CodingKeys: String, CodingKey {
        case perfumeName = "perfume_name"
        case perfumeBrand = "perfume_brand"
        case score
    }
}

struct SaveRecommendationsRequest: Codable {
    let userId: String
    let recommendRound: Int
    let recommendations: [PerfumeScoreRequest]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case recommendRound = "recommend_round"
        case recommendations
    }
}

struct PerfumeFilters: Codable {
    let brand: String?
    let priceRange: ClosedRange<Double>?
    let gender: String?
    let sortBy: String?
    
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let brand = brand {
            items.append(URLQueryItem(name: "brand", value: brand))
        }
        if let priceRange = priceRange {
            items.append(URLQueryItem(name: "min_price", value: String(priceRange.lowerBound)))
            items.append(URLQueryItem(name: "max_price", value: String(priceRange.upperBound)))
        }
        if let gender = gender {
            items.append(URLQueryItem(name: "gender", value: gender))
        }
        if let sortBy = sortBy {
            items.append(URLQueryItem(name: "sort_by", value: sortBy))
        }
        return items
    }
}

// MARK: - NetworkManager

class NetworkManager {
    static let shared = NetworkManager()
    let baseURL = "https://api.whiff.com"
    
    private init() {}
    
    // MARK: - 향수 추천 API
    
    func getPerfumeRecommendations(preferences: PerfumePreferences) async throws -> [PerfumeRecommendation] {
        let url = URL(string: "\(baseURL)/recommendations")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(preferences)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([PerfumeRecommendation].self, from: data)
    }
    
    func saveRecommendations(userId: String, recommendRound: Int, recommendations: [PerfumeScore]) async throws {
        let url = URL(string: "\(baseURL)/recommendations/save")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let request = SaveRecommendationsRequest(
            userId: userId,
            recommendRound: recommendRound,
            recommendations: recommendations.map { PerfumeScoreRequest(
                perfumeName: $0.id,
                perfumeBrand: "",
                score: Int($0.score * 100)
            )}
        )
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    // MARK: - 향수 상세/리스트 API
    
    func fetchPerfumes(filters: PerfumeFilters? = nil) async throws -> [Perfume] {
        var components = URLComponents(string: "\(baseURL)/perfumes")!
        if let filters = filters {
            components.queryItems = filters.toQueryItems()
        }
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([Perfume].self, from: data)
    }
    
    func fetchPerfumeDetail(id: String) async throws -> PerfumeDetail {
        let url = URL(string: "\(baseURL)/perfumes/\(id)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(PerfumeDetail.self, from: data)
    }
    
    // MARK: - 향수 매장 API
    
    func fetchStores(brand: String? = nil) async throws -> [Store] {
        var components = URLComponents(string: "\(baseURL)/stores")!
        if let brand = brand {
            components.queryItems = [URLQueryItem(name: "brand", value: brand)]
        }
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([Store].self, from: data)
    }
    
    // MARK: - 시향 일기 API
    
    func createDiary(diary: ScentDiaryModel) async throws {
        let url = URL(string: "\(baseURL)/diaries")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(diary)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    func fetchDiaries(userId: String? = nil) async throws -> [ScentDiaryModel] {
        var components = URLComponents(string: "\(baseURL)/diaries")!
        if let userId = userId {
            components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        }
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([ScentDiaryModel].self, from: data)
    }
    
    // MARK: - 추가 API 메서드
    
    func searchPerfumes(query: String) async throws -> [Perfume] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/perfumes/search?q=\(encodedQuery)") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode([Perfume].self, from: data)
    }
    
    func getRecommendations(projectId: String) async throws -> [PerfumeRecommendation] {
        let url = URL(string: "\(baseURL)/projects/\(projectId)/recommendations")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode([PerfumeRecommendation].self, from: data)
    }
}

struct Store: Codable, Identifiable {
    let storeName: String
    let brand: String
    let lat: Double
    let lon: Double
    let address: String
    
    var id: String { storeName }
    
    enum CodingKeys: String, CodingKey {
        case storeName = "store_name"
        case brand
        case lat
        case lon
        case address
    }
}

enum NetworkError: Error {
    case invalidResponse
    case invalidData
    case decodingError
    case invalidURL
    case notFound
    case serverError
    case unknown
} 