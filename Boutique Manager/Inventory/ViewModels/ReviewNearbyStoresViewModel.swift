import Foundation
internal import Combine
import Supabase

struct NearbyStoreCandidate: Identifiable, Hashable {
    var id: UUID { store.id }
    let store: Store
    let availableQuantity: Int
    let quantityRequested: Int
    let productName: String
    let productSKU: String
    let productImageUrl: String?
    
    static func == (lhs: NearbyStoreCandidate, rhs: NearbyStoreCandidate) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum NearbyStoresSortOption: String, CaseIterable, Identifiable {
    case highestQuantity = "Highest Quantity"
    case lowestQuantity = "Lowest Quantity"
    case alphabetical = "Alphabetical"
    
    var id: String { rawValue }
}

@MainActor
class ReviewNearbyStoresViewModel: ObservableObject {
    let alert: StockAlert
    
    @Published var nearbyStores: [NearbyStoreCandidate] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var selectedSortOption: NearbyStoresSortOption = .highestQuantity
    @Published var currentStore: Store? = nil
    @Published var currentStoreName: String = "Main Boutique"
    
    init(alert: StockAlert) {
        self.alert = alert
        Task {
            await fetchNearbyStores()
        }
    }
    
    func fetchNearbyStores() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Step 1: Read alert.storeID. If missing, treat as error.
            guard let requestingStoreID = alert.storeID else {
                print("❌ [ReviewNearbyStoresViewModel] Error: Request Store ID (alert.storeID) is missing.")
                self.nearbyStores = []
                return
            }
            
            print("\nRequest Store ID:\n\(requestingStoreID.uuidString)")
            
            // Step 2: Fetch the requesting store to obtain its region.
            let requestingStore: Store = try await SupabaseService.shared.client
                .from("Store")
                .select()
                .eq("id", value: requestingStoreID.uuidString)
                .single()
                .execute()
                .value
            
            self.currentStore = requestingStore
            self.currentStoreName = requestingStore.name.isEmpty ? requestingStore.location : requestingStore.name
            let resolvedRegion = requestingStore.region
            
            print("\nResolved Region:\n\(resolvedRegion)")
            
            // Step 3: Fetch every store in the same region, excluding requesting store.
            let candidateStores: [Store] = try await SupabaseService.shared.client
                .from("Store")
                .select()
                .eq("region", value: resolvedRegion)
                .neq("id", value: requestingStoreID.uuidString)
                .execute()
                .value
            
            print("\nCandidate Stores:\n\(candidateStores.count)")
            
            if candidateStores.isEmpty {
                self.nearbyStores = []
                return
            }
            
            // Step 4: Fetch StoreInventory rows using alert.productID.
            guard let targetProductID = alert.productID else {
                print("❌ [ReviewNearbyStoresViewModel] Error: Product ID (alert.productID) is missing.")
                self.nearbyStores = []
                return
            }
            
            let candidateStoreIDs = candidateStores.map { $0.id.uuidString }
            
            let inventories: [StoreInventory] = try await SupabaseService.shared.client
                .from("StoreInventory")
                .select()
                .eq("productid", value: targetProductID.uuidString)
                .in("storeid", values: candidateStoreIDs)
                .execute()
                .value
            
            print("\nInventory Matches:\n\(inventories.count)")
            
            // Step 5: Filter candidate stores satisfying currentquantity >= quantityRequested.
            let requestedQty = alert.quantityRequested ?? 1
            let candidateStoresDict = Dictionary(uniqueKeysWithValues: candidateStores.map { ($0.id, $0) })
            
            var validCandidates: [NearbyStoreCandidate] = []
            
            for inv in inventories {
                guard let store = candidateStoresDict[inv.storeid] else { continue }
                if inv.currentquantity >= requestedQty {
                    let candidateItem = NearbyStoreCandidate(
                        store: store,
                        availableQuantity: inv.currentquantity,
                        quantityRequested: requestedQty,
                        productName: alert.productName,
                        productSKU: alert.sku,
                        productImageUrl: alert.imageUrl
                    )
                    validCandidates.append(candidateItem)
                }
            }
            
            print("\nStores With Enough Quantity:\n\(validCandidates.count)\n")
            
            // Step 6: Expose presentation model
            self.nearbyStores = validCandidates
            
        } catch {
            print("❌ [ReviewNearbyStoresViewModel] Error during candidate store fetching: \(error)")
            self.nearbyStores = []
        }
    }
    
    // MARK: - Computed Properties for Filtered & Sorted Candidate Listing
    
    var filteredAndSortedStores: [NearbyStoreCandidate] {
        var items = nearbyStores.filter { candidate in
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesName = candidate.store.name.lowercased().contains(query)
                let matchesLocation = candidate.store.location.lowercased().contains(query)
                if !matchesName && !matchesLocation {
                    return false
                }
            }
            return true
        }
        
        // Sorting logic
        switch selectedSortOption {
        case .highestQuantity:
            items.sort { $0.availableQuantity > $1.availableQuantity }
        case .lowestQuantity:
            items.sort { $0.availableQuantity < $1.availableQuantity }
        case .alphabetical:
            items.sort { $0.store.name.lowercased() < $1.store.name.lowercased() }
        }
        
        return items
    }
}
