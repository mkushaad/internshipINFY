import Foundation
import Supabase
import Observation

@Observable
class BookAppointmentViewModel {
    var searchName: String = ""
    var customerResults: [ClientProfile] = []
    var isSearchingCustomers = false
    
    var storeAssociates: [User] = []
    var availableAssociates: [User] = []
    var allShifts: [UUID: Shift] = [:]
    var allLeaves: [Leave] = []
    var isSaving = false
    
    @MainActor
    func fetchCustomer(id: String) async {
        do {
            let fetched: ClientProfile = try await SupabaseService.shared.client
                .from("client_profiles")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
            self.customerResults = [fetched]
        } catch {
            print("Error fetching client profile: \(error)")
        }
    }
    
    @MainActor
    func searchCustomers() async {
        guard !searchName.trimmingCharacters(in: .whitespaces).isEmpty else {
            customerResults = []
            return
        }
        
        isSearchingCustomers = true
        do {
            let fetched: [ClientProfile] = try await SupabaseService.shared.client
                .from("client_profiles")
                .select()
                .ilike("name", value: "%\(searchName)%")
                .limit(5)
                .execute()
                .value
                
            customerResults = fetched
            isSearchingCustomers = false
        } catch {
            print("Error searching clients: \(error)")
            isSearchingCustomers = false
        }
    }
    
    @MainActor
    func fetchAssociates(storeID: UUID, date: Date, keeping currentlyAssignedID: UUID? = nil) async {
        do {
            let fetched: [User] = try await SupabaseService.shared.client
                .from("User")
                .select()
                .eq("Assigned StoreID", value: storeID.uuidString)
                .execute()
                .value
            
            storeAssociates = fetched.filter { $0.role == .salesAssociate }
            
            let fetchedShifts: [Shift] = try await SupabaseService.shared.client
                .from("Shift")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .execute()
                .value
            allShifts = Dictionary(uniqueKeysWithValues: fetchedShifts.map { ($0.userID, $0) })
            
            let fetchedLeaves: [Leave] = try await SupabaseService.shared.client
                .from("Leave")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .execute()
                .value
            allLeaves = fetchedLeaves
            
            filterAvailableAssociates(for: date, keeping: currentlyAssignedID)
        } catch {
            print("Error fetching associates: \(error)")
        }
    }
    
    func filterAvailableAssociates(for date: Date, keeping currentlyAssignedID: UUID? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        availableAssociates = storeAssociates.filter { associate in
            if associate.id == currentlyAssignedID { return true }
            
            let isOnLeave = allLeaves.contains { leave in
                leave.userID == associate.id && 
                leave.startDate <= dateString && 
                leave.endDate >= dateString
            }
            if isOnLeave { return false }
            
            guard let shift = allShifts[associate.id] else { return false }
            switch shift.shiftType {
            case .morning:
                return hour >= 9 && hour < 14
            case .evening:
                return hour >= 14 && hour < 19
            case .leave:
                return false
            }
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
            case .morning:
                return hour >= 9 && hour < 14
            case .evening:
                return hour >= 14 && hour < 19
            case .leave:
                return false
            }
        } catch {
            print("Error checking shift availability: \(error)")
            // If network fails, you could choose to let them book or block. Let's block to be safe.
            return false
        }
    }
    
    struct AppointmentPayload: Codable {
        let storeID: UUID
        let customerID: String
        let salesAssociateID: AnyJSON
        let date: Date
        let type: AppointmentType
        let status: AppointmentStatus
        let preferences: AnyJSON
    }
    
    private func createPayload(from appointment: Appointment) -> AppointmentPayload {
        return AppointmentPayload(
            storeID: appointment.storeID,
            customerID: appointment.customerID,
            salesAssociateID: appointment.salesAssociateID.map { .string($0.uuidString) } ?? .null,
            date: appointment.date,
            type: appointment.type,
            status: appointment.status,
            preferences: appointment.preferences.map { .string($0) } ?? .null
        )
    }

    @MainActor
    func insert(appointment: Appointment) async {
        isSaving = true
        do {
            let payload = createPayload(from: appointment)
            try await SupabaseService.shared.client
                .from("Appointment")
                .insert(payload)
                .execute()
        } catch {
            print("Error inserting appointment: \(error)")
        }
        isSaving = false
    }
    
    @MainActor
    func update(appointment: Appointment) async {
        isSaving = true
        do {
            let payload = createPayload(from: appointment)
            try await SupabaseService.shared.client
                .from("Appointment")
                .update(payload)
                .eq("id", value: appointment.id.uuidString)
                .execute()
        } catch {
            print("Error updating appointment: \(error)")
        }
        isSaving = false
    }
}
