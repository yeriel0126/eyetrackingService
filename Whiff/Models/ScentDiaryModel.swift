import Foundation

struct ScentDiaryModel: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let userProfileImage: String
    let perfumeId: String
    let perfumeName: String
    let brand: String
    let content: String
    let tags: [String]
    var likes: Int
    var comments: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case userProfileImage = "user_profile_image"
        case perfumeId = "perfume_id"
        case perfumeName = "perfume_name"
        case brand
        case content
        case tags
        case likes
        case comments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 필수 필드 디코딩
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        userName = try container.decode(String.self, forKey: .userName)
        perfumeId = try container.decode(String.self, forKey: .perfumeId)
        perfumeName = try container.decode(String.self, forKey: .perfumeName)
        brand = try container.decode(String.self, forKey: .brand)
        content = try container.decode(String.self, forKey: .content)
        
        // 선택적 필드 디코딩 (기본값 제공)
        userProfileImage = try container.decodeIfPresent(String.self, forKey: .userProfileImage) ?? "default_profile"
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        comments = try container.decodeIfPresent(Int.self, forKey: .comments) ?? 0
        
        // 날짜 처리
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
           let createdAtDate = dateFormatter.date(from: createdAtString) {
            createdAt = createdAtDate
        } else {
            createdAt = Date()
        }
        
        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt),
           let updatedAtDate = dateFormatter.date(from: updatedAtString) {
            updatedAt = updatedAtDate
        } else {
            updatedAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // 필수 필드 인코딩
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(userName, forKey: .userName)
        try container.encode(perfumeId, forKey: .perfumeId)
        try container.encode(perfumeName, forKey: .perfumeName)
        try container.encode(brand, forKey: .brand)
        try container.encode(content, forKey: .content)
        
        // 선택적 필드 인코딩
        try container.encode(userProfileImage, forKey: .userProfileImage)
        try container.encode(tags, forKey: .tags)
        try container.encode(likes, forKey: .likes)
        try container.encode(comments, forKey: .comments)
        
        // 날짜 인코딩
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
    
    init(id: String,
         userId: String,
         userName: String,
         userProfileImage: String = "default_profile",
         perfumeId: String,
         perfumeName: String,
         brand: String,
         content: String,
         tags: [String] = [],
         likes: Int = 0,
         comments: Int = 0,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userProfileImage = userProfileImage
        self.perfumeId = perfumeId
        self.perfumeName = perfumeName
        self.brand = brand
        self.content = content
        self.tags = tags
        self.likes = likes
        self.comments = comments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 