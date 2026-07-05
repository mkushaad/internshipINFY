//
//  HomeView.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import Foundation
import SwiftUI
internal import Combine
import Supabase

@MainActor
struct HomeCategorySaleData: Identifiable {
    let id = UUID()
    let category: ProductCategory
    let percentage: Double
    let color: Color
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isSettingsPresented = false
    @Published var targetPercentage: Int = 0
    @Published var targetAmount: Double = 8500000
    @Published var totalAchieved: Double = 0
    @Published var storeLocation: String = "Loading..."
    @Published var storeFlag: String = "🇺🇸"
    @Published var topPerformerName: String? = nil
    @Published var topPerformerSales: Double = 0
    @Published var topPerformerProgress: Double = 0
    @Published var recentSales: [RecentSaleItem] = []
    @Published var weeklyTrends: [DailySalesTrend] = []
    @Published var monthlyTrends: [DailySalesTrend] = []
    @Published var categorySales: [HomeCategorySaleData] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var hasUnassignedAppointments = false
    
    // We fetch this from the database now
    // private let weeklyTargetAmount: Double = 8500000
    func fetchDashboardData(forStoreID storeID: UUID) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let now = Date()
            var calendar = Calendar.current
            calendar.firstWeekday = 2 // Monday
            
            let weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            let startOfWeek = calendar.date(from: weekComponents) ?? now
            
