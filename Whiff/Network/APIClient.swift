import Foundation
import UIKit

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
    case invalidInput(String)
    case invalidToken
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL 입니다."
        case .networkError(let error):
            return "네트워크 오류가 발생했습니다: \(error.localizedDescription)"
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .decodingError(let error):
            return "데이터 디코딩 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .serverError(let message):
            return "서버 오류: \(message)"
        case .invalidInput(let message):
            return "입력 오류: \(message)"
        case .invalidToken:
            return "유효하지 않은 토큰입니다."
        }
    }
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
        
        if method.uppercased() == "POST" {
            print("🚀🚀🚀 [POST 요청 상세] URL: \(url.absoluteString)")
            if let body = body, let bodyString = String(data: body, encoding: .utf8) {
                print("🚀🚀🚀 [POST 요청 Body] \(bodyString)")
                
                // 1차 추천 API인 경우 특별히 표시
                if endpoint.contains("recommend") && !endpoint.contains("2nd") {
                    print("🎯🎯🎯 [1차 추천 API 호출!] 사용자 취향이 제대로 전달되는지 확인:")
                    print("🎯🎯🎯 Body: \(bodyString)")
                }
            } else {
                print("🚀🚀🚀 [POST 요청] Body 없음")
            }
        }
        
        return request
    }
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        let request = try createRequest(endpoint, method: method, body: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("응답이 HTTP가 아닙니다.")
                throw APIError.invalidResponse
            }
            
            let responseBody = String(data: data, encoding: .utf8) ?? "응답 바디 없음"
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    print("디코딩 에러: \(error.localizedDescription)")
                    print("응답 바디: \(responseBody)")
                    throw APIError.decodingError(error)
                }
            case 401:
                UserDefaults.standard.removeObject(forKey: "authToken")
                print("401 에러 - 인증 만료. 응답 바디: \(responseBody)")
                throw APIError.serverError("인증이 만료되었습니다.")
            case 403:
                print("403 에러 - 권한 없음. 응답 바디: \(responseBody)")
                throw APIError.serverError("접근 권한이 없습니다.")
            case 404:
                print("404 에러 - 리소스 없음. 응답 바디: \(responseBody)")
                throw APIError.serverError("요청한 리소스를 찾을 수 없습니다.")
            case 503:
                print("503 에러 - 서버 일시적 불가. 응답 바디: \(responseBody)")
                throw APIError.serverError("서버가 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도해주세요.")
            case 502:
                print("502 에러 - Bad Gateway. 응답 바디: \(responseBody)")
                throw APIError.serverError("현재 서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요.")
            case 500...599:
                print("서버 오류(\(httpResponse.statusCode)). 응답 바디: \(responseBody)")
                throw APIError.serverError("서버 오류가 발생했습니다. (상태 코드: \(httpResponse.statusCode))")
            default:
                print("알 수 없는 오류(\(httpResponse.statusCode)). 응답 바디: \(responseBody)")
                throw APIError.serverError("알 수 없는 오류가 발생했습니다.")
            }
        } catch let error as APIError {
            print("APIError: \(error.localizedDescription)")
            throw error
        } catch {
            print("네트워크 에러: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Default/Health APIs
    func getRoot() async throws -> RootResponse {
        return try await request("/")
    }
    
    func headRoot() async throws -> EmptyResponse {
        return try await request("/", method: "HEAD")
    }
    
    func getHealth() async throws -> HealthResponse {
        return try await request("/health")
    }
    
    func headHealth() async throws -> EmptyResponse {
        return try await request("/health", method: "HEAD")
    }
    
    func getStatus() async throws -> StatusResponse {
        return try await request("/status")
    }
    
    func getAPIInfo() async throws -> APIInfoResponse {
        return try await request("/api-info")
    }
    
    // MARK: - Auth APIs
    func getEmailStatus() async throws -> EmailStatusResponse {
        return try await request("/auth/email-status")
    }
    
    func testSMTP() async throws -> SMTPTestResponse {
        return try await request("/auth/test-smtp", method: "POST")
    }
    
    func testFirebaseToken() async throws -> AuthTestResponse {
        return try await request("/auth/test", method: "POST")
    }
    
    func register(email: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password]
        let data = try JSONEncoder().encode(body)
        return try await request("/auth/register", method: "POST", body: data)
    }
    
    func resendVerification(email: String) async throws -> VerificationResponse {
        let body = ["email": email]
        let data = try JSONEncoder().encode(body)
        return try await request("/auth/resend-verification", method: "POST", body: data)
    }
    
    func forgotPassword(email: String) async throws -> PasswordResetResponse {
        let body = ["email": email]
        let data = try JSONEncoder().encode(body)
        return try await request("/auth/forgot-password", method: "POST", body: data)
    }
    
    func sendTestEmail(email: String) async throws -> TestEmailResponse {
        let body = ["email": email]
        let data = try JSONEncoder().encode(body)
        return try await request("/auth/send-test-email", method: "POST", body: data)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password]
        let data = try JSONEncoder().encode(body)
        return try await request("/auth/login", method: "POST", body: data)
    }
    
    func googleLogin(idToken: String) async throws -> AuthResponse {
        let body = ["id_token": idToken]
        let data = try JSONEncoder().encode(body)
        return try await request("/auth/google-login", method: "POST", body: data)
    }
    
    func appleLogin(idToken: String) async throws -> AuthResponse {
        let body = ["id_token": idToken]
        let data = try JSONEncoder().encode(body)
        return try await request("/auth/apple-login", method: "POST", body: data)
    }
    
    func logout() async throws -> LogoutResponse {
        return try await request("/auth/logout", method: "POST")
    }
    
    func getFirebaseStatus() async throws -> FirebaseStatusResponse {
        return try await request("/auth/firebase-status")
    }
    
    // MARK: - User APIs
    func getCurrentUser() async throws -> UserResponse {
        return try await request("/users/me")
    }
    
    func getUserSettings() async throws -> UserSettingsResponse {
        return try await request("/users/settings")
    }
    
    func updateProfile(profileData: ProfileUpdateRequest) async throws -> ProfileUpdateResponse {
        let body = try JSONEncoder().encode(profileData)
        return try await request("/users/profile", method: "PUT", body: body)
    }
    
    func getUserStats() async throws -> UserStatsResponse {
        return try await request("/users/stats")
    }
    
    func withdrawUser() async throws -> WithdrawResponse {
        return try await request("/users/me/withdraw", method: "DELETE")
    }
    
    func getWithdrawPreview() async throws -> WithdrawPreviewResponse {
        return try await request("/users/me/withdraw-preview")
    }
    
    // MARK: - Perfume APIs
    func getPerfumes() async throws -> [PerfumeResponse] {
        return try await request("/perfumes/")
    }
    
    func getPerfumeDetail(name: String) async throws -> PerfumeDetailResponse {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw APIError.invalidInput("향수 이름을 인코딩할 수 없습니다.")
        }
        return try await request("/perfumes/\(encodedName)")
    }
    
    func getCSVInfo() async throws -> CSVInfoResponse {
        return try await request("/perfumes/debug/csv-info")
    }
    
    func recommendPerfumesByCluster(preferences: PerfumePreferences) async throws -> [PerfumeResponse] {
        let body = try JSONEncoder().encode(preferences.toAPIFormat())
        return try await request("/perfumes/recommend-cluster", method: "POST", body: body)
    }
    
    func recommendPerfumes(preferences: PerfumePreferences) async throws -> [PerfumeResponse] {
        let body = try JSONEncoder().encode(preferences.toAPIFormat())
        return try await request("/perfumes/recommend", method: "POST", body: body)
    }
    
    // MARK: - Store APIs
    func getStores() async throws -> [StoreResponse] {
        return try await request("/stores/")
    }
    
    func getStoresByBrand(brand: String) async throws -> [StoreResponse] {
        guard let encodedBrand = brand.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw APIError.invalidInput("브랜드 이름을 인코딩할 수 없습니다.")
        }
        return try await request("/stores/\(encodedBrand)")
    }
    
    // MARK: - Course APIs  
    func recommendCourse(preferences: CoursePreferences) async throws -> [CourseResponse] {
        let body = try JSONEncoder().encode(preferences)
        return try await request("/courses/recommend", method: "POST", body: body)
    }
    
    // MARK: - First Recommendation APIs
    func getFirstRecommendation(preferences: PerfumePreferences) async throws -> FirstRecommendationResponse {
        let body = try JSONEncoder().encode(preferences.toAPIFormat())
        
        // 백엔드에서 배열을 직접 반환하므로 [FirstRecommendationItem]으로 디코딩
        let items: [FirstRecommendationItem] = try await request("/perfumes/recommend", method: "POST", body: body)
        
        // FirstRecommendationResponse로 감싸서 반환
        return FirstRecommendationResponse(recommendations: items)
    }
    
    // MARK: - Second Recommendation APIs
    func getSecondRecommendation(requestData: SecondRecommendationRequest) async throws -> SecondRecommendationResponse {
        let body = try JSONEncoder().encode(requestData)
        return try await request("/perfumes/recommend-2nd", method: "POST", body: body)
    }
    
    func getNoteAnalysis(perfumeIndex: Int) async throws -> NoteAnalysisResponse {
        return try await request("/perfumes/note-analysis/\(perfumeIndex)")
    }
    
    func getSystemStatus() async throws -> SystemStatusResponse {
        return try await request("/perfumes/system-status")
    }
    
    // MARK: - Diary APIs
    func getDiaryFirebaseStatus() async throws -> FirebaseStatusResponse {
        return try await request("/diaries/firebase-status")
    }
    
    func createScentDiary(_ diary: ScentDiaryModel) async throws -> ScentDiaryModel {
        let body = try JSONEncoder().encode(diary)
        
        // 디버깅: 요청 정보 출력
        print("🔍 [시향일기 저장] 요청 시작")
        print("🔍 [시향일기 저장] URL: \(baseURL)/diaries/")
        if let bodyString = String(data: body, encoding: .utf8) {
            print("🔍 [시향일기 저장] 요청 바디: \(bodyString)")
        }
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            print("🔍 [시향일기 저장] 인증 토큰: \(String(token.prefix(20)))...")
        } else {
            print("❌ [시향일기 저장] 인증 토큰 없음!")
        }
        
        let response: ScentDiaryModel = try await request("/diaries/", method: "POST", body: body)
        print("✅ [시향일기 저장] 성공!")
        return response
    }
    
    func getDiaries() async throws -> [ScentDiaryModel] {
        return try await request("/diaries/")
    }
    
    func likeDiary(diaryId: String) async throws -> LikeResponse {
        return try await request("/diaries/\(diaryId)/like", method: "POST")
    }
    
    func unlikeDiary(diaryId: String) async throws -> UnlikeResponse {
        return try await request("/diaries/\(diaryId)/unlike", method: "DELETE")
    }
    
    func getUserDiaries(userId: String) async throws -> [ScentDiaryModel] {
        return try await request("/diaries/user/\(userId)")
    }
    
    func getDiaryStatus() async throws -> DiaryStatusResponse {
        return try await request("/diaries/status")
    }
    
    // MARK: - Recommendation APIs
    func saveRecommendation(recommendation: RecommendationSaveRequest) async throws -> RecommendationSaveResponse {
        let body = try JSONEncoder().encode(recommendation)
        return try await request("/recommendations/save", method: "POST", body: body)
    }
    
    // 추천 전체 삭제 API
    func clearMyRecommendations() async throws -> ClearRecommendationsResponse {
        return try await request("/recommendations/clear-my-recommendations", method: "DELETE")
    }

    // MARK: - Emotion Analysis API (외부 API)
    func getEmotionTags(from text: String) async throws -> [EmotionTag] {
        guard let url = URL(string: "https://scent-emotion-api.onrender.com/analyze") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["text": text]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // 디버깅: 실제 응답 내용 출력
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 [AI API] 백엔드 응답: \(responseString)")
            }
            
            do {
                // 먼저 원래 형식으로 시도
                let emotionResponse = try JSONDecoder().decode(EmotionTagResponse.self, from: data)
                return emotionResponse.tags
            } catch {
                print("🔄 [AI API] 원래 형식 실패, 대체 형식으로 시도...")
                
                // 대체 형식 1: 단순 문자열 배열
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("🔍 [AI API] JSON 객체 파싱: \(jsonObject)")
                        
                        // "tags" 필드가 문자열 배열인 경우
                        if let tagStrings = jsonObject["tags"] as? [String] {
                            print("✅ [AI API] tags 필드에서 문자열 배열 파싱: \(tagStrings)")
                            return tagStrings.enumerated().map { index, tagName in
                                EmotionTag(
                                    id: "\(index)",
                                    name: tagName,
                                    confidence: 0.8, // 기본값
                                    category: nil,
                                    description: nil
                                )
                            }
                        }
                        
                        // "tags" 필드가 NSArray인 경우 (iOS에서 자주 발생)
                        if let tagArray = jsonObject["tags"] as? NSArray {
                            print("🔍 [AI API] NSArray 형태의 tags 감지: \(tagArray)")
                            let tagStrings = tagArray.compactMap { $0 as? String }
                            print("✅ [AI API] NSArray에서 문자열 추출: \(tagStrings)")
                            return tagStrings.enumerated().map { index, tagName in
                                EmotionTag(
                                    id: "\(index)",
                                    name: tagName,
                                    confidence: 0.8,
                                    category: nil,
                                    description: nil
                                )
                            }
                        }
                        
                        // "tags" 필드가 문자열인 경우 (쉼표로 구분)
                        if let tagString = jsonObject["tags"] as? String {
                            print("🔍 [AI API] 문자열 형태의 tags: \(tagString)")
                            let tagStrings = tagString.components(separatedBy: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            print("✅ [AI API] 쉼표 분리 태그: \(tagStrings)")
                            return tagStrings.enumerated().map { index, tagName in
                                EmotionTag(
                                    id: "\(index)",
                                    name: tagName,
                                    confidence: 0.8,
                                    category: nil,
                                    description: nil
                                )
                            }
                        }
                    }
                } catch {
                    print("⚠️ [AI API] JSON 객체 파싱 실패: \(error)")
                }
                
                // 최종 폴백: 빈 배열 반환
                print("⚠️ [AI API] 모든 디코딩 시도 실패, 빈 배열 반환")
                return []
            }
        case 400:
            throw APIError.invalidInput("잘못된 입력입니다.")
        case 500...599:
            throw APIError.serverError("서버 오류가 발생했습니다.")
        default:
            throw APIError.serverError("알 수 없는 오류가 발생했습니다.")
        }
    }
    
    // 일기 이미지 업로드
    func uploadDiaryImage(diaryId: String, image: UIImage) async throws -> DiaryImageUploadResponse {
        let url = URL(string: baseURL + "/diaries/\(diaryId)/image")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidInput("이미지 인코딩 실패")
        }
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"diary_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("이미지 업로드 실패")
        }
        return try JSONDecoder().decode(DiaryImageUploadResponse.self, from: data)
    }
    // 일기 통계 요약
    func getDiaryStatsSummary() async throws -> DiaryStatsSummaryResponse {
        return try await request("/diaries/stats/summary")
    }
    // 일기 검색
    func searchDiaries(query: String) async throws -> [ScentDiaryModel] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await request("/diaries/search?q=\(encoded)")
    }
    // 관리자 전체 일기
    func getAllDiariesAdmin() async throws -> [ScentDiaryModel] {
        return try await request("/diaries/admin/all")
    }
    // 관리자 데이터 정리
    func cleanupDiariesAdmin() async throws -> CleanupResponse {
        return try await request("/diaries/admin/cleanup", method: "DELETE")
    }
    // 일기 모듈 상태
    func getDiariesHealth() async throws -> DiaryHealthResponse {
        return try await request("/diaries/health")
    }
    
    // 신고 관리 APIs
    func reportDiary(diaryId: String, reason: String) async throws -> ReportResponse {
        let body = ["diary_id": diaryId, "reason": reason]
        let data = try JSONEncoder().encode(body)
        return try await request("/reports/diary", method: "POST", body: data)
    }
    func getReports() async throws -> [ReportModel] {
        return try await request("/reports/")
    }
    func getReportStats() async throws -> ReportStatsResponse {
        return try await request("/reports/stats")
    }
    func handleReportAction(reportId: String, action: String) async throws -> ReportActionResponse {
        let body = ["action": action]
        let data = try JSONEncoder().encode(body)
        return try await request("/reports/\(reportId)/action", method: "PUT", body: data)
    }
    func deleteReport(reportId: String) async throws -> DeleteReportResponse {
        return try await request("/reports/\(reportId)", method: "DELETE")
    }
}

