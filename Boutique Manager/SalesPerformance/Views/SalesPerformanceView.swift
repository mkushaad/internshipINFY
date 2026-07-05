import SwiftUI
import Charts

struct SalesPerformanceView: View {
    @StateObject private var viewModel = SalesPerformanceViewModel()
    @State private var salesTargetViewModel = SalesTargetViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAngle: Double? = nil
    @State private var selectedCategory: ProductCategory? = nil
    
    // Use the logged-in user's assigned store ID
    private var currentStoreID: UUID {
        AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 28) {
                Group {
                    // Week Selector Header
                    HStack {
                        Text("Overview")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.boutiqueDarkBrown)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(viewModel.availableWeeks, id: \.self) { week in
                                Button(action: {
                                    withAnimation {
                                        let startDate = viewModel.startDate(for: week)
                                        let customTarget = salesTargetViewModel.weeklyTarget(for: startDate)
                                        viewModel.selectWeek(week, customWeeklyTarget: customTarget, storeID: currentStoreID)
                                    }
                                }) {
                                    HStack {
                                        Text(week)
                                        if viewModel.selectedWeek == week {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(viewModel.selectedWeek)
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.boutiqueGold.opacity(0.15))
                            .foregroundColor(Color.boutiqueGold)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Section 1 — Weekly Summary Card
                    SummaryMetricCard(summary: viewModel.weeklySummary)
                        .padding(.horizontal)
                    
                    // Section 2 — Sales Trend
                    salesTrendSection
                    
                    performanceComparisonSection
                    
                    // Section 3 — Daily Sales Breakdown
                    dailySalesBreakdownSection
                    
                    // Section 4 — Store KPIs
                    storeKPIsSection
                    
                    // Section 5 — Top Performing Sales Associates
//                    topPerformersSection
                    
                    // Section 6 — Associates Needing Attention
                }
                
                Group {
                    // Section 7 — Sales by Category
                    categorySalesSection
                    
                    // Section 8 — Best Selling Products
                    bestSellersSection
                    
                    // Bottom Button
                    generateReportButton
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color.boutiqueWarmWhite.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Loading Sales Data...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(error)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        let customTarget = salesTargetViewModel.weeklyTarget(for: viewModel.currentWeekStartDate)
                        viewModel.selectWeek(viewModel.selectedWeek, customWeeklyTarget: customTarget, storeID: currentStoreID)
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(Color.boutiqueGold)
                }
            }
            
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.navigationTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.boutiqueDarkBrown)
                    Text(viewModel.navigationSubtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .sheet(item: $selectedCategory) { category in
            CategoryDetailView(category: category, sales: viewModel.saleDisplays.filter { $0.primaryCategory == category })
        }
        .task {
            await salesTargetViewModel.fetchSalesTargets(forStoreID: currentStoreID)
            let customTarget = salesTargetViewModel.weeklyTarget(for: viewModel.currentWeekStartDate)
            viewModel.selectWeek(viewModel.selectedWeek, customWeeklyTarget: customTarget, storeID: currentStoreID)
        }
    }
    
    // MARK: - Section Views
    
    private var salesTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Target vs Actual Sales")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.boutiqueDarkBrown)
            
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 10, height: 10)
                        Text("Target")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.boutiqueGold)
                            .frame(width: 10, height: 10)
                        Text("Actual")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.boutiqueDarkBrown)
                    }
                }
                
                Chart {
                    ForEach(viewModel.salesTrends) { item in
                        LineMark(
                            x: .value("Day", item.day),
                            y: .value("Sales", item.target)
                        )
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .symbol {
                            Circle()
                                .strokeBorder(Color.gray.opacity(0.5), lineWidth: 2)
                                .frame(width: 8, height: 8)
                        }
                        
                        LineMark(
                            x: .value("Day", item.day),
                            y: .value("Sales", item.actual)
                        )
                        .foregroundStyle(Color.boutiqueGold)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .symbol {
                            Circle()
                                .fill(Color.boutiqueGold)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    private var dailySalesBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Sales Breakdown")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.boutiqueDarkBrown)
            
            VStack(spacing: 12) {
                // Table Header
                HStack(spacing: 4) {
                    Text("Day")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Target")
                        .lineLimit(1)
                        .frame(width: 50, alignment: .center)
                    Text("Actual")
                        .lineLimit(1)
                        .frame(width: 50, alignment: .center)
                    Text("Ach. %")
                        .lineLimit(1)
                        .frame(width: 55, alignment: .center)
                    Text("Status")
                        .lineLimit(1)
                        .frame(width: 105, alignment: .trailing)
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
                
                Divider()
                
                // Table Rows
                ForEach(viewModel.dailySalesBreakdown) { row in
                    HStack(spacing: 4) {
                        Text(row.day)
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.boutiqueDarkBrown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(row.target)
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 50, alignment: .center)
                        
                        Text(row.actual)
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.boutiqueDarkBrown)
                            .frame(width: 50, alignment: .center)
                        
                        Text(row.achievementPercentage)
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.boutiqueGold)
                            .frame(width: 55, alignment: .center)
                        
                        Text(row.status.rawValue)
                            .lineLimit(1)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(row.status.color)
                            .clipShape(Capsule())
                            .frame(width: 105, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    
                    if row.id != viewModel.dailySalesBreakdown.last?.id {
                        Divider()
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    private var storeKPIsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Store KPIs")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.boutiqueDarkBrown)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.storeKPIs) { kpi in
                        KPIStatCard(kpi: kpi)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
    
    private var categorySalesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sales by Category")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.boutiqueDarkBrown)
            
            VStack(spacing: 24) {
                Chart {
                    ForEach(viewModel.categorySales) { item in
                        SectorMark(
                            angle: .value("Share", item.percentage),
                            innerRadius: .ratio(0.65),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.color)
                        .annotation(position: .overlay) {
                            Text("\(Int(item.percentage))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .chartAngleSelection(value: $selectedAngle)
                .frame(height: 220)
                .onChange(of: selectedAngle) { new in
                    if let new = new {
                        var cumulative: Double = 0
                        for item in viewModel.categorySales {
                            cumulative += item.percentage
                            if new <= cumulative {
                                selectedCategory = item.category
                                selectedAngle = nil
                                break
                            }
                        }
                    }
                }
                
                // Legend
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(viewModel.categorySales) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.category.rawValue.capitalized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.boutiqueDarkBrown)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = item.category
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
         .padding(.horizontal)
    }
    
    private var bestSellersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Best Sellers")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.boutiqueDarkBrown)
                Spacer()
                NavigationLink(destination: AllSalesView(sales: viewModel.saleDisplays)) {
                    Text("View All")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.boutiqueGold)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.bestSellers) { product in
                    ProductSalesCard(product: product)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var performanceComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Comparison")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.boutiqueDarkBrown)
            
            HStack(spacing: 16) {
                ForEach(viewModel.comparisons) { comp in
                    ComparisonCard(comparison: comp)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var generateReportButton: some View {
        Button(action: {
            // Placeholder action
        }) {
            Text("Generate Weekly Report")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.boutiqueGold)
                .cornerRadius(16)
                .shadow(color: Color.boutiqueGold.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

#Preview {
    NavigationStack {
        SalesPerformanceView()
    }
}

extension ProductCategory: Identifiable {
    public var id: String { self.rawValue }
}

struct CategoryDetailView: View {
    let category: ProductCategory
    let sales: [SaleDisplayData]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Metrics Section
                    HStack(spacing: 16) {
                        let totalUnits = sales.reduce(0) { $0 + $1.totalQuantity }
                        metricCard(title: "Total Quantity Sold", value: "\(totalUnits) Units", icon: "cube.box.fill")
                        
                        let totalRev = sales.reduce(0) { $0 + $1.totalAmount }
                        metricCard(title: "Total Revenue", value: "₹\(formatAmount(totalRev))", icon: "indianrupeesign.circle.fill")
                    }
                    .padding(.horizontal)
                    
                    // Sold Items Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sold Items")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.boutiqueDarkBrown)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(sales) { sale in
                                HStack(spacing: 16) {
                                    Image(systemName: categoryIcon(for: category))
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.boutiqueGold)
                                        .frame(width: 48, height: 48)
                                        .background(Color.boutiqueGold.opacity(0.15))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(category.rawValue.capitalized) Item")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color.boutiqueDarkBrown)
                                        
                                        HStack(spacing: 8) {
                                            Text(sale.saleDate.formatted(date: .abbreviated, time: .shortened))
                                            Text("•")
                                            Text("\(sale.totalQuantity) \(sale.totalQuantity == 1 ? "Unit" : "Units")")
                                        }
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("₹\(formatAmount(sale.totalAmount))")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color.boutiqueDarkBrown)
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical, 24)
            }
            .background(Color.boutiqueWarmWhite.ignoresSafeArea())
            .navigationTitle("\(category.rawValue.capitalized) Sales")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.boutiqueGold)
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
    
    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.boutiqueGold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.boutiqueDarkBrown)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    private func categoryIcon(for category: ProductCategory) -> String {
        switch category {
        case .apparel: return "tshirt.fill"
        case .footwear: return "shoe.fill"
        case .accessories: return "eyeglasses"
        case .jewelry: return "sparkles"
        case .cosmetics: return "wand.and.stars"
        case .bag: return "bag.fill"
        case .perfume: return "drop.fill"
        case .wallet: return "creditcard.fill"
        case .ring: return "diamond.fill"
        default: return "tag.fill"
        }
    }
}

enum SalesSortOption: String, CaseIterable, Identifiable {
    case date = "Date"
    case amount = "Amount"
    case quantity = "Quantity"
    var id: String { self.rawValue }
}

struct AllSalesView: View {
    let sales: [SaleDisplayData]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: ProductCategory? = nil
    @State private var sortOption: SalesSortOption = .date
    @State private var isAscending: Bool = false // default to recent most (descending date)
    
    var filteredAndSortedSales: [SaleDisplayData] {
        var result = sales
        
        if let category = selectedCategory {
            result = result.filter { $0.primaryCategory == category }
        }
        
        result.sort { sale1, sale2 in
            switch sortOption {
            case .date:
                return isAscending ? (sale1.saleDate < sale2.saleDate) : (sale1.saleDate > sale2.saleDate)
            case .amount:
                return isAscending ? (sale1.totalAmount < sale2.totalAmount) : (sale1.totalAmount > sale2.totalAmount)
            case .quantity:
                return isAscending ? (sale1.totalQuantity < sale2.totalQuantity) : (sale1.totalQuantity > sale2.totalQuantity)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter and Sort Bar
                VStack(spacing: 16) {
                    // Category Filter ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            
                            ForEach([ProductCategory.apparel, .footwear, .jewelry, .accessories, .cosmetics, .bag, .perfume, .wallet, .ring], id: \.self) { cat in
                                FilterChip(title: cat.rawValue.capitalized, isSelected: selectedCategory == cat) {
                                    selectedCategory = cat
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Sort Options & Order
                    HStack(spacing: 12) {
                        Text("Sort by:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.boutiqueDarkBrown)
                        
                        // Sort Option Picker / Menu
                        Menu {
                            ForEach(SalesSortOption.allCases) { option in
                                Button(option.rawValue) {
                                    sortOption = option
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(sortOption.rawValue)
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.boutiqueGold.opacity(0.15))
                            .foregroundColor(Color.boutiqueGold)
                            .cornerRadius(12)
                        }
                        
                        Spacer()
                        
                        // Ascending / Descending Toggle Button
                        Button(action: {
                            isAscending.toggle()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 12, weight: .bold))
                                Text(isAscending ? "Ascending" : "Descending")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.boutiqueGold.opacity(0.15))
                            .foregroundColor(Color.boutiqueGold)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                
                // Sales List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAndSortedSales) { sale in
                            SaleDetailRow(sale: sale)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color.boutiqueWarmWhite.ignoresSafeArea())
            .navigationTitle("All Sales")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(Color.boutiqueGold)
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.boutiqueGold : Color.white)
                .foregroundColor(isSelected ? .white : Color.boutiqueDarkBrown)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.boutiqueGold : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct SaleDetailRow: View {
    let sale: SaleDisplayData
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: categoryIcon)
                .font(.system(size: 24))
                .foregroundColor(Color.boutiqueGold)
                .frame(width: 48, height: 48)
                .background(Color.boutiqueGold.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(sale.primaryCategory?.rawValue.capitalized ?? "General") Item")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.boutiqueDarkBrown)
                
                HStack(spacing: 8) {
                    Text(sale.saleDate.formatted(date: .abbreviated, time: .shortened))
                    Text("•")
                    Text("\(sale.totalQuantity) \(sale.totalQuantity == 1 ? "Unit" : "Units")")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("₹\(formatAmount(sale.totalAmount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.boutiqueDarkBrown)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var categoryIcon: String {
        switch sale.primaryCategory {
        case .apparel: return "tshirt.fill"
        case .footwear: return "shoe.fill"
        case .accessories: return "eyeglasses"
        case .jewelry: return "sparkles"
        case .cosmetics: return "wand.and.stars"
        case .bag: return "bag.fill"
        case .perfume: return "drop.fill"
        case .wallet: return "creditcard.fill"
        case .ring: return "diamond.fill"
        default: return "bag.fill"
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
