import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
    case invalidInput(String)
    case invalidToken
}

class APIClient {
    static let shared = APIClient()
    private let baseURL: String = {
        guard let url = Bundle.main.infoDictionary?["API_BASE_URL"] as? String else {
            fatalError("API_BASE_URL not found in Info.plist")
        }
        return url
    }()
    
    private init() {}
    
    private func createRequest(_ endpoint: String, method: String, body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
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
        let request = try createRequest(endpoint, method: method, body: body)
        
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
                UserDefaults.standard.removeObject(forKey: "authToken")
                throw APIError.serverError("인증이 만료되었습니다.")
            case 403:
                throw APIError.serverError("접근 권한이 없습니다.")
            case 404:
                throw APIError.serverError("요청한 리소스를 찾을 수 없습니다.")
            case 500...599:
                throw APIError.serverError("서버 오류가 발생했습니다. (상태 코드: \(httpResponse.statusCode))")
            default:
                throw APIError.serverError("알 수 없는 오류가 발생했습니다.")
            }
        } catch let error as APIError {
            throw error
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
    func submitPreferences(projectId: String, preferences: [PreferenceRating]) async throws -> PreferenceRecommendationResponse {
        let body = try JSONEncoder().encode(PreferenceRequest(preferences: preferences))
        return try await request("/projects/\(projectId)/preferences", method: "POST", body: body)
    }
    
    func getRecommendations(projectId: String) async throws -> [Perfume] {
        return try await request("/projects/\(projectId)/recommendations")
    }
    
    // MARK: - Scent Diary APIs
    func fetchDiaries() async throws -> [ScentDiaryModel] {
        return try await request("/diaries")
    }
    
    func createScentDiary(_ diary: ScentDiaryModel) async throws -> ScentDiaryModel {
        let body = try JSONEncoder().encode(diary)
        return try await request("/diaries", method: "POST", body: body)
    }
    
    // MARK: - Like APIs
    func likeDiary(diaryId: String) async throws -> EmptyResponse {
        try await request("/diaries/\(diaryId)/like", method: "POST")
    }
    
    func unlikeDiary(diaryId: String) async throws -> EmptyResponse {
        try await request("/diaries/\(diaryId)/unlike", method: "DELETE")
    }
    
    // MARK: - Project APIs
    func createProject(name: String, preferences: [PreferenceRating]) async throws -> ProjectModel {
        guard let url = URL(string: baseURL)?.appendingPathComponent("projects") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let projectRequest = CreateProjectRequest(name: name, preferences: preferences)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(projectRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ProjectModel.self, from: data)
    }
    
    func getProjects() async throws -> [ProjectModel] {
        guard let url = URL(string: baseURL)?.appendingPathComponent("projects") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([ProjectModel].self, from: data)
    }
    
    func updateProject(_ project: ProjectModel) async throws -> ProjectModel {
        guard let url = URL(string: baseURL)?.appendingPathComponent("projects/\(String(project.id))") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(project)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ProjectModel.self, from: data)
    }
    
    func deleteProject(id: String) async throws {
        guard let url = URL(string: baseURL)?.appendingPathComponent("projects/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Diary API
    
    func createDiary(diary: ScentDiaryModel) async throws {
        guard let url = URL(string: baseURL)?.appendingPathComponent("diaries") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        request.httpBody = try encoder.encode(diary)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("서버 오류가 발생했습니다. (상태 코드: \(httpResponse.statusCode))")
        }
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

struct PreferenceRecommendationResponse: Codable {
    let recommendations: [Perfume]
    let matchScore: Int
}

struct CreateProjectRequest: Codable {
    let name: String
    let preferences: [PreferenceRating]
}

struct EmptyResponse: Codable {} 