import Foundation
internal import Combine
import Supabase

struct StoreInventoryRequestItem: Identifiable {
    let request: StoreRequestToInventory
    let productName: String
    let sku: String
    let brand: String
    let categoryName: String
    let imageUrl: String?
    
    var id: UUID { request.id }
}

enum RequestStatusFilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"
    case fulfilled = "Fulfilled"
    case rejected = "Rejected"
    
    var id: String { rawValue }
}

@MainActor
class InventoryOverviewViewModel: ObservableObject {
    @Published var selectedSegmentIndex: Int = 0
    @Published var stockAlerts: [StockAlert] = []
    @Published var storeRequests: [StoreRequest] = []
    @Published var inventoryRequests: [StoreInventoryRequestItem] = []
    @Published var isLoading: Bool = false
    @Published var ignoredAlertIds: Set<UUID> = []
    @Published var showSuccessToast: Bool = false
    @Published var successToastMessage: String = ""
    
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
    @Published var selectedInventoryRequestStatusFilter: RequestStatusFilterOption = .all

    init() {
        Task {
            await fetchDynamicStockAlerts()
        }
        
        NotificationCenter.default.addObserver(forName: .salesAssociateRequestUpdated, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchDynamicStockAlerts()
            }
        }
        NotificationCenter.default.addObserver(forName: .storeInventoryUpdated, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchDynamicStockAlerts()
            }
        }
        NotificationCenter.default.addObserver(forName: .inventoryDataRefreshedAll, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchDynamicStockAlerts()
            }
        }
    }
    
    // MARK: - Dynamic Stock Alert & Sales Associate Request Generation
    
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
                fetchedInventories = (try? await SupabaseService.shared.client
                    .from("store_inventory")
                    .select()
                    .eq("store_id", value: targetStoreID.uuidString)
                    .execute()
                    .value) ?? []
            }

            // Step 3: Query SalesAssociateStockRequest table for assigned store
            var fetchedSalesRequests: [SalesAssociateStockRequest] = []
            do {
                fetchedSalesRequests = try await SupabaseService.shared.client
                    .from("SalesAssociateStockRequest")
                    .select()
                    .eq("storeid", value: targetStoreID.uuidString)
                    .execute()
                    .value
            } catch {
                fetchedSalesRequests = (try? await SupabaseService.shared.client
                    .from("sales_associate_stock_request")
                    .select()
                    .eq("store_id", value: targetStoreID.uuidString)
                    .execute()
                    .value) ?? []
            }

            // Step 4: Map inventories by product ID
            let inventoryDict = Dictionary(uniqueKeysWithValues: fetchedInventories.map { ($0.productid, $0) })
            let inventoryStockMap = Dictionary(uniqueKeysWithValues: fetchedInventories.map { ($0.productid, $0.currentquantity) })

            // Step 5: Batch fetch matching Product records
            var allProductIDs = Set(fetchedInventories.map { $0.productid })
            for req in fetchedSalesRequests {
                allProductIDs.insert(req.productID)
            }

            var productsDict: [UUID: Product] = [:]
            if !allProductIDs.isEmpty {
                let idStrings = allProductIDs.map { $0.uuidString }
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

            // Step 6: Dynamically generate system alerts for items where currentquantity <= thresholdquantity
            var dynamicSystemAlerts: [StockAlert] = []

            for item in fetchedInventories where item.currentquantity <= item.thresholdquantity {
                guard let product = productsDict[item.productid] else { continue }
                
                let alertId = item.id
                if ignoredAlertIds.contains(alertId) { continue }

                let isOutOfStock = item.currentquantity == 0
                let alertType: AlertType = isOutOfStock ? .outOfStock : .lowStock
                let priority: AlertPriority = isOutOfStock ? .high : (item.currentquantity <= item.thresholdquantity / 2 ? .high : .medium)

                let desc: String
                if isOutOfStock {
                    desc = "System Alert: \(product.name) (SKU: \(product.sku)) is currently out of stock."
                } else {
                    desc = "System Alert: \(product.name) (SKU: \(product.sku)) stock quantity (\(item.currentquantity) units) is low."
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
                    imageUrl: product.imageUrl,
                    productID: item.productid,
                    thresholdQuantity: item.thresholdquantity
                )
                dynamicSystemAlerts.append(alert)
            }

            // Step 6.5: Batch fetch Sales Associate Users for requestedBy
            let requestedByIDs = Array(Set(fetchedSalesRequests.map { $0.requestedBy }))
            var userNamesDict: [UUID: String] = [:]
            if !requestedByIDs.isEmpty {
                let idStrings = requestedByIDs.map { $0.uuidString }
                var fetchedUsers: [User] = []
                do {
                    fetchedUsers = try await SupabaseService.shared.client
                        .from("User")
                        .select()
                        .in("id", values: idStrings)
                        .execute()
                        .value
                } catch {
                    fetchedUsers = (try? await SupabaseService.shared.client
                        .from("user")
                        .select()
                        .in("id", values: idStrings)
                        .execute()
                        .value) ?? []
                }
                
                for user in fetchedUsers {
                    let fullName = "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespaces)
                    userNamesDict[user.id] = fullName.isEmpty ? "Sales Associate" : fullName
                }
            }

            // Step 7: Convert SalesAssociateStockRequest rows into StockAlert presentation models
            var requestAlerts: [StockAlert] = []
            for req in fetchedSalesRequests {
                if ignoredAlertIds.contains(req.id) { continue }
                if req.status == .rejected || req.status == .fulfilled { continue }
                guard let product = productsDict[req.productID] else { continue }
                let currentStock = inventoryDict[req.productID]?.currentquantity ?? 0

                let priority: AlertPriority = req.urgency == .urgent ? .high : .medium
                let associateName = userNamesDict[req.requestedBy] ?? "Sales Associate"

                let requestAlert = StockAlert(
                    id: req.id,
                    productName: product.name,
                    sku: product.sku,
                    currentQuantity: currentStock,
                    alertType: .transferRequested,
                    priority: priority,
                    source: .salesAssociate,
                    generatedAt: req.createdAt,
                    description: req.managerRemark ?? "Stock request submitted by \(associateName)",
                    imageUrl: product.imageUrl,
                    quantityRequested: req.quantityRequested,
                    requestStatus: req.status,
                    requestedBy: req.requestedBy,
                    managerRemark: req.managerRemark,
                    salesAssociateName: associateName,
                    productID: req.productID,
                    storeID: req.storeID
                )
                requestAlerts.append(requestAlert)
            }

            // Step 8: Delegate notification creation to NotificationManager
            NotificationManager.shared.evaluateStoreInventory(storeInventories: fetchedInventories, products: productsDict)
            NotificationManager.shared.evaluateSalesAssociateRequests(requests: fetchedSalesRequests, products: productsDict, inventories: inventoryStockMap)

            // Step 9: Update combined stock alerts list
            self.stockAlerts = dynamicSystemAlerts + requestAlerts

            // Step 10: Fetch StoreRequestToInventory rows for Inventory Requests segment
            await fetchInventoryRequests()

        } catch {
            print("Error generating dynamic stock alerts: \(error)")
        }
    }
    
    // MARK: - Computed Properties for Filtered Listings
    
    var filteredStockAlerts: [StockAlert] {
        var items = stockAlerts.filter { alert in
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

        // When priority filter is selected (or sorting by priority), sort items based on priority (high > medium > low)
        if selectedAlertPriority != nil {
            items.sort { a, b in
                let order: [AlertPriority: Int] = [.high: 3, .medium: 2, .low: 1]
                let pA = order[a.priority] ?? 0
                let pB = order[b.priority] ?? 0
                return pA > pB
            }
        }

        return items
    }
    
    var filteredStoreRequests: [StoreRequest] {
        storeRequests.filter { request in
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesName = request.productName.lowercased().contains(query)
                let matchesSku = request.sku.lowercased().contains(query)
                if !matchesName && !matchesSku {
                    return false
                }
            }
            
            if let priority = selectedRequestPriority, request.priority != priority {
                return false
            }
            
            if let status = selectedRequestStatus, request.status != status {
                return false
            }
            
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

    func removeProcessedSystemAlert(id: UUID) {
        ignoredAlertIds.insert(id)
        stockAlerts.removeAll { $0.id == id }
    }

    func triggerSuccessToast(message: String) {
        successToastMessage = message
        showSuccessToast = true
    }

    func acceptSalesAssociateRequest(requestId: UUID, managerRemark: String?) async {
        let trimmedRemark = managerRemark?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove locally immediately so UI updates
        ignoreAlert(id: requestId)
        
        let tables = ["SalesAssociateStockRequest", "sales_associate_stock_request"]
        let remarkKeys = ["managerremark", "manager_remark", "managerRemark"]
        let statusValues = ["fulfilled", "Fulfilled", "approved", "Approved"]
        let idFormats = [requestId.uuidString, requestId.uuidString.lowercased()]
        
        var isUpdated = false
        
        for table in tables {
            if isUpdated { break }
            
            for idStr in idFormats {
                if isUpdated { break }
                
                // 1. Try with remark if provided
                if let remark = trimmedRemark, !remark.isEmpty {
                    for remarkKey in remarkKeys {
                        for statusVal in statusValues {
                            let payload: [String: AnyJSON] = [
                                "status": .string(statusVal),
                                remarkKey: .string(remark)
                            ]
                            do {
                                try await SupabaseService.shared.client
                                    .from(table)
                                    .update(payload)
                                    .eq("id", value: idStr)
                                    .execute()
                                print("Successfully accepted \(table) (status: \(statusVal), \(remarkKey)) for id \(idStr)")
                                isUpdated = true
                                break
                            } catch {
                                print("Accept update attempt failed on \(table) with \(remarkKey) & status \(statusVal): \(error)")
                            }
                        }
                        if isUpdated { break }
                    }
                }
                
                // 2. If remark update failed or no remark provided, update status alone
                if !isUpdated {
                    for statusVal in statusValues {
                        let payload: [String: AnyJSON] = [
                            "status": .string(statusVal)
                        ]
                        do {
                            try await SupabaseService.shared.client
                                .from(table)
                                .update(payload)
                                .eq("id", value: idStr)
                                .execute()
                            print("Successfully accepted \(table) status to \(statusVal) for id \(idStr)")
                            isUpdated = true
                            break
                        } catch {
                            print("Status update attempt failed on \(table) with \(statusVal): \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func declineSalesAssociateRequest(requestId: UUID, managerRemark: String?) async {
        let trimmedRemark = managerRemark?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove locally immediately so UI updates
        ignoreAlert(id: requestId)
        
        let tables = ["SalesAssociateStockRequest", "sales_associate_stock_request"]
        let remarkKeys = ["managerremark", "manager_remark", "managerRemark"]
        let statusValues = ["rejected", "Rejected"]
        let idFormats = [requestId.uuidString, requestId.uuidString.lowercased()]
        
        var isUpdated = false
        
        for table in tables {
            if isUpdated { break }
            
            for idStr in idFormats {
                if isUpdated { break }
                
                // 1. Try with remark if provided
                if let remark = trimmedRemark, !remark.isEmpty {
                    for remarkKey in remarkKeys {
                        for statusVal in statusValues {
                            let payload: [String: AnyJSON] = [
                                "status": .string(statusVal),
                                remarkKey: .string(remark)
                            ]
                            do {
                                try await SupabaseService.shared.client
                                    .from(table)
                                    .update(payload)
                                    .eq("id", value: idStr)
                                    .execute()
                                print("Successfully updated \(table) (status: \(statusVal), \(remarkKey)) for id \(idStr)")
                                isUpdated = true
                                break
                            } catch {
                                print("Update attempt failed on \(table) with \(remarkKey) & status \(statusVal): \(error)")
                            }
                        }
                        if isUpdated { break }
                    }
                }
                
                // 2. If remark update failed or no remark provided, update status alone
                if !isUpdated {
                    for statusVal in statusValues {
                        let payload: [String: AnyJSON] = [
                            "status": .string(statusVal)
                        ]
                        do {
                            try await SupabaseService.shared.client
                                .from(table)
                                .update(payload)
                                .eq("id", value: idStr)
                                .execute()
                            print("Successfully updated \(table) status to \(statusVal) for id \(idStr)")
                            isUpdated = true
                            break
                        } catch {
                            print("Status update attempt failed on \(table) with \(statusVal): \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func fetchUserName(userId: UUID) async -> String {
        do {
            var fetchedUser: User? = try await SupabaseService.shared.client
                .from("User")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            if fetchedUser == nil {
                fetchedUser = try? await SupabaseService.shared.client
                    .from("user")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .single()
                    .execute()
                    .value
            }
            if let user = fetchedUser {
                let fullName = "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespaces)
                return fullName.isEmpty ? "Sales Associate" : fullName
            }
        } catch {
            print("Error fetching user name for \(userId): \(error)")
        }
        return "Sales Associate"
    }
    
    // MARK: - Fetch Live StoreRequestToInventory (Inventory Requests Segment)
    func fetchInventoryRequests() async {
        do {
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

            guard let targetStoreID = storeID else { return }

            // 1. Fetch StoreRequestToInventory rows for this store
            var rawRequests: [StoreRequestToInventory] = []
            do {
                rawRequests = try await SupabaseService.shared.client
                    .from("StoreRequestToInventory")
                    .select()
                    .eq("storeid", value: targetStoreID.uuidString)
                    .execute()
                    .value
            } catch {
                do {
                    rawRequests = try await SupabaseService.shared.client
                        .from("store_request_to_inventory")
                        .select()
                        .eq("store_id", value: targetStoreID.uuidString)
                        .execute()
                        .value
                } catch {
                    rawRequests = []
                }
            }

            if rawRequests.isEmpty {
                self.inventoryRequests = []
                return
            }

            // 2. Batch fetch Products for productIDs
            let productIDs = Array(Set(rawRequests.map { $0.productID }))
            var productsDict: [UUID: Product] = [:]
            if !productIDs.isEmpty {
                let idStrings = productIDs.map { $0.uuidString }
                var fetchedProducts: [Product] = []
                do {
                    fetchedProducts = try await SupabaseService.shared.client
                        .from("Product")
                        .select()
                        .in("id", values: idStrings)
                        .execute()
                        .value
                } catch {
                    do {
                        fetchedProducts = try await SupabaseService.shared.client
                            .from("product")
                            .select()
                            .in("id", values: idStrings)
                            .execute()
                            .value
                    } catch {
                        fetchedProducts = []
                    }
                }
                for p in fetchedProducts {
                    productsDict[p.id] = p
                }
            }

            // 3. Map into StoreInventoryRequestItem
            var items: [StoreInventoryRequestItem] = []
            for req in rawRequests {
                let p = productsDict[req.productID]
                let item = StoreInventoryRequestItem(
                    request: req,
                    productName: p?.name ?? "Inventory Item",
                    sku: p?.sku ?? "SKU-UNKNOWN",
                    brand: p?.brand ?? "Luxury Brand",
                    categoryName: p?.category.rawValue.capitalized ?? "General",
                    imageUrl: p?.imageUrl
                )
                items.append(item)
            }

            // Sort by createdAt descending
            items.sort { $0.request.createdAt > $1.request.createdAt }
            self.inventoryRequests = items
        } catch {
            print("Error fetching store inventory requests: \(error)")
        }
    }
    
    // MARK: - Computed Properties for Filtered Inventory Requests
    var filteredInventoryRequests: [StoreInventoryRequestItem] {
        inventoryRequests.filter { item in
            // Search text filter
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesName = item.productName.lowercased().contains(query)
                let matchesSku = item.sku.lowercased().contains(query)
                if !matchesName && !matchesSku {
                    return false
                }
            }
            
            // Status filter
            switch selectedInventoryRequestStatusFilter {
            case .all:
                break
            case .pending:
                if item.request.status != .pending { return false }
            case .fulfilled:
                if item.request.status != .fulfilled { return false }
            case .rejected:
                if item.request.status != .rejected { return false }
            }
            
            return true
        }
    }
}
