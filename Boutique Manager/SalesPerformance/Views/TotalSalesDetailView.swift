import SwiftUI
import Charts

struct TotalSalesDetailView: View {
    @StateObject private var viewModel = SalesPerformanceViewModel()
    @State private var salesTargetViewModel = SalesTargetViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: String = "This Week"
    private let filters = ["Yesterday", "Today", "This Week"]
    
    private var activePeakHours: [PeakHourData] {
        switch selectedFilter {
        case "Yesterday": return viewModel.peakHoursYesterday
        case "Today": return viewModel.peakHoursToday
        default: return viewModel.peakHoursThisWeek
        }
    }
    
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
                    Text("Total Sales Overview")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.boutiqueDarkBrown)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Peak Hours Area Chart
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Peak Hours Analysis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.boutiqueDarkBrown)
                        Spacer()
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(filters, id: \.self) { filter in
                                Text(filter).tag(filter)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(Color.boutiqueGold)
                    }
                    .padding(.horizontal)
                    
                    VStack {
                        Chart {
                            ForEach(activePeakHours) { item in
                                AreaMark(
                                    x: .value("Time of Day", item.period),
                                    y: .value("Revenue", item.revenue)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.boutiqueGold.opacity(0.4), Color.boutiqueGold.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.monotone)
                                
                                LineMark(
                                    x: .value("Time of Day", item.period),
                                    y: .value("Revenue", item.revenue)
                                )
                                .foregroundStyle(Color.boutiqueGold)
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                .interpolationMethod(.monotone)
                                .symbol {
                                    Circle()
                                        .fill(Color.white)
                                        .strokeBorder(Color.boutiqueGold, lineWidth: 2)
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        .frame(height: 220)
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
                    .padding(.horizontal)
                }
                
                // KPIs
                VStack(alignment: .leading, spacing: 16) {
                    Text("Store Metrics")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.boutiqueDarkBrown)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.storeKPIs) { kpi in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.boutiqueGold.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: kpi.iconName)
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.boutiqueGold)
                                    }
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(kpi.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(kpi.value)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color.boutiqueDarkBrown)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
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
