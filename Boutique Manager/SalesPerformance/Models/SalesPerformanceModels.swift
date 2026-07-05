import Foundation
import SwiftUI

// MARK: - Color Palette Extension
extension Color {
    static let boutiqueWarmWhite = Color(red: 248 / 255.0, green: 246 / 255.0, blue: 242 / 255.0)
    static let boutiqueGold = Color(red: 176 / 255.0, green: 138 / 255.0, blue: 69 / 255.0)
    static let boutiqueDarkBrown = Color(red: 45 / 255.0, green: 42 / 255.0, blue: 38 / 255.0)
}

// MARK: - Data Models

struct WeeklySummary: Identifiable {
    let id = UUID()
    let weeklyTarget: String
    let achievedSales: String
    let remainingTarget: String
    let achievementPercentage: Double
}

struct DailySalesTrend: Identifiable {
    let id = UUID()
    let day: String
    let target: Double
    let actual: Double
    var isFuture: Bool = false
}

enum DailyStatus: String, CaseIterable {
    case belowTarget = "Below Target"
    case targetAchieved = "Target Achieved"
    case excellent = "Excellent"
    case nearTarget = "Near Target"
    case needsAttention = "Needs Attention"
    
    var color: Color {
        switch self {
        case .belowTarget:
            return Color.orange
        case .targetAchieved, .excellent:
            return Color.green
        case .nearTarget:
            return Color.orange
        case .needsAttention:
            return Color.red
        }
    }
}

struct DailySalesBreakdown: Identifiable {
    let id = UUID()
    let day: String
    let target: String
    let actual: String
    let achievementPercentage: String
    let status: DailyStatus
}

struct StoreKPI: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let iconName: String
}

struct CategorySalesShare: Identifiable {
    let id = UUID()
    let category: ProductCategory
    let percentage: Double
    let color: Color
}

struct BestSellingProduct: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let unitsSold: String
    let revenue: String
}

struct DetailedSaleItem: Identifiable, Equatable {
    let id = UUID()
    let productName: String
    let category: ProductCategory
    let date: Date
    let units: Int
    let amount: Double
    let iconName: String
}

struct PerformanceComparison: Identifiable {
    let id = UUID()
    let period: String
    let percentageChange: Double
    let percentageString: String
    var isDataAvailable: Bool = true
}

struct PeakHourData: Identifiable {
    let id = UUID()
    let period: String // e.g., "Morning", "Afternoon", "Evening"
    let revenue: Double
    let color: Color
}

struct SalesAssociatePerformance: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let weeklySales: String
    let achievementPercentage: Double
}

struct AssociateNeedingAttention: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let achievementPercentage: Double
    let reason: String
}

struct MissedOpportunity: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let estimatedRevenueLoss: String
    let iconName: String
}

struct AIRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let impactText: String
    let iconName: String
}

struct PendingActionItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
}
