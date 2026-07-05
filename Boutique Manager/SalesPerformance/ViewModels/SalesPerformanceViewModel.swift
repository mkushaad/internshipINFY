import Foundation
import SwiftUI
internal import Combine
import Supabase

@MainActor
class SalesPerformanceViewModel: ObservableObject {
    // Navigation info
    @Published var navigationTitle: String = "Weekly Sales Performance"
    @Published var navigationSubtitle: String = "Week 24 • Jun 16 – Jun 22"
    
    // Week Selection
    @Published var availableWeeks: [String] = ["Week 24 (Current)", "Week 23", "Week 22", "Week 21"]
    @Published var selectedWeek: String = "Week 24 (Current)"
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Section 1: Weekly Summary
    @Published var weeklySummary = WeeklySummary(
        weeklyTarget: "₹0",
        achievedSales: "₹0",
        remainingTarget: "₹0",
        achievementPercentage: 0.0
    )
    
    // Section 11: Performance Comparison
    @Published var comparisons: [PerformanceComparison] = []
    
    // Section 2: Sales Trend
    @Published var salesTrends: [DailySalesTrend] = []
    
    // Section 3: Daily Sales Breakdown
    @Published var dailySalesBreakdown: [DailySalesBreakdown] = []
    
    // Section 4: Store KPIs
    @Published var storeKPIs: [StoreKPI] = []
    

    
    // Section 7: Sales by Category
    @Published var categorySales: [CategorySalesShare] = []
    
    // Section 8: Best Selling Products
    @Published var bestSellers: [BestSellingProduct] = []
    
    // Peak Hours Analysis
    @Published var peakHoursToday: [PeakHourData] = []
    @Published var peakHoursYesterday: [PeakHourData] = []
    @Published var peakHoursThisWeek: [PeakHourData] = []
    
    // All Sales List
    @Published var detailedSalesList: [DetailedSaleItem] = []

    
    // Fetched Sales Data
    @Published var mockSales: [Sale] = []
    @Published var mockSalesItems: [SalesItem] = []
    @Published var mockProducts: [Product] = []
    @Published var mockAssociates: [User] = []
    
    var saleDisplays: [SaleDisplayData] {
        mockSales.map { sale in
            let items = mockSalesItems.filter { $0.saleID == sale.id }
            let productIDs = Set(items.map { $0.productID })
            let prods = mockProducts.filter { productIDs.contains($0.id) }
            return SaleDisplayData(sale: sale, items: items, products: prods)
        }
    }
    
    var currentWeekStartDate: Date {
        startDate(for: selectedWeek)
    }
    
    func startDate(for week: String) -> Date {
        let daysOffset: Int
        switch week {
        case "Week 23": daysOffset = -7
        case "Week 22": daysOffset = -14
        case "Week 21": daysOffset = -21
        default: daysOffset = 0
        }
        let calendar = Calendar.current
        
        // Start of week based on current day offset (assuming week starts on Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        let startOfCurrentWeek = calendar.date(from: components) ?? Date()
        
        return calendar.date(byAdding: .day, value: daysOffset, to: startOfCurrentWeek) ?? Date()
    }
    
    init() {
        // Data is now fetched asynchronously via fetchSalesData
    }
    
    func selectWeek(_ week: String, customWeeklyTarget: Double? = nil, storeID: UUID) {
        selectedWeek = week
        let start = startDate(for: week)
        Task {
            await fetchSalesData(forStoreID: storeID, start: start, weekLabel: week.split(separator: " ").prefix(2).joined(separator: " "), customWeeklyTarget: customWeeklyTarget)
        }
    }
    