// MARK: - Response Models

// Default/Health 관련 Response
struct RootResponse: Codable {
    let message: String
    let service: String
    let version: String?
    let timestamp: String?
}

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let components: [String: String]?
    let database: String?
    let firebase: String?
}

struct StatusResponse: Codable {
    let status: String
    let uptime: String?
    let memory_usage: String?
    let active_connections: Int?
    let last_request: String?
}

struct APIInfoResponse: Codable {
    let api_name: String
    let version: String
    let description: String?
    let endpoints: [String]?
    let documentation: String?
}

struct EmptyResponse: Codable {}

// Auth 관련 Response
struct EmailStatusResponse: Codable {
    let status: String
}

struct SMTPTestResponse: Codable {
    let status: String
    let message: String
}

struct AuthTestResponse: Codable {
    let message: String
    let uid: String
    let email: String
}

struct AuthResponse: Codable {
    let token: String
    let user: UserData
}

struct VerificationResponse: Codable {
    let message: String
}

struct PasswordResetResponse: Codable {
    let message: String
}

struct TestEmailResponse: Codable {
    let message: String
}

struct LogoutResponse: Codable {
    let message: String
}

struct FirebaseStatusResponse: Codable {
    let firebase_available: Bool
    let firebase_apps_count: Int
    let environment_config: EnvironmentConfig?
}

