import Foundation
internal import Combine
import Supabase

enum TransferDirectionFilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case sent = "Sent"
    case received = "Received"
    
    var id: String { rawValue }
}

enum SalesAssociateFilterOption: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case forwarded = "Forwarded"
    case fulfilled = "Fulfilled"
    case history = "History"
    case all = "All"
    
    var id: String { rawValue }
}

enum StoreTransferFilterOption: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case cancelled = "Cancelled"
    case history = "History"
    case all = "All"
    
    var id: String { rawValue }
}

@MainActor
class StockRequestsViewModel: ObservableObject {
    // Top tab selection: 0 = Sales Associate, 1 = Store Transfers
    @Published var selectedSegmentIndex: Int = 0
    
    // Search text
    @Published var searchText: String = ""
    
    // Filter selection state for Segment 0 (Sales Associate)
    @Published var selectedSalesFilter: SalesAssociateFilterOption = .pending
    
    // Filter selection state for Segment 1 (Store Transfers)
    @Published var selectedTransferFilter: StoreTransferFilterOption = .pending
    @Published var selectedDirectionFilter: TransferDirectionFilterOption = .all
    
    // Data sources
    @Published var overviewViewModel: InventoryOverviewViewModel = InventoryOverviewViewModel()
    @Published var storeTransfers: [StoreTransferDisplayItem] = []
    @Published var isLoading: Bool = false
    
