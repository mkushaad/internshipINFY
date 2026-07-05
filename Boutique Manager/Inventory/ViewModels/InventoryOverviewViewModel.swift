import Foundation
internal import Combine
import Supabase

@MainActor
class InventoryOverviewViewModel: ObservableObject {
    @Published var selectedSegmentIndex: Int = 0
    @Published var stockAlerts: [StockAlert] = []
    @Published var storeRequests: [StoreRequest] = []
    @Published var isLoading: Bool = false
    @Published var ignoredAlertIds: Set<UUID> = []
    
    // Search and Filter States
    @Published var searchText: String = ""
    
    // Alerts Filter States
    @Published var selectedAlertPriority: AlertPriority? = nil
    @Published var selectedAlertType: AlertType? = nil
    @Published var selectedAlertSource: AlertSource? = nil
    
    // Requests Filter States
    @Published var selectedRequestPriority: Priority? = nil
    @Published var selectedRequestStatus: RequestStatus? = nil
    @Published var selectedRequestType: RequestType? = nil
    
    // Private store for sales associate generated alerts
    private var salesAssociateAlerts: [StockAlert] = []

    init() {
        loadMockData()
        Task {
            await fetchDynamicStockAlerts()
        }
    }
    
    // MARK: - Dynamic Stock Alert Generation
    
    func fetchDynamicStockAlerts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Step 1: Obtain assigned store ID for current user
            var storeID: UUID? = AuthManager.shared.currentUser?.assignedStoreID

            if storeID == nil {
                if let session = try? await SupabaseService.shared.client.auth.session {
                    let authUserID = session.user.id
                    let user: User? = try? await SupabaseService.shared.client
                        .from("User")
                        .select()
                        .eq("id", value: authUserID)
                        .single()
                        .execute()
                        .value
                    
                    if let user = user {
                        AuthManager.shared.currentUser = user
                        storeID = user.assignedStoreID
                    }
                }
            }

            guard let targetStoreID = storeID else {
                return
            }

            // Step 2: Query StoreInventory table for assigned store
            var fetchedInventories: [StoreInventory] = []
            do {
                fetchedInventories = try await SupabaseService.shared.client
                    .from("StoreInventory")
                    .select()
                    .eq("storeid", value: targetStoreID.uuidString)
                    .execute()
                    .value
            } catch {
                fetchedInventories = try await SupabaseService.shared.client
                    .from("store_inventory")
                    .select()
                    .eq("store_id", value: targetStoreID.uuidString)
                    .execute()
                    .value
            }

            // Step 3: Fetch matching Product records
            let productIDs = Set(fetchedInventories.map { $0.productid })
            var productsDict: [UUID: Product] = [:]

            if !productIDs.isEmpty {
                let idStrings = productIDs.map { $0.uuidString }
                let fetchedProducts: [Product] = (try? await SupabaseService.shared.client
                    .from("Product")
                    .select()
                    .in("id", values: idStrings)
                    .execute()
                    .value) ?? []

                for product in fetchedProducts {
                    productsDict[product.id] = product
                }
            }

            // Step 4: Dynamically generate system alerts for items where currentquantity <= thresholdquantity
            var dynamicAlerts: [StockAlert] = []

            for item in fetchedInventories where item.currentquantity <= item.thresholdquantity {
                guard let product = productsDict[item.productid] else { continue }
                
                // Deterministic UUID based on item ID so user dismissals remain consistent
                let alertId = item.id

                if ignoredAlertIds.contains(alertId) {
                    continue
                }

                let isOutOfStock = item.currentquantity == 0
                let alertType: AlertType = isOutOfStock ? .outOfStock : .lowStock
                let priority: AlertPriority = isOutOfStock ? .high : (item.currentquantity <= item.thresholdquantity / 2 ? .high : .medium)

                let desc: String
                if isOutOfStock {
                    desc = "System Alert: \(product.name) (SKU: \(product.sku)) is currently out of stock in your store (Threshold: \(item.thresholdquantity) units). Please generate a stock request."
                } else {
                    desc = "System Alert: \(product.name) (SKU: \(product.sku)) stock quantity (\(item.currentquantity) units) has reached or fallen below the store threshold (\(item.thresholdquantity) units). Refill recommended."
                }

                let alert = StockAlert(
                    id: alertId,
                    productName: product.name,
                    sku: product.sku,
                    currentQuantity: item.currentquantity,
                    alertType: alertType,
                    priority: priority,
                    source: .system,
                    generatedAt: item.updatedat ?? Date(),
                    description: desc,
                    imageUrl: product.imageUrl
                )
                dynamicAlerts.append(alert)
            }

