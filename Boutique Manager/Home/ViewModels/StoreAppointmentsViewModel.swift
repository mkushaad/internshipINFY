import Foundation
import Supabase
import Observation

@Observable
class StoreAppointmentsViewModel {
    var upcomingAppointments: [Appointment] = []
    var ongoingAppointments: [Appointment] = []
    var completedAppointments: [Appointment] = []
    var unassignedAppointments: [Appointment] = []
    
    var isLoading = false
    var errorMessage: String? = nil
    
    @MainActor
    func fetchAppointments(for storeID: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select("*, client_profiles(*), User(*)")
                .eq("storeID", value: storeID.uuidString)
                .order("date", ascending: true)
                .execute()
                .value
            
            let now = Date()
            
            // "ongoing" = Scheduled for today
            // "upcoming" = Scheduled for future dates
            // "completed" = Any status other than scheduled (completed, cancelled, noShow)
            
            var upcoming: [Appointment] = []
            var ongoing: [Appointment] = []
            var completed: [Appointment] = []
            var unassigned: [Appointment] = []
            
            let calendar = Calendar.current
            
            for appt in fetched {
                if appt.salesAssociateID == nil && appt.status != .cancelled {
                    unassigned.append(appt)
                }
                
                if appt.status != .scheduled {
                    completed.append(appt)
                } else {
                    if appt.date > now {
                        upcoming.append(appt)
                    } else {
                        // Time has passed but it's still marked 'scheduled', meaning it's currently happening
                        ongoing.append(appt)
                    }
                }
            }
            
            self.upcomingAppointments = upcoming
            self.ongoingAppointments = ongoing
            self.unassignedAppointments = unassigned
            self.completedAppointments = completed.sorted { $0.date > $1.date } // Recent first
            
        } catch {
            print("Error fetching store appointments: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
