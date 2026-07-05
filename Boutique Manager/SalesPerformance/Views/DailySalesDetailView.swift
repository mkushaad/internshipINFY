import SwiftUI
import Charts

struct DailySalesDetailView: View {
    @StateObject private var viewModel = SalesPerformanceViewModel()
    @State private var salesTargetViewModel = SalesTargetViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    
    private var currentStoreID: UUID {
        AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
    }
    
    private func formatValue(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value >= 100000 {
            let lakhs = value / 100000.0
            return lakhs == floor(lakhs) ? "\(Int(lakhs))L" : String(format: "%.1fL", lakhs)
        } else if value >= 1000 {
            let thousands = value / 1000.0
            return thousands == floor(thousands) ? "\(Int(thousands))K" : String(format: "%.1fK", thousands)
        } else {
            return value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Daily Volume")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.boutiqueDarkBrown)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Main Chart
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Daily Sales Volume")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.boutiqueDarkBrown)
                        Spacer()
                        ZStack(alignment: .trailing) {
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .labelsHidden()
                                .colorMultiply(.clear)
                                .onChange(of: selectedDate) { newDate in
                                    Task {
                                        await salesTargetViewModel.fetchSalesTargets(forStoreID: currentStoreID)
                                        let customTarget = salesTargetViewModel.weeklyTarget(for: newDate)
                                        viewModel.selectWeek(viewModel.selectedWeek, customWeeklyTarget: customTarget, storeID: currentStoreID)
                                    }
                                }
                            
                            Image(systemName: "calendar")
                                .font(.system(size: 24))
                                .foregroundColor(Color.boutiqueGold)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack {
                        Chart {
                            ForEach(viewModel.salesTrends) { item in
                                BarMark(
                                    x: .value("Day", item.day),
                                    y: .value("Sales", item.actual)
                                )
                                .foregroundStyle(Color.boutiqueGold.gradient)
                                .cornerRadius(6)
                                .annotation(position: .top) {
                                    Text(formatValue(item.actual))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .frame(height: 250)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisTick()
                                if let number = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text(formatValue(number))
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal)
                
                // Comparisons
                VStack(alignment: .leading, spacing: 16) {
                    Text("Performance Insights")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.boutiqueDarkBrown)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(viewModel.comparisons) { comparison in
                            HStack {
                                Text(comparison.period)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.boutiqueDarkBrown)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: comparison.percentageChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(comparison.percentageString)
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(comparison.percentageChange >= 0 ? .green : .red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(comparison.percentageChange >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color.boutiqueWarmWhite.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(Color.boutiqueGold)
                }
            }
        }
        .task {
            await salesTargetViewModel.fetchSalesTargets(forStoreID: currentStoreID)
            let customTarget = salesTargetViewModel.weeklyTarget(for: viewModel.currentWeekStartDate)
            viewModel.selectWeek(viewModel.selectedWeek, customWeeklyTarget: customTarget, storeID: currentStoreID)
        }
    }
}
