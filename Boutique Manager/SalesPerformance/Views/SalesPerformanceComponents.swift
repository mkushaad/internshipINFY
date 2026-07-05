import SwiftUI

// MARK: - SummaryMetricCard
struct SummaryMetricCard: View {
    let summary: WeeklySummary
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 20) {
                // Circular Progress Indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(summary.achievementPercentage / 100.0))
                        .stroke(Color.boutiqueGold, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(Int(summary.achievementPercentage))%")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(Color.boutiqueDarkBrown)
                        Text("Achieved")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 110, height: 110)
                
                // Metrics Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    metricRow(title: "Weekly Target", value: summary.weeklyTarget, valueColor: Color.boutiqueDarkBrown)
                    metricRow(title: "Achieved Sales", value: summary.achievedSales, valueColor: Color.boutiqueGold)
                    metricRow(title: "Remaining Target", value: summary.remainingTarget, valueColor: .gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func metricRow(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - KPIStatCard
struct KPIStatCard: View {
    let kpi: StoreKPI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: kpi.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(Color.boutiqueGold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(kpi.value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.boutiqueDarkBrown)
                
                Text(kpi.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(width: 160, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - EmployeePerformanceCard
struct EmployeePerformanceCard: View {
    let associate: SalesAssociatePerformance
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: associate.imageName)
                .resizable()
                .frame(width: 44, height: 44)
                .foregroundColor(Color.boutiqueGold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(associate.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.boutiqueDarkBrown)
                    
                    Spacer()
                    
                    Text(associate.weeklySales)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.boutiqueGold)
                }
                
                HStack(spacing: 12) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(Color.boutiqueGold)
                                .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(associate.achievementPercentage / 100.0)), height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(Int(associate.achievementPercentage))%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.boutiqueDarkBrown)
                        .frame(width: 45, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - ProductSalesCard
struct ProductSalesCard: View {
    let product: BestSellingProduct
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.boutiqueWarmWhite)
                    .frame(width: 50, height: 50)
                
                Image(systemName: product.imageName)
                    .font(.system(size: 24))
                    .foregroundColor(Color.boutiqueGold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.boutiqueDarkBrown)
                
                Text(product.unitsSold)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(product.revenue)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.boutiqueGold)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - ComparisonCard
struct ComparisonCard: View {
    let comparison: PerformanceComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(comparison.period)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 4) {
                Image(systemName: comparison.percentageChange >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .foregroundColor(comparison.percentageChange >= 0 ? .green : .red)
                
                Text(comparison.percentageString)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(comparison.percentageChange >= 0 ? .green : .red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - ActionRow
struct ActionRow: View {
    let actionItem: PendingActionItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: actionItem.iconName)
                .font(.system(size: 20))
                .foregroundColor(Color.boutiqueGold)
            
            Text(actionItem.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.boutiqueDarkBrown)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Previews
#Preview {
    ZStack {
        Color.boutiqueWarmWhite.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 16) {
                SummaryMetricCard(summary: WeeklySummary(weeklyTarget: "₹85,00,000", achievedSales: "₹62,30,000", remainingTarget: "₹22,70,000", achievementPercentage: 73.0))
                KPIStatCard(kpi: StoreKPI(title: "Orders", value: "248", iconName: "bag.fill"))
                EmployeePerformanceCard(associate: SalesAssociatePerformance(name: "Emma", imageName: "person.circle.fill", weeklySales: "₹12.4L", achievementPercentage: 143.0))
                ProductSalesCard(product: BestSellingProduct(name: "Rolex Daytona", imageName: "watch.fill", unitsSold: "18 Units", revenue: "₹2.3 Cr"))
                ComparisonCard(comparison: PerformanceComparison(period: "vs Yesterday", percentageChange: 8.0, percentageString: "+8%"))
                ActionRow(actionItem: PendingActionItem(title: "Approve Stock Transfer", iconName: "checkmark.circle.fill"))
            }
            .padding()
        }
    }
}