            let monthComponents = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: monthComponents) ?? now
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            let startString = formatter.string(from: startOfMonth)
            let endString = formatter.string(from: endOfMonth)
            
            // 0. Fetch Sales Target (Monthly)
            var fetchedMonthlyTarget: Double = 0 // Removed mock fallback
            if let targets: [StoreSalesTarget] = try? await SupabaseService.shared.client
                .from("StoreSalesTarget")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .execute()
                .value, !targets.isEmpty {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let monthStartStr = dateFormatter.string(from: startOfMonth)
                
                let activeTarget = targets.first { target in
                    if let start = target.startDate, let end = target.endDate {
                        return start <= monthStartStr && end >= monthStartStr
                    }
                    return target.isActive ?? false
                } ?? targets.first!
                
                fetchedMonthlyTarget = activeTarget.targetAmount
            }
            
            // Update view model on main thread
            self.targetAmount = fetchedMonthlyTarget
            
            // 1. Fetch Sales for the current week
            let fetchedSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .gte("salesDate", value: startString)
                .lt("salesDate", value: endString)
                .execute()
                .value
            
            let totalSales = fetchedSales.reduce(0) { $0 + $1.totalAmount }
            self.totalAchieved = totalSales
            self.targetPercentage = Int((totalSales / fetchedMonthlyTarget) * 100)
            
            // Compute daily trends from fetched sales (uses only current week's dates from startOfWeek)
            let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let dailyTarget = fetchedMonthlyTarget / 30.0 / 100000.0 // per day in lakhs (approximate)
            var trends: [DailySalesTrend] = []
            
            let startOfToday = calendar.startOfDay(for: now)
            
            for i in 0..<7 {
                let currentDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? startOfWeek
                let daySales = fetchedSales
                    .filter { calendar.isDate($0.saleDate, inSameDayAs: currentDate) }
                    .reduce(0) { $0 + $1.totalAmount }
                let actualLakhs = daySales / 100000.0
                let isFuture = calendar.startOfDay(for: currentDate) > startOfToday
                trends.append(DailySalesTrend(day: dayLabels[i], target: dailyTarget, actual: actualLakhs, isFuture: isFuture))
            }
            self.weeklyTrends = trends
            
            // Compute monthly (now Weekly) trends
            var mTrends: [DailySalesTrend] = []
            let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
            let weeklyTargetAmount = (fetchedMonthlyTarget / 4.0) / 100000.0
            
            let numWeeks = Int(ceil(Double(daysInMonth) / 7.0))
            for w in 0..<numWeeks {
                let startDayOffset = w * 7
                let endDayOffset = min((w + 1) * 7, daysInMonth)
                
                var weekSalesTotal: Double = 0
                var anyPastDaysInWeek = false
                
                for i in startDayOffset..<endDayOffset {
                    let currentDate = calendar.date(byAdding: .day, value: i, to: startOfMonth) ?? startOfMonth
                    let daySales = fetchedSales
                        .filter { calendar.isDate($0.saleDate, inSameDayAs: currentDate) }
                        .reduce(0) { $0 + $1.totalAmount }
                    weekSalesTotal += daySales
                    
                    if calendar.startOfDay(for: currentDate) <= startOfToday {
                        anyPastDaysInWeek = true
                    }
                }
                
                let actualLakhs = weekSalesTotal / 100000.0
                let isFuture = !anyPastDaysInWeek
                mTrends.append(DailySalesTrend(day: "W\(w + 1)", target: weeklyTargetAmount, actual: actualLakhs, isFuture: isFuture))
            }
            self.monthlyTrends = mTrends
            
            // 1.2 Fetch Category Data for the Week
            let allSaleIDs = fetchedSales.map { $0.id.uuidString }
            if !allSaleIDs.isEmpty {
                let items: [SalesItem] = try await SupabaseService.shared.client
                    .from("SalesItem")
                    .select()
                    .in("saleID", values: allSaleIDs)
                    .execute()
                    .value
                
                let productIDs = Set(items.map { $0.productID.uuidString })
                if !productIDs.isEmpty {
                    let products: [Product] = try await SupabaseService.shared.client
                        .from("Product")
                        .select()
                        .in("id", values: Array(productIDs))
                        .execute()
                        .value
                    
                    var categoryTotals: [ProductCategory: Double] = [:]
                    var totalVolume: Double = 0
                    
                    for item in items {
                        if let product = products.first(where: { $0.id == item.productID }) {
                            categoryTotals[product.category, default: 0] += item.subTotal
                            totalVolume += item.subTotal
                        }
                    }
                    
                    if totalVolume > 0 {
                        let sortedCats = categoryTotals.sorted { $0.value > $1.value }
                        var newCats: [HomeCategorySaleData] = []
                        let colors: [Color] = [.themeAccent, .themeText, .themeSubtle, .gray, .themeSuccess, .blue]
                        for (i, cat) in sortedCats.enumerated() {
                            let pct = (cat.value / totalVolume) * 100.0
                            let color = i < colors.count ? colors[i] : .black
                            newCats.append(HomeCategorySaleData(category: cat.key, percentage: pct, color: color))
                        }
                        self.categorySales = newCats
                    }
                }
            } else {
                self.categorySales = []
            }
            
            // 1.5 Fetch Store Details
            do {
                struct StoreLocationData: Codable {
                    let location: String?
                    let region: String?
                }
                
                let store: StoreLocationData = try await SupabaseService.shared.client
                    .from("Store")
                    .select()
                    .eq("id", value: storeID.uuidString)
                    .single()
                    .execute()
                    .value
                
                self.storeLocation = store.location ?? "Unknown Location"
                
                let loc = (store.location ?? "").lowercased()
                let reg = (store.region ?? "").lowercased()
                
                if loc.contains("mumbai") || loc.contains("delhi") || loc.contains("pune") || loc.contains("chennai") || loc.contains("jaipur") || loc.contains("bangalore") || reg.contains("india") {
                    self.storeFlag = "🇮🇳"
                } else if reg.contains("northamerica") || loc.contains("cupertino") || loc.contains("new york") || loc.contains("san francisco") {
                    self.storeFlag = "🇺🇸"
                } else if reg.contains("europe") || loc.contains("london") || loc.contains("paris") {
                    self.storeFlag = "🇪🇺"
                } else if reg.contains("asiapacific") {
                    self.storeFlag = "🌏"
                } else if reg.contains("latinamerica") {
                    self.storeFlag = "🌎"
                } else if reg.contains("middleeast") || loc.contains("dubai") {
                    self.storeFlag = "🌍"
                } else {
                    self.storeFlag = "🏳️"
                }
            } catch {
                self.storeLocation = "Unknown Location"
                self.storeFlag = "🏳️"
                print("Failed to fetch store details: \(error)")
            }
            
            // 2. Top Performer
            var associateSales: [UUID: Double] = [:]
            for sale in fetchedSales {
                associateSales[sale.salesAssociateID, default: 0] += sale.totalAmount
            }
            
            if let topAssociateID = associateSales.max(by: { $0.value < $1.value })?.key {
                let salesAmount = associateSales[topAssociateID] ?? 0
                self.topPerformerSales = salesAmount
                self.topPerformerProgress = min(salesAmount / 2000000.0, 1.0)
                
                // Fetch User exactly
                do {
                    let user: User = try await SupabaseService.shared.client
                        .from("User")
                        .select()
                        .eq("id", value: topAssociateID)
                        .single()
                        .execute()
                        .value
                    
                    self.topPerformerName = "\(user.firstName) \(user.lastName)"
                } catch {
                    self.topPerformerName = "Unknown Associate"
                }
            } else {
                self.topPerformerName = nil
                self.topPerformerSales = 0
                self.topPerformerProgress = 0
            }
            
            // 3. Recent Sales (Top 3 across all time, typically means today/yesterday)
            let recentFetchedSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .order("salesDate", ascending: false)
                .limit(3)
                .execute()
                .value
            
            if !recentFetchedSales.isEmpty {
                let saleIDs = recentFetchedSales.map { $0.id.uuidString }
                let items: [SalesItem] = try await SupabaseService.shared.client
                    .from("SalesItem")
                    .select()
                    .in("saleID", values: saleIDs)
                    .execute()
                    .value
                
                let productIDs = Set(items.map { $0.productID.uuidString })
                var fetchedProducts: [Product] = []
                if !productIDs.isEmpty {
                    fetchedProducts = try await SupabaseService.shared.client
                        .from("Product")
                        .select()
                        .in("id", values: Array(productIDs))
                        .execute()
                        .value
                }
                
                let relFormatter = RelativeDateTimeFormatter()
                relFormatter.unitsStyle = .abbreviated
                
                var newRecentSales: [RecentSaleItem] = []
                
                for sale in recentFetchedSales {
                    if let item = items.first(where: { $0.saleID == sale.id }),
                       let product = fetchedProducts.first(where: { $0.id == item.productID }) {
                        
                        let saleDate = sale.saleDate
                        
                        newRecentSales.append(RecentSaleItem(
                            name: product.name,
                            category: product.category.rawValue.capitalized,
                            timeAgo: relFormatter.localizedString(for: saleDate, relativeTo: now),
                            price: sale.totalAmount
                        ))
                    }
                }
                self.recentSales = newRecentSales
            } else {
                self.recentSales = []
            }
            
            // 4. Check for Unassigned Appointments Today & Tomorrow
            let todayStart = calendar.startOfDay(for: now)
            guard let twoDaysLater = calendar.date(byAdding: .day, value: 2, to: todayStart) else { return }
            
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
            
            let unassignedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .is("salesAssociateID", value: nil)
                .gte("date", value: isoFormatter.string(from: todayStart))
                .lt("date", value: isoFormatter.string(from: twoDaysLater))
                .limit(1)
                .execute()
                .value
            
            self.hasUnassignedAppointments = !unassignedAppts.isEmpty
            
        } catch {
            print("Failed to fetch dashboard data: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        self.isLoading = false
    }
}

