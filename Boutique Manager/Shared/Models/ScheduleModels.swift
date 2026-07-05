import Foundation

struct Shift: Identifiable, Codable {
    let id: UUID
    var userID: UUID
    var storeID: UUID
    var shiftType: ShiftType
}

struct Leave: Identifiable, Codable {
    let id: UUID
    var userID: UUID
    var storeID: UUID
    var startDate: String // "YYYY-MM-DD"
    var endDate: String // "YYYY-MM-DD"
}

struct DailyTask: Identifiable, Codable {
    let id: UUID
    var userID: UUID
    var date: String // "YYYY-MM-DD"
    var title: String
    var isCompleted: Bool
}
