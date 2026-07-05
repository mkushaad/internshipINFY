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
    
    // Section 2: Sales Trend
    @Published var salesTrends: [DailySalesTrend] = []
    
    // Section 3: Daily Sales Breakdown
    @Published var dailySalesBreakdown: [DailySalesBreakdown] = []
    
    // Section 4: Store KPIs
    @Published var storeKPIs: [StoreKPI] = []
    
    // Section 5: Top Performing Sales Associates
    @Published var topPerformers: [SalesAssociatePerformance] = []
    
    // Section 6: Associates Needing Attention
    @Published var needingAttention: [AssociateNeedingAttention] = []
    
    // Section 7: Sales by Category
    @Published var categorySales: [CategorySalesShare] = []
    
    // Section 8: Best Selling Products
    @Published var bestSellers: [BestSellingProduct] = []
    
    // Section 9: Missed Opportunities
    @Published var missedOpportunities: [MissedOpportunity] = [
        MissedOpportunity(title: "Out of Stock", subtitle: "12 lost sales", estimatedRevenueLoss: "₹14.5L", iconName: "exclamationmark.triangle.fill"),
        MissedOpportunity(title: "Customer Left Without Purchase", subtitle: "8 lost sales", estimatedRevenueLoss: "₹8.2L", iconName: "person.fill.xmark"),
        MissedOpportunity(title: "Transfer Pending", subtitle: "6 pending", estimatedRevenueLoss: "₹4.5L", iconName: "arrow.left.arrow.right")
    ]
    
    // Section 10: AI Recommendations
    @Published var aiRecommendations: [AIRecommendation] = [
        AIRecommendation(title: "Move 4 Rolex Daytonas from Dubai Boutique", impactText: "Potential Revenue +₹12L", iconName: "sparkles"),
        AIRecommendation(title: "Increase Leather Goods Display", impactText: "Potential Revenue +₹8.5L", iconName: "sparkles"),
        AIRecommendation(title: "Promote VIP Follow-up Campaign", impactText: "Expected Conversion +9%", iconName: "sparkles")
    ]
    
    // Section 11: Performance Comparison
    @Published var comparisons: [PerformanceComparison] = []
    
    // Section 12: Pending Actions
    @Published var pendingActions: [PendingActionItem] = [
        PendingActionItem(title: "Approve Stock Transfer", iconName: "checkmark.circle.fill"),
        PendingActionItem(title: "Review Low Stock Alerts", iconName: "bell.fill"),
        PendingActionItem(title: "Assign VIP Client", iconName: "person.2.fill"),
        PendingActionItem(title: "Approve Inventory Discrepancy", iconName: "doc.text.fill")
    ]
    
    // Fetched Sales Data
    @Published var mockSales: [Sale] = []
    @Published var mockSalesItems: [SalesItem] = []
    @Published var mockProducts: [Product] = []
    
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
    
    var detailedSalesList: [DetailedSaleItem] {
        return mockSalesItems.compactMap { item in
            guard let sale = mockSales.first(where: { $0.id == item.saleID }),
                  let product = mockProducts.first(where: { $0.id == item.productID }) else {
                return nil
            }
            
            let iconName: String
            switch product.category {
            case .bag: iconName = "handbag.fill"
            case .perfume: iconName = "drop.fill"
            case .wallet: iconName = "creditcard.fill"
            case .ring: iconName = "sparkles"
            default: iconName = "cube.box.fill"
            }
            
            return DetailedSaleItem(
                productName: product.name,
                category: product.category,
                date: sale.saleDate,
                units: item.quantity,
                amount: item.subTotal,
                iconName: iconName
            )
        }.sorted { $0.date > $1.date }
    }
    
    private func computePeakHours(for datePredicate: (Date) -> Bool) -> [PeakHourData] {
        let relevantSales = mockSales.filter { datePredicate($0.saleDate) }
        var hourRevenue: [Int: Double] = [:]
        let calendar = Calendar.current
        for sale in relevantSales {
            let hour = calendar.component(.hour, from: sale.saleDate)
            hourRevenue[hour, default: 0] += sale.totalAmount
        }
        
        let sortedHours = hourRevenue.keys.sorted()
        return sortedHours.map { hour in
            let amPm = hour < 12 ? "AM" : "PM"
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return PeakHourData(period: "\(displayHour) \(amPm)", revenue: hourRevenue[hour] ?? 0.0)
        }
    }
    
    var peakHoursYesterday: [PeakHourData] {
        let calendar = Calendar.current
        return computePeakHours { calendar.isDateInYesterday($0) }
    }
    
    var peakHoursToday: [PeakHourData] {
        let calendar = Calendar.current
        return computePeakHours { calendar.isDateInToday($0) }
    }
    
    var peakHoursThisWeek: [PeakHourData] {
        return computePeakHours { _ in true } // uses all mockSales currently fetched for the selected week
    }
    
    init() {}
    
    func selectWeek(_ week: String, customWeeklyTarget: Double? = nil, storeID: UUID) {
        selectedWeek = week
        Task {
            await fetchSalesData(forStoreID: storeID, week: week, customWeeklyTarget: customWeeklyTarget)
        }
    }
    
    func fetchSalesData(forStoreID storeID: UUID, week: String, customWeeklyTarget: Double? = nil) async {
        isLoading = true
        errorMessage = nil
        selectedWeek = week
        
        let start = startDate(for: week)
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        navigationSubtitle = "\(week.split(separator: " ").prefix(2).joined(separator: " ")) • \(formatter.string(from: start)) – \(formatter.string(from: end))"
        
        loadMockCards(for: week)
        
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
            }
            
            calculateMetrics(for: week, customWeeklyTarget: customWeeklyTarget, start: start)
            self.isLoading = false
            
        } catch {
            self.errorMessage = "Failed to load sales data: \(error.localizedDescription)"
            self.isLoading = false
            print("Error fetching sales: \(error)")
            // Provide fallback calculations with empty data
            calculateMetrics(for: week, customWeeklyTarget: customWeeklyTarget, start: start)
        }
    }
    
    private func loadMockCards(for week: String) {
        // Keep the mock data for VIP appointments, top performers, etc.
        switch week {
        case "Week 23":
            topPerformers = [
                SalesAssociatePerformance(name: "John", imageName: "person.circle.fill", weeklySales: "₹14.2L", achievementPercentage: 135.0),
                SalesAssociatePerformance(name: "Sophia", imageName: "person.circle.fill", weeklySales: "₹11.5L", achievementPercentage: 118.0),
                SalesAssociatePerformance(name: "Emma", imageName: "person.circle.fill", weeklySales: "₹10.1L", achievementPercentage: 105.0)
            ]
            needingAttention = [
                AssociateNeedingAttention(name: "David", imageName: "person.crop.circle.badge.exclamationmark", achievementPercentage: 68.0, reason: "Improving"),
                AssociateNeedingAttention(name: "Lucas", imageName: "person.crop.circle.badge.exclamationmark", achievementPercentage: 58.0, reason: "Low Client Outreach")
            ]
        case "Week 22":
            topPerformers = [
                SalesAssociatePerformance(name: "Sophia", imageName: "person.circle.fill", weeklySales: "₹15.0L", achievementPercentage: 142.0),
                SalesAssociatePerformance(name: "Emma", imageName: "person.circle.fill", weeklySales: "₹12.2L", achievementPercentage: 125.0),
                SalesAssociatePerformance(name: "David", imageName: "person.circle.fill", weeklySales: "₹9.8L", achievementPercentage: 102.0)
            ]
            needingAttention = [
                AssociateNeedingAttention(name: "Oliver", imageName: "person.crop.circle.badge.exclamationmark", achievementPercentage: 60.0, reason: "Product Knowledge")
            ]
        case "Week 21":
            topPerformers = [
                SalesAssociatePerformance(name: "Emma", imageName: "person.circle.fill", weeklySales: "₹13.1L", achievementPercentage: 138.0),
                SalesAssociatePerformance(name: "John", imageName: "person.circle.fill", weeklySales: "₹11.2L", achievementPercentage: 122.0),
                SalesAssociatePerformance(name: "Lucas", imageName: "person.circle.fill", weeklySales: "₹9.5L", achievementPercentage: 108.0)
            ]
            needingAttention = [
                AssociateNeedingAttention(name: "Sophia", imageName: "person.crop.circle.badge.exclamationmark", achievementPercentage: 72.0, reason: "On Leave Partial Week"),
                AssociateNeedingAttention(name: "David", imageName: "person.crop.circle.badge.exclamationmark", achievementPercentage: 64.0, reason: "Low Add-on Sales")
            ]
        default:
            topPerformers = [
                SalesAssociatePerformance(name: "Emma", imageName: "person.circle.fill", weeklySales: "₹12.4L", achievementPercentage: 143.0),
                SalesAssociatePerformance(name: "John", imageName: "person.circle.fill", weeklySales: "₹10.8L", achievementPercentage: 120.0),
                SalesAssociatePerformance(name: "Sophia", imageName: "person.circle.fill", weeklySales: "₹9.3L", achievementPercentage: 111.0)
            ]
            needingAttention = [
                AssociateNeedingAttention(name: "David", imageName: "person.crop.circle.badge.exclamationmark", achievementPercentage: 62.0, reason: "Training Recommended"),
                AssociateNeedingAttention(name: "Oliver", imageName: "person.crop.circle.badge.exclamationmark", achievementPercentage: 55.0, reason: "Low Conversion Rate")
            ]
        }
    }
    
    private func calculateMetrics(for week: String, customWeeklyTarget: Double?, start: Date) {
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
        
        let categories: [ProductCategory] = [.bag, .perfume, .wallet, .ring, .apparel, .footwear, .jewelry, .accessories, .cosmetics]
        let categoryColors: [ProductCategory: Color] = [
            .bag: Color.boutiqueGold,
            .perfume: Color.purple,
            .wallet: Color.brown,
            .ring: Color.orange,
            .apparel: Color.boutiqueGold,
            .footwear: Color.brown,
            .jewelry: Color.orange,
            .accessories: Color.gray,
            .cosmetics: Color.purple
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
        
        let vipConversion = {
            switch week {
            case "Week 23": return "82%"
            case "Week 22": return "75%"
            case "Week 21": return "79%"
            default: return "78%"
            }
        }()
        
        let unitsSold = mockSalesItems.reduce(0) { $0 + $1.quantity }
        
        self.storeKPIs = [
            StoreKPI(title: "Orders", value: "\(ordersCount)", iconName: "bag.fill"),
            StoreKPI(title: "Average Order Value", value: "₹\(avgString)", iconName: "creditcard.fill"),
            StoreKPI(title: "VIP Conversion", value: vipConversion, iconName: "star.fill"),
            StoreKPI(title: "Units Sold", value: "\(unitsSold)", iconName: "cube.box.fill")
        ]
        
        let todayTotal = mockSales.filter { calendar.isDateInToday($0.saleDate) }.reduce(0) { $0 + $1.totalAmount }
        let yesterdayTotal = mockSales.filter { calendar.isDateInYesterday($0.saleDate) }.reduce(0) { $0 + $1.totalAmount }
        let yesterdayChange = yesterdayTotal > 0 ? ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100.0 : 0
        
        let lastWeekBaseline = totalAchieved / 1.12 // Mock comparison as we only fetched this week
        let lastWeekChange = lastWeekBaseline > 0 ? ((totalAchieved - lastWeekBaseline) / lastWeekBaseline) * 100.0 : 0
        
        let lastMonthBaseline = totalAchieved / 0.98
        let lastMonthChange = lastMonthBaseline > 0 ? ((totalAchieved - lastMonthBaseline) / lastMonthBaseline) * 100.0 : 0
        
        self.comparisons = [
            PerformanceComparison(
                period: "vs Yesterday",
                percentageChange: yesterdayChange,
                percentageString: String(format: "%+d%%", Int(round(yesterdayChange)))
            ),
            PerformanceComparison(
                period: "vs Last Week",
                percentageChange: lastWeekChange,
                percentageString: String(format: "%+d%%", Int(round(lastWeekChange)))
            ),
            PerformanceComparison(
                period: "vs Last Month",
                percentageChange: lastMonthChange,
                percentageString: String(format: "%+d%%", Int(round(lastMonthChange)))
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
                case .bag: iconName = "handbag.fill"
                case .perfume: iconName = "drop.fill"
                case .wallet: iconName = "creditcard.fill"
                case .ring: iconName = "sparkles"
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
    }
}
