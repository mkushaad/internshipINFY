//
//  StaffViewModel.swift
//  Boutique Manager
//

import Foundation
import Observation
import Supabase

@Observable
class StaffViewModel {
    var liveStaff: [User]? = nil
    var isLoading = false
    var errorMessage: String? = nil
    
    func fetchStaff(forStoreID storeID: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedUsers: [User] = try await SupabaseService.shared.client
                .from("User")
                .select()
                .eq("Assigned StoreID", value: storeID.uuidString)
                .execute()
                .value
            
            await MainActor.run {
                self.liveStaff = fetchedUsers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load staff: \(error.localizedDescription)"
                self.isLoading = false
                print("Error fetching staff from DB: \(error)")
            }
        }
    }
    
    func addStaff(_ user: User) {
        if liveStaff == nil {
            liveStaff = []
        }
        liveStaff?.append(user)
    }
    
    func deleteStaff(usersToDelete: [User]) async {
        // Remove locally first for a snappy experience
        await MainActor.run {
            liveStaff?.removeAll { user in usersToDelete.contains(where: { $0.id == user.id }) }
        }
        
        // Delete from Supabase
        for user in usersToDelete {
            do {
                try await SupabaseService.shared.client
                    .from("User")
                    .delete()
                    .eq("id", value: user.id.uuidString)
                    .execute()
            } catch {
                print("Failed to delete user from Supabase: \(error)")
                // Ideally handle rollback or showing an error here
            }
        }
    }
    
    // MARK: - Schedule Data
    
    var shifts: [UUID: Shift] = [:]
    var leaves: [UUID: Leave] = [:]
    var tasks: [UUID: [DailyTask]] = [:]
    var appointmentCounts: [UUID: Int] = [:]
    var unassignedDates: Set<String> = []
    var isScheduleLoading = false
    
    func fetchScheduleData(forStoreID storeID: UUID, date: Date) async {
        isScheduleLoading = true
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)
            
            // Fetch Base Shifts
            let fetchedShifts: [Shift] = try await SupabaseService.shared.client
                .from("Shift")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .execute()
                .value
                
            // Fetch Leaves covering this date
            let fetchedLeaves: [Leave] = try await SupabaseService.shared.client
                .from("Leave")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .lte("startDate", value: dateString)
                .gte("endDate", value: dateString)
                .execute()
                .value
            
            // Fetch Tasks
            let fetchedTasks: [DailyTask] = try await SupabaseService.shared.client
                .from("DailyTask")
                .select()
                .eq("date", value: dateString) // Assuming tasks don't have storeID, just filter by date
                .execute()
                .value
            
            // Fetch Appointments for the given day
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
            
            let fetchedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .gte("date", value: isoFormatter.string(from: startOfDay))
                .lt("date", value: isoFormatter.string(from: endOfDay))
                .execute()
                .value
            
            await MainActor.run {
                self.shifts = Dictionary(fetchedShifts.map { ($0.userID, $0) }, uniquingKeysWith: { first, _ in first })
                self.leaves = Dictionary(fetchedLeaves.map { ($0.userID, $0) }, uniquingKeysWith: { first, _ in first })
                self.tasks = Dictionary(grouping: fetchedTasks, by: { $0.userID })
                
                let counts = fetchedAppts.reduce(into: [UUID: Int]()) { result, appt in
                    if let associateID = appt.salesAssociateID {
                        result[associateID, default: 0] += 1
                    }
                }
                
                self.appointmentCounts = counts
                self.isScheduleLoading = false
            }
        } catch {
            await MainActor.run {
                self.isScheduleLoading = false
                print("Error fetching schedule data: \(error)")
            }
        }
    }
    
    @MainActor
    func fetchAlerts(forStoreID storeID: UUID) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2
        let startOfWeek = calendar.date(from: components) ?? today
        guard let endOfPeriod = calendar.date(byAdding: .day, value: 14, to: startOfWeek) else { return }
        
        let stringFormatter = DateFormatter()
        stringFormatter.dateFormat = "yyyy-MM-dd"
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        do {
            let fetchedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .gte("date", value: isoFormatter.string(from: startOfWeek))
                .lt("date", value: isoFormatter.string(from: endOfPeriod))
                .execute()
                .value
            
            var unassigned: Set<String> = []
            
            for appt in fetchedAppts {
                if appt.salesAssociateID == nil {
                    let dateStr = stringFormatter.string(from: appt.date)
                    unassigned.insert(dateStr)
                }
            }
            
            self.unassignedDates = unassigned
            
        } catch {
            print("Error fetching alerts: \(error)")
        }
    }
    
}
