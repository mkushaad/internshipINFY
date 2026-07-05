import Foundation
internal import Combine
import Supabase

@MainActor
class StoreTransferDetailViewModel: ObservableObject {
    let item: StoreTransferDisplayItem
    
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var isSuccess: Bool = false
    @Published var successMessage: String = ""
    
    init(item: StoreTransferDisplayItem) {
        self.item = item
    }
    
    // MARK: - ACCEPT WORKFLOW (With Pre-flight Guards & Idempotency)
    func acceptTransfer() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        showErrorAlert = false
        
        defer { isSubmitting = false }
        
        let transferID = item.request.id
        let salesAssocID = item.request.salesAssociateRequestID
        let senderStoreID = item.request.senderStoreID
        let destStoreID = item.request.destinationStoreID
        let productID = item.request.productID
        let qtyRequested = item.request.quantityRequested
        
        // ----------------------------------------------------
        // PRE-FLIGHT CHECK 1: Idempotency check (Ensure status is STILL pending)
        // ----------------------------------------------------
        var liveTransferRequests: [StoreToStoreTransferRequest] = []
        do {
            liveTransferRequests = try await SupabaseService.shared.client
                .from("StoreToStoreTransferRequest")
                .select()
                .eq("id", value: transferID.uuidString)
                .execute()
                .value
        } catch {
            liveTransferRequests = (try? await SupabaseService.shared.client
                .from("store_to_store_transfer_request")
                .select()
                .eq("id", value: transferID.uuidString)
                .execute()
                .value) ?? []
        }
        
        if let currentTransfer = liveTransferRequests.first, currentTransfer.status != .pending {
            print("❌ [StoreTransferDetailViewModel] Pre-flight failed: Transfer request already \(currentTransfer.status.displayName).")
            self.errorMessage = "This transfer request has already been processed (\(currentTransfer.status.displayName))."
            self.showErrorAlert = true
            return
        }
        
        // ----------------------------------------------------
        // PRE-FLIGHT CHECK 2: Live Sender Store inventory verification
        // ----------------------------------------------------
        var senderRecords: [StoreInventory] = []
        do {
            senderRecords = try await SupabaseService.shared.client
                .from("StoreInventory")
                .select()
                .eq("storeid", value: senderStoreID.uuidString)
                .eq("productid", value: productID.uuidString)
                .execute()
                .value
        } catch {
            senderRecords = (try? await SupabaseService.shared.client
                .from("store_inventory")
                .select()
                .eq("storeid", value: senderStoreID.uuidString)
                .eq("productid", value: productID.uuidString)
                .execute()
                .value) ?? []
        }
        
        guard let senderInv = senderRecords.first, senderInv.currentquantity >= qtyRequested else {
            print("❌ [StoreTransferDetailViewModel] Pre-flight failed: Sender store has insufficient inventory.")
            self.errorMessage = "Transfer cannot be completed because the source store no longer has sufficient inventory."
            self.showErrorAlert = true
            return
        }
        
        // ----------------------------------------------------
        // MUTATION STAGE: All pre-flight checks passed!
        // ----------------------------------------------------
        
        // Step 1: Update StoreToStoreTransferRequest.status -> accepted
        var step1Success = false
        do {
            try await SupabaseService.shared.client
                .from("StoreToStoreTransferRequest")
                .update(["status": "accepted"])
                .eq("id", value: transferID.uuidString)
                .execute()
            step1Success = true
        } catch {
            do {
                try await SupabaseService.shared.client
                    .from("store_to_store_transfer_request")
                    .update(["status": "accepted"])
                    .eq("id", value: transferID.uuidString)
                    .execute()
                step1Success = true
            } catch {
                print("❌ [StoreTransferDetailViewModel] Error in Step 1 (Update Transfer Request): \(error)")
                self.errorMessage = "Failed to update transfer request status: \(error.localizedDescription)"
                self.showErrorAlert = true
                return
            }
        }
        
        guard step1Success else { return }
        
        // Step 2: Update SalesAssociateStockRequest.status -> fulfilled
        do {
            try await SupabaseService.shared.client
                .from("SalesAssociateStockRequest")
                .update(["status": "fulfilled"])
                .eq("id", value: salesAssocID.uuidString)
                .execute()
        } catch {
            do {
                try await SupabaseService.shared.client
                    .from("sales_associate_stock_request")
                    .update(["status": "fulfilled"])
                    .eq("id", value: salesAssocID.uuidString)
                    .execute()
            } catch {
                print("❌ [StoreTransferDetailViewModel] Warning in Step 2 (Update SalesAssociateStockRequest): \(error)")
            }
        }
        
        // Step 3A: Update Sender Inventory (Subtract qtyRequested)
        let senderOldQty = senderInv.currentquantity
        let senderNewQty = max(0, senderOldQty - qtyRequested)
        _ = try? await SupabaseService.shared.client
            .from("StoreInventory")
            .update(["currentquantity": senderNewQty])
            .eq("id", value: senderInv.id.uuidString)
            .execute()
        
