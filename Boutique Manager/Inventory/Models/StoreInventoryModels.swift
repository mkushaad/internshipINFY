import SwiftUI
import Foundation

// MARK: - StoreInventory Database Model
struct StoreInventory: Identifiable, Codable {
    let id: UUID
    let storeid: UUID
    let productid: UUID
    let currentquantity: Int
    let thresholdquantity: Int
    let updatedat: Date?

    init(
        id: UUID,
        storeid: UUID,
        productid: UUID,
        currentquantity: Int,
        thresholdquantity: Int,
        updatedat: Date? = nil
    ) {
        self.id = id
        self.storeid = storeid
        self.productid = productid
        self.currentquantity = currentquantity
        self.thresholdquantity = thresholdquantity
        self.updatedat = updatedat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        // id
        if let key = DynamicCodingKeys(stringValue: "id"), let val = try? container.decode(UUID.self, forKey: key) {
            self.id = val
        } else if let key = DynamicCodingKeys(stringValue: "id"), let str = try? container.decode(String.self, forKey: key), let u = UUID(uuidString: str) {
            self.id = u
        } else {
            self.id = UUID()
        }

        // storeid
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "storeid")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "store_id")!)) {
            self.storeid = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "storeid")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "store_id")!)), let u = UUID(uuidString: str) {
            self.storeid = u
        } else {
            self.storeid = UUID()
        }

        // productid
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "productid")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "product_id")!)) {
            self.productid = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "productid")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "product_id")!)), let u = UUID(uuidString: str) {
            self.productid = u
        } else {
            self.productid = UUID()
        }

        // currentquantity
        self.currentquantity = (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "currentquantity")!))
            ?? (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "current_quantity")!))
            ?? 0

        // thresholdquantity
        self.thresholdquantity = (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "thresholdquantity")!))
            ?? (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "threshold_quantity")!))
            ?? 0

        // updatedat
        self.updatedat = (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "updatedat")!))
            ?? (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "updated_at")!))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(id, forKey: DynamicCodingKeys(stringValue: "id")!)
        try container.encode(storeid, forKey: DynamicCodingKeys(stringValue: "storeid")!)
        try container.encode(productid, forKey: DynamicCodingKeys(stringValue: "productid")!)
        try container.encode(currentquantity, forKey: DynamicCodingKeys(stringValue: "currentquantity")!)
        try container.encode(thresholdquantity, forKey: DynamicCodingKeys(stringValue: "thresholdquantity")!)
    }
}

// MARK: - Availability Status Enum
enum AvailabilityStatus: String, CaseIterable, Identifiable {
    case outOfStock = "Out of Stock"
    case lowStock = "Low Stock"
    case available = "Available"

    var id: String { self.rawValue }

    var badgeColor: Color {
        switch self {
        case .outOfStock: return .red
        case .lowStock: return .orange
        case .available: return .green
        }
    }
}

// MARK: - Store Inventory Presentation Model
struct StoreInventoryItem: Identifiable {
    var id: UUID { inventory.id }
    let inventory: StoreInventory
    let product: Product

    var availabilityStatus: AvailabilityStatus {
        if inventory.currentquantity == 0 {
            return .outOfStock
        } else if inventory.currentquantity <= inventory.thresholdquantity {
            return .lowStock
        } else {
            return .available
        }
    }
}

// MARK: - Filter Options
enum InventoryFilterOption: String, CaseIterable, Identifiable {
    case all = "All Items"
    case lowStock = "Low Stock"
    case noStock = "No Stock"

    var id: String { self.rawValue }
}

// MARK: - Sorting Options
enum StoreInventorySortOption: String, CaseIterable, Identifiable {
    case alphabetical = "Alphabetically"
    case quantity = "Current Quantity"
    case recentlyUpdated = "Recently Updated"

    var id: String { self.rawValue }
}

// MARK: - Sort Direction Options
enum SortDirection: String, CaseIterable, Identifiable {
    case ascending = "Ascending"
    case descending = "Descending"

    var id: String { self.rawValue }
}
