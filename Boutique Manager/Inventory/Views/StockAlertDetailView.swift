import SwiftUI

struct StockAlertDetailView: View {
    let alert: StockAlert
    @ObservedObject var viewModel: InventoryOverviewViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCreateRequestForm = false
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Product Header Section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.themeAccent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: alert.alertType == .transferRequested ? "arrow.left.arrow.right" : "shippingbox.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.themeAccent)
                        }
                        
                        VStack(spacing: 4) {
                            Text(alert.productName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.themeText)
                                .multilineTextAlignment(.center)
                            
                            Text("SKU: \(alert.sku)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Alert Specification Details
                    DetailSection(title: "Alert Information") {
                        InfoRow(title: "Alert Type", value: alert.alertType.rawValue, isBoldValue: true, valueColor: alert.alertType == .outOfStock ? .red : .themeText)
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Source", value: alert.source.rawValue)
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Priority", value: alert.priority.rawValue, isBoldValue: true, valueColor: alert.priority == .high ? .red : (alert.priority == .medium ? .orange : .gray))
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Current Quantity", value: alert.currentQuantity == 0 ? "Out of Stock" : "\(alert.currentQuantity) units", isBoldValue: true, valueColor: alert.currentQuantity == 0 ? .red : .themeText)
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Generated Date", value: alert.generatedAt.formattedString())
                    }
                    
                    // Alert Description / Reason
                    DetailSection(title: "Reason & Description") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(alert.description)
                                .font(.system(size: 13))
                                .foregroundColor(.themeText)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Action Buttons Footer
                    VStack(spacing: 12) {
                        // Convert to Stock Request Button
                        Button(action: {
                            showCreateRequestForm = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Convert To Stock Request")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.themeAccent)
                            .cornerRadius(12)
                            .shadow(color: Color.themeAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        // Ignore Button
                        Button(action: {
                            // TODO: Future Supabase Integration
                            // This button will later call the database API to mark the stock alert as 'resolved' or 'ignored'
                            // so it is cleared from the manager's action panel.
                            //
                            // backend.ignoreAlert(alertId: alert.id)
                            
                            viewModel.ignoreAlert(id: alert.id)
                            dismiss()
                        }) {
                            Text("Ignore")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding()
            }
        }
        .navigationTitle("Alert Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateRequestForm) {
            CreateStoreRequestView(alert: alert, viewModel: viewModel) {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        StockAlertDetailView(
            alert: StockAlert(
                id: UUID(),
                productName: "Rolex Daytona",
                sku: "RLX-DT-116500",
                currentQuantity: 2,
                alertType: .lowStock,
                priority: .high,
                source: .system,
                generatedAt: Date(),
                description: "Rolex Daytona current quantity is below the safety stock threshold of 5 units."
            ),
            viewModel: InventoryOverviewViewModel()
        )
    }
}
