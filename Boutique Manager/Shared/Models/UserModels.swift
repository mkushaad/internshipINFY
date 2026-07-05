import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var role: UserRoleType?
    var assignedStoreID: UUID?
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "First Name"
        case lastName = "Last Name"
        case email = "Email"
        case phoneNumber = "Phone Number"
        case role = "User Role"
        case assignedStoreID = "Assigned StoreID"
        case isActive
    }
}

struct Customer: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var phone: String
    var vipTier: VIPTier
    var consentGranted: Bool
}