            // Step 5: Merge system alerts with non-system sales associate alerts (excluding ignored ones)
            let activeAssociateAlerts = salesAssociateAlerts.filter { !ignoredAlertIds.contains($0.id) }
            self.stockAlerts = dynamicAlerts + activeAssociateAlerts

        } catch {
            print("Error generating dynamic stock alerts: \(error)")
        }
    }
    
    // MARK: - Computed Properties for Filtered Listings
    
    var filteredStockAlerts: [StockAlert] {
        stockAlerts.filter { alert in
            // Search Text Match (Product Name or SKU)
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesName = alert.productName.lowercased().contains(query)
                let matchesSku = alert.sku.lowercased().contains(query)
                if !matchesName && !matchesSku {
                    return false
                }
            }
            
            // Priority Match
            if let priority = selectedAlertPriority, alert.priority != priority {
                return false
            }
            
            // Alert Type Match
            if let type = selectedAlertType, alert.alertType != type {
                return false
            }
            
            // Source Match
            if let source = selectedAlertSource, alert.source != source {
                return false
            }
            
            return true
        }
    }
    
    var filteredStoreRequests: [StoreRequest] {
        storeRequests.filter { request in
            // Search Text Match (Product Name or SKU)
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesName = request.productName.lowercased().contains(query)
                let matchesSku = request.sku.lowercased().contains(query)
                if !matchesName && !matchesSku {
                    return false
                }
            }
            
            // Priority Match
            if let priority = selectedRequestPriority, request.priority != priority {
                return false
            }
            
            // Status Match
            if let status = selectedRequestStatus, request.status != status {
                return false
            }
            
            // Request Type Match
            if let type = selectedRequestType, request.requestType != type {
                return false
            }
            
            return true
        }
    }
    
    var hasActiveFilters: Bool {
        if !searchText.isEmpty { return true }
        if selectedSegmentIndex == 0 {
            return selectedAlertPriority != nil || selectedAlertType != nil || selectedAlertSource != nil
        } else {
            return selectedRequestPriority != nil || selectedRequestStatus != nil || selectedRequestType != nil
        }
    }
    
    func resetFilters() {
        searchText = ""
        selectedAlertPriority = nil
        selectedAlertType = nil
        selectedAlertSource = nil
        selectedRequestPriority = nil
        selectedRequestStatus = nil
        selectedRequestType = nil
    }
    
    private func loadMockData() {
        let now = Date()
        let calendar = Calendar.current
        
        // Populate Sales Associate generated alerts only (System alerts are dynamically generated)
        salesAssociateAlerts = [
            StockAlert(
                id: UUID(),
                productName: "Rolex Submariner",
                sku: "RLX-SUB-126610",
                currentQuantity: 4,
                alertType: .transferRequested,
                priority: .medium,
                source: .salesAssociate,
                generatedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                description: "Sales Associate 'Sarah Jenkins' from the Mumbai boutique has requested a stock transfer of 2 units of Rolex Submariner to fulfill local VIP customer demand."
            ),
            StockAlert(
                id: UUID(),
                productName: "Chanel No. 5 Eau de Parfum",
                sku: "CHN-N5-100",
                currentQuantity: 0,
                alertType: .outOfStock,
                priority: .high,
                source: .salesAssociate,
                generatedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                description: "Sales Associate 'John Doe' from the Cupertino boutique has submitted a high-priority request for Chanel No. 5 refill due to upcoming promotional event."
            )
        ]
        
        // Populate Store Requests
        storeRequests = [
            StoreRequest(
                id: UUID().uuidString,
                requestType: .transfer,
                storeName: "Dubai Mall Flagship",
                sku: "RLX-DT-116500",
                productName: "Rolex Daytona",
                quantityRequested: 3,
                priority: .urgent,
                managerRemark: "Awaiting approval from Cupertino Central Hub. Store-to-store shipping scheduled once approved.",
                status: .pending,
                createdAt: calendar.date(byAdding: .hour, value: -4, to: now) ?? now
            ),
            StoreRequest(
                id: UUID().uuidString,
                requestType: .refill,
                storeName: "New York Flagship",
                sku: "RLX-SUB-126610",
                productName: "Rolex Submariner",
                quantityRequested: 5,
                priority: .normal,
                managerRemark: "Refill approved by Regional Manager. Shipped from Central Warehouse via DHL Express (Airway Bill: #DHL881729).",
                status: .approved,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            StoreRequest(
                id: UUID().uuidString,
                requestType: .transfer,
                storeName: "Paris Champs-Élysées",
                sku: "HMS-KL-28",
                productName: "Hermès Kelly 28",
                quantityRequested: 1,
                priority: .urgent,
                managerRemark: "Transfer request completely fulfilled. Item received in boutique, verified by Store Manager and catalog updated.",
                status: .fulfilled,
                createdAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now
            ),
            StoreRequest(
                id: UUID().uuidString,
                requestType: .refill,
                storeName: "Milan Boutique",
                sku: "LV-WT-M60017",
                productName: "LV Zippy Wallet",
                quantityRequested: 10,
                priority: .normal,
                managerRemark: "Refill request rejected due to global stock shortage. Stock allocation prioritizing retail sales.",
                status: .rejected,
                createdAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now
            )
        ]
    }
    
    // MARK: - Actions
    
    func ignoreAlert(id: UUID) {
        ignoredAlertIds.insert(id)
        stockAlerts.removeAll { $0.id == id }
    }
    
    func convertAlertToStoreRequest(alertId: UUID, request: StoreRequest) {
        storeRequests.insert(request, at: 0)
        ignoredAlertIds.insert(alertId)
        stockAlerts.removeAll { $0.id == alertId }
    }
}
