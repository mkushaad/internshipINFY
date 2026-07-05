import Foundation

struct InventoryRecord: Identifiable, Codable {
    let id: String
    var productID: UUID
    var storeID: UUID
    var quantity: Int
    var reorderThreshold: Int
    var lastUpdated: Date
}

struct StockRequest: Identifiable, Codable {
    let id: UUID
    var productID: UUID
    var sourceStoreID: UUID
    var destinationStoreID: UUID
    var quantity: Int
    var status: TransferRequestStatus
}

struct InventoryTransfer: Identifiable, Codable {
    let id: UUID
    var stockRequestID: UUID
    var transferDate: Date
    var status: InventoryTransferStatus
}

struct VendorRequest: Identifiable, Codable {
    let id: UUID
    var supplierName: String
    var productID: UUID
    var quantity: Int
    var status: VendorRequestStatus
}

struct GoodsReceipt: Identifiable, Codable {
    let id: UUID
    var vendorRequestID: UUID
    var receivedDate: Date
    var receivedQuantity: Int
    var verifiedBy: UUID
}

struct VarianceRecord: Identifiable, Codable {
    let id: UUID
    var productID: UUID
    var expectedQuantity: Int
    var actualQuantity: Int
    var status: VarianceStatus
    var isShrinkage: Bool
}