    init() {
        NotificationCenter.default.addObserver(forName: .salesAssociateRequestUpdated, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchRequests()
            }
        }
        NotificationCenter.default.addObserver(forName: .storeInventoryUpdated, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchRequests()
            }
        }
        NotificationCenter.default.addObserver(forName: .inventoryDataRefreshedAll, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchRequests()
            }
        }
    }
    
    func fetchRequests() async {
        isLoading = true
        defer { isLoading = false }
        await overviewViewModel.fetchDynamicStockAlerts()
        await fetchStoreTransfers()
    }
    
    // MARK: - Live Store Transfers Fetching from Supabase
    func fetchStoreTransfers() async {
        // 1. Fetch all StoreToStoreTransferRequest rows from Supabase
        var rawRequests: [StoreToStoreTransferRequest] = []
        do {
            rawRequests = try await SupabaseService.shared.client
                .from("StoreToStoreTransferRequest")
                .select()
                .execute()
                .value
        } catch {
            rawRequests = (try? await SupabaseService.shared.client
                .from("store_to_store_transfer_request")
                .select()
                .execute()
                .value) ?? []
        }
        
        if rawRequests.isEmpty {
            self.storeTransfers = []
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
                fetchedProducts = (try? await SupabaseService.shared.client
                    .from("product")
                    .select()
                    .in("id", values: idStrings)
                    .execute()
                    .value) ?? []
            }
            
            for p in fetchedProducts {
                productsDict[p.id] = p
            }
        }
        
        // 3. Batch fetch Stores for sender & destination storeIDs
        var allStoreIDs = Set<UUID>()
        for req in rawRequests {
            allStoreIDs.insert(req.senderStoreID)
            allStoreIDs.insert(req.destinationStoreID)
        }
        
        var storesDict: [UUID: Store] = [:]
        if !allStoreIDs.isEmpty {
            let storeIDStrings = allStoreIDs.map { $0.uuidString }
            var fetchedStores: [Store] = []
            do {
                fetchedStores = try await SupabaseService.shared.client
                    .from("Store")
                    .select()
                    .in("id", values: storeIDStrings)
                    .execute()
                    .value
            } catch {
                fetchedStores = (try? await SupabaseService.shared.client
                    .from("store")
                    .select()
                    .in("id", values: storeIDStrings)
                    .execute()
                    .value) ?? []
            }
            
            for s in fetchedStores {
                storesDict[s.id] = s
            }
        }
        
        // Determine current user's assigned store ID
        let currentStoreID = AuthManager.shared.currentUser?.assignedStoreID
        
        // 4. Map into StoreTransferDisplayItem presentation models
        var items: [StoreTransferDisplayItem] = []
        for req in rawRequests {
            let product = productsDict[req.productID]
            let senderStore = storesDict[req.senderStoreID]
            let destStore = storesDict[req.destinationStoreID]
            
            let pName = product?.name ?? "Luxury Item"
            let pSku = product?.sku ?? "SKU-UNKNOWN"
            let pImg = product?.imageUrl
            
            let senderName = senderStore?.name.isEmpty == false ? senderStore!.name : (senderStore?.location ?? "Sender Boutique")
            let destName = destStore?.name.isEmpty == false ? destStore!.name : (destStore?.location ?? "Destination Boutique")
            
            // isSent = true if destinationStoreID is current user's store
            let isSent: Bool
            if let userStoreID = currentStoreID {
                isSent = (req.destinationStoreID == userStoreID)
            } else {
                isSent = false
            }
            
            let displayItem = StoreTransferDisplayItem(
                request: req,
                productName: pName,
                sku: pSku,
                imageUrl: pImg,
                senderStoreName: senderName,
                destinationStoreName: destName,
                isSent: isSent
            )
            items.append(displayItem)
        }
        
        self.storeTransfers = items
    }
    
    // MARK: - Filtered Sales Associate Requests (Sorted by latest generatedAt)
    var filteredSalesAssociateRequests: [StockAlert] {
        var items = overviewViewModel.filteredStockAlerts.filter { alert in
            guard alert.source == .salesAssociate || alert.alertType == .transferRequested else {
                return false
            }
            
            // Search text filter
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesName = alert.productName.lowercased().contains(query)
                let matchesSku = alert.sku.lowercased().contains(query)
                if !matchesName && !matchesSku {
                    return false
                }
            }
            
            // Status Filter (By default, only pending requests are shown)
            switch selectedSalesFilter {
            case .pending:
                if alert.requestStatus != .pending { return false }
            case .forwarded:
                if alert.requestStatus != .forwarded { return false }
            case .fulfilled:
                if alert.requestStatus != .fulfilled { return false }
            case .history:
                if alert.requestStatus == .pending { return false }
            case .all:
                break
            }
            
            return true
        }
        
        // Sort by latest created/generated date first
        items.sort { $0.generatedAt > $1.generatedAt }
        return items
    }
    
    // MARK: - Filtered Store Transfers (Sorted by latest createdAt)
    var filteredStoreTransfers: [StoreTransferDisplayItem] {
        var items = storeTransfers.filter { item in
            // Search text filter
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesName = item.productName.lowercased().contains(query)
                let matchesSku = item.sku.lowercased().contains(query)
                let matchesSender = item.senderStoreName.lowercased().contains(query)
                let matchesDest = item.destinationStoreName.lowercased().contains(query)
                if !matchesName && !matchesSku && !matchesSender && !matchesDest {
                    return false
                }
            }
            
            // Direction Filter (All, Sent, Received)
            switch selectedDirectionFilter {
            case .all:
                break
            case .sent:
                if !item.isSent { return false }
            case .received:
                if item.isSent { return false }
            }
            
            // Status Filter (By default, only pending requests are shown)
            switch selectedTransferFilter {
            case .pending:
                if item.request.status != .pending { return false }
            case .accepted:
                if item.request.status != .accepted { return false }
            case .declined:
                if item.request.status != .declined { return false }
            case .cancelled:
                if item.request.status != .cancelled { return false }
            case .history:
                if item.request.status == .pending { return false }
            case .all:
                break
            }
            
            return true
        }
        
        // Sort by latest created date first
        items.sort { $0.request.createdAt > $1.request.createdAt }
        return items
    }
    
    var hasActiveFilters: Bool {
        if !searchText.isEmpty { return true }
        if selectedSegmentIndex == 0 {
            return selectedSalesFilter != .pending
        } else {
            return selectedTransferFilter != .pending || selectedDirectionFilter != .all
        }
    }
    
    func resetFilters() {
        searchText = ""
        selectedSalesFilter = .pending
        selectedTransferFilter = .pending
        selectedDirectionFilter = .all
    }
}
