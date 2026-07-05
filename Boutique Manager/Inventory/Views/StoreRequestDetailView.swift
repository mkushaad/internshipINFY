import SwiftUI

struct StoreRequestDetailView: View {
    let request: StoreRequest
    
    var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .forwarded: return .green
        case .rejected: return .red
        case .fulfilled: return .blue
        }
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
                            
                            Image(systemName: request.requestType == .transfer ? "arrow.left.arrow.right" : "arrow.down.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.themeAccent)
                        }
                        
                        VStack(spacing: 4) {
                            Text(request.productName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.themeText)
                                .multilineTextAlignment(.center)
                            
                            Text("SKU: \(request.sku)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Request details
                    DetailSection(title: "Request details") {
                        InfoRow(title: "Request Type", value: request.requestType.rawValue, isBoldValue: true)
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Boutique Location", value: request.storeName)
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Quantity Requested", value: "\(request.quantityRequested) units", isBoldValue: true)
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Priority", value: request.priority.displayName, isBoldValue: true, valueColor: request.priority == .urgent ? .red : .gray)
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Current Status", value: request.status.displayName, isBoldValue: true, valueColor: statusColor)
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(title: "Created Date", value: request.createdAt.formattedString())
                    }
                    
                    // Timeline Section
                    DetailSection(title: "Status Timeline") {
                        VStack(alignment: .leading, spacing: 0) {
                            TimelineView(
                                createdDate: request.createdAt,
                                currentStatus: request.status.displayName,
                                statusColor: statusColor
                            )
                        }
                        .padding(.vertical, 12)
                    }
                    
                    // Manager Remark
                    DetailSection(title: "Manager Remarks") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(request.managerRemark == nil || (request.managerRemark?.isEmpty ?? true) ? "No manager remarks available." : request.managerRemark!)
                                .font(.system(size: 13))
                                .foregroundColor(.themeText)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Request Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StoreRequestDetailView(
            request: StoreRequest(
                id: UUID().uuidString,
                requestType: .transfer,
                storeName: "Dubai Mall Flagship",
                sku: "RLX-DT-116500",
                productName: "Rolex Daytona",
                quantityRequested: 3,
                priority: .urgent,
                managerRemark: "Awaiting approval from Cupertino Central Hub.",
                status: .pending,
                createdAt: Date()
            )
        )
    }
}
