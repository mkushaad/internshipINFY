import Foundation
import Supabase
import Observation

@Observable
class UnassignedAppointmentsViewModel {
    var appointments: [Appointment] = []
    var isLoading = false
    var errorMessage: String? = nil
    
    @MainActor
    func fetchUnassigned(storeID: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select("*, client_profiles(*)")
                .eq("storeID", value: storeID.uuidString)
                .is("salesAssociateID", value: nil)
                .execute()
                .value
            
            appointments = fetched.sorted { $0.date < $1.date }
        } catch {
            print("Error fetching unassigned appointments: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func assign(appointment: Appointment, to associateID: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            // Update Supabase
            struct UpdatePayload: Codable {
                let salesAssociateID: UUID
            }
            let payload = UpdatePayload(salesAssociateID: associateID)
            
            try await SupabaseService.shared.client
                .from("Appointment")
                .update(payload)
                .eq("id", value: appointment.id.uuidString)
                .execute()
            
            isLoading = false
            return true
        } catch {
            print("Error assigning appointment: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    @MainActor
    func checkShiftAvailability(associateID: UUID, date: Date) async -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        do {
            let fetchedLeaves: [Leave] = try await SupabaseService.shared.client
                .from("Leave")
                .select()
                .eq("userID", value: associateID.uuidString)
                .lte("startDate", value: dateString)
                .gte("endDate", value: dateString)
                .execute()
                .value
            
            if !fetchedLeaves.isEmpty {
                return false // On leave
            }
            
            let fetchedShifts: [Shift] = try await SupabaseService.shared.client
                .from("Shift")
                .select()
                .eq("userID", value: associateID.uuidString)
                .execute()
                .value
            
            guard let shift = fetchedShifts.first else {
                return false
            }
            
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            
            switch shift.shiftType {
            case .morning: return hour >= 9 && hour < 14
            case .evening: return hour >= 14 && hour < 19
            case .leave: return false
            }
        } catch {
            return false
        }
    }
}