// User 관련 Response
struct UserResponse: Codable {
    let message: String
    let data: UserData
    let firebase_status: FirebaseStatus?
}

struct UserData: Codable {
    let uid: String
    let email: String
    let name: String?
    let picture: String?
    let is_test_user: Bool?
}

struct FirebaseStatus: Codable {
    let firebase_available: Bool
    let firebase_apps_count: Int
    let environment_config: EnvironmentConfig
}

struct EnvironmentConfig: Codable {
    let firebase_credential_json_env: String
    let firebase_project_id_env: String
    let firebase_private_key_env: String
    let firebase_client_email_env: String
}

struct UserSettingsResponse: Codable {
    let settings: UserSettings
}

struct UserSettings: Codable {
    let notifications: Bool
    let theme: String
}

struct ProfileUpdateRequest: Codable {
    let name: String?
    let picture: String?
}

struct ProfileUpdateResponse: Codable {
    let message: String
    let user: UserData
}

struct UserStatsResponse: Codable {
    let stats: UserStats
}

struct UserStats: Codable {
    let total_diaries: Int
    let total_likes: Int
    let total_comments: Int
}

struct WithdrawResponse: Codable {
    let message: String
}

struct WithdrawPreviewResponse: Codable {
    let message: String
    let data_to_delete: DataToDelete
}

