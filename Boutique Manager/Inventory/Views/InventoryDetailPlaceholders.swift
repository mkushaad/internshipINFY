import SwiftUI

// MARK: - Helper Construction Card
struct ModulePlaceholderContent: View {
    let title: String
    let iconName: String
    let description: String
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.themeAccent.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.themeAccent)
                }
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.themeText)
                    
                    Text("Module Under Construction")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 40)
            }
            .padding()
        }
    }
}

// MARK: - Stock Alerts Placeholder View
struct StockAlertsView: View {
    var body: some View {
        ModulePlaceholderContent(
            title: "Stock Alerts",
            iconName: "bell.badge.fill",
            description: "Here you will manage and resolve critical stock levels, review inventory replenishments, and set automatic restocking thresholds."
        )
        .navigationTitle("Stock Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Stock Requests Placeholder View (Deprecated in favor of StockRequestsView.swift)
// struct StockRequestsView: View { ... }

// MARK: - Inventory Discrepancies Placeholder View
struct InventoryDiscrepanciesView: View {
    var body: some View {
        ModulePlaceholderContent(
            title: "Discrepancies",
            iconName: "exclamationmark.triangle.fill",
            description: "Perform cycle counts, review mismatched quantities between expected and actual counts, and submit discrepancy resolution audits."
        )
        .navigationTitle("Discrepancies")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StockAlertsView()
    }
}