    func selectDate(_ date: Date, customWeeklyTarget: Double? = nil, storeID: UUID) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Monday
        let start = calendar.date(from: components) ?? date
        Task {
            await fetchSalesData(forStoreID: storeID, start: start, referenceDate: date, weekLabel: "Custom Week", customWeeklyTarget: customWeeklyTarget)
        }
    }
    
    private func fetchSalesData(forStoreID storeID: UUID, start: Date, referenceDate: Date? = nil, weekLabel: String, customWeeklyTarget: Double? = nil) async {
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        navigationSubtitle = "\(weekLabel) • \(formatter.string(from: start)) – \(formatter.string(from: end))"
        

        do {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            let startString = dateFormatter.string(from: start)
            let endString = dateFormatter.string(from: end)
            
            let fetchedSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .gte("salesDate", value: startString)
                .lte("salesDate", value: endString)
                .execute()
                .value
            
            self.mockSales = fetchedSales
            
            let saleIDs = fetchedSales.map { $0.id.uuidString }
            if !saleIDs.isEmpty {
                let associateIDs = Set(fetchedSales.map { $0.salesAssociateID.uuidString })
                if !associateIDs.isEmpty {
                    let fetchedAssociates: [User] = try await SupabaseService.shared.client
                        .from("User")
                        .select()
                        .in("id", values: Array(associateIDs))
                        .execute()
                        .value
                    self.mockAssociates = fetchedAssociates
                } else {
                    self.mockAssociates = []
                }
                
                let fetchedItems: [SalesItem] = try await SupabaseService.shared.client
                    .from("SalesItem")
                    .select()
                    .in("saleID", values: saleIDs)
                    .execute()
                    .value
                
                self.mockSalesItems = fetchedItems
                
                let productIDs = Set(fetchedItems.map { $0.productID.uuidString })
                if !productIDs.isEmpty {
                    let fetchedProducts: [Product] = try await SupabaseService.shared.client
                        .from("Product")
                        .select()
                        .in("id", values: Array(productIDs))
                        .execute()
                        .value
                    self.mockProducts = fetchedProducts
                } else {
                    self.mockProducts = []
                }
            } else {
                self.mockSalesItems = []
                self.mockProducts = []
                self.mockAssociates = []
            }
            
            calculateMetrics(customWeeklyTarget: customWeeklyTarget, start: start, referenceDate: referenceDate)
            self.isLoading = false
            
        } catch {
            self.errorMessage = "Failed to load sales data: \(error.localizedDescription)"
            self.isLoading = false
            print("Error fetching sales: \(error)")
            // Provide fallback calculations with empty data
            calculateMetrics(customWeeklyTarget: customWeeklyTarget, start: start, referenceDate: referenceDate)
        }
    }
    

    
    private func calculateMetrics(customWeeklyTarget: Double?, start: Date, referenceDate: Date? = nil) {
        var weeklyTargetAmount: Double = customWeeklyTarget ?? 8500000
        var dailyTargets: [Double] = [8.0, 8.0, 8.0, 10.0, 12.0, 20.0, 19.0]
        
        // Scale daily targets based on custom target
        if let customTarget = customWeeklyTarget {
            let scale = customTarget / 8500000
            dailyTargets = dailyTargets.map { $0 * scale }
        }
        
        let totalAchieved = mockSales.reduce(0) { $0 + $1.totalAmount }
        let remaining = max(0, weeklyTargetAmount - totalAchieved)
        let achPercent = weeklyTargetAmount > 0 ? (totalAchieved / weeklyTargetAmount) * 100.0 : 0
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        let achievedString = formatter.string(from: NSNumber(value: totalAchieved)) ?? "0"
        let remainingString = formatter.string(from: NSNumber(value: remaining)) ?? "0"
        let targetString = formatter.string(from: NSNumber(value: weeklyTargetAmount)) ?? "0"
        
        self.weeklySummary = WeeklySummary(
            weeklyTarget: "₹\(targetString)",
            achievedSales: "₹\(achievedString)",
            remainingTarget: "₹\(remainingString)",
            achievementPercentage: achPercent
        )
        
        let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let singleDayLabels = ["M", "T", "W", "T", "F", "S", "S"]
        
        var trends: [DailySalesTrend] = []
        var breakdowns: [DailySalesBreakdown] = []
        
        let calendar = Calendar.current
        for i in 0..<7 {
            let currentDate = calendar.date(byAdding: .day, value: i, to: start) ?? start
            let daySales = mockSales.filter { calendar.isDate($0.saleDate, inSameDayAs: currentDate) }.reduce(0) { $0 + $1.totalAmount }
            
            let actualLakhs = daySales / 100000.0
            let targetLakhs = dailyTargets[i]
            
            trends.append(DailySalesTrend(day: dayLabels[i], target: targetLakhs, actual: actualLakhs))
            
            let percentage = targetLakhs > 0 ? Int((actualLakhs / targetLakhs) * 100) : 0
            let status: DailyStatus
            if percentage >= 110 {
                status = .excellent
            } else if percentage >= 100 {
                status = .targetAchieved
            } else if percentage >= 95 {
                status = .nearTarget
            } else if percentage >= 80 {
                status = .belowTarget
            } else {
                status = .needsAttention
            }
            
            let actualString = String(format: "%.1f", actualLakhs).replacingOccurrences(of: ".0", with: "")
            let targetString = String(format: "%.1f", targetLakhs).replacingOccurrences(of: ".0", with: "")
            
            breakdowns.append(DailySalesBreakdown(
                day: singleDayLabels[i],
                target: "₹\(targetString)L",
                actual: "₹\(actualString)L",
                achievementPercentage: "\(percentage)%",
                status: status
            ))
        }
        self.salesTrends = trends
        self.dailySalesBreakdown = breakdowns
        
        let categories: [ProductCategory] = [.handbags, .fragrances, .accessories, .footware, .general, .jewellery, .watches]
        let categoryColors: [ProductCategory: Color] = [
            .handbags: Color.boutiqueGold,
            .fragrances: Color.purple,
            .accessories: Color.gray,
            .jewellery: Color.orange,
            .watches: Color.blue,
            .footware: Color.brown,
            .general: Color.black
        ]
        
        var catSales: [CategorySalesShare] = []
        for category in categories {
            let catProductIDs = Set(mockProducts.filter { $0.category == category }.map { $0.id })
            let catTotal = mockSalesItems.filter { catProductIDs.contains($0.productID) }.reduce(0) { $0 + $1.subTotal }
            let share = totalAchieved > 0 ? (catTotal / totalAchieved) * 100.0 : 0
            if share > 0 {
                catSales.append(CategorySalesShare(
                    category: category,
                    percentage: share,
                    color: categoryColors[category] ?? .gray
                ))
            }
        }
        self.categorySales = catSales
        
        let ordersCount = mockSales.count
        let avgOrderValue = ordersCount > 0 ? totalAchieved / Double(ordersCount) : 0
        let avgString = formatter.string(from: NSNumber(value: avgOrderValue)) ?? "0"
        
        let unitsSold = mockSalesItems.reduce(0) { $0 + $1.quantity }
        
        let itemsPerOrder = ordersCount > 0 ? Double(unitsSold) / Double(ordersCount) : 0
        let itemsPerOrderString = String(format: "%.1f", itemsPerOrder)
        
        self.storeKPIs = [
            StoreKPI(title: "Orders", value: "\(ordersCount)", iconName: "bag.fill"),
            StoreKPI(title: "Average Order Value", value: "₹\(avgString)", iconName: "creditcard.fill"),
            StoreKPI(title: "Items per Order", value: itemsPerOrderString, iconName: "chart.bar.fill"),
            StoreKPI(title: "Units Sold", value: "\(unitsSold)", iconName: "cube.box.fill")
        ]
        
        let targetDay = referenceDate ?? Date()
        let yesterdayDay = calendar.date(byAdding: .day, value: -1, to: targetDay) ?? targetDay
        let todayTotal = mockSales.filter { calendar.isDate($0.saleDate, inSameDayAs: targetDay) }.reduce(0) { $0 + $1.totalAmount }
        let yesterdayTotal = mockSales.filter { calendar.isDate($0.saleDate, inSameDayAs: yesterdayDay) }.reduce(0) { $0 + $1.totalAmount }
        let yesterdayChange = yesterdayTotal > 0 ? ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100.0 : 0
        
        let lastWeekBaseline = totalAchieved / 1.12 // Mock comparison as we only fetched this week
        let lastWeekChange = lastWeekBaseline > 0 ? ((totalAchieved - lastWeekBaseline) / lastWeekBaseline) * 100.0 : 0
        
        let lastMonthBaseline = totalAchieved / 0.98
        let lastMonthChange = lastMonthBaseline > 0 ? ((totalAchieved - lastMonthBaseline) / lastMonthBaseline) * 100.0 : 0
        
        let isYesterdayAvailable = yesterdayTotal > 0 || todayTotal > 0
        let isLastWeekAvailable = totalAchieved > 0
        let isLastMonthAvailable = totalAchieved > 0
        
        self.comparisons = [
            PerformanceComparison(
                period: "vs Yesterday",
                percentageChange: yesterdayChange,
                percentageString: isYesterdayAvailable ? String(format: "%+d%%", Int(round(yesterdayChange))) : "Data Not Available",
                isDataAvailable: isYesterdayAvailable
            ),
            PerformanceComparison(
                period: "vs Last Week",
                percentageChange: lastWeekChange,
                percentageString: isLastWeekAvailable ? String(format: "%+d%%", Int(round(lastWeekChange))) : "Data Not Available",
                isDataAvailable: isLastWeekAvailable
            ),
            PerformanceComparison(
                period: "vs Last Month",
                percentageChange: lastMonthChange,
                percentageString: isLastMonthAvailable ? String(format: "%+d%%", Int(round(lastMonthChange))) : "Data Not Available",
                isDataAvailable: isLastMonthAvailable
            )
        ]
        
        var productSales: [UUID: (units: Int, revenue: Double)] = [:]
        for item in mockSalesItems {
            let current = productSales[item.productID] ?? (0, 0.0)
            productSales[item.productID] = (current.units + item.quantity, current.revenue + item.subTotal)
        }
        
        let sortedProducts = productSales.sorted { $0.value.revenue > $1.value.revenue }
        var computedBestSellers: [BestSellingProduct] = []
        for (productID, stats) in sortedProducts.prefix(3) {
            if let product = mockProducts.first(where: { $0.id == productID }) {
                let revenueValue = stats.revenue
                let formattedRevenue: String
                if revenueValue >= 10000000 {
                    formattedRevenue = String(format: "₹%.1f Cr", revenueValue / 10000000.0)
                } else if revenueValue >= 100000 {
                    formattedRevenue = String(format: "₹%.1fL", revenueValue / 100000.0)
                } else {
                    formattedRevenue = "₹\(Int(revenueValue))"
                }
                
                let iconName: String
                switch product.category {
                case .handbags: iconName = "handbag.fill"
                case .fragrances: iconName = "drop.fill"
                case .accessories: iconName = "creditcard.fill"
                case .jewellery: iconName = "sparkles"
                case .watches: iconName = "applewatch"
                case .footware: iconName = "shoe.fill"
                default: iconName = "cube.box.fill"
                }
                
                computedBestSellers.append(BestSellingProduct(
                    name: product.name,
                    imageName: iconName,
                    unitsSold: "\(stats.units) Units",
                    revenue: formattedRevenue.replacingOccurrences(of: ".0", with: "")
                ))
            }
        }
        self.bestSellers = computedBestSellers
        

        // Calculate Peak Hours (Morning, Afternoon, Evening)
        var todayMorning: Double = 0, todayAfternoon: Double = 0, todayEvening: Double = 0
        var yesterdayMorning: Double = 0, yesterdayAfternoon: Double = 0, yesterdayEvening: Double = 0
        var weekMorning: Double = 0, weekAfternoon: Double = 0, weekEvening: Double = 0
        
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        
        for sale in mockSales {
            let hour = Calendar.current.component(.hour, from: sale.saleDate)
            
            let isToday = Calendar.current.isDate(sale.saleDate, inSameDayAs: today)
            let isYesterday = Calendar.current.isDate(sale.saleDate, inSameDayAs: yesterday)
            
            if hour >= 6 && hour < 12 {
                weekMorning += sale.totalAmount
                if isToday { todayMorning += sale.totalAmount }
                if isYesterday { yesterdayMorning += sale.totalAmount }
            } else if hour >= 12 && hour < 17 {
                weekAfternoon += sale.totalAmount
                if isToday { todayAfternoon += sale.totalAmount }
                if isYesterday { yesterdayAfternoon += sale.totalAmount }
            } else {
                weekEvening += sale.totalAmount
                if isToday { todayEvening += sale.totalAmount }
                if isYesterday { yesterdayEvening += sale.totalAmount }
            }
        }
        
        self.peakHoursToday = [
            PeakHourData(period: "Morning", revenue: todayMorning, color: .gray),
            PeakHourData(period: "Afternoon", revenue: todayAfternoon, color: .gray),
            PeakHourData(period: "Evening", revenue: todayEvening, color: .gray)
        ]
        
        self.peakHoursYesterday = [
            PeakHourData(period: "Morning", revenue: yesterdayMorning, color: .gray),
            PeakHourData(period: "Afternoon", revenue: yesterdayAfternoon, color: .gray),
            PeakHourData(period: "Evening", revenue: yesterdayEvening, color: .gray)
        ]
        
        self.peakHoursThisWeek = [
            PeakHourData(period: "Morning", revenue: weekMorning, color: .gray),
            PeakHourData(period: "Afternoon", revenue: weekAfternoon, color: .gray),
            PeakHourData(period: "Evening", revenue: weekEvening, color: .gray)
        ]
        
        // Populate Detailed Sales List
        var computedSalesList: [DetailedSaleItem] = []
        for item in mockSalesItems {
            if let sale = mockSales.first(where: { $0.id == item.saleID }),
               let product = mockProducts.first(where: { $0.id == item.productID }) {
                
                let iconName: String
                switch product.category {
                case .handbags: iconName = "handbag.fill"
                case .fragrances: iconName = "drop.fill"
                case .accessories: iconName = "creditcard.fill"
                case .jewellery: iconName = "sparkles"
                case .watches: iconName = "applewatch"
                case .footware: iconName = "shoe.fill"
                default: iconName = "cube.box.fill"
                }
                
                computedSalesList.append(DetailedSaleItem(
                    productName: product.name,
                    category: product.category,
                    date: sale.saleDate,
                    units: item.quantity,
                    amount: item.subTotal,
                    iconName: iconName
                ))
            }
        }
        
        // Sort descending by default
        self.detailedSalesList = computedSalesList.sorted { $0.date > $1.date }
    }
}