struct DataToDelete: Codable {
    let diaries: Int
    let likes: Int
    let comments: Int
}

// Perfume 관련 Response
struct PerfumeResponse: Codable {
    let name: String
    let brand: String
    let image_url: String
    let price: Double?
    let description: String?
    let notes: String?
    let rating: Double?
    let emotion_tags: [String]?
    let similarity: Double?
    
    // Perfume 모델로 변환
    func toPerfume() -> Perfume {
        // 백엔드 이미지 URL이 있으면 사용, 없거나 빈 값이면 플레이스홀더 생성
        let finalImageURL = image_url.trimmingCharacters(in: .whitespaces).isEmpty ? 
            generateSafeImageURL(for: name, brand: brand) : image_url
        
        return Perfume(
            id: "\(brand.lowercased().replacingOccurrences(of: " ", with: "_"))_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: name,
            brand: brand,
            imageURL: finalImageURL,
            price: price ?? 0.0,
            description: description ?? "\(brand)의 \(name) 향수입니다.",
            notes: parseNotesFromString(notes ?? ""),
            rating: rating ?? 4.0,
            emotionTags: emotion_tags ?? [],
            similarity: similarity ?? 0.0
        )
    }
    
    // 안정적인 이미지 URL 생성 헬퍼 함수
    private func generateSafeImageURL(for name: String, brand: String) -> String {
        // 향수 이름과 브랜드를 조합하여 일관된 시드 생성
        let combined = "\(brand)\(name)".lowercased().replacingOccurrences(of: " ", with: "")
        let seed = abs(combined.hashValue) % 1000 + 1
        return "https://picsum.photos/200/300?random=\(seed)"
    }
    
    private func parseNotesFromString(_ notesString: String) -> PerfumeNotes {
        let noteArray = notesString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        let count = noteArray.count
        let topCount = max(1, count / 3)
        let middleCount = max(1, (count - topCount) / 2)
        
        let topNotes = Array(noteArray.prefix(topCount))
        let middleNotes = Array(noteArray.dropFirst(topCount).prefix(middleCount))
        let baseNotes = Array(noteArray.dropFirst(topCount + middleCount))
        
        return PerfumeNotes(
            top: topNotes.isEmpty ? ["Unknown"] : topNotes,
            middle: middleNotes.isEmpty ? ["Unknown"] : middleNotes,
            base: baseNotes.isEmpty ? ["Unknown"] : baseNotes
        )
    }
}

struct PerfumeDetailResponse: Codable {
    let name: String
    let brand: String
    let image_url: String
    let notes: String?
    let emotion_tags: String?
    let price: Double?
    let description: String?
    let rating: Double?
    let review_count: Int?
}

struct CSVInfoResponse: Codable {
    let message: String
    let info: CSVInfo
}

struct CSVInfo: Codable {
    let total_rows: Int
    let columns: [String]
}

