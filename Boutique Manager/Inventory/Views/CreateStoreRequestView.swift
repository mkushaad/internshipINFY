import SwiftUI

struct CreateStoreRequestView: View {
    let alert: StockAlert
    @ObservedObject var overviewViewModel: InventoryOverviewViewModel
    @StateObject private var viewModel: CreateStoreRequestViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Callback to dismiss parent details screen
    var onCompletion: () -> Void
    
    init(alert: StockAlert, overviewViewModel: InventoryOverviewViewModel, onCompletion: @escaping () -> Void) {
        self.alert = alert
        self.overviewViewModel = overviewViewModel
        self._viewModel = StateObject(wrappedValue: CreateStoreRequestViewModel(alert: alert))
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Product Details")) {
                        HStack {
                            Text("Product")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(alert.productName)
                                .fontWeight(.semibold)
                                .foregroundColor(.themeText)
                        }
                        HStack {
                            Text("SKU")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(alert.sku)
                                .foregroundColor(.themeText)
                        }
                        HStack {
                            Text("Current Quantity")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(alert.currentQuantity) units")
                                .foregroundColor(alert.currentQuantity == 0 ? .red : .themeText)
                                .fontWeight(alert.currentQuantity == 0 ? .bold : .regular)
                        }
                    }
                    
                    Section(header: Text("Request Options")) {
                        HStack {
                            Text("Request Type")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Refill")
                                .fontWeight(.semibold)
                                .foregroundColor(.themeText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            Picker("Priority", selection: $viewModel.selectedPriority) {
                                ForEach(Priority.allCases, id: \.self) { prio in
                                    Text(prio.displayName).tag(prio)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.vertical, 4)
                        
                        Stepper(value: $viewModel.quantity, in: 1...1000) {
                            HStack {
                                Text("Quantity Required")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(viewModel.quantity) units")
                                    .fontWeight(.bold)
                                    .foregroundColor(.themeText)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .preferredColorScheme(.light)
                
                if viewModel.isSubmitting {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                        Text("Sending Store Request...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(12)
                }
            }
            .navigationTitle("New Store Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .disabled(viewModel.isSubmitting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            let success = await viewModel.submitStoreRequest()
                            if success {
                                overviewViewModel.removeProcessedSystemAlert(id: alert.id)
                                overviewViewModel.triggerSuccessToast(message: "Stock request sent to Inventory Controller.")
                                dismiss()
                                onCompletion()
                            }
                        }
                    }) {
                        if viewModel.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Send")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.themeAccent)
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                }
            }
            .alert("Failed to Send Request", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred while uploading the store request.")
            }
        }
    }
}

#Preview {
    CreateStoreRequestView(
        alert: StockAlert(
            id: UUID(),
            productName: "Rolex Daytona",
            sku: "RLX-DT-116500",
            currentQuantity: 2,
            alertType: .lowStock,
            priority: .high,
            source: .system,
            generatedAt: Date(),
            description: "Rolex Daytona low stock level alert.",
            productID: UUID(),
            thresholdQuantity: 8
        ),
        overviewViewModel: InventoryOverviewViewModel(),
        onCompletion: {}
    )
}
