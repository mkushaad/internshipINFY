import Foundation
import Observation
import Supabase
import FoundationModels

@Observable
class AssociateDetailsViewModel {
    var shift: Shift?
    var leave: Leave?
    var tasks: [DailyTask] = []
    
    var monthlyTarget: AssociateSalesTarget?
    var monthlySalesTotal: Double = 0.0
    var recentMonthlySales: [Sale] = []
    var dailySalesDisplayData: [SaleDisplayData] = []
    
    var isLoading = false
    var storeCurrency: Currency = .usd
    
    var intelligenceSummary: String = ""
    var isGeneratingSummary = false
    var monthlyAppointmentsCount: Int = 0
    
    func fetchData(userID: UUID, storeID: UUID, date: Date) async {
        isLoading = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        do {
            let fetchedShifts: [Shift] = try await SupabaseService.shared.client
                .from("Shift")
                .select()
                .eq("userID", value: userID.uuidString)
                .execute()
                .value
                
            let fetchedLeaves: [Leave] = try await SupabaseService.shared.client
                .from("Leave")
                .select()
                .eq("userID", value: userID.uuidString)
                .lte("startDate", value: dateString)
                .gte("endDate", value: dateString)
                .execute()
                .value
            
            let fetchedTasks: [DailyTask] = try await SupabaseService.shared.client
                .from("DailyTask")
                .select()
                .eq("userID", value: userID.uuidString)
                .eq("date", value: dateString)
                .execute()
                .value
            
            let fetchedStore: Store = try await SupabaseService.shared.client
                .from("Store")
                .select()
                .eq("id", value: storeID.uuidString)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.shift = fetchedShifts.first
                self.leave = fetchedLeaves.first
                self.tasks = fetchedTasks.sorted { $0.isCompleted && !$1.isCompleted }
                self.storeCurrency = fetchedStore.currency
                self.isLoading = false
            }
            
            await fetchSales(userID: userID, storeID: storeID, date: date)
        } catch {
            print("Error fetching associate details: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func saveShift(userID: UUID, storeID: UUID, date: Date, type: ShiftType) async {
        do {
            let newShift = Shift(id: UUID(), userID: userID, storeID: storeID, shiftType: type)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
            
            try await SupabaseService.shared.client
                .from("Shift")
                .upsert(newShift, onConflict: "userID")
                .execute()
                
            var conflictingIDs: [UUID] = []
            
            let fetchedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select()
                .eq("salesAssociateID", value: userID.uuidString)
                .gte("date", value: isoFormatter.string(from: Date()))
                .execute()
                .value
                
            let calendar = Calendar.current
            
            for appt in fetchedAppts {
                let hour = calendar.component(.hour, from: appt.date)
                
                var hasConflict = false
                switch type {
                case .morning: hasConflict = !(hour >= 9 && hour < 14)
                case .evening: hasConflict = !(hour >= 14 && hour < 19)
                case .leave: hasConflict = true
                }
                
                if hasConflict {
                    conflictingIDs.append(appt.id)
                }
            }
            
            if !conflictingIDs.isEmpty {
                let payload: [String: AnyJSON] = ["salesAssociateID": .null]
                try await SupabaseService.shared.client
                    .from("Appointment")
                    .update(payload)
                    .in("id", values: conflictingIDs.map { $0.uuidString })
                    .execute()
            }
            
            await fetchData(userID: userID, storeID: storeID, date: date)
        } catch {
            print("Failed to save shift: \(error)")
        }
    }
    
    func getNextConflictingAppointment(userID: UUID, newShiftType: ShiftType) async -> Appointment? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        do {
            let fetchedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select("*, client_profiles(*)")
                .eq("salesAssociateID", value: userID.uuidString)
                .gte("date", value: isoFormatter.string(from: Date()))
                .order("date", ascending: true)
                .execute()
                .value
                
            let calendar = Calendar.current
            for appt in fetchedAppts {
                let hour = calendar.component(.hour, from: appt.date)
                let isConflict: Bool
                switch newShiftType {
                case .morning:
                    isConflict = !(hour >= 9 && hour < 14)
                case .evening:
                    isConflict = !(hour >= 14 && hour < 19)
                case .leave:
                    isConflict = true
                }
                
                if isConflict {
                    return appt
                }
            }
            return nil
        } catch {
            print("Error checking shift conflicts: \(error)")
            return nil
        }
    }
    