// Store 관련 Response
struct StoreResponse: Codable {
    let name: String
    let brand: String
    let address: String
    let phone: String?
    let hours: String?
}

// Course 관련 Response
struct CourseResponse: Codable {
    let id: String
    let name: String
    let description: String
    let perfumes: [String]
    let price: Double
    let duration: Int
}

struct CoursePreferences: Codable {
    let preferences: [String]
    let budget: Int?
    let location: String?
}

// First Recommendation 관련 Response (클러스터 기반 새로운 구조)
struct FirstRecommendationResponse: Codable {
    let recommendations: [FirstRecommendationItem]
    let clusterInfo: ClusterInfo?
    
    // 이전 코드 호환성을 위한 초기화
    init(recommendations: [FirstRecommendationItem], clusterInfo: ClusterInfo? = nil) {
        self.recommendations = recommendations
        self.clusterInfo = clusterInfo
    }
}

struct FirstRecommendationItem: Codable {
    let perfume_index: Int
    let emotion_cluster: Int
    let cluster_proba: Double?
    let rank: Int?
    
    // 이전 코드 호환성을 위한 초기화
    init(perfume_index: Int, emotion_cluster: Int, cluster_proba: Double? = nil, rank: Int? = nil) {
        self.perfume_index = perfume_index
        self.emotion_cluster = emotion_cluster
        self.cluster_proba = cluster_proba
        self.rank = rank
    }
}

struct ClusterInfo: Codable {
    let cluster: Int
    let description: String
    let proba: [Double]
    let recommended_notes: [String]
    let selected_idx: [Int]
}

// 이전 First Recommendation 응답 형식 (호환성을 위해 남겨둠)
struct LegacyFirstRecommendationItem: Codable {
    let name: String
    let brand: String
    let image_url: String
    let notes: String
    let emotions: String
    let reason: String
    let score: Double
    let method: String
    
    // Perfume 모델로 변환
    func toPerfume() -> Perfume {
        // 백엔드 이미지 URL이 있으면 사용, 없거나 빈 값이면 플레이스홀더 생성
        let finalImageURL = image_url.trimmingCharacters(in: .whitespaces).isEmpty ? 
            generateSafeImageURL(for: name, brand: brand) : image_url
        
        return Perfume(
            id: "\(brand.lowercased().replacingOccurrences(of: " ", with: "_"))_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: name,
            brand: brand,
            imageURL: finalImageURL,
            price: 0.0,
            description: reason,
            notes: parseNotesFromString(notes),
            rating: 4.0,
            emotionTags: emotions.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            similarity: score
        )
    }
    
    // 안정적인 이미지 URL 생성 헬퍼 함수
    private func generateSafeImageURL(for name: String, brand: String) -> String {
        // 향수 이름과 브랜드를 조합하여 일관된 시드 생성
        let combined = "\(brand)\(name)".lowercased().replacingOccurrences(of: " ", with: "")
        let seed = abs(combined.hashValue) % 1000 + 1
        return "https://picsum.photos/200/300?random=\(seed)"
    }
    
    private func parseNotesFromString(_ notesString: String) -> PerfumeNotes {
        let noteArray = notesString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        let count = noteArray.count
        let topCount = max(1, count / 3)
        let middleCount = max(1, (count - topCount) / 2)
        
        let topNotes = Array(noteArray.prefix(topCount))
        let middleNotes = Array(noteArray.dropFirst(topCount).prefix(middleCount))
        let baseNotes = Array(noteArray.dropFirst(topCount + middleCount))
        
        return PerfumeNotes(
            top: topNotes.isEmpty ? ["Unknown"] : topNotes,
            middle: middleNotes.isEmpty ? ["Unknown"] : middleNotes,
            base: baseNotes.isEmpty ? ["Unknown"] : baseNotes
        )
    }
}

// Second Recommendation 관련 Response
struct SecondRecommendationRequest: Codable {
    let user_preferences: UserPreferencesForSecond
    let user_note_scores: [String: Int]
    let emotion_proba: [Double]
    let selected_idx: [Int]
}

struct UserPreferencesForSecond: Codable {
    let gender: String?
    let season_tags: String?
    let time_tags: String?
    let desired_impression: String?
    let activity: String?
    let weather: String?
    
    init() {
        self.gender = "women"
        self.season_tags = "spring"
        self.time_tags = "day"
        self.desired_impression = "fresh, confident"
        self.activity = "casual"
        self.weather = "sunny"
    }
    
    init(from preferences: PerfumePreferences) {
        // 모든 값을 소문자로 변환하고 백엔드 스펙에 맞게 매핑
        self.gender = Self.mapGender(preferences.gender)
        self.season_tags = Self.mapSeason(preferences.seasonTags)
        self.time_tags = Self.mapTime(preferences.timeTags)
        self.desired_impression = Self.mapDesiredImpression(preferences.desiredImpression)
        self.activity = Self.mapActivity(preferences.activity)
        self.weather = Self.mapWeather(preferences.weather)
    }
    
    // Gender 매핑 (Male->men, Female->women, Unisex->unisex)
    private static func mapGender(_ gender: String) -> String {
        switch gender.lowercased() {
        case "male": return "men"
        case "female": return "women"  
        case "unisex": return "unisex"
        default: return "unisex" // 기본값
        }
    }
    
    // Season 매핑
    private static func mapSeason(_ season: String) -> String {
        return season.lowercased()
    }
    
    // Time 매핑
    private static func mapTime(_ time: String) -> String {
        return time.lowercased()
    }
    