        // Step 3B: Update Destination Inventory (Add qtyRequested)
        var destOldQty = 0
        var destNewQty = 0
        var destRecords: [StoreInventory] = []
        do {
            destRecords = try await SupabaseService.shared.client
                .from("StoreInventory")
                .select()
                .eq("storeid", value: destStoreID.uuidString)
                .eq("productid", value: productID.uuidString)
                .execute()
                .value
        } catch {
            destRecords = (try? await SupabaseService.shared.client
                .from("store_inventory")
                .select()
                .eq("storeid", value: destStoreID.uuidString)
                .eq("productid", value: productID.uuidString)
                .execute()
                .value) ?? []
        }
        
        if let destInv = destRecords.first {
            destOldQty = destInv.currentquantity
            destNewQty = destOldQty + qtyRequested
            
            _ = try? await SupabaseService.shared.client
                .from("StoreInventory")
                .update(["currentquantity": destNewQty])
                .eq("id", value: destInv.id.uuidString)
                .execute()
        } else {
            destOldQty = 0
            destNewQty = qtyRequested
            let newDestInv = StoreInventory(
                id: UUID(),
                storeid: destStoreID,
                productid: productID,
                currentquantity: destNewQty,
                thresholdquantity: 5,
                updatedat: Date()
            )
            _ = try? await SupabaseService.shared.client
                .from("StoreInventory")
                .insert(newDestInv)
                .execute()
        }
        
        // Structured Console Debug Logging
        print("\nTransfer Request ID:\n\(transferID.uuidString)")
        print("\nSender Store:\n\(item.senderStoreName)")
        print("\nDestination Store:\n\(item.destinationStoreName)")
        print("\nProduct ID:\n\(productID.uuidString)")
        print("\nQuantity:\n\(qtyRequested)")
        print("\nTransfer Status Updated:\naccepted")
        print("\nSalesAssociateStockRequest Updated:\nfulfilled")
        print("\nSender Inventory Updated:\n\(senderOldQty) → \(senderNewQty)")
        print("\nDestination Inventory Updated:\n\(destOldQty) → \(destNewQty)\n")
        
        NotificationCenter.default.post(name: .salesAssociateRequestUpdated, object: nil)
        NotificationCenter.default.post(name: .storeInventoryUpdated, object: nil)
        NotificationCenter.default.post(name: .inventoryDataRefreshedAll, object: nil)
        
