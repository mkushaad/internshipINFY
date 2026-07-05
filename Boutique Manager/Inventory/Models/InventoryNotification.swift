import Foundation

// MARK: - Notification Enums
enum NotificationStatus: String, Codable, CaseIterable {
    case unread
    case read
}

enum NotificationType: String, Codable, CaseIterable {
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
    case stockTransfer = "Stock Transfer"
}

// MARK: - Inventory Notification Data Model
struct InventoryNotification: Identifiable, Codable, Hashable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let productID: UUID
    let storeID: UUID
    let createdAt: Date
    var status: NotificationStatus
    
    // Supplementary metadata for rich presentation
    let productName: String
    let currentQuantity: Int
    let thresholdQuantity: Int
    
    init(
        id: UUID = UUID(),
        type: NotificationType,
        title: String,
        message: String,
        productID: UUID,
        storeID: UUID,
        createdAt: Date = Date(),
        status: NotificationStatus = .unread,
        productName: String,
        currentQuantity: Int,
        thresholdQuantity: Int
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.productID = productID
        self.storeID = storeID
        self.createdAt = createdAt
        self.status = status
        self.productName = productName
        self.currentQuantity = currentQuantity
        self.thresholdQuantity = thresholdQuantity
    }
}