    // Desired Impression 매핑 (백엔드 허용 조합으로 변환)
    private static func mapDesiredImpression(_ impression: String) -> String {
        // 빈 문자열 처리
        if impression.isEmpty {
            return "elegant, friendly" // 기본값
        }
        
        // 사용자가 선택한 2개 인상을 개별적으로 분리
        let selectedImpressions = impression.lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .sorted()
        
        // 백엔드 허용 조합 목록
        let allowedCombinations = [
            "confident, fresh",
            "confident, mysterious", 
            "elegant, friendly",
            "pure, friendly"
        ]
        
        // 선택된 조합이 이미 허용되는 조합인지 확인
        let userCombination = selectedImpressions.joined(separator: ", ")
        if allowedCombinations.contains(userCombination) {
            return userCombination
        }
        
        print("🔄 [2차 인상 매핑] 사용자 선택: '\(userCombination)' -> 허용 조합으로 변환")
        
        // 각 인상별 우선순위 매핑
        var mappedCombination = "elegant, friendly" // 기본값
        
        // 우선순위 기반 매핑 로직
        if selectedImpressions.contains("confident") {
            if selectedImpressions.contains("mysterious") {
                mappedCombination = "confident, mysterious"
            } else {
                mappedCombination = "confident, fresh" // confident + 다른 것
            }
        } else if selectedImpressions.contains("pure") {
            mappedCombination = "pure, friendly" // pure가 포함되면 pure, friendly
        } else if selectedImpressions.contains("elegant") {
            mappedCombination = "elegant, friendly" // elegant가 포함되면 elegant, friendly
        } else if selectedImpressions.contains("mysterious") {
            mappedCombination = "confident, mysterious" // mysterious가 포함되면 confident, mysterious
        } else if selectedImpressions.contains("fresh") {
            mappedCombination = "confident, fresh" // fresh가 포함되면 confident, fresh
        } else if selectedImpressions.contains("friendly") {
            mappedCombination = "elegant, friendly" // friendly가 포함되면 elegant, friendly
        }
        
        print("🎯 [2차 인상 매핑] 최종 결과: '\(mappedCombination)'")
        return mappedCombination
    }
    
    // Activity 매핑
    private static func mapActivity(_ activity: String) -> String {
        return activity.lowercased()
    }
    
    // Weather 매핑
    private static func mapWeather(_ weather: String) -> String {
        switch weather.lowercased() {
        case "hot": return "hot"
        case "cold": return "cold"
        case "rainy": return "rainy"
        case "any": return "any"
        // 추가 매핑
        case "sunny", "clear": return "hot"
        case "winter": return "cold"
        case "rain": return "rainy"
        default: return "any" // 기본값
        }
    }
}

struct SecondRecommendationResponse: Codable {
    let recommendations: [SecondRecommendationItem]
}

struct SecondRecommendationItem: Codable {
    let name: String
    let brand: String
    let final_score: Double
    let emotion_cluster: Int
    let image_url: String
    let description: String?
    let emotion_tags: [String]?
    let recommendation_reason: String?
    let scent_profile: String?
    
    // Perfume 모델로 변환
    func toPerfume() -> Perfume {
        // 백엔드 이미지 URL이 있으면 사용, 없거나 빈 값이면 플레이스홀더 생성
        let finalImageURL = image_url.trimmingCharacters(in: .whitespaces).isEmpty ? 
            generateSafeImageURL(for: name, brand: brand) : image_url
        
        // 🔍 이미지 URL 디버깅 정보
        print("🖼️ [이미지 URL] \(brand) - \(name)")
        print("   - 백엔드 URL: '\(image_url)'")
        print("   - 최종 URL: '\(finalImageURL)'")
        print("   - URL 유효성: \(URL(string: finalImageURL) != nil ? "✅" : "❌")")
        
        // 향수 설명을 풍부하게 구성
        let perfumeDescription = buildRichDescription()
        
        // 🌿 실제 향수 노트 정보 조회 시도 (동기적으로)
        let perfumeNotes = fetchRealPerfumeNotesSync() ?? generatePerfumeNotes()
        
        return Perfume(
            id: "\(brand.lowercased().replacingOccurrences(of: " ", with: "_"))_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: name,
            brand: brand,
            imageURL: finalImageURL,
            price: 0.0,
            description: perfumeDescription,
            notes: perfumeNotes,
            rating: 4.0,
            emotionTags: emotion_tags ?? [],
            similarity: final_score
        )
    }
    
    // 실제 향수 노트 정보 조회 (동기 버전)
    private func fetchRealPerfumeNotesSync() -> PerfumeNotes? {
        print("🔍 [실제 향수 정보 조회 시도] \(brand) - \(name)")
        
        // 여러 검색 키워드로 시도
        let searchTerms = [
            name, // 향수 이름만
            "\(brand) \(name)", // 브랜드 + 향수 이름
            name.replacingOccurrences(of: " ", with: ""), // 공백 제거
            name.lowercased() // 소문자
        ]
        
        for searchTerm in searchTerms {
            if let notes = tryFetchPerfumeNotes(searchTerm: searchTerm) {
                print("✅ [실제 노트 정보 발견] '\(searchTerm)' 검색으로 발견")
                return notes
            }
        }
        
        print("⚠️ [실제 노트 정보 없음] \(brand) - \(name) - 생성된 노트 사용")
        return nil
    }
    
    // 특정 검색어로 향수 노트 조회
    private func tryFetchPerfumeNotes(searchTerm: String) -> PerfumeNotes? {
        // 동기적 네트워크 호출은 권장되지 않으므로, 로컬 데이터베이스에서 먼저 찾아보기
        return findPerfumeNotesFromLocalData(searchTerm: searchTerm)
    }
    
