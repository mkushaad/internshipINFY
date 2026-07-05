import Foundation
internal import Combine

/// Single Source of Truth for Inventory Notifications & Duplicate Prevention
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var notifications: [InventoryNotification] = []
    
    // Tracks active alert types per product/store tuple to handle resolution when restocked
    private var activeAlertState: [String: NotificationType] = [:]

    private init() {}

    // MARK: - Computed Properties

    var unreadCount: Int {
        notifications.filter { $0.status == .unread }.count
    }

    var unreadNotifications: [InventoryNotification] {
        notifications.filter { $0.status == .unread }
    }

    var readCount: Int {
        notifications.filter { $0.status == .read }.count
    }

    var readNotifications: [InventoryNotification] {
        notifications.filter { $0.status == .read }
    }

    var hasUnread: Bool {
        unreadCount > 0
    }

    // MARK: - Core Inventory Evaluation Engine

    /// Evaluates store inventory records against alert rules.
    /// Generates notifications ONLY when a product enters an alert state for the first time
    /// or re-enters after being restocked above threshold.
    func evaluateStoreInventory(storeInventories: [StoreInventory], products: [UUID: Product]) {
        for item in storeInventories {
            guard let product = products[item.productid] else { continue }
            
            let stateKey = "\(item.storeid.uuidString)_\(item.productid.uuidString)"
            
            // Determine alert condition
            let currentType: NotificationType?
            if item.currentquantity == 0 {
                currentType = .outOfStock
            } else if item.currentquantity <= item.thresholdquantity {
                currentType = .lowStock
            } else {
                currentType = nil
            }

            // Case 1: Product is now adequately stocked (restocked above threshold)
            if currentType == nil {
                if activeAlertState[stateKey] != nil {
                    // Product left the alert state. Clear active alert state so future drops trigger a new alert.
                    activeAlertState.removeValue(forKey: stateKey)
                    
                    // Remove resolved notifications for this product so subsequent drops can generate a new notification
                    notifications.removeAll { $0.productID == item.productid && $0.storeID == item.storeid }
                }
                continue
            }

            // Case 2: Product is in low stock or out of stock alert state
            guard let alertType = currentType else { continue }

            // Update active alert state tracking
            activeAlertState[stateKey] = alertType

            // Rule Check: Duplicate Prevention
            // Check if an unread or read notification already exists for (Product, Store, Alert Type)
            let existingNotification = notifications.first { n in
                n.productID == item.productid &&
                n.storeID == item.storeid &&
                n.type == alertType
            }

            // If a notification already exists (unread OR read), DO NOT create another
            if existingNotification != nil {
                continue
            }

            // Generate new notification
            let title = alertType == .outOfStock ? "Out of Stock Alert" : "Low Stock Alert"
            let message: String
            if alertType == .outOfStock {
                message = "\(product.name) (SKU: \(product.sku)) is out of stock in your store."
            } else {
                message = "\(product.name) (SKU: \(product.sku)) stock (\(item.currentquantity) units) is below the threshold of \(item.thresholdquantity)."
            }

            let newNotification = InventoryNotification(
                type: alertType,
                title: title,
                message: message,
                productID: item.productid,
                storeID: item.storeid,
                createdAt: Date(),
                status: .unread,
                productName: product.name,
                currentQuantity: item.currentquantity,
                thresholdQuantity: item.thresholdquantity
            )

            notifications.insert(newNotification, at: 0)
        }
    }

    /// Evaluates sales associate stock requests and creates notifications for new requests.
    func evaluateSalesAssociateRequests(requests: [SalesAssociateStockRequest], products: [UUID: Product], inventories: [UUID: Int]) {
        for request in requests {
            guard let product = products[request.productID] else { continue }
            let currentStock = inventories[request.productID] ?? 0

            // Check duplicate prevention: avoid duplicate notifications for the same request ID
            let existingNotification = notifications.first { n in
                n.id == request.id || (n.productID == request.productID && n.storeID == request.storeID && n.message.contains("Requested: \(request.quantityRequested)"))
            }

            if existingNotification != nil {
                continue
            }

            let newNotification = InventoryNotification(
                id: request.id,
                type: .stockTransfer,
                title: "Stock Transfer",
                message: "\(product.name) - Sales Associate requested \(request.quantityRequested) units.",
                productID: request.productID,
                storeID: request.storeID,
                createdAt: request.createdAt,
                status: .unread,
                productName: product.name,
                currentQuantity: currentStock,
                thresholdQuantity: request.quantityRequested
            )

            notifications.insert(newNotification, at: 0)
        }
    }

    // MARK: - Notification Status Management

    /// Marks a single notification as read. The notification remains in history.
    func markAsRead(id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].status = .read
        }
    }

    /// Marks all unread notifications as read. Notifications remain in history.
    func markAllAsRead() {
        for index in notifications.indices {
            if notifications[index].status == .unread {
                notifications[index].status = .read
            }
        }
    }
    
    /// Clears all notification history (optional helper)
    func clearAll() {
        notifications.removeAll()
    }
}
