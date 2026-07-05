import Foundation

struct ClientProfile: Identifiable, Codable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let tier: String?
    let lifetimePurchaseAmount: Int?
}
