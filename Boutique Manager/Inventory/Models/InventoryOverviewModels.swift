import Foundation

// MARK: - Stock Alert Enums
enum AlertSource: String, CaseIterable, Identifiable, Codable {
    case system = "System"
    case salesAssociate = "Sales Associate"
    
    var id: String { self.rawValue }
}

enum AlertType: String, CaseIterable, Identifiable, Codable {
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
    case transferRequested = "Transfer Requested"
    
    var id: String { self.rawValue }
}

enum AlertPriority: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    var colorName: String {
        switch self {
        case .low: return "gray"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Stock Alert Model
struct StockAlert: Identifiable, Codable {
    let id: UUID
    let productName: String
    let sku: String
    let currentQuantity: Int
    let alertType: AlertType
    let priority: AlertPriority
    let source: AlertSource
    let generatedAt: Date
    let description: String
    var imageUrl: String? = nil
    var quantityRequested: Int? = nil
    var requestStatus: RequestStatus? = nil
    var requestedBy: UUID? = nil
    var managerRemark: String? = nil
    var salesAssociateName: String? = nil
    var productID: UUID? = nil
    var thresholdQuantity: Int? = nil
    var storeID: UUID? = nil
}

// MARK: - User Defined Models & Enums for StoreRequest
struct StoreRequest: Identifiable, Codable, Hashable {
    let id: String
    let requestType: RequestType
    let storeName: String
    let sku: String
    let productName: String
    let quantityRequested: Int
    let priority: Priority
    let managerRemark: String?
    var status: RequestStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case requestType = "request_type"
        case storeName = "store_name"
        case sku
        case productName = "product_name"
        case quantityRequested = "quantity_requested"
        case priority
        case managerRemark = "manager_remark"
        case status
        case createdAt = "created_at"
    }
}

enum RequestType: String, Codable, CaseIterable {
    case refill = "Refill"
    case transfer = "Transfer"
}

enum RequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case forwarded = "forwarded"
    case rejected = "rejected"
    case fulfilled = "fulfilled"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .forwarded: return "Forwarded"
        case .rejected: return "Rejected"
        case .fulfilled: return "Fulfilled"
        }
    }
}

enum Priority: String, Codable, CaseIterable {
    case normal = "normal"
    case urgent = "urgent"

    var displayName: String {
        switch self {
        case .normal:
            return "Normal"
        case .urgent:
            return "Urgent"
        }
    }
}
