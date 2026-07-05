import SwiftUI

struct AssociateSalesHistoryView: View {
    let user: User
    let storeID: UUID
    @State private var viewModel = AssociateSalesHistoryViewModel()
    @State private var selectedTab = 0 // 0 for Last Month, 1 for This Year
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Timeframe", selection: $selectedTab) {
                Text("Last Month").tag(0)
                Text("This Year").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Fetching Sales...")
                Spacer()
            } else {
                let salesList = selectedTab == 0 ? viewModel.lastMonthSales : viewModel.thisYearSales
                let total = selectedTab == 0 ? viewModel.lastMonthTotal : viewModel.thisYearTotal
                
                if salesList.isEmpty {
                    Spacer()
                    Text("No sales found for this period.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Total Card
                            VStack(spacing: 8) {
                                Text("Total Sales")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(String(format: "$%.2f", total)) // In a real app we'd pass currency here
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.themeAccent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.themeCard)
                            .cornerRadius(12)
                            
                            // List of Sales
                            ForEach(salesList) { sale in
                                SaleHistoryRow(sale: sale)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Sales History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchHistory(userID: user.id, storeID: storeID)
        }
    }
}

struct SaleHistoryRow: View {
    let sale: Sale
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Order #\(sale.id.uuidString.prefix(6))")
                    .font(.system(size: 15, weight: .semibold))
                Text(sale.saleDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(String(format: "$%.2f", sale.totalAmount)) // Should use currency symbol in real app
                .font(.system(size: 16, weight: .bold))
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}
