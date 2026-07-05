import SwiftUI

struct StoreTransferRequestDetailView: View {
    let item: StoreTransferDisplayItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: StoreTransferDetailViewModel
    @State private var showSuccessToast = false
    
    init(item: StoreTransferDisplayItem) {
        self.item = item
        self._viewModel = StateObject(wrappedValue: StoreTransferDetailViewModel(item: item))
    }
    
    // Automatically determine if the current user/store is the Receiver or Sender
    var isReceiver: Bool {
        !item.isSent
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Product Header Section
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.themeAccent.opacity(0.1))
                                .frame(width: 72, height: 72)
                            
                            if let imageUrlString = item.imageUrl,
                               let url = URL(string: imageUrlString),
                               !imageUrlString.isEmpty {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 48, height: 48)
                                            .cornerRadius(8)
                                    default:
                                        Image(systemName: "arrow.left.arrow.right")
                                            .font(.system(size: 28))
                                            .foregroundColor(.themeAccent)
                                    }
                                }
                            } else {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 28))
                                    .foregroundColor(.themeAccent)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text(item.productName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.themeText)
                                .multilineTextAlignment(.center)
                            
                            Text("SKU: \(item.sku)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 6)
                    
                    // Transfer Details Card (Displays only Receiver OR Sender details based on item.isSent)
                    DetailSection(title: isReceiver ? "Incoming Store Transfer" : "Outgoing Store Transfer") {
                        if isReceiver {
                            InfoRow(
                                title: "Sender Store",
                                value: item.senderStoreName,
                                isBoldValue: true,
                                valueColor: .themeAccent
                            )
                        } else {
                            InfoRow(
                                title: "Destination Store",
                                value: item.destinationStoreName,
                                isBoldValue: true,
                                valueColor: .themeAccent
                            )
                        }
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Quantity",
                            value: "\(item.request.quantityRequested) units",
                            isBoldValue: true
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Status",
                            value: item.request.status.displayName,
                            isBoldValue: true,
                            valueColor: statusColor(item.request.status)
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Created Date", value: item.request.createdAt.formattedString())
                    }
                    
                    Spacer(minLength: 24)
                    
                    // Action Buttons Area (Displays only applicable buttons)
                    if isReceiver {
                        // Receiver View Buttons (Accept / Decline) - shown if request is pending
                        if item.request.status == .pending {
                            HStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await viewModel.declineTransfer()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        if viewModel.isSubmitting {
                                            ProgressView()
                                                .tint(.red)
                                        } else {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 15))
                                            Text("Decline")
                                                .font(.system(size: 15, weight: .bold))
                                        }
                                    }
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
                                
                                Button(action: {
                                    Task {
                                        await viewModel.acceptTransfer()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        if viewModel.isSubmitting {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 15))
                                            Text("Accept")
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
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 20)
                        }
                    } else {
                        // Sender View Button (Cancel Request) - shown if request is pending
                        if item.request.status == .pending {
                            Button(action: {
                                Task {
                                    await viewModel.cancelTransfer()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if viewModel.isSubmitting {
                                        ProgressView()
                                            .tint(.red)
                                    } else {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 15))
                                        Text("Cancel Request")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                }
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
                            .padding(.horizontal, 4)
                            .padding(.bottom, 20)
                        }
                    }
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
                        
                        Text(viewModel.successMessage)
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
        .navigationTitle("Store Transfer Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Transfer Operation Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
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
    
    private func statusColor(_ status: TransferRequestStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .cancelled: return .gray
        default: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        StoreTransferRequestDetailView(
            item: StoreTransferDisplayItem(
                request: StoreToStoreTransferRequest(
                    id: UUID(),
                    senderStoreID: UUID(),
                    destinationStoreID: UUID(),
                    productID: UUID(),
                    quantityRequested: 2,
                    salesAssociateRequestID: UUID(),
                    status: .pending,
                    createdAt: Date()
                ),
                productName: "Rolex Submariner Date",
                sku: "RLX-SUB-002",
                senderStoreName: "Dubai Mall Flagship",
                destinationStoreName: "Paris Champs-Élysées",
                isSent: false
            )
        )
    }
}
