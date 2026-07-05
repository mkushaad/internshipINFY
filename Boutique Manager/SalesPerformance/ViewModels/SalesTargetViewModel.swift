//
//  SalesTargetViewModel.swift
//  Boutique Manager
//

import Foundation
import Observation
import Supabase

@Observable
class SalesTargetViewModel {
    var salesTargets: [StoreSalesTarget] = []
    var isLoading = false
    var errorMessage: String? = nil
    
    func fetchSalesTargets(forStoreID storeID: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedTargets: [StoreSalesTarget] = try await SupabaseService.shared.client
                .from("StoreSalesTarget")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .order("startDate", ascending: true)
                .execute()
                .value
            
            await MainActor.run {
                self.salesTargets = fetchedTargets
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load sales targets: \(error.localizedDescription)"
                self.isLoading = false
                print("Error fetching sales targets from DB: \(error)")
            }
        }
    }
    
    func target(for weekStartDate: Date) -> StoreSalesTarget? {
        return salesTargets.first { target in
            target.startDate <= weekStartDate && target.endDate >= weekStartDate
        }
    }
    
    func weeklyTarget(for weekStartDate: Date) -> Double? {
        guard let target = target(for: weekStartDate) else { return nil }
        switch target.period {
        case .monthly:
            return target.targetAmount / 4.0
        case .quarterly:
            return target.targetAmount / 16.0
        case .yearly:
            return target.targetAmount / 52.0
        }
    }
}
