import Foundation
import Observation
import Supabase

@Observable
class AssociateSalesHistoryViewModel {
    var lastMonthSales: [Sale] = []
    var thisYearSales: [Sale] = []
    var isLoading = false
    
    var lastMonthTotal: Double {
        lastMonthSales.reduce(0) { $0 + $1.totalAmount }
    }
    
    var thisYearTotal: Double {
        thisYearSales.reduce(0) { $0 + $1.totalAmount }
    }
    
    func fetchHistory(userID: UUID, storeID: UUID) async {
        isLoading = true
        let calendar = Calendar.current
        let now = Date()
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        // This Year calculation
        var yearComponents = calendar.dateComponents([.year], from: now)
        yearComponents.month = 1
        yearComponents.day = 1
        yearComponents.hour = 0
        yearComponents.minute = 0
        yearComponents.second = 0
        guard let startOfYear = calendar.date(from: yearComponents) else { return }
        
        // Last Month calculation
        var monthComponents = calendar.dateComponents([.year, .month], from: now)
        monthComponents.month! -= 1
        guard let startOfLastMonth = calendar.date(from: monthComponents),
              let endOfLastMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfLastMonth) else { return }
        
        do {
            let earliestDate = startOfYear < startOfLastMonth ? startOfYear : startOfLastMonth
            
            let allRelevantSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("salesAssociateID", value: userID.uuidString)
                .eq("storeID", value: storeID.uuidString)
                .gte("salesDate", value: isoFormatter.string(from: earliestDate))
                .execute()
                .value
                
            let lastMonthList = allRelevantSales.filter { sale in
                sale.saleDate >= startOfLastMonth && sale.saleDate <= endOfLastMonth
            }.sorted { $0.saleDate > $1.saleDate }
            
            let thisYearList = allRelevantSales.filter { sale in
                sale.saleDate >= startOfYear
            }.sorted { $0.saleDate > $1.saleDate }
            
            await MainActor.run {
                self.lastMonthSales = lastMonthList
                self.thisYearSales = thisYearList
                self.isLoading = false
            }
        } catch {
            print("Error fetching historical sales: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}
