import SwiftUI

struct StockRequestsView: View {
    @StateObject private var viewModel = StockRequestsViewModel()
    @State private var showFilters: Bool = false
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Segmented Control at top
                Picker("Request Category", selection: $viewModel.selectedSegmentIndex) {
                    Text("Sales Associate").tag(0)
                    Text("Store Transfers").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                // 2. Immediately below Segmented Control: Search Bar + Filter Button Row
                HStack(spacing: 12) {
                    // Search Pill
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        
                        TextField(
                            viewModel.selectedSegmentIndex == 0 ? "Search request or SKU..." : "Search transfer, SKU or store...",
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
                            if viewModel.hasActiveFilters {
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
                
                // Expandable Filter Drawer
                if showFilters {
                    VStack(alignment: .leading, spacing: 14) {
                        if viewModel.selectedSegmentIndex == 0 {
                            // Sales Associate Filters
                            filterSectionTitle("Status Filter")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(SalesAssociateFilterOption.allCases) { option in
                                        filterChip(option.rawValue, isSelected: viewModel.selectedSalesFilter == option) {
                                            viewModel.selectedSalesFilter = option
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        } else {
                            // Store Transfer Filters: Direction (Sent / Received) & Status
                            filterSectionTitle("Transfer Direction")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(TransferDirectionFilterOption.allCases) { option in
                                        filterChip(option.rawValue, isSelected: viewModel.selectedDirectionFilter == option) {
                                            viewModel.selectedDirectionFilter = option
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            filterSectionTitle("Transfer Status")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(StoreTransferFilterOption.allCases) { option in
                                        filterChip(option.rawValue, isSelected: viewModel.selectedTransferFilter == option) {
                                            viewModel.selectedTransferFilter = option
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        if viewModel.hasActiveFilters {
                            Button(action: {
                                withAnimation {
                                    viewModel.resetFilters()
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
                
                // 3. List Section
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.selectedSegmentIndex == 0 {
                            // Segment 1: Sales Associate
                            if viewModel.isLoading {
                                ProgressView("Loading stock requests...")
                                    .tint(.themeAccent)
                                    .padding(.top, 40)
                            } else if viewModel.filteredSalesAssociateRequests.isEmpty {
                                emptyStateView(message: viewModel.hasActiveFilters ? "No Sales Associate stock requests match your filter." : "No active Sales Associate stock requests available.")
                            } else {
                                ForEach(viewModel.filteredSalesAssociateRequests) { alert in
                                    NavigationLink(destination: SalesAssociateRequestDetailView(alert: alert, viewModel: viewModel.overviewViewModel)) {
                                        SalesAssociateRequestRowCard(alert: alert)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            // Segment 2: Store Transfers
                            if viewModel.filteredStoreTransfers.isEmpty {
                                emptyStateView(message: viewModel.hasActiveFilters ? "No store-to-store transfer requests match your filter." : "No active store-to-store transfer requests available.")
                            } else {
                                ForEach(viewModel.filteredStoreTransfers) { item in
                                    NavigationLink(destination: StoreTransferRequestDetailView(item: item)) {
                                        StoreTransferRowCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Stock Requests")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .task {
            await viewModel.fetchRequests()
        }
    }
    
    // MARK: - Subviews & Helpers
    
    @ViewBuilder
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 40)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Sales Associate Request Row Card
struct SalesAssociateRequestRowCard: View {
    let alert: StockAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row: Priority Badge & Status Badge
            HStack {
                RequestPriorityBadge(priority: alert.priority == .high ? .urgent : .normal)
                Spacer()
                if let status = alert.requestStatus {
                    StoreRequestStatusBadge(status: status)
                } else {
                    Text("Pending")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            
            // Product Information Row
            HStack(spacing: 14) {
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
                                Image(systemName: "arrow.left.arrow.right")
                                    .foregroundColor(.themeAccent)
                                    .font(.system(size: 22))
                            }
                        }
                    } else {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundColor(.themeAccent)
                            .font(.system(size: 22))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(alert.productName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeText)
                        .lineLimit(2)
                    
                    // Quantity Requested & Quantity Available Stats
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Req:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.themeAccent)
                            Text("\(alert.quantityRequested ?? 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.themeAccent)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.themeAccent.opacity(0.1))
                        .cornerRadius(8)
                        
                        HStack(spacing: 4) {
                            Text("Avail:")
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
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
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
}

// MARK: - Store Transfer Row Card
struct StoreTransferRowCard: View {
    let item: StoreTransferDisplayItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row: Direction Badge Tag (Sent vs Received) & Status Badge
            HStack {
                directionBadge(isSent: item.isSent)
                Spacer()
                transferStatusBadge(item.request.status)
            }
            
            // Product Information Row
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.themeAccent.opacity(0.08))
                        .frame(width: 56, height: 56)
                    
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
                                    .cornerRadius(10)
                            default:
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.themeAccent)
                                    .font(.system(size: 22))
                            }
                        }
                    } else {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.themeAccent)
                            .font(.system(size: 22))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.productName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeText)
                        .lineLimit(1)
                    
                    Text("SKU: \(item.sku)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.themeText.opacity(0.06))
            
            // Store detail row: Displays "Sent to: <store>" if sent, or "Received from: <store>" if received
            HStack {
                Text(item.isSent ? "Sent to:" : "Received from:")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
                Text(item.isSent ? item.destinationStoreName : item.senderStoreName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeText)
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
    
    @ViewBuilder
    private func directionBadge(isSent: Bool) -> some View {
        let label = isSent ? "Sent" : "Received"
        let color: Color = isSent ? .blue : .indigo
        
        HStack(spacing: 4) {
            Image(systemName: isSent ? "paperplane.fill" : "tray.and.arrow.down.fill")
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(color.opacity(0.1))
        .cornerRadius(20)
    }
    
    private func statusColor(_ status: TransferRequestStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .cancelled: return .gray
        }
    }
    
    @ViewBuilder
    private func transferStatusBadge(_ status: TransferRequestStatus) -> some View {
        let color = statusColor(status)
        Text(status.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(color.opacity(0.1))
            .cornerRadius(20)
    }
}

#Preview {
    NavigationStack {
        StockRequestsView()
    }
}
