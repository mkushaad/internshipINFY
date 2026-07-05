import Foundation

struct Planogram: Identifiable, Codable {
    let id: UUID
    var title: String
    var version: String
    var storeID: UUID
    var createdBy: UUID
    var status: PlanogramStatus
}

struct ComplianceReport: Identifiable, Codable {
    let id: UUID
    var storeID: UUID
    var planogramID: UUID
    var submittedBy: UUID
    var status: ComplianceStatus
    var reviewedBy: UUID?
}

struct ProductRequest: Identifiable, Codable {
    let id: UUID
    var productID: UUID
    var submittedBy: UUID
    var status: ApprovalStatus
    var reviewedBy: UUID?
}

struct ApprovalRequest: Identifiable, Codable {
    let id: UUID
    var type: ApprovalType
    var submittedBy: UUID
    var approvedBy: UUID?
    var status: ApprovalStatus
}

struct Wishlist: Identifiable, Codable {
    let id: UUID
    var customerID: UUID
    var itemCount: Int
}

struct UnifiedBusinessReport: Identifiable, Codable {
    let id: String
    var reportDate: Date
    var salesMetrics: SalesMetrics
    var inventoryMetrics: InventoryMetrics
}

struct SalesMetrics: Codable {
    var totalRevenue: Double
    var transactionCount: Int
}

struct InventoryMetrics: Codable {
    var totalSKUs: Int
    var stockHealthPercentage: Double
}

struct StoreSalesTarget: Codable, Identifiable {
    let id: UUID
    let storeID: UUID?
    let targetAmount: Double
    let currency: Currency?
    let period: SalesTargetPeriod?
    let startDate: String?
    let endDate: String?
    let assignedDate: String?
    let assignedBy: UUID?
    let isActive: Bool?
    
    let createDate: String?
    let updateDate: String?
}
