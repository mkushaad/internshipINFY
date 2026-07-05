import Foundation

struct Appointment: Identifiable, Codable {
    let id: UUID
    var storeID: UUID
    var customerID: String
    var salesAssociateID: UUID?
    var date: Date
    var type: AppointmentType
    var status: AppointmentStatus
    var preferences: String?
    
    // Joined relations
    var client_profiles: ClientProfile? = nil
    var associate: User? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case storeID
        case customerID
        case salesAssociateID
        case date
        case type
        case status
        case preferences
        case client_profiles
        case associate = "User"
    }
}

struct VIPEvent: Identifiable, Codable {
    let id: UUID
    var storeID: UUID
    var organizerID: UUID
    var title: String
    var date: Date
    var maxCapacity: Int
    var campaignID: UUID?
}

struct EventInvitation: Identifiable, Codable {
    let id: UUID
    var eventID: UUID
    var customerID: UUID
    var rsvpStatus: RSVPStatus
}