    // 로컬 향수 데이터에서 노트 정보 찾기
    private func findPerfumeNotesFromLocalData(searchTerm: String) -> PerfumeNotes? {
        let searchTermLower = searchTerm.lowercased()
        
        // PerfumeDataUtils에서 실제 향수 데이터 가져오기
        let realisticPerfumes = PerfumeDataUtils.createRealisticPerfumes()
        
        // 이름 매칭 시도
        for perfume in realisticPerfumes {
            let perfumeNameLower = perfume.name.lowercased()
            let perfumeBrandLower = perfume.brand.lowercased()
            
            // 정확 매칭
            if perfumeNameLower == searchTermLower ||
               "\(perfumeBrandLower) \(perfumeNameLower)" == searchTermLower {
                print("✅ [로컬 데이터 정확 매칭] \(perfume.brand) - \(perfume.name)")
                return perfume.notes
            }
            
            // 부분 매칭 (향수 이름이 포함되어 있는 경우)
            if perfumeNameLower.contains(searchTermLower) || 
               searchTermLower.contains(perfumeNameLower) {
                print("✅ [로컬 데이터 부분 매칭] \(perfume.brand) - \(perfume.name)")
                return perfume.notes
            }
        }
        
        // 브랜드별 대표 노트 패턴 적용
        return getBrandSignatureNotes()
    }
    
    // 브랜드별 시그니처 노트 패턴
    private func getBrandSignatureNotes() -> PerfumeNotes? {
        let brandLower = brand.lowercased()
        
        switch brandLower {
        case let brand where brand.contains("chanel"):
            return PerfumeNotes(
                top: ["Aldehydes", "Bergamot", "Neroli"],
                middle: ["May Rose", "Jasmine", "Ylang-Ylang"],
                base: ["Sandalwood", "Vetiver", "White Musk"]
            )
        case let brand where brand.contains("dior"):
            return PerfumeNotes(
                top: ["Mandarin", "Pink Pepper", "Blood Orange"],
                middle: ["Grasse Rose", "Peony", "Magnolia"],
                base: ["Patchouli", "White Musk", "Benzoin"]
            )
        case let brand where brand.contains("tom ford"):
            return PerfumeNotes(
                top: ["Black Cherry", "Plum", "Pink Pepper"],
                middle: ["Black Truffle", "Turkish Rose", "Jasmine"],
                base: ["Patchouli", "Roasted Tonka", "Sandalwood"]
            )
        case let brand where brand.contains("jo malone"):
            return PerfumeNotes(
                top: ["Earl Grey Tea", "Bergamot", "Orange Blossom"],
                middle: ["Fig", "Bay Leaves", "Cucumber"],
                base: ["White Musk", "Vetiver", "Cedar"]
            )
        case let brand where brand.contains("byredo"):
            return PerfumeNotes(
                top: ["Black Currant", "Pink Pepper", "Green Fig"],
                middle: ["Rose", "Violet", "Freesia"],
                base: ["Cedar", "Amber", "Musk"]
            )
        case let brand where brand.contains("maison"):
            return PerfumeNotes(
                top: ["Bergamot", "Lemon", "Aqua"],
                middle: ["White Tea", "Jasmine", "Iris"],
                base: ["White Musk", "Ambergris", "Cedar"]
            )
        default:
            return nil // 알려진 브랜드 패턴이 없으면 nil 반환
        }
    }
    
    // 풍부한 설명 생성
    private func buildRichDescription() -> String {
        var components: [String] = []
        
        // 기본 브랜드 정보
        components.append("\(brand)의 \(name) 향수입니다.")
        
        // 백엔드에서 제공한 설명
        if let description = description, !description.isEmpty {
            components.append(description)
        }
        
        // 추천 이유
        if let reason = recommendation_reason, !reason.isEmpty {
            components.append("추천 이유: \(reason)")
        }
        
        // 향 프로필
        if let profile = scent_profile, !profile.isEmpty {
            components.append("향 특성: \(profile)")
        }
        
        // 감정 클러스터 정보
        let clusterDescription = getEmotionClusterDescription(emotion_cluster)
        components.append("감정 클러스터: \(clusterDescription)")
        
        return components.joined(separator: "\n\n")
    }
    
    // 감정 클러스터 설명
    private func getEmotionClusterDescription(_ cluster: Int) -> String {
        switch cluster {
        case 0: return "차분하고 안정적인 분위기"
        case 1: return "활기차고 에너지 넘치는 분위기"
        case 2: return "우아하고 세련된 분위기"
        case 3: return "신선하고 청량한 분위기"
        case 4: return "신비롭고 매혹적인 분위기"
        case 5: return "따뜻하고 포근한 분위기"
        default: return "개성적이고 독특한 분위기"
        }
    }
    
    // 안정적인 이미지 URL 생성 헬퍼 함수
    private func generateSafeImageURL(for name: String, brand: String) -> String {
        // 향수 이름과 브랜드를 조합하여 일관된 시드 생성
        let combined = "\(brand)\(name)".lowercased().replacingOccurrences(of: " ", with: "")
        let seed = abs(combined.hashValue) % 1000 + 1
        return "https://picsum.photos/200/300?random=\(seed)"
    }
    
