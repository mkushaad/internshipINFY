import Foundation

struct Campaign: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var type: String?
    var status: String?
    var sentTo: String?
    var sentToRegion: String?
    var themeName: String?
    var discountType: String?
    var discountValue: Double?
    var createdAt: String?
    var created_till: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case type
        case status
        case sentTo
        case sentToRegion
        case themeName
        case discountType
        case discountValue
        case createdAt
        case created_till
    }
}
