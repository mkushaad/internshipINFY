import Foundation

struct Store: Identifiable, Codable {
    let id: UUID
    var name: String
    var location: String
    var region: String
    var managerID: UUID?
    var inventoryControllerID: UUID?
    var currency: Currency?
    var privacyRegulation: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case region
        case managerID
        case inventoryControllerID
        case currency
        case privacyRegulation
    }
}
