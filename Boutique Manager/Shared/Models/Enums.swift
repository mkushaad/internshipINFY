import Foundation

enum StoreRegion: String, Codable {
    case northAmerica
    case europe
    case asiaPacific
    case latinAmerica
    case middleEast
    // Add more as needed
}

enum Currency: String, Codable, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case inr = "INR"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .inr: return "₹"
        }
    }
}

enum UserRoleType: String, Codable {
    case corporateAdmin = "admin"
    case boutiqueManager = "manager"
    case inventoryController = "inventory"
    case salesAssociate = "associate"
}

enum VIPTier: String, Codable {
    case none
    case silver
    case gold
    case platinum
    case diamond
}

enum ProductCategory: String, Codable {
    case handbags = "Handbags"
    case fragrances = "Fragrances"
    case accessories = "Accessories"
    case jewellery = "Jewellery"
    case watches = "Watches"
    case footware = "Footware"
    case general = "General"
    
    // Legacy/Main view categories
    case apparel = "Apparel"
    case footwear = "Footwear"
    case jewelry = "Jewelry"
    case cosmetics = "Cosmetics"
    case bag = "Bag"
    case perfume = "Perfume"
    case wallet = "Wallet"
    case ring = "Ring"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self)) ?? ""
        if let exact = ProductCategory(rawValue: raw) {
            self = exact
        } else if let lower = ProductCategory(rawValue: raw.capitalized) {
            self = lower
        } else {
            self = .general
        }
    }
}

enum AppointmentType: String, Codable {
    case walkIn
    case videoConsultation
    
    var displayName: String {
        switch self {
        case .walkIn: return "Walk-In"
        case .videoConsultation: return "Video Consultation"
        }
    }
}

enum AppointmentStatus: String, Codable {
    case scheduled
    case completed
    case cancelled
    case noShow
}

enum TransferRequestStatus: String, Codable {
    case pending
    case approved
    case rejected
    case inTransit
    case completed
    case accepted
    case declined
    case cancelled
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved, .accepted: return "Approved"
        case .rejected, .declined: return "Rejected"
        case .inTransit: return "In Transit"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

enum InventoryTransferStatus: String, Codable {
    case preparing
    case shipped
    case received
    case delayed
    case cancelled
}

enum VendorRequestStatus: String, Codable {
    case submitted
    case processing
    case shipped
    case partiallyReceived
    case fulfilled
    case cancelled
}

enum VarianceStatus: String, Codable {
    case reported
    case investigating
    case resolved
    case writtenOff
}

enum ReturnStatus: String, Codable {
    case requested
    case approved
    case rejected
    case processed
}

enum PlanogramStatus: String, Codable {
    case draft
    case active
    case archived
}

enum ComplianceStatus: String, Codable {
    case pendingReview
    case compliant
    case nonCompliant
    case actionRequired
}

enum RSVPStatus: String, Codable {
    case pending
    case accepted
    case declined
    case maybe
}

enum DiscountType: String, Codable {
    case percentage
    case fixedAmount
}

enum PromotionStatus: String, Codable {
    case upcoming
    case active
    case expired
    case suspended
}

enum ApprovalStatus: String, Codable {
    case pending
    case approved
    case rejected
}

enum ApprovalType: String, Codable {
    case discount
    case returnException
    case inventoryWriteOff
    case other
}

enum SalesTargetPeriod: String, Codable {
    case monthly
    case quarterly
    case yearly
}

enum ShiftType: String, Codable {
    case morning
    case evening
    case leave
    
    var displayName: String {
        switch self {
        case .morning: return "9:00 AM - 2:00 PM"
        case .evening: return "2:00 PM - 7:00 PM"
        case .leave: return "On Leave"
        }
    }
}
// MARK: - Inventory-Specific Enums

enum StoreRequestStatus: String, Codable, Hashable {
    case pending
    case approved
    case rejected
    case fulfilled
    case cancelled
}

