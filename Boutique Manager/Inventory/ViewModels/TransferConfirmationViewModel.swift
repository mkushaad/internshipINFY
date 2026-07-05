import Foundation
internal import Combine
import Supabase

@MainActor
class TransferConfirmationViewModel: ObservableObject {
    let candidate: NearbyStoreCandidate
    let alert: StockAlert
    let currentStoreName: String
    
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var isSuccess: Bool = false
    
    init(candidate: NearbyStoreCandidate, alert: StockAlert, currentStoreName: String) {
        self.candidate = candidate
        self.alert = alert
        self.currentStoreName = currentStoreName
    }
    
    func sendTransferRequest() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        showErrorAlert = false
        
        defer { isSubmitting = false }
        
        // 1. Resolve destinationStoreID (originating boutique requesting stock)
        guard let destinationStoreID = alert.storeID else {
            print("❌ [TransferConfirmationViewModel] Error: alert.storeID (destinationStoreID) is missing.")
            self.errorMessage = "Originating boutique store ID is missing."
            self.showErrorAlert = true
            return
        }
        
        // 2. Resolve productID
        guard let productID = alert.productID else {
            print("❌ [TransferConfirmationViewModel] Error: alert.productID is missing.")
            self.errorMessage = "Product ID is missing for this request."
            self.showErrorAlert = true
            return
        }
        
        let requestedQty = alert.quantityRequested ?? 1
        let newTransferID = UUID()
        let newCreatedAt = Date()
        
        // Construct StoreToStoreTransferRequest
        let transferRequest = StoreToStoreTransferRequest(
            id: newTransferID,
            senderStoreID: candidate.store.id,
            destinationStoreID: destinationStoreID,
            productID: productID,
            quantityRequested: requestedQty,
            salesAssociateRequestID: alert.id,
            status: .pending,
            createdAt: newCreatedAt
        )
        
        let senderStoreName = candidate.store.name.isEmpty ? candidate.store.location : candidate.store.name
        
        // Step A: Upload StoreToStoreTransferRequest to Supabase
        var uploadSuccess = false
        do {
            try await SupabaseService.shared.client
                .from("StoreToStoreTransferRequest")
                .insert(transferRequest)
                .execute()
            uploadSuccess = true
        } catch {
            print("Notice: 'StoreToStoreTransferRequest' table insert failed (\(error.localizedDescription)). Trying 'store_to_store_transfer_request'...")
            do {
                try await SupabaseService.shared.client
                    .from("store_to_store_transfer_request")
                    .insert(transferRequest)
                    .execute()
                uploadSuccess = true
            } catch {
                print("❌ [TransferConfirmationViewModel] Error inserting StoreToStoreTransferRequest: \(error)")
                self.errorMessage = "Failed to upload transfer request: \(error.localizedDescription)"
                self.showErrorAlert = true
                return
            }
        }
        
        guard uploadSuccess else { return }
        
        // Step B: Only after upload succeeds, update SalesAssociateStockRequest.status from pending -> forwarded
        var updateSuccess = false
        do {
            try await SupabaseService.shared.client
                .from("SalesAssociateStockRequest")
                .update(["status": "forwarded"])
                .eq("id", value: alert.id.uuidString)
                .execute()
            updateSuccess = true
        } catch {
            print("Notice: 'SalesAssociateStockRequest' update failed (\(error.localizedDescription)). Trying 'sales_associate_stock_request'...")
            do {
                try await SupabaseService.shared.client
                    .from("sales_associate_stock_request")
                    .update(["status": "forwarded"])
                    .eq("id", value: alert.id.uuidString)
                    .execute()
                updateSuccess = true
            } catch {
                print("❌ [TransferConfirmationViewModel] Warning: Failed to update SalesAssociateStockRequest status to forwarded: \(error)")
            }
        }
        
        // Step C: Debug Logging
        print("\nSender Store:\n\(senderStoreName)")
        print("\nDestination Store:\n\(currentStoreName)")
        print("\nProduct:\n\(alert.productName)")
        print("\nQuantity:\n\(requestedQty)")
        print("\nStoreToStoreTransferRequest Created:\n\(newTransferID.uuidString)")
        print("\nSalesAssociateStockRequest Updated → Forwarded:\n\(alert.id.uuidString)\n")
        
        // Post notifications to refresh all views across modules
        NotificationCenter.default.post(name: .salesAssociateRequestUpdated, object: nil)
        NotificationCenter.default.post(name: .storeInventoryUpdated, object: nil)
        NotificationCenter.default.post(name: .inventoryDataRefreshedAll, object: nil)
        
        self.isSuccess = true
    }
}