    func addTask(userID: UUID, date: Date, title: String) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let newTask = DailyTask(id: UUID(), userID: userID, date: dateString, title: title, isCompleted: false)
        do {
            try await SupabaseService.shared.client
                .from("DailyTask")
                .insert(newTask)
                .execute()
            
            await MainActor.run {
                self.tasks.append(newTask)
            }
        } catch {
            print("Failed to add task: \(error)")
        }
    }
    
    func toggleTask(_ task: DailyTask) async {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        
        do {
            try await SupabaseService.shared.client
                .from("DailyTask")
                .update(["isCompleted": updatedTask.isCompleted])
                .eq("id", value: task.id.uuidString)
                .execute()
            
            await MainActor.run {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[index] = updatedTask
                }
            }
        } catch {
            print("Failed to toggle task: \(error)")
        }
    }
    
    func deleteTask(_ task: DailyTask) async {
        do {
            try await SupabaseService.shared.client
                .from("DailyTask")
                .delete()
                .eq("id", value: task.id.uuidString)
                .execute()
            
            await MainActor.run {
                self.tasks.removeAll { $0.id == task.id }
            }
        } catch {
            print("Failed to delete task: \(error)")
        }
    }
    
    func checkLeaveConflicts(userID: UUID, startDate: Date, endDate: Date) async -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else { return 0 }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        do {
            let fetchedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select()
                .eq("salesAssociateID", value: userID.uuidString)
                .gte("date", value: isoFormatter.string(from: startOfDay))
                .lt("date", value: isoFormatter.string(from: endOfDay))
                .execute()
                .value
            
            return fetchedAppts.count
        } catch {
            print("Error checking leave conflicts: \(error)")
            return 0
        }
    }
    
    func checkIfAlreadyOnLeave(userID: UUID, startDate: Date, endDate: Date) async -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        do {
            let fetchedLeaves: [Leave] = try await SupabaseService.shared.client
                .from("Leave")
                .select()
                .eq("userID", value: userID.uuidString)
                .eq("startDate", value: formatter.string(from: startDate))
                .eq("endDate", value: formatter.string(from: endDate))
                .execute()
                .value
            
            return !fetchedLeaves.isEmpty
        } catch {
            return false
        }
    }
    
    func assignLeave(userID: UUID, storeID: UUID, startDate: Date, endDate: Date, currentViewDate: Date) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let newLeave = Leave(
            id: UUID(),
            userID: userID,
            storeID: storeID,
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate)
        )
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else { return }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        do {
            try await SupabaseService.shared.client
                .from("Leave")
                .insert(newLeave)
                .execute()
                
            // Unassign any appointments overlapping this leave period
            let payload: [String: AnyJSON] = ["salesAssociateID": .null]
            try? await SupabaseService.shared.client
                .from("Appointment")
                .update(payload)
                .eq("salesAssociateID", value: userID.uuidString)
                .gte("date", value: isoFormatter.string(from: startOfDay))
                .lt("date", value: isoFormatter.string(from: endOfDay))
                .execute()
                
            // Update the user's active status in the database to false
            let userPayload: [String: Bool] = ["isActive": false]
            try? await SupabaseService.shared.client
                .from("User")
                .update(userPayload)
                .eq("id", value: userID.uuidString)
                .execute()
            
            await fetchData(userID: userID, storeID: storeID, date: currentViewDate)
        } catch {
            print("Failed to assign leave: \(error)")
        }
    }
    
    func fetchSales(userID: UUID, storeID: UUID, date: Date) async {
        let calendar = Calendar.current
        
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else { return }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        do {
            let fetchedTargets: [AssociateSalesTarget] = try await SupabaseService.shared.client
                .from("AssociateSalesTarget")
                .select()
                .eq("assignedToID", value: userID.uuidString)
                .gte("periodStartDate", value: isoFormatter.string(from: monthStart))
                .lte("periodStartDate", value: isoFormatter.string(from: monthEnd))
                .execute()
                .value
                
            let target = fetchedTargets.first
            await MainActor.run { self.monthlyTarget = target }
        } catch {
            print("No existing target found or error: \(error)")
        }
        
        do {
            let fetchedSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("salesAssociateID", value: userID.uuidString)
                .gte("salesDate", value: isoFormatter.string(from: monthStart))
                .lte("salesDate", value: isoFormatter.string(from: calendar.date(byAdding: .day, value: 1, to: monthEnd)!))
                .execute()
                .value
                
            let total = fetchedSales.reduce(0) { $0 + $1.totalAmount }
            let sortedSales = fetchedSales.sorted { $0.saleDate > $1.saleDate }
            let recent = Array(sortedSales.prefix(3))
            await MainActor.run { 
                self.monthlySalesTotal = total 
                self.recentMonthlySales = recent
            }
        } catch {
            print("Error fetching monthly sales: \(error)")
        }
        
        do {
            let fetchedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select()
                .eq("salesAssociateID", value: userID.uuidString)
                .eq("status", value: AppointmentStatus.completed.rawValue)
                .gte("date", value: isoFormatter.string(from: monthStart))
                .lte("date", value: isoFormatter.string(from: monthEnd))
                .execute()
                .value
            await MainActor.run { self.monthlyAppointmentsCount = fetchedAppts.count }
        } catch {
            print("Error fetching appointments: \(error)")
        }
        
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        do {
            let dailyFetchedSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("salesAssociateID", value: userID.uuidString)
                .gte("salesDate", value: isoFormatter.string(from: startOfDay))
                .lt("salesDate", value: isoFormatter.string(from: endOfDay))
                .execute()
                .value
                
            var displayData: [SaleDisplayData] = []
            
            for sale in dailyFetchedSales {
                let items: [SalesItem] = try await SupabaseService.shared.client
                    .from("SalesItem")
                    .select()
                    .eq("saleID", value: sale.id.uuidString)
                    .execute()
                    .value
                    
                let productIDs = items.map { $0.productID.uuidString }
                var products: [Product] = []
                if !productIDs.isEmpty {
                    products = try await SupabaseService.shared.client
                        .from("Product")
                        .select()
                        .in("id", values: productIDs)
                        .execute()
                        .value
                }
                
                displayData.append(SaleDisplayData(sale: sale, items: items, products: products))
            }
            
            let finalData = displayData
            await MainActor.run { self.dailySalesDisplayData = finalData }
        } catch {
            print("Error fetching daily sales details: \(error)")
        }
    }
    
    private var session: LanguageModelSession?
    
    func generateIntelligenceSummary(associateName: String) async {
        await MainActor.run {
            self.isGeneratingSummary = true
            self.intelligenceSummary = ""
        }
        
        let targetAmount = monthlyTarget?.targetAmount ?? 0
        let achievedAmount = monthlySalesTotal
        let appts = monthlyAppointmentsCount
        let targetPercentage = targetAmount > 0 ? (achievedAmount / targetAmount) * 100 : 0
        
        if session == nil {
            let instructions = """
            ROLE: You are an expert retail performance analyst reporting to a Store Manager.
            RULES:
            - Provide a brief analysis (MAXIMUM 2-3 short sentences).
            - Blend the provided stats (sales, target %, appointments) naturally into your insights to back up your analysis.
            - Keep the tone highly professional, objective, and constructively supportive (NEVER be harsh or overly critical, even if targets are missed).
            - Speak directly to the manager (e.g., "Gorish's 56% target completion and 3 appointments show...").
            """
            session = LanguageModelSession(instructions: instructions)
        }
        
        guard let currentSession = session else { return }
        let difference = achievedAmount - targetAmount
        
        let performanceStatus: String
        if targetAmount == 0 {
            performanceStatus = "They have $\(String(format: "%.0f", achievedAmount)) in sales with no set target."
        } else if difference > 0 {
            performanceStatus = "They exceeded their $\(String(format: "%.0f", targetAmount)) target by $\(String(format: "%.0f", difference)) (achieving \(String(format: "%.0f", targetPercentage))%)."
        } else if difference < 0 {
            performanceStatus = "They are $\(String(format: "%.0f", abs(difference))) short of their $\(String(format: "%.0f", targetAmount)) target (achieving \(String(format: "%.0f", targetPercentage))%)."
        } else {
            performanceStatus = "They exactly met their $\(String(format: "%.0f", targetAmount)) target."
        }
        
        let prompt = "Analyze the performance for associate: \(associateName). \(performanceStatus) Total sales: $\(String(format: "%.0f", achievedAmount)). Successfully completed appointments: \(appts). DO NOT do any math, just use these facts."
        
        do {
            let response = try await currentSession.respond(to: prompt)
            
            // Stream the text to the UI for a dynamic Apple Intelligence effect
            let words = response.content.components(separatedBy: " ")
            for word in words {
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds per word
                await MainActor.run {
                    self.intelligenceSummary += (self.intelligenceSummary.isEmpty ? "" : " ") + word
                }
            }
        } catch {
            await MainActor.run {
                self.intelligenceSummary = "Unable to generate summary at this time."
            }
        }
        
        await MainActor.run {
            self.isGeneratingSummary = false
        }
    }

    func saveMonthlyTarget(amount: Double, userID: UUID, storeID: UUID, date: Date) async {
        let calendar = Calendar.current
        let currentDate = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else { return }
              
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let target = AssociateSalesTarget(
            id: monthlyTarget?.id ?? UUID(),
            storeID: storeID,
            assignedToID: userID,
            periodStartDate: formatter.string(from: currentDate),
            periodEndDate: formatter.string(from: monthEnd),
            targetAmount: amount
        )
        
        do {
            try await SupabaseService.shared.client
                .from("AssociateSalesTarget")
                .upsert(target)
                .execute()
            await MainActor.run { self.monthlyTarget = target }
        } catch {
            print("Error saving target: \(error)")
        }
    }
}