    // 향수 노트 정보 생성
    private func generatePerfumeNotes() -> PerfumeNotes {
        let lowerName = name.lowercased()
        let lowerBrand = brand.lowercased()
        
        // 향수명과 브랜드에서 키워드 추출하여 노트 유추
        var topNotes: [String] = []
        var middleNotes: [String] = []
        var baseNotes: [String] = []
        
        // 감정 클러스터에 따른 기본 노트 패턴
        switch emotion_cluster {
        case 0: // 차분하고 안정적
            topNotes = ["Bergamot", "Lavender", "Green Tea"]
            middleNotes = ["Rose", "Jasmine", "Lily of the Valley"]
            baseNotes = ["Sandalwood", "Musk", "Amber"]
        case 1: // 활기차고 에너지 넘치는
            topNotes = ["Lemon", "Orange", "Mint"]
            middleNotes = ["Ginger", "Black Pepper", "Cardamom"]
            baseNotes = ["Cedar", "Vetiver", "Tonka Bean"]
        case 2: // 우아하고 세련된
            topNotes = ["Bergamot", "Pink Pepper", "Mandarin"]
            middleNotes = ["Rose", "Iris", "Peony"]
            baseNotes = ["Sandalwood", "Musk", "Vanilla"]
        case 3: // 신선하고 청량한
            topNotes = ["Citrus", "Aqua", "Marine"]
            middleNotes = ["Water Lily", "Cucumber", "Green Apple"]
            baseNotes = ["White Musk", "Driftwood", "Ambergris"]
        case 4: // 신비롭고 매혹적
            topNotes = ["Black Currant", "Bergamot", "Pink Pepper"]
            middleNotes = ["Rose", "Patchouli", "Ylang-Ylang"]
            baseNotes = ["Oud", "Amber", "Vanilla"]
        case 5: // 따뜻하고 포근한
            topNotes = ["Orange Blossom", "Honey", "Cinnamon"]
            middleNotes = ["Vanilla", "Caramel", "Almond"]
            baseNotes = ["Tonka Bean", "Benzoin", "Sandalwood"]
        default:
            topNotes = ["Bergamot", "Lemon", "Rose"]
            middleNotes = ["Jasmine", "Lily", "Iris"]
            baseNotes = ["Musk", "Sandalwood", "Amber"]
        }
        
        // 향수명에서 특정 키워드 감지하여 노트 조정
        if lowerName.contains("rose") || lowerName.contains("로즈") {
            if !middleNotes.contains("Rose") {
                middleNotes.insert("Rose", at: 0)
            }
        }
        
        if lowerName.contains("vanilla") || lowerName.contains("바닐라") {
            if !baseNotes.contains("Vanilla") {
                baseNotes.insert("Vanilla", at: 0)
            }
        }
        
        if lowerName.contains("citrus") || lowerName.contains("시트러스") {
            if !topNotes.contains("Citrus") {
                topNotes.insert("Citrus", at: 0)
            }
        }
        
        if lowerName.contains("musk") || lowerName.contains("머스크") {
            if !baseNotes.contains("Musk") {
                baseNotes.insert("Musk", at: 0)
            }
        }
        
        if lowerName.contains("oud") || lowerName.contains("우드") {
            if !baseNotes.contains("Oud") {
                baseNotes.insert("Oud", at: 0)
            }
        }
        
        // 브랜드별 특성 반영
        if lowerBrand.contains("chanel") {
            topNotes.append("Aldehydes")
            middleNotes.append("May Rose")
        } else if lowerBrand.contains("dior") {
            topNotes.append("Mandarin")
            middleNotes.append("Grasse Rose")
        } else if lowerBrand.contains("tom ford") {
            middleNotes.append("Black Truffle")
            baseNotes.append("Patchouli")
        }
        
        // 중복 제거 및 최대 4개로 제한
        topNotes = Array(Set(topNotes)).prefix(4).map { $0 }
        middleNotes = Array(Set(middleNotes)).prefix(4).map { $0 }
        baseNotes = Array(Set(baseNotes)).prefix(4).map { $0 }
        
        return PerfumeNotes(
            top: topNotes,
            middle: middleNotes,
            base: baseNotes
        )
    }
}

struct NoteAnalysisResponse: Codable {
    let perfume_index: Int
    let notes: [String: Double]
    let analysis: String
}

struct SystemStatusResponse: Codable {
    let status: String
    let model_version: String
    let last_updated: String
}

// Diary 관련 Response
struct LikeResponse: Codable {
    let message: String
    let likes: Int
}

struct UnlikeResponse: Codable {
    let message: String
    let likes: Int
}

struct DiaryStatusResponse: Codable {
    let status: String
    let total_diaries: Int
    let active_users: Int
}

// Recommendation 관련 Response
struct RecommendationSaveRequest: Codable {
    let user_id: String
    let perfume_ids: [String]
    let preferences: [String: String]
}

struct RecommendationSaveResponse: Codable {
    let message: String
    let recommendation_id: String
}

// 추천 전체 삭제 응답
struct ClearRecommendationsResponse: Codable {
    let message: String
}

// 신고 관련 Response/Model
struct ReportResponse: Codable {
    let message: String
    let report_id: String?
}
struct ReportModel: Codable {
    let id: String
    let diary_id: String
    let reporter_id: String
    let reason: String
    let status: String
    let created_at: String
}
struct ReportStatsResponse: Codable {
    let total: Int
    let pending: Int
    let resolved: Int
}
struct ReportActionResponse: Codable {
    let message: String
    let status: String
}
struct DeleteReportResponse: Codable {
    let message: String
}

// 기존 모델들 (호환성 유지)
struct FirebaseUser: Codable {
    let uid: String
    let email: String
    let name: String?
    let profile_image: String?
} 

struct DiaryImageUploadResponse: Codable {
    let image_url: String
}
struct DiaryStatsSummaryResponse: Codable {
    let total: Int
    let publicCount: Int
    let privateCount: Int
}
struct CleanupResponse: Codable {
    let message: String
}
struct DiaryHealthResponse: Codable {
    let status: String
    let details: String?
} 