struct HomeView: View {
    @State private var showSettings = false
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var currentCarouselIndex = 0
    let carouselTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    // Greeting based on time of day
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    // Short date for subtitle — uppercase like screenshot
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date()).uppercased()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // ── Greeting ──
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting)
                            .font(.system(.largeTitle, design: .serif))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.themeText)
                        Text(formattedDate)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .tracking(1.2)
                    }
                    .padding(.horizontal)
                    
                    // ── Swipable Hero Section ──
                    TabView(selection: $currentCarouselIndex) {
                        // Card 1
                        NavigationLink(destination: TotalSalesDetailView()) {
                            SalesTargetCard(
                                totalAchieved: viewModel.totalAchieved,
                                targetAmount: viewModel.targetAmount,
                                location: viewModel.storeLocation,
                                flag: viewModel.storeFlag
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 36)
                        }
                        .tag(0)
                        
                        // Card 2
                        NavigationLink(destination: DailySalesDetailView()) {
                            DailySalesChartCard(
                                weeklyTrends: viewModel.weeklyTrends,
                                monthlyTrends: viewModel.monthlyTrends
                            )
                                .padding(.horizontal)
                                .padding(.bottom, 36)
                        }
                        .tag(1)
                        
                        // Card 3
                        NavigationLink(destination: CategorySalesDetailView()) {
                            SalesByCategoryCard(categorySales: viewModel.categorySales)
                                .padding(.horizontal)
                                .padding(.bottom, 36)
                        }
                        .tag(2)
                    }
                    .frame(height: 270)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .onReceive(carouselTimer) { _ in
                        withAnimation {
                            currentCarouselIndex = (currentCarouselIndex + 1) % 3
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // ── Manage Appointments ──
                    NavigationLink(destination: StoreAppointmentsView(initialTab: viewModel.hasUnassignedAppointments ? 3 : 0)
                        .onDisappear {
                            Task {
                                let storeID = AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
                                await viewModel.fetchDashboardData(forStoreID: storeID)
                            }
                        }
                    ) {
                        HStack(spacing: 14) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title3)
                                .foregroundColor(.themeAccent)
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.themeAccent.opacity(0.10))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Manage Appointments")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                if viewModel.hasUnassignedAppointments {
                                    Text("Needs Attention")
                                        .font(.subheadline)
                                        .foregroundStyle(.red)
                                } else {
                                    Text("View Schedule")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if viewModel.hasUnassignedAppointments {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.themeCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    // ── 2-Column Grid (Middle Section) ──
                    HStack(spacing: 16) {
                        TopPerformerCard(
                            topPerformerName: viewModel.topPerformerName,
                            topPerformerSales: viewModel.topPerformerSales,
                            progress: CGFloat(viewModel.topPerformerProgress)
                        )
                        
                        VIPEventCard()
                    }
                    .padding(.horizontal)
                    
                    // ── Recent Sales ──
                    RecentSalesSection(items: viewModel.recentSales)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                .padding(.bottom, 120) // clear the tab bar
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.isSettingsPresented = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.themeText)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isSettingsPresented) {
                SettingsView()
            }
        }
        .task {
            let storeID = AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
            await viewModel.fetchDashboardData(forStoreID: storeID)
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    HomeView()
}
