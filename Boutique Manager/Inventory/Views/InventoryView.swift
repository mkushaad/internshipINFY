import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var showNotificationSheet = false
    @State private var isSettingsPresented = false
    @State private var selectedSegment: InventorySegment = .alerts
    
    enum InventorySegment: String, CaseIterable, Identifiable {
        case alerts = "Stock Alerts"
        case requests = "Stock Requests"
        
        var id: String { self.rawValue }
    }
    
    // Grid layout columns for summary KPI cards (2x2 grid)
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color matching standard theme
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                        VStack(spacing: 20) {
                            
                            // Section 1 — Inventory Summary KPI cards (with interactive navigation links for Products and Discrepancies)
                            LazyVGrid(columns: columns, spacing: 16) {
                                NavigationLink(destination: StoreInventoryView()) {
                                    InventorySummaryCard(
                                        title: "Products",
                                        value: "\(viewModel.summary.totalProducts)",
                                        iconName: "shippingbox.fill",
                                        iconColor: .themeAccent
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                InventorySummaryCard(
                                    title: "Low Stock",
                                    value: "\(viewModel.summary.lowStockCount)",
                                    iconName: "exclamationmark.triangle.fill",
                                    iconColor: .red
                                )
                                
                                InventorySummaryCard(
                                    title: "Stock Requests",
                                    value: "\(viewModel.summary.stockRequestsCount)",
                                    iconName: "arrow.left.arrow.right",
                                    iconColor: .blue
                                )
                                
                                NavigationLink(destination: InventoryDiscrepanciesView()) {
                                    InventorySummaryCard(
                                        title: "Discrepancies",
                                        value: "\(viewModel.summary.discrepancyCount)",
                                        iconName: "exclamationmark.arrow.triangle.2.circlepath",
                                        iconColor: .orange
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Section 2 & 3 — Section Header (HIG compliant: Title + View All next to it)
                            HStack(alignment: .firstTextBaseline) {
                                Text("Alerts and Requests")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.themeText)
                                
                                Spacer()
                                
                                NavigationLink(destination: InventoryOverviewView()) {
                                    Text("View All")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.themeAccent)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 4)
                            .padding(.top, 8)
                            
                            // Combined Preview Card
                            VStack(alignment: .leading, spacing: 0) {
                                // Segmented Control (Placed at the top of the card)
                                Picker("Inventory Section", selection: $selectedSegment) {
                                    ForEach(InventorySegment.allCases) { segment in
                                        Text(segment.rawValue).tag(segment)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 16)
                                
                                // List content based on selection
                                VStack(spacing: 0) {
                                    if selectedSegment == .alerts {
                                        if viewModel.stockAlerts.isEmpty {
                                            Text("No active stock alerts")
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                                .padding(.vertical, 24)
                                        } else {
                                            ForEach(Array(viewModel.stockAlerts.prefix(3))) { alert in
                                                StockAlertRow(alert: alert)
                                                if alert.id != viewModel.stockAlerts.prefix(3).last?.id {
                                                    Divider()
                                                        .background(Color.themeText.opacity(0.08))
                                                }
                                            }
                                        }
                                    } else {
                                        if viewModel.stockRequests.isEmpty {
                                            Text("No active stock requests")
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                                .padding(.vertical, 24)
                                        } else {
                                            ForEach(Array(viewModel.stockRequests.prefix(3))) { request in
                                                StockRequestRow(request: request)
                                                if request.id != viewModel.stockRequests.prefix(3).last?.id {
                                                    Divider()
                                                        .background(Color.themeText.opacity(0.08))
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                                .frame(minHeight: 180, alignment: .top) // Stable height during transition
                            }
                            .background(Color.themeCard)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
                            
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                    .redacted(reason: viewModel.isLoading ? .placeholder : [])
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Notification button with number badge count circle
                        Button(action: {
                            showNotificationSheet = true
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .font(.system(size: 18))
                                    .foregroundColor(.themeAccent)

                                if viewModel.hasUnreadNotifications && !viewModel.unreadNotifications.isEmpty {
                                    Text("\(viewModel.unreadNotifications.count)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 15, height: 15)
                                        .background(Circle().fill(Color.red))
                                        .offset(x: 8, y: -6)
                                }
                            }
                        }
                        
                        // Refresh button
                        Button(action: {
                            Task {
                                await viewModel.refresh()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.themeAccent)
                        }
                        
                        // Settings Profile Icon
                        Button(action: {
                            isSettingsPresented = true
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.themeText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showNotificationSheet) {
                InventoryNotificationsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
        }
        .preferredColorScheme(.light)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await viewModel.fetchLiveSummary()
        }
    }
}

#Preview {
    InventoryView()
}
