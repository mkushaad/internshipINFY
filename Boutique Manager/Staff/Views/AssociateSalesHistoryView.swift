import SwiftUI
import Charts


struct AssociateSalesHistoryView: View {
    let user: User
    let storeID: UUID
    @State private var viewModel = AssociateSalesHistoryViewModel()
    @State private var selectedTab = 0 // 0 for Last Month, 1 for This Year
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Timeframe", selection: $selectedTab) {
                Text("This Month").tag(0)
                Text("This Year").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Fetching Sales...")
                Spacer()
            } else {
                let salesList = selectedTab == 0 ? viewModel.thisMonthSales : viewModel.thisYearSales
                let total = selectedTab == 0 ? viewModel.thisMonthTotal : viewModel.thisYearTotal
                
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
                            
                            // Chart Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sales Trend")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Chart {
                                    if selectedTab == 0 {
                                        let dailyTotals = Dictionary(grouping: salesList, by: { Calendar.current.startOfDay(for: $0.saleDate) })
                                            .mapValues { $0.reduce(0, { sum, data in sum + data.totalAmount }) }
                                        
                                        ForEach(dailyTotals.keys.sorted(), id: \.self) { date in
                                            LineMark(
                                                x: .value("Date", date, unit: .day),
                                                y: .value("Sales", dailyTotals[date]!)
                                            )
                                            .foregroundStyle(Color.themeAccent)
                                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                            
                                            PointMark(
                                                x: .value("Date", date, unit: .day),
                                                y: .value("Sales", dailyTotals[date]!)
                                            )
                                            .foregroundStyle(Color.themeAccent)
                                            
                                            AreaMark(
                                                x: .value("Date", date, unit: .day),
                                                y: .value("Sales", dailyTotals[date]!)
                                            )
                                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.themeAccent.opacity(0.3), Color.themeAccent.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                                        }
                                    } else {
                                        let monthlyTotals = Dictionary(grouping: salesList, by: { 
                                            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: $0.saleDate))! 
                                        })
                                        .mapValues { $0.reduce(0, { sum, data in sum + data.totalAmount }) }
                                        
                                        ForEach(monthlyTotals.keys.sorted(), id: \.self) { date in
                                            LineMark(
                                                x: .value("Month", date, unit: .month),
                                                y: .value("Sales", monthlyTotals[date]!)
                                            )
                                            .foregroundStyle(Color.themeAccent)
                                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                            
                                            PointMark(
                                                x: .value("Month", date, unit: .month),
                                                y: .value("Sales", monthlyTotals[date]!)
                                            )
                                            .foregroundStyle(Color.themeAccent)
                                            
                                            AreaMark(
                                                x: .value("Month", date, unit: .month),
                                                y: .value("Sales", monthlyTotals[date]!)
                                            )
                                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.themeAccent.opacity(0.3), Color.themeAccent.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                                        }
                                    }
                                }
                                .frame(height: 180)
                                .chartXScale(domain: {
                                    let now = Date()
                                    let calendar = Calendar.current
                                    if selectedTab == 0 {
                                        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                                        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
                                        return startOfMonth...endOfMonth
                                    } else {
                                        var comp = calendar.dateComponents([.year], from: now)
                                        let startOfYear = calendar.date(from: comp)!
                                        comp.year! += 1
                                        comp.day = -1
                                        let endOfYear = calendar.date(from: comp)!
                                        return startOfYear...endOfYear
                                    }
                                }())
                                .chartXAxis {
                                    if selectedTab == 0 {
                                        AxisMarks(values: .stride(by: .day, count: 5)) { value in
                                            AxisValueLabel(format: .dateTime.day())
                                        }
                                    } else {
                                        AxisMarks(values: .stride(by: .month)) { value in
                                            AxisValueLabel(format: .dateTime.month(.narrow))
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.themeCard)
                            .cornerRadius(12)
                            
                            // List of Sales
                            ForEach(salesList) { data in
                                SaleHistoryRow(displayData: data)
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
    let displayData: SaleDisplayData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                let titleText: String = {
                    if let firstProduct = displayData.products.first {
                        if displayData.products.count > 1 {
                            return "\(firstProduct.name) & \(displayData.products.count - 1) more"
                        } else {
                            return firstProduct.name
                        }
                    }
                    return "Order #\(displayData.sale.id.uuidString.prefix(6))"
                }()
                
                Text(titleText)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text(displayData.saleDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(String(format: "$%.2f", displayData.totalAmount)) // Should use currency symbol in real app
                .font(.system(size: 16, weight: .bold))
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}
