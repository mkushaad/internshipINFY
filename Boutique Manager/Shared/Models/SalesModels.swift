import Foundation

struct Sale: Identifiable, Codable {
    let id: UUID
    var customerID: UUID
    var salesAssociateID: UUID
    var storeID: UUID
    var saleDate: Date
    var currency: Currency
    var preTaxAmount: Double
    var taxAmount: Double
    var totalAmount: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case customerID
        case salesAssociateID
        case storeID
        case saleDate = "salesDate"
        case currency = "Currency"
        case preTaxAmount
        case taxAmount
        case totalAmount
    }
    
    init(id: UUID, customerID: UUID, salesAssociateID: UUID, storeID: UUID, saleDate: Date, currency: Currency, preTaxAmount: Double, taxAmount: Double, totalAmount: Double) {
        self.id = id
        self.customerID = customerID
        self.salesAssociateID = salesAssociateID
        self.storeID = storeID
        self.saleDate = saleDate
        self.currency = currency
        self.preTaxAmount = preTaxAmount
        self.taxAmount = taxAmount
        self.totalAmount = totalAmount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        customerID = try container.decode(UUID.self, forKey: .customerID)
        salesAssociateID = try container.decode(UUID.self, forKey: .salesAssociateID)
        storeID = try container.decode(UUID.self, forKey: .storeID)
        
        let dateString = try container.decode(String.self, forKey: .saleDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            saleDate = date
        } else {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                saleDate = date
            } else {
                let standardIso = ISO8601DateFormatter()
                if let date = standardIso.date(from: dateString) {
                    saleDate = date
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .saleDate, in: container, debugDescription: "Invalid date string: \(dateString)")
                }
            }
        }
        
        currency = try container.decode(Currency.self, forKey: .currency)
        preTaxAmount = try container.decode(Double.self, forKey: .preTaxAmount)
        taxAmount = try container.decode(Double.self, forKey: .taxAmount)
        totalAmount = try container.decode(Double.self, forKey: .totalAmount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(customerID, forKey: .customerID)
        try container.encode(salesAssociateID, forKey: .salesAssociateID)
        try container.encode(storeID, forKey: .storeID)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        try container.encode(formatter.string(from: saleDate), forKey: .saleDate)
        
        try container.encode(currency, forKey: .currency)
        try container.encode(preTaxAmount, forKey: .preTaxAmount)
        try container.encode(taxAmount, forKey: .taxAmount)
        try container.encode(totalAmount, forKey: .totalAmount)
    }
}

struct SalesItem: Identifiable, Codable {
    let id: UUID
    var saleID: UUID
    var productID: UUID
    var quantity: Int
    var unitPrice: Double
    var subTotal: Double
}

struct SaleDisplayData: Identifiable {
    var id: UUID { sale.id }
    let sale: Sale
    let items: [SalesItem]
    let products: [Product]
    
    var totalAmount: Double { sale.totalAmount }
    var saleDate: Date { sale.saleDate }
    var totalQuantity: Int { items.reduce(0) { $0 + $1.quantity } }
    var primaryCategory: ProductCategory? { products.first?.category }
}

struct Cart: Identifiable, Codable {
    let id: UUID
    var customerID: UUID
    var storeID: UUID
        var totalAmount: Double
}

struct CartItem: Identifiable, Codable {
    let id: UUID
    var productID: UUID
    var quantity: Int
    var unitPrice: Double
    var subtotal: Double
}

struct ReturnRequest: Identifiable, Codable {
    let id: UUID
    var saleID: UUID
    var customerID: UUID
    var reason: String
    var status: ReturnStatus
    var approvedBy: UUID?
}

struct Promotion: Identifiable, Codable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var discountType: DiscountType
    var discountValue: Double
    var status: PromotionStatus
}

struct AssociateSalesTarget: Identifiable, Codable {
    let id: UUID
    var storeID: UUID
    /// If nil, this represents the overarching Store Target set by Corporate Admin.
    /// If set, this represents a specific portion of the target delegated to an Associate.
    var assignedToID: UUID? 
    var periodStartDate: String
    var periodEndDate: String
    var targetAmount: Double
    }
