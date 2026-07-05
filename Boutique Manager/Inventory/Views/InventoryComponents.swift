import SwiftUI

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let style: BadgeStyle
    
    enum BadgeStyle {
        case critical
        case warning
        case success
        case pending
        case info
        
        var backgroundColor: Color {
            switch self {
            case .critical: return Color.red.opacity(0.1)
            case .warning: return Color.themeAccent.opacity(0.15)
            case .success: return Color.green.opacity(0.1)
            case .pending: return Color.gray.opacity(0.15)
            case .info: return Color.blue.opacity(0.1)
            }
        }
        
        var textColor: Color {
            switch self {
            case .critical: return Color.red
            case .warning: return Color.themeAccent
            case .success: return Color.green
            case .pending: return Color.themeText.opacity(0.7)
            case .info: return Color.blue
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(style.textColor)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(style.backgroundColor)
            .cornerRadius(20)
    }
}

// MARK: - Search Bar Component (Visual Only)
struct SearchBar: View {
    @State private var text: String = ""
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            TextField("Search store inventory...", text: $text)
                .font(.system(size: 15))
                .disabled(true) // Visual only
            
            Spacer()
            
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(.gray)
                .font(.system(size: 16))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.themeBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.themeText.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Inventory Summary Card
struct InventorySummaryCard: View {
    let title: String
    let value: String
    let iconName: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.themeText)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Inventory Section Preview Card Wrapper
struct InventorySectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    let buttonText: String
    let content: Content
    
    init(title: String, subtitle: String, buttonText: String = "View Details →", @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.buttonText = buttonText
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.themeText)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .padding([.top, .horizontal], 20)
            .padding(.bottom, 16)
            
            // Content
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 20)
            
            Divider()
                .background(Color.themeText.opacity(0.08))
                .padding(.top, 16)
            
            // Footer Action Link
            HStack {
                Spacer()
                Text(buttonText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.themeAccent)
                Spacer()
            }
            .padding(.vertical, 14)
        }
        .background(Color.themeCard)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }
}

// MARK: - Stock Alert Row
struct StockAlertRow: View {
    let alert: StockAlertPreview
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Icon Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.themeBackground)
                    .frame(width: 44, height: 44)
                
                Image(systemName: alert.imageSymbol)
                    .foregroundColor(.themeAccent)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.productName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeText)
                
                Text(alert.currentQuantity == 0 ? "Out of Stock" : "\(alert.currentQuantity) Remaining")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(
                text: alert.status.rawValue,
                style: alert.status == .critical ? .critical : (alert.status == .outOfStock ? .critical : .warning)
            )
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Stock Request Row
struct StockRequestRow: View {
    let request: StockRequestPreview
    
    var badgeStyle: StatusBadge.BadgeStyle {
        switch request.status {
        case .pending: return .pending
        case .approved: return .success
        case .inTransit: return .info
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.productName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeText)
                
                Spacer()
                
                Text("Qty \(request.quantity)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FROM")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text(request.sourceStore)
                        .font(.system(size: 11))
                        .foregroundColor(.themeText)
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeAccent.opacity(0.8))
                    .padding(.horizontal, 6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("TO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text(request.destinationStore)
                        .font(.system(size: 11))
                        .foregroundColor(.themeText)
                }
                
                Spacer()
                
                StatusBadge(text: request.status.rawValue, style: badgeStyle)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Inventory Discrepancy Row
struct InventoryDiscrepancyRow: View {
    let discrepancy: InventoryDiscrepancyPreview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(discrepancy.productName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeText)
                
                Spacer()
                
                StatusBadge(
                    text: discrepancy.status.rawValue,
                    style: discrepancy.status == .resolved ? .success : .pending
                )
            }
            
            HStack(spacing: 0) {
                // Expected
                VStack(alignment: .leading, spacing: 2) {
                    Text("EXPECTED")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(discrepancy.expectedQuantity)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.themeText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Actual
                VStack(alignment: .leading, spacing: 2) {
                    Text("ACTUAL")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(discrepancy.actualQuantity)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.themeText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Difference
                VStack(alignment: .leading, spacing: 2) {
                    Text("DIFFERENCE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                    Text(discrepancy.difference > 0 ? "+\(discrepancy.difference)" : "\(discrepancy.difference)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(discrepancy.difference < 0 ? .red : (discrepancy.difference > 0 ? .green : .themeText))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(Color.themeBackground)
            .cornerRadius(8)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Inventory Product Row
struct InventoryProductRow: View {
    let product: InventoryProductPreview
    
    var badgeStyle: StatusBadge.BadgeStyle {
        switch product.availability {
        case .available: return .success
        case .lowStock: return .warning
        case .outOfStock: return .critical
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.themeBackground)
                    .frame(width: 44, height: 44)
                
                Image(systemName: product.imageSymbol)
                    .foregroundColor(.themeAccent)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.productName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeText)
                
                Text("Stock: \(product.currentStock)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(text: product.availability.rawValue, style: badgeStyle)
        }
        .padding(.vertical, 8)
    }
}