        self.successMessage = "Transfer completed successfully."
        self.isSuccess = true
    }
    
    // MARK: - DECLINE WORKFLOW (With Pre-flight Idempotency Check)
    func declineTransfer() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        showErrorAlert = false
        
        defer { isSubmitting = false }
        
        let transferID = item.request.id
        let salesAssocID = item.request.salesAssociateRequestID
        let productID = item.request.productID
        let qtyRequested = item.request.quantityRequested
        
        // ----------------------------------------------------
        // PRE-FLIGHT CHECK: Idempotency check (Ensure status is STILL pending)
        // ----------------------------------------------------
        var liveTransferRequests: [StoreToStoreTransferRequest] = []
        do {
            liveTransferRequests = try await SupabaseService.shared.client
                .from("StoreToStoreTransferRequest")
                .select()
                .eq("id", value: transferID.uuidString)
                .execute()
                .value
        } catch {
            liveTransferRequests = (try? await SupabaseService.shared.client
                .from("store_to_store_transfer_request")
                .select()
                .eq("id", value: transferID.uuidString)
                .execute()
                .value) ?? []
        }
        
        if let currentTransfer = liveTransferRequests.first, currentTransfer.status != .pending {
            print("❌ [StoreTransferDetailViewModel] Pre-flight failed: Transfer request already \(currentTransfer.status.displayName).")
            self.errorMessage = "This transfer request has already been processed (\(currentTransfer.status.displayName))."
            self.showErrorAlert = true
            return
        }
        
        // Step 1: Update StoreToStoreTransferRequest.status -> declined
        var step1Success = false
        do {
            try await SupabaseService.shared.client
                .from("StoreToStoreTransferRequest")
                .update(["status": "declined"])
                .eq("id", value: transferID.uuidString)
                .execute()
            step1Success = true
        } catch {
            do {
                try await SupabaseService.shared.client
                    .from("store_to_store_transfer_request")
                    .update(["status": "declined"])
                    .eq("id", value: transferID.uuidString)
                    .execute()
                step1Success = true
            } catch {
                print("❌ [StoreTransferDetailViewModel] Error in Step 1 (Decline Transfer Request): \(error)")
                self.errorMessage = "Failed to update transfer request status: \(error.localizedDescription)"
                self.showErrorAlert = true
                return
            }
        }
        
        guard step1Success else { return }
        
        // Step 2: Update SalesAssociateStockRequest.status -> pending (so BM can search another store)
        do {
            try await SupabaseService.shared.client
                .from("SalesAssociateStockRequest")
                .update(["status": "pending"])
                .eq("id", value: salesAssocID.uuidString)
                .execute()
        } catch {
            do {
                try await SupabaseService.shared.client
                    .from("sales_associate_stock_request")
                    .update(["status": "pending"])
                    .eq("id", value: salesAssocID.uuidString)
                    .execute()
            } catch {
                print("❌ [StoreTransferDetailViewModel] Warning in Step 2 (Revert SalesAssociateStockRequest to pending): \(error)")
            }
        }
        
        // Structured Console Debug Logging
        print("\nTransfer Request ID:\n\(transferID.uuidString)")
        print("\nSender Store:\n\(item.senderStoreName)")
        print("\nDestination Store:\n\(item.destinationStoreName)")
        print("\nProduct ID:\n\(productID.uuidString)")
        print("\nQuantity:\n\(qtyRequested)")
        print("\nTransfer Status Updated:\ndeclined")
        print("\nSalesAssociateStockRequest Updated:\npending\n")
        
        NotificationCenter.default.post(name: .salesAssociateRequestUpdated, object: nil)
        NotificationCenter.default.post(name: .storeInventoryUpdated, object: nil)
        NotificationCenter.default.post(name: .inventoryDataRefreshedAll, object: nil)
        
        self.successMessage = "Transfer request declined."
        self.isSuccess = true
    }
    
    // MARK: - CANCEL WORKFLOW (Sender Can Cancel Outgoing Request)
    func cancelTransfer() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        showErrorAlert = false
        
        defer { isSubmitting = false }
        
        let transferID = item.request.id
        let salesAssocID = item.request.salesAssociateRequestID
        let productID = item.request.productID
        let qtyRequested = item.request.quantityRequested
        
        // ----------------------------------------------------
        // PRE-FLIGHT CHECK: Idempotency check (Ensure status is STILL pending)
        // ----------------------------------------------------
        var liveTransferRequests: [StoreToStoreTransferRequest] = []
        do {
            liveTransferRequests = try await SupabaseService.shared.client
                .from("StoreToStoreTransferRequest")
                .select()
                .eq("id", value: transferID.uuidString)
                .execute()
                .value
        } catch {
            liveTransferRequests = (try? await SupabaseService.shared.client
                .from("store_to_store_transfer_request")
                .select()
                .eq("id", value: transferID.uuidString)
                .execute()
                .value) ?? []
        }
        
        if let currentTransfer = liveTransferRequests.first, currentTransfer.status != .pending {
            print("❌ [StoreTransferDetailViewModel] Pre-flight failed: Transfer request already \(currentTransfer.status.displayName).")
            self.errorMessage = "This transfer request has already been processed (\(currentTransfer.status.displayName))."
            self.showErrorAlert = true
            return
        }
        
        // Step 1: Update StoreToStoreTransferRequest.status -> cancelled
        var step1Success = false
        do {
            try await SupabaseService.shared.client
                .from("StoreToStoreTransferRequest")
                .update(["status": "cancelled"])
                .eq("id", value: transferID.uuidString)
                .execute()
            step1Success = true
        } catch {
            do {
                try await SupabaseService.shared.client
                    .from("store_to_store_transfer_request")
                    .update(["status": "cancelled"])
                    .eq("id", value: transferID.uuidString)
                    .execute()
                step1Success = true
            } catch {
                print("❌ [StoreTransferDetailViewModel] Error in Step 1 (Cancel Transfer Request): \(error)")
                self.errorMessage = "Failed to update transfer request status: \(error.localizedDescription)"
                self.showErrorAlert = true
                return
            }
        }
        
        guard step1Success else { return }
        
        // Step 2: Update SalesAssociateStockRequest.status -> pending (reverting it to pending)
        do {
            try await SupabaseService.shared.client
                .from("SalesAssociateStockRequest")
                .update(["status": "pending"])
                .eq("id", value: salesAssocID.uuidString)
                .execute()
        } catch {
            do {
                try await SupabaseService.shared.client
                    .from("sales_associate_stock_request")
                    .update(["status": "pending"])
                    .eq("id", value: salesAssocID.uuidString)
                    .execute()
            } catch {
                print("❌ [StoreTransferDetailViewModel] Warning in Step 2 (Revert SalesAssociateStockRequest to pending): \(error)")
            }
        }
        
        // Structured Console Debug Logging
        print("\nTransfer Request ID:\n\(transferID.uuidString)")
        print("\nSender Store:\n\(item.senderStoreName)")
        print("\nDestination Store:\n\(item.destinationStoreName)")
        print("\nProduct ID:\n\(productID.uuidString)")
        print("\nQuantity:\n\(qtyRequested)")
        print("\nTransfer Status Updated:\ncancelled")
        print("\nSalesAssociateStockRequest Updated:\npending\n")
        
        NotificationCenter.default.post(name: .salesAssociateRequestUpdated, object: nil)
        NotificationCenter.default.post(name: .storeInventoryUpdated, object: nil)
        NotificationCenter.default.post(name: .inventoryDataRefreshedAll, object: nil)
        
        self.successMessage = "Transfer request cancelled."
        self.isSuccess = true
    }
}
