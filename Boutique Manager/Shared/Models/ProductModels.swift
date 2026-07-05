import Foundation

// MARK: - Dynamic Coding Key Helper for Flexible Decoding
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }
}

// MARK: - Product Model
struct Product: Identifiable, Codable {
    let id: UUID
    var sku: String
    var name: String
    var brand: String
    var category: ProductCategory
    var barcode: String
    var basePrice: Double
    var isActive: Bool
    var imageUrl: String?
    var updatedAt: Date?
    var createdAt: Date?
    var currentStock: Int?
    var reorderThreshold: Int?

    init(
        id: UUID,
        sku: String,
        name: String,
        brand: String,
        category: ProductCategory,
        barcode: String = "",
        basePrice: Double = 0.0,
        isActive: Bool = true,
        imageUrl: String? = nil,
        updatedAt: Date? = nil,
        createdAt: Date? = nil,
        currentStock: Int? = nil,
        reorderThreshold: Int? = nil
    ) {
        self.id = id
        self.sku = sku
        self.name = name
        self.brand = brand
        self.category = category
        self.barcode = barcode
        self.basePrice = basePrice
        self.isActive = isActive
        self.imageUrl = imageUrl
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.currentStock = currentStock
        self.reorderThreshold = reorderThreshold
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

        // sku
        self.sku = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "sku")!)) ?? ""

        // name
        self.name = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "name")!)) ?? ""

        // brand
        self.brand = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "brand")!)) ?? ""

        // category
        if let cat = try? container.decode(ProductCategory.self, forKey: DynamicCodingKeys(stringValue: "category")!) {
            self.category = cat
        } else {
            self.category = .general
        }

        // barcode
        self.barcode = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "barcode")!)) ?? ""

        // basePrice
        self.basePrice = (try? container.decode(Double.self, forKey: DynamicCodingKeys(stringValue: "basePrice")!))
            ?? (try? container.decode(Double.self, forKey: DynamicCodingKeys(stringValue: "base_price")!))
            ?? 0.0

        // isActive
        self.isActive = (try? container.decode(Bool.self, forKey: DynamicCodingKeys(stringValue: "isActive")!))
            ?? (try? container.decode(Bool.self, forKey: DynamicCodingKeys(stringValue: "is_active")!))
            ?? true

        // imageUrl
        self.imageUrl = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "image_url")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "imageUrl")!))

        // updatedAt
        self.updatedAt = (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "updatedat")!))
            ?? (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "updated_at")!))

        // createdAt
        self.createdAt = (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "createdat")!))
            ?? (try? container.decode(Date.self, forKey: DynamicCodingKeys(stringValue: "created_at")!))

        // currentStock (ignored for StoreInventory view)
        self.currentStock = (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "current_stock")!))

        // reorderThreshold (ignored for StoreInventory view)
        self.reorderThreshold = (try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "reorder_threshold")!))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(id, forKey: DynamicCodingKeys(stringValue: "id")!)
        try container.encode(sku, forKey: DynamicCodingKeys(stringValue: "sku")!)
        try container.encode(name, forKey: DynamicCodingKeys(stringValue: "name")!)
        try container.encode(brand, forKey: DynamicCodingKeys(stringValue: "brand")!)
        try container.encode(category, forKey: DynamicCodingKeys(stringValue: "category")!)
        try container.encode(barcode, forKey: DynamicCodingKeys(stringValue: "barcode")!)
        try container.encode(basePrice, forKey: DynamicCodingKeys(stringValue: "basePrice")!)
        try container.encode(isActive, forKey: DynamicCodingKeys(stringValue: "isActive")!)
        try container.encodeIfPresent(imageUrl, forKey: DynamicCodingKeys(stringValue: "image_url")!)
    }
}
