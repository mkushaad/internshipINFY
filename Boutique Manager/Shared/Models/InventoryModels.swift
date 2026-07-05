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

struct SalesAssociateStockRequest: Identifiable, Codable, Hashable {
    let id: UUID
    let productID: UUID
    let requestedBy: UUID
    let storeID: UUID
    let quantityRequested: Int
    let urgency: Priority
    var status: RequestStatus
    var managerRemark: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        productID: UUID,
        requestedBy: UUID,
        storeID: UUID,
        quantityRequested: Int,
        urgency: Priority = .normal,
        status: RequestStatus = .pending,
        managerRemark: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.productID = productID
        self.requestedBy = requestedBy
        self.storeID = storeID
        self.quantityRequested = quantityRequested
        self.urgency = urgency
        self.status = status
        self.managerRemark = managerRemark
        self.createdAt = createdAt
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

        // productid
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "productid")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "product_id")!)) {
            self.productID = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "productid")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "product_id")!)), let u = UUID(uuidString: str) {
            self.productID = u
        } else {
            self.productID = UUID()
        }

        // requestedby
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "requestedby")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "requested_by")!)) {
            self.requestedBy = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "requestedby")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "requested_by")!)), let u = UUID(uuidString: str) {
            self.requestedBy = u
        } else {
            self.requestedBy = UUID()
        }

        // storeid
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "storeid")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "store_id")!)) {
            self.storeID = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "storeid")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "store_id")!)), let u = UUID(uuidString: str) {
            self.storeID = u
        } else {
            self.storeID = UUID()
        }

        // quantityrequested
        self.quantityRequested = (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "quantityrequested")!))
            ?? (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "quantity_requested")!))
            ?? 0

        // urgency
        if let uKey = DynamicCodingKeys(stringValue: "urgency"), let uStr = try? container.decode(String.self, forKey: uKey) {
            self.urgency = Priority(rawValue: uStr.lowercased()) ?? .normal
        } else if let uKey = DynamicCodingKeys(stringValue: "urgency"), let uVal = try? container.decode(Priority.self, forKey: uKey) {
            self.urgency = uVal
        } else {
            self.urgency = .normal
        }

        // status
        if let sKey = DynamicCodingKeys(stringValue: "status"), let sStr = try? container.decode(String.self, forKey: sKey) {
            self.status = RequestStatus(rawValue: sStr.lowercased()) ?? .pending
        } else if let sKey = DynamicCodingKeys(stringValue: "status"), let sVal = try? container.decode(RequestStatus.self, forKey: sKey) {
            self.status = sVal
        } else {
            self.status = .pending
        }

        // managerremark
        self.managerRemark = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "managerremark")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "manager_remark")!))

        // createdat
        self.createdAt = (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "createdat")!))
            ?? (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "created_at")!))
            ?? Date()
    }
}

struct StoreRequestToInventory: Identifiable, Codable, Hashable {
    let id: UUID
    let requestType: RequestType
    let storeID: UUID
    let productID: UUID
    let quantityRequested: Int
    let priority: Priority
    let transferRequestID: UUID?
    var status: StoreRequestStatus
    let createdAt: Date

    init(
        id: UUID = UUID(),
        requestType: RequestType = .refill,
        storeID: UUID,
        productID: UUID,
        quantityRequested: Int,
        priority: Priority = .normal,
        transferRequestID: UUID? = nil,
        status: StoreRequestStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.requestType = requestType
        self.storeID = storeID
        self.productID = productID
        self.quantityRequested = quantityRequested
        self.priority = priority
        self.transferRequestID = transferRequestID
        self.status = status
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case requestType = "requesttype"
        case storeID = "storeid"
        case productID = "productid"
        case quantityRequested = "quantityrequested"
        case priority
        case transferRequestID = "transferrequestid"
        case status
        case createdAt = "createdat"
    }
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

struct StoreToStoreTransferRequest: Identifiable, Codable, Hashable {
    let id: UUID
    let senderStoreID: UUID
    let destinationStoreID: UUID
    let productID: UUID
    let quantityRequested: Int
    let salesAssociateRequestID: UUID
    var status: TransferRequestStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case senderStoreID = "senderstoreid"
        case destinationStoreID = "destinationstoreid"
        case productID = "productid"
        case quantityRequested = "quantityrequested"
        case salesAssociateRequestID = "salesassociaterequestid"
        case status
        case createdAt = "createdat"
    }

    init(
        id: UUID = UUID(),
        senderStoreID: UUID,
        destinationStoreID: UUID,
        productID: UUID,
        quantityRequested: Int,
        salesAssociateRequestID: UUID,
        status: TransferRequestStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.senderStoreID = senderStoreID
        self.destinationStoreID = destinationStoreID
        self.productID = productID
        self.quantityRequested = quantityRequested
        self.salesAssociateRequestID = salesAssociateRequestID
        self.status = status
        self.createdAt = createdAt
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

        // senderstoreid
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "senderstoreid")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "sender_store_id")!)) {
            self.senderStoreID = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "senderstoreid")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "sender_store_id")!)), let u = UUID(uuidString: str) {
            self.senderStoreID = u
        } else {
            self.senderStoreID = UUID()
        }

        // destinationstoreid
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "destinationstoreid")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "destination_store_id")!)) {
            self.destinationStoreID = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "destinationstoreid")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "destination_store_id")!)), let u = UUID(uuidString: str) {
            self.destinationStoreID = u
        } else {
            self.destinationStoreID = UUID()
        }

        // productid
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "productid")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "product_id")!)) {
            self.productID = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "productid")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "product_id")!)), let u = UUID(uuidString: str) {
            self.productID = u
        } else {
            self.productID = UUID()
        }

        // quantityrequested
        self.quantityRequested = (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "quantityrequested")!))
            ?? (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "quantity_requested")!))
            ?? 0

        // salesassociaterequestid
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "salesassociaterequestid")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "sales_associate_request_id")!)) {
            self.salesAssociateRequestID = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "salesassociaterequestid")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "sales_associate_request_id")!)), let u = UUID(uuidString: str) {
            self.salesAssociateRequestID = u
        } else {
            self.salesAssociateRequestID = UUID()
        }

        // status
        if let sKey = DynamicCodingKeys(stringValue: "status"), let sStr = try? container.decode(String.self, forKey: sKey) {
            self.status = TransferRequestStatus(rawValue: sStr.lowercased()) ?? .pending
        } else if let sKey = DynamicCodingKeys(stringValue: "status"), let sVal = try? container.decode(TransferRequestStatus.self, forKey: sKey) {
            self.status = sVal
        } else {
            self.status = .pending
        }

        // createdat
        self.createdAt = (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "createdat")!))
            ?? (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "created_at")!))
            ?? Date()
    }
}

struct StoreTransferDisplayItem: Identifiable, Hashable {
    let id: UUID
    let request: StoreToStoreTransferRequest
    let productName: String
    let sku: String
    let imageUrl: String?
    let senderStoreName: String
    let destinationStoreName: String
    let isSent: Bool
    
    init(
        request: StoreToStoreTransferRequest,
        productName: String,
        sku: String,
        imageUrl: String? = nil,
        senderStoreName: String,
        destinationStoreName: String,
        isSent: Bool = false
    ) {
        self.id = request.id
        self.request = request
        self.productName = productName
        self.sku = sku
        self.imageUrl = imageUrl
        self.senderStoreName = senderStoreName
        self.destinationStoreName = destinationStoreName
        self.isSent = isSent
    }
}

