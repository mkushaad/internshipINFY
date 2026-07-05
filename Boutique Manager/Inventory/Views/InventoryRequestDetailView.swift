import SwiftUI

struct InventoryRequestDetailView: View {
    let item: StoreInventoryRequestItem
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Product Header Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.themeAccent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            if let imageUrlString = item.imageUrl,
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
                            Text(item.productName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.themeText)
                                .multilineTextAlignment(.center)
                            
                            Text("SKU: \(item.sku)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Product Metadata Card
                    DetailSection(title: "Product Information") {
                        InfoRow(
                            title: "Brand",
                            value: item.brand,
                            isBoldValue: true,
                            valueColor: .themeText
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Category",
                            value: item.categoryName,
                            isBoldValue: false
                        )
                    }
                    
                    // Request Metadata Card (Read-Only)
                    DetailSection(title: "Inventory Controller Request") {
                        InfoRow(
                            title: "Quantity Requested",
                            value: "\(item.request.quantityRequested) units",
                            isBoldValue: true,
                            valueColor: .themeAccent
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Request Type",
                            value: item.request.requestType.rawValue.capitalized,
                            isBoldValue: false
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Priority Level",
                            value: item.request.priority.displayName,
                            isBoldValue: false
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        HStack {
                            Text("Status")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                            statusBadge(status: item.request.status)
                        }
                        .padding(.vertical, 4)
                        
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Created Date",
                            value: formattedDate(item.request.createdAt),
                            isBoldValue: false
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Inventory Request Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func statusBadge(status: StoreRequestStatus) -> some View {
        let (text, color, bgColor): (String, Color, Color) = {
            switch status {
            case .pending:
                return ("Pending", .orange, Color.orange.opacity(0.12))
            case .fulfilled:
                return ("Fulfilled", .green, Color.green.opacity(0.12))
            case .approved:
                return ("Approved", .blue, Color.blue.opacity(0.12))
            case .rejected:
                return ("Rejected", .red, Color.red.opacity(0.12))
            case .cancelled:
                return ("Cancelled", .gray, Color.gray.opacity(0.12))
            }
        }()
        
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(bgColor)
            .cornerRadius(12)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
