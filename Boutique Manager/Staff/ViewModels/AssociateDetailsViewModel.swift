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
    var storeMonthlySalesTotal: Double = 0.0
    var recentMonthlySales: [SaleDisplayData] = []
    var dailySalesDisplayData: [SaleDisplayData] = []
    
    var monthlyAppointmentsCount: Int = 0
    var monthlySalesCount: Int = 0
    var appointmentAttendanceRate: Double = 0
    var highValueClientAppointments: Int = 0
    
    var isLoading = false
    var storeCurrency: Currency = .usd
    
    var intelligenceSummary: String = ""
    var isGeneratingSummary = false
    
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
                self.storeCurrency = fetchedStore.currency ?? .usd
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
        
        let monthComponents = calendar.dateComponents([.year, .month], from: date)
        let monthStart = calendar.date(from: monthComponents) ?? date
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? date
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        let startString = isoFormatter.string(from: monthStart)
        let endString = isoFormatter.string(from: monthEnd)
        
        do {
            let fetchedTargets: [AssociateSalesTarget] = try await SupabaseService.shared.client
                .from("AssociateSalesTarget")
                .select()
                .eq("assignedToID", value: userID.uuidString)
                .gte("periodStartDate", value: startString)
                .lt("periodStartDate", value: endString)
                .execute()
                .value
                
            let target = fetchedTargets.first
            await MainActor.run { self.monthlyTarget = target }
        } catch {
            print("No existing target found or error: \(error)")
        }
        
        do {
            // Fetch all sales for store in month to perfectly match HomeView's working logic
            let fetchedSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .gte("salesDate", value: startString)
                .lt("salesDate", value: endString)
                .execute()
                .value
                
            let storeTotal = fetchedSales.reduce(0) { $0 + $1.totalAmount }
            let userSales = fetchedSales.filter { $0.salesAssociateID == userID }
            let total = userSales.reduce(0) { $0 + $1.totalAmount }
            let sortedSales = userSales.sorted { $0.saleDate > $1.saleDate }
            let recent = Array(sortedSales.prefix(3))
            
            var displayData: [SaleDisplayData] = []
            for sale in recent {
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
            
            await MainActor.run {
                self.monthlySalesTotal = total
                self.monthlySalesCount = userSales.count
                self.storeMonthlySalesTotal = storeTotal
                self.recentMonthlySales = displayData
            }
        } catch {
            print("Error fetching monthly sales: \(error)")
        }
        
        do {
            let fetchedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select("*, client_profiles(*)")
                .eq("salesAssociateID", value: userID.uuidString)
                .gte("date", value: startString)
                .lt("date", value: endString)
                .execute()
                .value
                
            let completed = fetchedAppts.filter { $0.status == .completed }.count
            let totalSched = fetchedAppts.count
            let attendance = totalSched > 0 ? (Double(completed) / Double(totalSched)) * 100 : 0
            
            let highTier = fetchedAppts.filter { appt in
                if let tier = appt.client_profiles?.tier {
                    return tier.localizedCaseInsensitiveContains("VIP") || tier.localizedCaseInsensitiveContains("Platinum") || tier.localizedCaseInsensitiveContains("Gold")
                }
                return false
            }.count
            
            await MainActor.run { 
                self.monthlyAppointmentsCount = completed 
                self.appointmentAttendanceRate = attendance
                self.highValueClientAppointments = highTier
            }
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
            ROLE: You are an elite retail performance analyst advising a Store Manager on team talent optimization and performance incentive allocation.
            
            RULES:
            - YOU are speaking TO the Store Manager. 
            - The data provided belongs to a SALES ASSOCIATE (named e.g. "Shubhrat"). The associate is the employee being evaluated by the manager.
            - Refer to the associate in the third person using their name. NEVER address the associate directly as "you". NEVER call the associate a manager.
            - CRITICAL LENGTH LIMIT: Limit response to a MAXIMUM of 40 words. Be extremely crisp, punchy, and direct. Do not write a long paragraph. 2-3 sentences max.
            - TONE: Adopt a constructive, professional, and empathetic tone typical of high-end luxury retail managers. Frame underperformance as an opportunity for coaching rather than a failure.
            - Focus on the overarching narrative: Are they relying on low-volume high-margin sales? Are they struggling with operational discipline despite good sales? How do they compare to the store's overall performance?
            - CRITICAL: You must accurately state whether they met, exceeded, or fell short of their sales target based on the context provided. Avoid harsh words like "FAILED"; instead, use "fell short" or "did not meet".
            - DO NOT simply output a robotic list of all raw stats. However, when you discuss a derived metric, you MUST include the exact number provided in the context to ground your assessment.
            - Conclude with a clear recommendation on whether they deserve recognition, mentorship, or urgent intervention.
            """
            session = LanguageModelSession(instructions: instructions)
        }
        
        guard let currentSession = session else { return }
        
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let taskCompletionRate = totalTasks > 0 ? (Double(completedTasks) / Double(totalTasks)) * 100 : 0
        let topRecentSale = recentMonthlySales.max(by: { $0.totalAmount < $1.totalAmount })
        let topSaleText = topRecentSale != nil ? "Their highest recent transaction was $\(String(format: "%.0f", topRecentSale!.totalAmount))." : ""
        let atv = monthlySalesCount > 0 ? achievedAmount / Double(monthlySalesCount) : 0
        
        let difference = achievedAmount - targetAmount
        
        let performanceStatus: String
        if targetAmount == 0 {
            performanceStatus = "generated $\(String(format: "%.0f", achievedAmount)) in sales without a formal baseline target set."
        } else if difference > 0 {
            performanceStatus = "crushed expectations by surpassing their $\(String(format: "%.0f", targetAmount)) target by $\(String(format: "%.0f", difference)), unlocking an impressive \(String(format: "%.0f", targetPercentage))% target completion."
        } else if difference < 0 {
            performanceStatus = "fell short of their sales target. They finished $\(String(format: "%.0f", abs(difference))) shy of their $\(String(format: "%.0f", targetAmount)) target, meeting only \(String(format: "%.0f", targetPercentage))% of the objective."
        } else {
            performanceStatus = "hit their target exactly, converting a perfect $\(String(format: "%.0f", targetAmount)) value."
        }
        
        let prompt = """
        Provide an extremely concise, qualitative managerial assessment for \(associateName) (MAXIMUM 40 WORDS) based on this hidden data context: 
        Sales Context: They \(performanceStatus) (Total Revenue: $\(String(format: "%.0f", achievedAmount)), Average Transaction Value: $\(String(format: "%.0f", atv))). 
        Store Context: The entire store generated $\(String(format: "%.0f", storeMonthlySalesTotal)) this month. This associate contributed \((storeMonthlySalesTotal > 0 ? (achievedAmount / storeMonthlySalesTotal) * 100 : 0).formatted(.number.precision(.fractionLength(0))))% of the store's total revenue.
        Client Interaction: \(appts) completed appointments (\(String(format: "%.0f", appointmentAttendanceRate))% attendance rate), with \(highValueClientAppointments) being VIP/high-tier clients.
        Operational Efficiency: \(String(format: "%.0f", taskCompletionRate))% task completion rate. \(topSaleText)
        
        Synthesize this into a meaningful, human-like insight. Remember: DO NOT recite the numbers. Tell the manager what the numbers *mean*. BE EXTREMELY SHORT.
        """
        
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
        let monthComponents = calendar.dateComponents([.year, .month], from: date)
        let monthStart = calendar.date(from: monthComponents) ?? date
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? date
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        let target = AssociateSalesTarget(
            id: monthlyTarget?.id ?? UUID(),
            storeID: storeID,
            assignedToID: userID,
            periodStartDate: formatter.string(from: monthStart),
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

