import SwiftUI

struct InventoryOverviewView: View {
    @StateObject private var viewModel = InventoryOverviewViewModel()
    @State private var showFilters: Bool = false
    
    var body: some View {
        ZStack {
            // Background color matching standard theme
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented picker placed in top header bar
                Picker("Workspace Mode", selection: $viewModel.selectedSegmentIndex) {
                    Text("Stock Alerts").tag(0)
                    Text("Stock Requests").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                // Search and Filter Bar Row
                HStack(spacing: 12) {
                    // Search Pill
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        
                        TextField("Search product or SKU...", text: $viewModel.searchText)
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
                
                // Expandable Advanced Filters Drawer
                if showFilters {
                    VStack(alignment: .leading, spacing: 14) {
                        if viewModel.selectedSegmentIndex == 0 {
                            // Alerts Filters
                            VStack(alignment: .leading, spacing: 12) {
                                // Priority Filters
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
                                
                                // Alert Type Filters
                                filterSectionTitle("Alert Type")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        filterChip("All Types", isSelected: viewModel.selectedAlertType == nil) {
                                            viewModel.selectedAlertType = nil
                                        }
                                        ForEach(AlertType.allCases) { type in
                                            filterChip(type.rawValue, isSelected: viewModel.selectedAlertType == type) {
                                                viewModel.selectedAlertType = type
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                
                                // Source Filters
                                filterSectionTitle("Source")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        filterChip("All Sources", isSelected: viewModel.selectedAlertSource == nil) {
                                            viewModel.selectedAlertSource = nil
                                        }
                                        ForEach(AlertSource.allCases) { source in
                                            filterChip(source.rawValue, isSelected: viewModel.selectedAlertSource == source) {
                                                viewModel.selectedAlertSource = source
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        } else {
                            // Requests Filters
                            VStack(alignment: .leading, spacing: 12) {
                                // Priority Filters
                                filterSectionTitle("Urgency / Priority")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        filterChip("All Priority", isSelected: viewModel.selectedRequestPriority == nil) {
                                            viewModel.selectedRequestPriority = nil
                                        }
                                        ForEach(Priority.allCases, id: \.self) { priority in
                                            filterChip(priority.displayName, isSelected: viewModel.selectedRequestPriority == priority) {
                                                viewModel.selectedRequestPriority = priority
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                
                                // Status Filters
                                filterSectionTitle("Status")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        filterChip("All Status", isSelected: viewModel.selectedRequestStatus == nil) {
                                            viewModel.selectedRequestStatus = nil
                                        }
                                        ForEach(RequestStatus.allCases, id: \.self) { status in
                                            filterChip(status.displayName, isSelected: viewModel.selectedRequestStatus == status) {
                                                viewModel.selectedRequestStatus = status
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                
                                // Request Type Filters
                                filterSectionTitle("Request Type")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        filterChip("All Types", isSelected: viewModel.selectedRequestType == nil) {
                                            viewModel.selectedRequestType = nil
                                        }
                                        ForEach(RequestType.allCases, id: \.self) { type in
                                            filterChip(type.rawValue, isSelected: viewModel.selectedRequestType == type) {
                                                viewModel.selectedRequestType = type
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        // Clear filters footer
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
                
                // Main scrollable list content area
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.selectedSegmentIndex == 0 {
                            // Stock Alerts Segment
                            if viewModel.filteredStockAlerts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bell.slash")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.top, 40)
                                    Text(viewModel.hasActiveFilters ? "No matching alerts found" : "No active stock alerts")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(viewModel.filteredStockAlerts) { alert in
                                    NavigationLink(destination: StockAlertDetailView(alert: alert, viewModel: viewModel)) {
                                        StockAlertCard(alert: alert)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            // Store Requests Segment
                            if viewModel.filteredStoreRequests.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "arrow.left.arrow.right.circle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.top, 40)
                                    Text(viewModel.hasActiveFilters ? "No matching requests found" : "No store transfer requests")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(viewModel.filteredStoreRequests) { request in
                                    NavigationLink(destination: StoreRequestDetailView(request: request)) {
                                        StoreRequestCard(request: request)
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
        .navigationTitle("Alerts and Requests")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .task {
            await viewModel.fetchDynamicStockAlerts()
        }
    }
    
    // MARK: - UI Sub-views for filters
    
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

#Preview {
    NavigationStack {
        InventoryOverviewView()
    }
}
