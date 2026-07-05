import Foundation
internal import Combine
import Supabase

@MainActor
class InventoryViewModel: ObservableObject {
    @Published var summary: InventorySummary = InventorySummary(
        totalProducts: 0,
        lowStockCount: 0,
        stockRequestsCount: 0,
        discrepancyCount: 0
    )

    @Published var stockAlerts: [StockAlertPreview] = []

    @Published var stockRequests: [StockRequestPreview] = [
        StockRequestPreview(productName: "Rolex Daytona", quantity: 3, sourceStore: "Dubai Mall", destinationStore: "New York Flagship", status: .pending),
        StockRequestPreview(productName: "Hermès Birkin", quantity: 1, sourceStore: "Paris Champs-Élysées", destinationStore: "London Bond St", status: .inTransit),
        StockRequestPreview(productName: "Cartier Love Bracelet", quantity: 5, sourceStore: "Milan Boutique", destinationStore: "Munich Store", status: .approved)
    ]

    @Published var discrepancies: [InventoryDiscrepancyPreview] = [
        InventoryDiscrepancyPreview(productName: "LV Wallet", expectedQuantity: 12, actualQuantity: 10, status: .pendingApproval),
        InventoryDiscrepancyPreview(productName: "Rolex Submariner", expectedQuantity: 5, actualQuantity: 4, status: .pendingApproval),
        InventoryDiscrepancyPreview(productName: "Chanel Handbag", expectedQuantity: 8, actualQuantity: 9, status: .resolved)
    ]

    @Published var storeInventory: [InventoryProductPreview] = []

    @Published var isLoading: Bool = false

    init() {
        Task {
            await fetchLiveSummary()
        }
        
        NotificationCenter.default.addObserver(forName: .salesAssociateRequestUpdated, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchLiveSummary()
            }
        }
        NotificationCenter.default.addObserver(forName: .storeInventoryUpdated, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchLiveSummary()
            }
        }
        NotificationCenter.default.addObserver(forName: .inventoryDataRefreshedAll, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchLiveSummary()
            }
        }
    }

    func fetchLiveSummary() async {
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

            // Step 2: Fetch StoreInventory for assigned store
            var fetchedInventories: [StoreInventory] = []
            do {
                fetchedInventories = try await SupabaseService.shared.client
                    .from("StoreInventory")
                    .select()
                    .eq("storeid", value: targetStoreID.uuidString)
                    .execute()
                    .value
            } catch {
                // Fallback attempt with snake_case table name if camelCase fails
                fetchedInventories = try await SupabaseService.shared.client
                    .from("store_inventory")
                    .select()
                    .eq("store_id", value: targetStoreID.uuidString)
                    .execute()
                    .value
            }

            // Step 3: Compute actual number of distinct products present in the store inventory
            let distinctProductCount = Set(fetchedInventories.map { $0.productid }).count

            // Step 4: Compute number of products currently below threshold
            let lowStockItems = fetchedInventories.filter { $0.currentquantity <= $0.thresholdquantity }
            let lowStockCount = lowStockItems.count

            // Step 4.5: Fetch live count of pending Sales Associate stock requests from Supabase
            var liveRequestCount = 0
            if let fetchedRequests: [SalesAssociateStockRequest] = try? await SupabaseService.shared.client
                .from("SalesAssociateStockRequest")
                .select()
                .eq("status", value: "pending")
                .execute()
                .value {
                liveRequestCount = fetchedRequests.count
            } else if let fetchedRequests: [SalesAssociateStockRequest] = try? await SupabaseService.shared.client
                .from("sales_associate_stock_request")
                .select()
                .eq("status", value: "pending")
                .execute()
                .value {
                liveRequestCount = fetchedRequests.count
            }

            self.summary = InventorySummary(
                totalProducts: distinctProductCount,
                lowStockCount: lowStockCount,
                stockRequestsCount: liveRequestCount,
                discrepancyCount: 0
            )

            // Step 5: Fetch Product metadata and delegate notification evaluation to NotificationManager
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

                productsDict = Dictionary(uniqueKeysWithValues: fetchedProducts.map { ($0.id, $0) })
            }

            // Evaluate notifications via NotificationManager (duplicate prevention & persistent state)
            NotificationManager.shared.evaluateStoreInventory(storeInventories: fetchedInventories, products: productsDict)

            // Dynamic previews for dashboard cards
            let dynamicPreviews = lowStockItems.compactMap { item -> StockAlertPreview? in
                guard let prod = productsDict[item.productid] else { return nil }
                let status: StockAlertPreview.AlertStatus
                if item.currentquantity == 0 {
                    status = .outOfStock
                } else if item.currentquantity <= item.thresholdquantity / 2 {
                    status = .critical
                } else {
                    status = .warning
                }
                return StockAlertPreview(
                    productName: prod.name,
                    currentQuantity: item.currentquantity,
                    status: status,
                    imageSymbol: "shippingbox.fill"
                )
            }
            self.stockAlerts = dynamicPreviews

        } catch {
            print("Error loading live inventory summary: \(error)")
        }
    }

    func refresh() async {
        await fetchLiveSummary()
    }
}
