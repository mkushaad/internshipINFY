import SwiftUI

struct LowStockAlertsView: View {
    @StateObject private var viewModel = InventoryOverviewViewModel()
    @State private var selectedSegmentIndex: Int = 0 // 0 = Alerts, 1 = Inventory Requests
    @State private var showFilters: Bool = false
    
    var systemAlerts: [StockAlert] {
        viewModel.filteredStockAlerts.filter { alert in
            alert.source == .system && alert.alertType != .transferRequested
        }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Segmented Control Picker
                Picker("Low Stock Segment", selection: $selectedSegmentIndex) {
                    Text("Alerts").tag(0)
                    Text("Inventory Requests").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                
                Divider()
                
                // Search and Filter Bar Row
                HStack(spacing: 12) {
                    // Search Field
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        
                        TextField(
                            selectedSegmentIndex == 0 ? "Search low stock product or SKU..." : "Search request product or SKU...",
                            text: $viewModel.searchText
                        )
                        .font(.system(size: 14))
                        .foregroundColor(.themeText)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.themeBackground)
                    .cornerRadius(10)
                    
                    // Filter Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showFilters.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            if isFilterActive {
                                Circle()
                                    .fill(Color.themeAccent)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(showFilters ? .white : .themeAccent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(showFilters ? Color.themeAccent : Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                
                // Expandable Filters Drawer
                if showFilters {
                    VStack(alignment: .leading, spacing: 14) {
                        if selectedSegmentIndex == 0 {
                            // Alerts Filters
                            filterSectionTitle("Urgency / Priority")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    filterChip("All Priority", isSelected: viewModel.selectedAlertPriority == nil) {
                                        viewModel.selectedAlertPriority = nil
                                    }
                                    ForEach(AlertPriority.allCases) { priority in
                                        filterChip(priority.rawValue, isSelected: viewModel.selectedAlertPriority == priority) {
                                            viewModel.selectedAlertPriority = priority
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            filterSectionTitle("Alert Type")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    filterChip("All Types", isSelected: viewModel.selectedAlertType == nil) {
                                        viewModel.selectedAlertType = nil
                                    }
                                    filterChip(AlertType.lowStock.rawValue, isSelected: viewModel.selectedAlertType == .lowStock) {
                                        viewModel.selectedAlertType = .lowStock
                                    }
                                    filterChip(AlertType.outOfStock.rawValue, isSelected: viewModel.selectedAlertType == .outOfStock) {
                                        viewModel.selectedAlertType = .outOfStock
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        } else {
                            // Inventory Requests Filters
                            filterSectionTitle("Request Status")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(RequestStatusFilterOption.allCases) { option in
                                        filterChip(option.rawValue, isSelected: viewModel.selectedInventoryRequestStatusFilter == option) {
                                            viewModel.selectedInventoryRequestStatusFilter = option
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Clear filters footer
                        if isFilterActive || !viewModel.searchText.isEmpty {
                            Button(action: {
                                withAnimation {
                                    viewModel.resetFilters()
                                    viewModel.selectedInventoryRequestStatusFilter = .all
                                }
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear All Filters")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.05))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 4)
                }
                
                // Content Area
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView(selectedSegmentIndex == 0 ? "Loading system low stock alerts..." : "Loading inventory requests...")
                                .tint(.themeAccent)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else if selectedSegmentIndex == 0 {
                            // Segment 0: System Low Stock Alerts
                            if systemAlerts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.top, 40)
                                    Text(viewModel.hasActiveFilters ? "No matching low stock alerts found" : "No low stock alerts for this boutique")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(systemAlerts) { alert in
                                    NavigationLink(destination: StockAlertDetailView(alert: alert, viewModel: viewModel)) {
                                        StockAlertCard(alert: alert)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            // Segment 1: Inventory Requests (StoreRequestToInventory)
                            if viewModel.filteredInventoryRequests.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.top, 40)
                                    Text(viewModel.selectedInventoryRequestStatusFilter != .all || !viewModel.searchText.isEmpty ? "No matching inventory requests found" : "No active inventory requests")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(viewModel.filteredInventoryRequests) { item in
                                    NavigationLink(destination: InventoryRequestDetailView(item: item)) {
                                        InventoryRequestRowCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await viewModel.fetchDynamicStockAlerts()
                }
            }
        }
        .navigationTitle("Low Stock")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .task {
            await viewModel.fetchDynamicStockAlerts()
        }
    }
    
    private var isFilterActive: Bool {
        if selectedSegmentIndex == 0 {
            return viewModel.selectedAlertPriority != nil || viewModel.selectedAlertType != nil
        } else {
            return viewModel.selectedInventoryRequestStatusFilter != .all
        }
    }
    
    @ViewBuilder
    private func filterSectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.gray)
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                action()
            }
        }) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .themeText)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.themeAccent : Color.themeBackground)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Color.themeAccent : Color.gray.opacity(0.15), lineWidth: 1)
                )
        }
    }
}

// MARK: - Inventory Request Row Card Component
struct InventoryRequestRowCard: View {
    let item: StoreInventoryRequestItem
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeAccent.opacity(0.08))
                    .frame(width: 50, height: 50)
                
                if let imageUrlString = item.imageUrl,
                   let url = URL(string: imageUrlString),
                   !imageUrlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)
                        default:
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(.themeAccent)
                                .font(.system(size: 20))
                        }
                    }
                } else {
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(.themeAccent)
                        .font(.system(size: 20))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeText)
                    .lineLimit(1)
                
                Text("Requested: \(item.request.quantityRequested) units")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(formattedDate(item.request.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                statusBadge(status: item.request.status)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
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
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(bgColor)
            .cornerRadius(8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        LowStockAlertsView()
    }
}
