import Foundation
import Supabase
import Observation

@Observable
class AssociateAppointmentsViewModel {
    var appointments: [Appointment] = []
    var isLoading = false
    var errorMessage: String? = nil
    
    @MainActor
    func fetch(for associateID: UUID) async {
        do {
            isLoading = true
            let fetchedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select("*, client_profiles(*)")
                .eq("salesAssociateID", value: associateID.uuidString)
                .execute()
                .value
                
            appointments = fetchedAppts.sorted { $0.date < $1.date }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("Error fetching associate appointments: \(error)")
        }
    }
    
    @MainActor
    func unassign(appointment: Appointment) async {
        do {
            let payload: [String: AnyJSON] = ["salesAssociateID": .null]
            try await SupabaseService.shared.client
                .from("Appointment")
                .update(payload)
                .eq("id", value: appointment.id.uuidString)
                .execute()
            
            appointments.removeAll { $0.id == appointment.id }
        } catch {
            print("Error unassigning appointment: \(error)")
        }
    }
}
