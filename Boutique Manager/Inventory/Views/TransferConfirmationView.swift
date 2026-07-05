import SwiftUI

struct TransferConfirmationView: View {
    let candidate: NearbyStoreCandidate
    let alert: StockAlert
    let currentStoreName: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TransferConfirmationViewModel
    @State private var showSuccessToast = false
    
    init(candidate: NearbyStoreCandidate, alert: StockAlert, currentStoreName: String) {
        self.candidate = candidate
        self.alert = alert
        self.currentStoreName = currentStoreName
        self._viewModel = StateObject(
            wrappedValue: TransferConfirmationViewModel(
                candidate: candidate,
                alert: alert,
                currentStoreName: currentStoreName
            )
        )
    }
    
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
                            
                            if let imageUrlString = candidate.productImageUrl,
                               let url = URL(string: imageUrlString),
                               !imageUrlString.isEmpty {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 54, height: 54)
                                            .cornerRadius(10)
                                    default:
                                        Image(systemName: "shippingbox.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.themeAccent)
                                    }
                                }
                            } else {
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.themeAccent)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text(candidate.productName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.themeText)
                                .multilineTextAlignment(.center)
                            
                            Text("SKU: \(candidate.productSKU)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Transfer Details Card
                    DetailSection(title: "Transfer Request Confirmation") {
                        InfoRow(
                            title: "Sender Store",
                            value: candidate.store.name.isEmpty ? candidate.store.location : candidate.store.name,
                            isBoldValue: true,
                            valueColor: .themeAccent
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Destination Store",
                            value: currentStoreName,
                            isBoldValue: true,
                            valueColor: .themeText
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Quantity Requested",
                            value: "\(candidate.quantityRequested) units",
                            isBoldValue: true,
                            valueColor: .themeAccent
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Available at Sender",
                            value: "\(candidate.availableQuantity) units",
                            isBoldValue: true,
                            valueColor: .green
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Region",
                            value: candidate.store.region,
                            isBoldValue: false
                        )
                    }
                    
                    Spacer(minLength: 24)
                    
                    // Action Buttons: Send Transfer Request & Cancel
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await viewModel.sendTransferRequest()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if viewModel.isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 15))
                                    Text("Send Transfer Request")
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.isSubmitting ? Color.gray : Color.themeAccent)
                            .cornerRadius(12)
                            .shadow(color: Color.themeAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(viewModel.isSubmitting)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold))
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
                        .disabled(viewModel.isSubmitting)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            
            // Success Toast Banner
            if showSuccessToast {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                        
                        Text("Transfer request sent successfully.")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("Transfer Confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Transfer Request Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred while sending the transfer request.")
        }
        .onChange(of: viewModel.isSuccess) { _, isSuccess in
            if isSuccess {
                withAnimation {
                    showSuccessToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TransferConfirmationView(
            candidate: NearbyStoreCandidate(
                store: Store(
                    id: UUID(),
                    name: "Boutique - Dubai Mall",
                    location: "Dubai Mall, Fashion Avenue",
                    region: "Dubai",
                    managerID: nil,
                    inventoryControllerID: nil,
                    currency: .usd,
                    privacyRegulation: "GDPR"
                ),
                availableQuantity: 12,
                quantityRequested: 4,
                productName: "Rolex Daytona 116500LN",
                productSKU: "RLX-DT-116500",
                productImageUrl: nil
            ),
            alert: StockAlert(
                id: UUID(),
                productName: "Rolex Daytona 116500LN",
                sku: "RLX-DT-116500",
                currentQuantity: 2,
                alertType: .transferRequested,
                priority: .high,
                source: .salesAssociate,
                generatedAt: Date(),
                description: "Stock request",
                quantityRequested: 4,
                productID: UUID(),
                storeID: UUID()
            ),
            currentStoreName: "Paris Champs-Élysées"
        )
    }
}
