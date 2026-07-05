import Foundation
import Observation
import Supabase

@Observable
class AssociateSalesHistoryViewModel {
    var thisMonthSales: [SaleDisplayData] = []
    var thisYearSales: [SaleDisplayData] = []
    var isLoading = false
    
    var thisMonthTotal: Double {
        thisMonthSales.reduce(0) { $0 + $1.totalAmount }
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
        
        // This Month calculation
        var monthComponents = calendar.dateComponents([.year, .month], from: now)
        guard let startOfThisMonth = calendar.date(from: monthComponents) else { return }
        
        do {
            let earliestDate = startOfYear < startOfThisMonth ? startOfYear : startOfThisMonth
            
            let allRelevantSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("salesAssociateID", value: userID.uuidString)
                .eq("storeID", value: storeID.uuidString)
                .gte("salesDate", value: isoFormatter.string(from: earliestDate))
                .execute()
                .value
                
            var displayDataList: [SaleDisplayData] = []
            
            let saleIDs = allRelevantSales.map { $0.id.uuidString }
            if !saleIDs.isEmpty {
                let fetchedItems: [SalesItem] = try await SupabaseService.shared.client
                    .from("SalesItem")
                    .select()
                    .in("saleID", values: saleIDs)
                    .execute()
                    .value
                
                let productIDs = Array(Set(fetchedItems.map { $0.productID.uuidString }))
                var fetchedProducts: [Product] = []
                if !productIDs.isEmpty {
                    fetchedProducts = try await SupabaseService.shared.client
                        .from("Product")
                        .select()
                        .in("id", values: productIDs)
                        .execute()
                        .value
                }
                
                for sale in allRelevantSales {
                    let items = fetchedItems.filter { $0.saleID == sale.id }
                    let itemProdIDs = Set(items.map { $0.productID })
                    let products = fetchedProducts.filter { itemProdIDs.contains($0.id) }
                    displayDataList.append(SaleDisplayData(sale: sale, items: items, products: products))
                }
            }
            
            let thisMonthList = displayDataList.filter { data in
                data.sale.saleDate >= startOfThisMonth
            }.sorted { $0.saleDate > $1.saleDate }
            
            let thisYearList = displayDataList.filter { data in
                data.sale.saleDate >= startOfYear
            }.sorted { $0.saleDate > $1.saleDate }
            
            await MainActor.run {
                self.thisMonthSales = thisMonthList
                self.thisYearSales = thisYearList
                self.isLoading = false
            }
        } catch {
            print("Error fetching historical sales: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}
