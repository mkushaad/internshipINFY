import SwiftUI

struct CreateStoreRequestView: View {
    let alert: StockAlert
    @ObservedObject var viewModel: InventoryOverviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Form Input States
    @State private var selectedType: RequestType = .refill
    @State private var selectedPriority: Priority = .normal
    @State private var quantity: Int = 5
    @State private var explanationText: String = ""
    
    // Callback to dismiss parent details screen
    var onCompletion: () -> Void
    
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
                    }
                    
                    Section(header: Text("Request Options")) {
                        Picker("Request Type", selection: $selectedType) {
                            ForEach(RequestType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            Picker("Priority", selection: $selectedPriority) {
                                ForEach(Priority.allCases, id: \.self) { prio in
                                    Text(prio.displayName).tag(prio)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.vertical, 4)
                        
                        Stepper(value: $quantity, in: 1...100) {
                            HStack {
                                Text("Quantity Required")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(quantity) units")
                                    .fontWeight(.bold)
                                    .foregroundColor(.themeText)
                            }
                        }
                    }
                    
                    Section(header: Text("Explanation & Remarks")) {
                        TextEditor(text: $explanationText)
                            .frame(height: 100)
                            .overlay(
                                Group {
                                    if explanationText.isEmpty {
                                        VStack {
                                            HStack {
                                                Text("Explain the reason for this request...")
                                                    .foregroundColor(.gray.opacity(0.6))
                                                    .font(.system(size: 14))
                                                    .padding(.top, 8)
                                                    .padding(.leading, 4)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            )
                    }
                }
                .scrollContentBackground(.hidden)
                .preferredColorScheme(.light)
            }
            .navigationTitle("New Store Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send Request") {
                        // Create a StoreRequest object
                        let newRequest = StoreRequest(
                            id: UUID().uuidString,
                            requestType: selectedType,
                            storeName: alert.source == .salesAssociate ? "Mumbai Flagship" : "Cupertino Headquarters",
                            sku: alert.sku,
                            productName: alert.productName,
                            quantityRequested: quantity,
                            priority: selectedPriority,
                            managerRemark: explanationText.isEmpty ? nil : explanationText,
                            status: .pending,
                            createdAt: Date()
                        )
                        
                        // Push into viewModel
                        viewModel.convertAlertToStoreRequest(alertId: alert.id, request: newRequest)
                        
                        // Dismiss form and parent detail view
                        dismiss()
                        onCompletion()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeAccent)
                }
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
            description: "Rolex Daytona low stock level alert."
        ),
        viewModel: InventoryOverviewViewModel(),
        onCompletion: {}
    )
}
