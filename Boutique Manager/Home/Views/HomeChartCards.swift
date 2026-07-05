import SwiftUI
import Charts
struct DailySalesChartCard: View {
    let weeklyTrends: [DailySalesTrend]
    let monthlyTrends: [DailySalesTrend]
    
    @State private var selectedSegment: String = "Daily"
    
    private var activeTrends: [DailySalesTrend] {
        selectedSegment == "Daily" ? weeklyTrends : monthlyTrends
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // Header
            HStack {
                Label("Daily Sales", systemImage: "chart.bar.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Picker("Period", selection: $selectedSegment) {
                    Text("Daily").tag("Daily")
                    Text("Weekly").tag("Weekly")
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            
            // Chart
            Chart {
                ForEach(activeTrends) { item in
                    if !item.isFuture {
                        LineMark(
                            x: .value("Day", item.day),
                            y: .value("Sales", item.actual)
                        )
                        .foregroundStyle(Color.themeAccent)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        
                        PointMark(
                            x: .value("Day", item.day),
                            y: .value("Sales", item.actual)
                        )
                        .foregroundStyle(Color.themeAccent)
                        .symbolSize(40)
                    }
                    
                    // Invisible mark to guarantee the X-axis domain is preserved
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Sales", 0)
                    )
                    .foregroundStyle(.clear)
                }
            }
            .frame(maxHeight: .infinity)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                    AxisValueLabel() {
                        if let count = value.as(Double.self) {
                            Text("\(count, specifier: "%.1f")L")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel() {
                        if let day = value.as(String.self) {
                            if selectedSegment == "Daily" {
                                Text(day.prefix(1))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                // For monthly, only show label if it's 1st, 5th, 10th, etc.
                                // Our labels are strings like "1", "5", etc. But some might be empty.
                                Text(day)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .padding(20)
        .background(Color.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}
struct SalesByCategoryCard: View {
    let categorySales: [HomeCategorySaleData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // Header
            HStack {
                Label("Sales by Category", systemImage: "chart.pie.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            if categorySales.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.largeTitle)
                        .foregroundStyle(Color.themeSubtle)
                    Text("No category data yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 20) {
                    // Pie Chart
                    Chart {
                        ForEach(categorySales) { item in
                            SectorMark(
                                angle: .value("Share", item.percentage),
                                innerRadius: .ratio(0.65),
                                angularInset: 1.5
                            )
                            .foregroundStyle(item.color.gradient)
                            .cornerRadius(4)
                        }
                    }
                    .frame(width: 110, height: 110)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categorySales.prefix(3)) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                Text(item.category.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .padding(20)
        .background(Color.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}
