import Foundation

struct InventorySummary {
    let totalProducts: Int
    let lowStockCount: Int
    let stockRequestsCount: Int
    let discrepancyCount: Int
}

struct StockAlertPreview: Identifiable {
    let id = UUID()
    let productName: String
    let currentQuantity: Int
    let status: AlertStatus
    let imageSymbol: String
    
    enum AlertStatus: String {
        case critical = "Critical"
        case warning = "Warning"
        case outOfStock = "Out of Stock"
    }
}

struct StockRequestPreview: Identifiable {
    let id = UUID()
    let productName: String
    let quantity: Int
    let sourceStore: String
    let destinationStore: String
    let status: RequestStatus
    
    enum RequestStatus: String {
        case pending = "Pending"
        case approved = "Approved"
        case inTransit = "In Transit"
    }
}

struct InventoryDiscrepancyPreview: Identifiable {
    let id = UUID()
    let productName: String
    let expectedQuantity: Int
    let actualQuantity: Int
    let status: DiscrepancyStatus
    
    var difference: Int {
        actualQuantity - expectedQuantity
    }
    
    enum DiscrepancyStatus: String {
        case pendingApproval = "Pending Approval"
        case resolved = "Resolved"
    }
}

struct InventoryProductPreview: Identifiable {
    let id = UUID()
    let productName: String
    let currentStock: Int
    let availability: AvailabilityStatus
    let imageSymbol: String
    
    enum AvailabilityStatus: String {
        case available = "Available"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
    }
}
