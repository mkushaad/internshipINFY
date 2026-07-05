import Foundation
import SwiftUI
internal import Combine
import Supabase

@MainActor
class CreateStoreRequestViewModel: ObservableObject {
    let alert: StockAlert
    
    // Form Inputs
    @Published var quantity: Int
    @Published var selectedPriority: Priority = .normal
    
    // Loading & Error States
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    
    init(alert: StockAlert) {
        self.alert = alert
        let defaultQty = CreateStoreRequestViewModel.calculateDefaultQuantity(
            currentQuantity: alert.currentQuantity,
            thresholdQuantity: alert.thresholdQuantity
        )
        self.quantity = defaultQty
    }
    
    init(product: Product, defaultQuantity: Int = 1) {
        self.alert = StockAlert(
            id: UUID(),
            productName: product.name,
            sku: product.sku,
            currentQuantity: 0,
            alertType: .outOfStock,
            priority: .medium,
            source: .system,
            generatedAt: Date(),
            description: "New Product Request",
            quantityRequested: defaultQuantity,
            productID: product.id,
            storeID: nil
        )
        self.quantity = defaultQuantity
    }
    
    /// Calculates default quantity: thresholdQuantity - currentQuantity.
    /// If currentQuantity >= thresholdQuantity or threshold is unavailable, default is 1.
    static func calculateDefaultQuantity(currentQuantity: Int, thresholdQuantity: Int?) -> Int {
        guard let threshold = thresholdQuantity else { return 1 }
        if currentQuantity >= threshold {
            return 1
        }
        let diff = threshold - currentQuantity
        return max(diff, 1)
    }
    
    /// Resolves storeID from AuthManager or directly from Supabase session if needed
    private func resolveStoreID() async -> UUID? {
        if let storeID = AuthManager.shared.currentUser?.assignedStoreID {
            return storeID
        }
        
        do {
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
                    return user.assignedStoreID
                }
            }
        } catch {
            print("Error resolving store ID for request: \(error)")
        }
        
        return nil
    }
    
    /// Prepares and uploads StoreRequestToInventory instance to Supabase
    func submitStoreRequest() async -> Bool {
        guard !isSubmitting else { return false }
        isSubmitting = true
        errorMessage = nil
        showErrorAlert = false
        
        defer { isSubmitting = false }
        
        // 1. Resolve store ID
        guard let storeID = await resolveStoreID() else {
            self.errorMessage = "Could not identify assigned Store ID for current user. Please log in again."
            self.showErrorAlert = true
            return false
        }
        
        // 2. Resolve product ID
        guard let productID = alert.productID else {
            self.errorMessage = "Product ID missing for selected stock alert."
            self.showErrorAlert = true
            return false
        }
        
        // 2.5 Check for existing pending request
        do {
            var hasPendingRequest = false
            do {
                let existingRequests: [StoreRequestToInventory] = try await SupabaseService.shared.client
                    .from("StoreRequestToInventory")
                    .select()
                    .eq("storeid", value: storeID.uuidString)
                    .eq("productid", value: productID.uuidString)
                    .eq("status", value: "pending")
                    .execute()
                    .value
                hasPendingRequest = !existingRequests.isEmpty
            } catch {
                let existingRequests: [StoreRequestToInventory] = try await SupabaseService.shared.client
                    .from("store_request_to_inventory")
                    .select()
                    .eq("store_id", value: storeID.uuidString)
                    .eq("product_id", value: productID.uuidString)
                    .eq("status", value: "pending")
                    .execute()
                    .value
                hasPendingRequest = !existingRequests.isEmpty
            }
            
            if hasPendingRequest {
                self.errorMessage = "A pending inventory request for this product already exists."
                self.showErrorAlert = true
                return false
            }
        } catch {
            print("Error verifying existing pending request: \(error)")
        }
        
        // 3. Construct StoreRequestToInventory object according to specifications
        let requestObject = StoreRequestToInventory(
            id: UUID(),
            requestType: .refill,          // Always Refill
            storeID: storeID,
            productID: productID,
            quantityRequested: max(quantity, 1),
            priority: selectedPriority,
            transferRequestID: nil,         // Always NULL
            status: .pending,               // Always Pending
            createdAt: Date()               // Current Date
        )
        
        // 4. Upload object to StoreRequestToInventory table in Supabase
        do {
            _ = try await SupabaseService.shared.client
                .from("StoreRequestToInventory")
                .insert(requestObject)
                .execute()
            NotificationCenter.default.post(name: .salesAssociateRequestUpdated, object: nil)
            NotificationCenter.default.post(name: .storeInventoryUpdated, object: nil)
            NotificationCenter.default.post(name: .inventoryDataRefreshedAll, object: nil)
            
            return true
        } catch {
            print("Failed to insert model directly into StoreRequestToInventory table: \(error)")
            
            // Fallback: Dictionary insert matching exact table StoreRequestToInventory & lowercased column names
            do {
                let payload: [String: AnyJSON] = [
                    "id": .string(requestObject.id.uuidString),
                    "requesttype": .string("Refill"),
                    "storeid": .string(storeID.uuidString),
                    "productid": .string(productID.uuidString),
                    "quantityrequested": .integer(requestObject.quantityRequested),
                    "priority": .string(requestObject.priority.rawValue),
                    "transferrequestid": .null,
                    "status": .string("pending"),
                    "createdat": .string(ISO8601DateFormatter().string(from: requestObject.createdAt))
                ]
                
                try await SupabaseService.shared.client
                    .from("StoreRequestToInventory")
                    .insert(payload)
                    .execute()
                
                return true
            } catch {
                print("Dictionary insert into StoreRequestToInventory also failed: \(error)")
                self.errorMessage = "Failed to upload store request: \(error.localizedDescription)"
                self.showErrorAlert = true
                return false
            }
        }
    }
}
