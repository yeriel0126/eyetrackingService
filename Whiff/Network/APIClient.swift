import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
}

class APIClient {
    static let shared = APIClient()
    private let baseURL = "YOUR_BACKEND_API_URL" // 백엔드 API URL로 변경 필요
    
    private init() {}
    
    private func createRequest(_ endpoint: String, method: String, body: Data? = nil) -> URLRequest? {
        guard let url = URL(string: baseURL + endpoint) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let request = createRequest(endpoint, method: method, body: body) else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            case 401:
                // 토큰 만료 처리
                UserDefaults.standard.removeObject(forKey: "authToken")
                throw APIError.serverError("인증이 만료되었습니다.")
            default:
                throw APIError.serverError("서버 오류가 발생했습니다.")
            }
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Auth APIs
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = try JSONEncoder().encode(LoginRequest(email: email, password: password))
        return try await request("/auth/login", method: "POST", body: body)
    }
    
    func register(email: String, password: String, name: String) async throws -> AuthResponse {
        let body = try JSONEncoder().encode(RegisterRequest(email: email, password: password, name: name))
        return try await request("/auth/register", method: "POST", body: body)
    }
    
    // MARK: - Perfume APIs
    func getPerfumes() async throws -> [Perfume] {
        return try await request("/perfumes")
    }
    
    func getPerfumeDetail(id: String) async throws -> PerfumeDetail {
        return try await request("/perfumes/\(id)")
    }
    
    // MARK: - Preference APIs
    func submitPreferences(projectId: String, preferences: [PreferenceRating]) async throws -> RecommendationResponse {
        let body = try JSONEncoder().encode(PreferenceRequest(preferences: preferences))
        return try await request("/projects/\(projectId)/preferences", method: "POST", body: body)
    }
    
    func getRecommendations(projectId: String) async throws -> [Perfume] {
        return try await request("/projects/\(projectId)/recommendations")
    }
    
    // MARK: - Scent Diary APIs
    func getScentDiaries() async throws -> [ScentDiary] {
        return try await request("/diaries")
    }
    
    func createScentDiary(_ diary: ScentDiary) async throws -> ScentDiary {
        let body = try JSONEncoder().encode(diary)
        return try await request("/diaries", method: "POST", body: body)
    }
    
    func toggleLike(diaryId: String) async throws -> Bool {
        let response: [String: Bool] = try await request("/diaries/\(diaryId)/like", method: "POST")
        return response["isLiked"] ?? false
    }
}

// MARK: - Request/Response Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct PreferenceRequest: Codable {
    let preferences: [PreferenceRating]
}

struct RecommendationResponse: Codable {
    let recommendations: [Perfume]
    let matchScore: Int
} 