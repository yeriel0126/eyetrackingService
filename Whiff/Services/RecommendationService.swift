import Foundation

class RecommendationService {
    static let shared = RecommendationService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    func getRecommendations(projectId: String) async throws -> [PerfumeRecommendation] {
        return try await networkManager.getRecommendations(projectId: projectId)
    }
    
    func saveRecommendations(userId: String, recommendRound: Int, recommendations: [PerfumeScore]) async throws {
        try await networkManager.saveRecommendations(
            userId: userId,
            recommendRound: recommendRound,
            recommendations: recommendations
        )
    }
    
    func saveRecommendationHistory(
        userId: String,
        recommendationId: String,
        selectedPerfumeId: String
    ) async throws {
        let url = URL(string: "\(networkManager.baseURL)/recommendations/history")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let request = [
            "user_id": userId,
            "recommendation_id": recommendationId,
            "selected_perfume_id": selectedPerfumeId
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request)
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
} 