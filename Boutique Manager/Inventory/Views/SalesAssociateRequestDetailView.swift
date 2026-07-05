import SwiftUI

struct SalesAssociateRequestDetailView: View {
    let alert: StockAlert
    @ObservedObject var viewModel: InventoryOverviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var managerRemark: String = ""
    @State private var salesAssociateName: String = ""
    @State private var isSubmittingDecline = false
    
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
                            
                            if let imageUrlString = alert.imageUrl,
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
                            Text(alert.productName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.themeText)
                                .multilineTextAlignment(.center)
                            
                            Text("SKU: \(alert.sku)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 6)
                    
                    // Request Specification Details Card
                    DetailSection(title: "Sales Associate Request Details") {
                        InfoRow(
                            title: "Requested By",
                            value: salesAssociateName.isEmpty ? (alert.salesAssociateName ?? "Sales Associate") : salesAssociateName,
                            isBoldValue: true
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Priority",
                            value: alert.priority.rawValue,
                            isBoldValue: true,
                            valueColor: alert.priority == .high ? .red : (alert.priority == .medium ? .orange : .gray)
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Quantity Available",
                            value: alert.currentQuantity == 0 ? "Out of Stock" : "\(alert.currentQuantity) units",
                            isBoldValue: true,
                            valueColor: alert.currentQuantity == 0 ? .red : .themeText
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        // Requested Quantity
                        HStack(alignment: .center) {
                            Text("Quantity Requested")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .frame(width: 140, alignment: .leading)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right.square.fill")
                                    .font(.system(size: 11))
                                Text("\(alert.quantityRequested ?? 1) units")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.themeAccent.opacity(0.15))
                            .foregroundColor(.themeAccent)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.themeAccent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.vertical, 8)
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        if let status = alert.requestStatus {
                            InfoRow(
                                title: "Status",
                                value: status.displayName,
                                isBoldValue: true,
                                valueColor: status == .pending ? .orange : (status == .fulfilled ? .green : .red)
                            )
                            Divider().background(Color.themeText.opacity(0.06))
                        }
                        
                        InfoRow(title: "Request Date", value: alert.generatedAt.formattedString())
                    }
                    
                    // Remarks Section
                    DetailSection(title: "Manager Remarks") {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $managerRemark)
                                .font(.system(size: 13))
                                .foregroundColor(.themeText)
                                .frame(minHeight: 65, maxHeight: 95)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Color.themeBackground.opacity(0.5))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .overlay(
                                    Group {
                                        if managerRemark.isEmpty {
                                            Text("Enter remarks for this stock request...")
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray.opacity(0.5))
                                                .padding(.leading, 12)
                                                .padding(.top, 14)
                                                .allowsHitTesting(false)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                        }
                        .padding(.vertical, 6)
                    }
                    
                    Spacer(minLength: 16)
                    
                    // Horizontal Action Buttons
                    HStack(spacing: 12) {
                        // Decline Button
                        Button(action: {
                            Task {
                                isSubmittingDecline = true
                                await viewModel.declineSalesAssociateRequest(requestId: alert.id, managerRemark: managerRemark)
                                isSubmittingDecline = false
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 6) {
                                if isSubmittingDecline {
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
                        .disabled(isSubmittingDecline)

                        // Review Stores Navigation Button
                        NavigationLink(destination: ReviewNearbyStoresView(alert: alert)) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.magnifyingglass")
                                    .font(.system(size: 15))
                                Text("Review Stores")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.themeAccent)
                            .cornerRadius(12)
                            .shadow(color: Color.themeAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isSubmittingDecline)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .navigationTitle("Request Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if managerRemark.isEmpty {
                managerRemark = alert.managerRemark ?? ""
            }
            if let preloadedName = alert.salesAssociateName, !preloadedName.isEmpty {
                salesAssociateName = preloadedName
            }
        }
        .task {
            if salesAssociateName.isEmpty, let userId = alert.requestedBy {
                salesAssociateName = await viewModel.fetchUserName(userId: userId)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SalesAssociateRequestDetailView(
            alert: StockAlert(
                id: UUID(),
                productName: "Hermès Birkin 30 Gold",
                sku: "HRM-BRK-001",
                currentQuantity: 3,
                alertType: .transferRequested,
                priority: .high,
                source: .salesAssociate,
                generatedAt: Date(),
                description: "Customer waiting in store.",
                quantityRequested: 1,
                requestedBy: UUID(),
                salesAssociateName: "Elena Rostova"
            ),
            viewModel: InventoryOverviewViewModel()
        )
    }
}
