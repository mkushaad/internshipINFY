import Foundation

struct Store: Identifiable, Codable {
    let id: UUID
    var name: String
    var location: String
    var region: String
    var managerID: UUID?
    var inventoryControllerID: UUID?
    var currency: Currency
    var privacyRegulation: String
    
    init(
        id: UUID,
        name: String,
        location: String,
        region: String,
        managerID: UUID? = nil,
        inventoryControllerID: UUID? = nil,
        currency: Currency = .usd,
        privacyRegulation: String = "GDPR"
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.region = region
        self.managerID = managerID
        self.inventoryControllerID = inventoryControllerID
        self.currency = currency
        self.privacyRegulation = privacyRegulation
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

        // name
        self.name = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "name")!)) ?? ""

        // location
        self.location = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "location")!)) ?? ""

        // region
        self.region = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "region")!)) ?? ""

        // managerID
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "managerID")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "manager_id")!)) {
            self.managerID = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "managerID")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "manager_id")!)), let u = UUID(uuidString: str) {
            self.managerID = u
        } else {
            self.managerID = nil
        }

        // inventoryControllerID
        if let val = (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "inventoryControllerID")!))
            ?? (try? container.decode(UUID.self, forKey: DynamicCodingKeys(stringValue: "inventory_controller_id")!)) {
            self.inventoryControllerID = val
        } else if let str = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "inventoryControllerID")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "inventory_controller_id")!)), let u = UUID(uuidString: str) {
            self.inventoryControllerID = u
        } else {
            self.inventoryControllerID = nil
        }

        // currency
        if let cStr = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "Currency")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "currency")!)),
           let c = Currency(rawValue: cStr) ?? Currency(rawValue: cStr.uppercased()) {
            self.currency = c
        } else {
            self.currency = .usd
        }

        // privacyRegulation
        self.privacyRegulation = (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "privacyRegulation")!))
            ?? (try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "privacy_regulation")!))
            ?? "GDPR"
    }
}
