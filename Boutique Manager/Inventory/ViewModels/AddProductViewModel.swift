import Foundation
internal import Combine
import Supabase

enum AddProductSortOption: String, CaseIterable, Identifiable {
    case alphabetical = "Alphabetical"
    case category = "Category"
    case brand = "Brand"
    
    var id: String { rawValue }
}

@MainActor
class AddProductViewModel: ObservableObject {
    @Published var unstockedProducts: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Local Search & Filter States
    @Published var searchText: String = ""
    @Published var selectedCategory: String? = nil
    @Published var selectedBrand: String? = nil
    @Published var selectedSortOption: AddProductSortOption = .alphabetical
    
    init() {
        Task {
            await fetchUnstockedProducts()
        }
    }
    
    func fetchUnstockedProducts() async {
        isLoading = true
        errorMessage = nil
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
                self.errorMessage = "Assigned store ID could not be identified."
                return
            }
            
            // Step 2: Fetch all products from Product table in Supabase
            var allProducts: [Product] = []
            do {
                allProducts = try await SupabaseService.shared.client
                    .from("Product")
                    .select()
                    .execute()
                    .value
            } catch {
                do {
                    allProducts = try await SupabaseService.shared.client
                        .from("product")
                        .select()
                        .execute()
                        .value
                } catch {
                    allProducts = []
                }
            }
            
            // Step 3: Fetch current store's StoreInventory to find already stocked product IDs
            var currentInventory: [StoreInventory] = []
            do {
                currentInventory = try await SupabaseService.shared.client
                    .from("StoreInventory")
                    .select()
                    .eq("storeid", value: targetStoreID.uuidString)
                    .execute()
                    .value
            } catch {
                do {
                    currentInventory = try await SupabaseService.shared.client
                        .from("store_inventory")
                        .select()
                        .eq("store_id", value: targetStoreID.uuidString)
                        .execute()
                        .value
                } catch {
                    currentInventory = []
                }
            }
            
            let stockedProductIDs = Set(currentInventory.map { $0.productid })
            
            // Step 3.5: Fetch pending StoreRequestToInventory to find products already requested
            var pendingRequests: [StoreRequestToInventory] = []
            do {
                pendingRequests = try await SupabaseService.shared.client
                    .from("StoreRequestToInventory")
                    .select()
                    .eq("storeid", value: targetStoreID.uuidString)
                    .eq("status", value: "pending")
                    .execute()
                    .value
            } catch {
                do {
                    pendingRequests = try await SupabaseService.shared.client
                        .from("store_request_to_inventory")
                        .select()
                        .eq("store_id", value: targetStoreID.uuidString)
                        .eq("status", value: "pending")
                        .execute()
                        .value
                } catch {
                    pendingRequests = []
                }
            }
            
            let requestedProductIDs = Set(pendingRequests.map { $0.productID })
            
            // Step 4: Filter catalog to only show products NOT currently present in StoreInventory AND NOT currently pending request
            self.unstockedProducts = allProducts.filter { !stockedProductIDs.contains($0.id) && !requestedProductIDs.contains($0.id) }
            
        } catch {
            print("Error fetching unstocked products: \(error)")
            self.errorMessage = "Failed to load available product catalog: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Dynamic Filter Options
    var categories: [String] {
        Array(Set(unstockedProducts.map { $0.category.rawValue.capitalized })).sorted()
    }
    
    var brands: [String] {
        Array(Set(unstockedProducts.map { $0.brand })).filter { !$0.isEmpty }.sorted()
    }
    
    // MARK: - Filtered and Sorted Products
    var filteredAndSortedProducts: [Product] {
        var items = unstockedProducts.filter { product in
            // Search text filter (Name, SKU, Brand)
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesName = product.name.lowercased().contains(query)
                let matchesSku = product.sku.lowercased().contains(query)
                let matchesBrand = product.brand.lowercased().contains(query)
                if !matchesName && !matchesSku && !matchesBrand {
                    return false
                }
            }
            
            // Category Filter
            if let category = selectedCategory, !category.isEmpty {
                if product.category.rawValue.lowercased() != category.lowercased() {
                    return false
                }
            }
            
            // Brand Filter
            if let brand = selectedBrand, !brand.isEmpty {
                if product.brand.lowercased() != brand.lowercased() {
                    return false
                }
            }
            
            return true
        }
        
        // Sorting
        switch selectedSortOption {
        case .alphabetical:
            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .category:
            items.sort { $0.category.rawValue.localizedCaseInsensitiveCompare($1.category.rawValue) == .orderedAscending }
        case .brand:
            items.sort { $0.brand.localizedCaseInsensitiveCompare($1.brand) == .orderedAscending }
        }
        
        return items
    }
    
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedCategory != nil || selectedBrand != nil
    }
    
    func resetFilters() {
        searchText = ""
        selectedCategory = nil
        selectedBrand = nil
        selectedSortOption = .alphabetical
    }
}
