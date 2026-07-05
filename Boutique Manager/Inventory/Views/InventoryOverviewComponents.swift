import SwiftUI

// MARK: - Priority Badge (Stock Alerts)
struct PriorityBadge: View {
    let priority: AlertPriority
    
    var color: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
    
    var body: some View {
        Text(priority.rawValue)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(color.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Priority Badge (Store Requests)
struct RequestPriorityBadge: View {
    let priority: Priority
    
    var color: Color {
        switch priority {
        case .normal: return .gray
        case .urgent: return .red
        }
    }
    
    var body: some View {
        Text(priority.displayName)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(color.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Source Badge
struct SourceBadge: View {
    let source: AlertSource
    
    var color: Color {
        switch source {
        case .system: return .blue
        case .salesAssociate: return .themeAccent
        }
    }
    
    var body: some View {
        Text(source.rawValue)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(color.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Alert Type Badge
struct AlertTypeBadge: View {
    let type: AlertType
    
    var color: Color {
        switch type {
        case .lowStock: return .orange
        case .outOfStock: return .red
        case .transferRequested: return .blue
        }
    }
    
    var body: some View {
        Text(type.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(color.opacity(0.1))
            .cornerRadius(20)
    }
}

// MARK: - Store Request Status Badge
struct StoreRequestStatusBadge: View {
    let status: RequestStatus
    
    var color: Color {
        switch status {
        case .pending: return .orange
        case .forwarded: return .green
        case .rejected: return .red
        case .fulfilled: return .blue
        }
    }
    
    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(color.opacity(0.1))
            .cornerRadius(20)
    }
}

// MARK: - Store Request Type Badge
struct StoreRequestTypeBadge: View {
    let type: RequestType
    
    var color: Color {
        switch type {
        case .transfer: return .themeAccent
        case .refill: return .purple
        }
    }
    
    var body: some View {
        Text(type.rawValue)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(color.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Stock Alert Card View
struct StockAlertCard: View {
    let alert: StockAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Badges Row: Left Tag (Stock Transfer / Alert Type) & Right Tag (Source)
            HStack {
                if alert.source == .salesAssociate || alert.quantityRequested != nil {
                    Text("Stock Transfer")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(20)
                } else {
                    AlertTypeBadge(type: alert.alertType)
                }
                Spacer()
                SourceBadge(source: alert.source)
            }
            
            // Product Information & Image Row
            HStack(spacing: 14) {
                // Product Image Container
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.themeAccent.opacity(0.08))
                        .frame(width: 56, height: 56)
                    
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
                                    .cornerRadius(10)
                            default:
                                fallbackIcon
                            }
                        }
                    } else {
                        fallbackIcon
                    }
                }
                
                // Product Name & Side-by-Side Decluttered Stock Stats
                VStack(alignment: .leading, spacing: 6) {
                    Text(alert.productName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Decluttered Side-by-Side Stock Stats
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Current:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(alert.currentQuantity == 0 ? "Out of Stock" : "\(alert.currentQuantity)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(alert.currentQuantity == 0 ? .red : .themeText)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(8)

                        if let requestedQty = alert.quantityRequested {
                            HStack(spacing: 4) {
                                Text("Requested:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.themeAccent)
                                Text("\(requestedQty)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.themeAccent)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.themeAccent.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
    }

    private var fallbackIcon: some View {
        Image(systemName: alert.source == .salesAssociate ? "arrow.left.arrow.right.circle.fill" : "shippingbox.fill")
            .foregroundColor(.themeAccent)
            .font(.system(size: 24))
    }
}

// MARK: - Store Request Card View
struct StoreRequestCard: View {
    let request: StoreRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                StoreRequestTypeBadge(type: request.requestType)
                Spacer()
                StoreRequestStatusBadge(status: request.status)
            }
            
            // Product details
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.themeBackground)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: request.requestType == .transfer ? "arrow.left.arrow.right" : "arrow.down.circle.fill")
                        .foregroundColor(.themeAccent)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.productName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.themeText)
                    
                    Text("SKU: \(request.sku)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            Divider()
                .background(Color.themeText.opacity(0.06))
            
            // Middle section
            VStack(spacing: 8) {
                HStack {
                    Text("Boutique Location:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(request.storeName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.themeText)
                }
                
                HStack {
                    Text("Quantity Requested:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(request.quantityRequested) units")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.themeText)
                }
            }
            
            Divider()
                .background(Color.themeText.opacity(0.06))
            
            // Footer Details
            HStack {
                Text("Created: \(request.createdAt.timeAgoString())")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Spacer()
                RequestPriorityBadge(priority: request.priority)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeAccent)
            }
        }
        .padding(16)
        .background(Color.themeCard)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Info Row for details alignment
struct InfoRow: View {
    let title: String
    let value: String
    var isBoldValue: Bool = false
    var valueColor: Color = .themeText
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .frame(width: 140, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: isBoldValue ? .bold : .medium))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Detail Section Wrapper
struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.themeCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    let createdDate: Date
    let currentStatus: String
    let statusColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // First step (Requested)
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                    
                    // Line connector
                    Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 2, height: 44)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Requested")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.themeText)
                    
                    Text("Store Request created and logged in the system.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(createdDate.formattedString())
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 12)
            }
            
            // Second step (Current status)
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 0) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(statusColor.opacity(0.3), lineWidth: 4)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Status: \(currentStatus)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeText)
                    
                    Text("Status is currently resolved as \(currentStatus.lowercased()).")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Date extension helpers
extension Date {
    func timeAgoString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
