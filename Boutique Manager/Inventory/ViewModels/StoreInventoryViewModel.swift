import Foundation
internal import Combine
import Supabase

@MainActor
class StoreInventoryViewModel: ObservableObject {
    @Published var inventoryItems: [StoreInventoryItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    @Published var selectedFilter: InventoryFilterOption = .all
    @Published var selectedSortOption: StoreInventorySortOption = .alphabetical
    @Published var sortDirection: SortDirection = .ascending

    init(initialFilterLowStock: Bool = false) {
        self.selectedFilter = initialFilterLowStock ? .lowStock : .all
        Task {
            await fetchStoreInventory()
        }
    }

    func clearFilters() {
        selectedFilter = .all
        searchText = ""
    }

    // MARK: - Computed Filtered and Sorted Items
    var filteredAndSortedItems: [StoreInventoryItem] {
        var items = inventoryItems

        // Filter by selected option
        switch selectedFilter {
        case .all:
            break
        case .lowStock:
            items = items.filter { $0.inventory.currentquantity <= $0.inventory.thresholdquantity }
        case .noStock:
            items = items.filter { $0.inventory.currentquantity == 0 }
        }

        // Search filtering (Product Name, SKU, Brand)
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            items = items.filter { item in
                item.product.name.lowercased().contains(query) ||
                item.product.sku.lowercased().contains(query) ||
                item.product.brand.lowercased().contains(query)
            }
        }

        // Sorting
        switch selectedSortOption {
        case .alphabetical:
            items.sort {
                let comparison = $0.product.name.localizedCaseInsensitiveCompare($1.product.name)
                return sortDirection == .ascending ? (comparison == .orderedAscending) : (comparison == .orderedDescending)
            }
        case .quantity:
            items.sort {
                sortDirection == .ascending ? ($0.inventory.currentquantity < $1.inventory.currentquantity) : ($0.inventory.currentquantity > $1.inventory.currentquantity)
            }
        case .recentlyUpdated:
            items.sort {
                let dateA = $0.inventory.updatedat ?? $0.product.updatedAt ?? Date.distantPast
                let dateB = $1.inventory.updatedat ?? $1.product.updatedAt ?? Date.distantPast
                return sortDirection == .ascending ? (dateA < dateB) : (dateA > dateB)
            }
        }

        return items
    }

    // MARK: - Fetching Workflow
    func fetchStoreInventory() async {
        isLoading = true
        errorMessage = nil

        do {
            // Step 1: Obtain assigned store ID for the current authenticated Boutique Manager
            var storeID: UUID? = AuthManager.shared.currentUser?.assignedStoreID

            if storeID == nil {
                // Fetch current session user from Supabase if AuthManager currentUser is not loaded yet
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
                self.errorMessage = "No assigned store found for the currently authenticated manager."
                self.isLoading = false
                return
            }

            // Step 2: Fetch StoreInventory records for the assigned store
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

            if fetchedInventories.isEmpty {
                self.inventoryItems = []
                self.isLoading = false
                return
            }

            // Step 3: Extract product IDs for batched product query
            let productIDs = fetchedInventories.map { $0.productid.uuidString }

            // Step 4: Perform ONE batched query to fetch matching Product records
            let fetchedProducts: [Product] = try await SupabaseService.shared.client
                .from("Product")
                .select()
                .in("id", values: productIDs)
                .execute()
                .value

            // Step 5: Merge datasets locally using StoreInventory.productid == Product.id
            var mergedItems: [StoreInventoryItem] = []
            for inventory in fetchedInventories {
                if let product = fetchedProducts.first(where: { $0.id == inventory.productid }) {
                    mergedItems.append(StoreInventoryItem(inventory: inventory, product: product))
                }
            }

            self.inventoryItems = mergedItems
            self.isLoading = false
        } catch {
            print("Error fetching store inventory: \(error)")
            self.errorMessage = "Failed to load store inventory: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}
