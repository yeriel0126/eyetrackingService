import Foundation

struct ProjectModel: Identifiable, Codable {
    let id : UUID
    let name: String
    let createdAt: Date
    let tags: [String]
    let recommendedPerfumes: [Perfume]
}
