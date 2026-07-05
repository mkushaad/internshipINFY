import SwiftUI
import Supabase
import Observation


struct AssociateDetailsView: View {
    let user: User
    let date: Date
    
    @State private var detailsVM = AssociateDetailsViewModel()
    @State private var showIntelligenceSummary = false
    
    @State private var isAddingChecklistItem = false
    @State private var newChecklistItemTitle = ""
    @FocusState private var isNewItemFocused: Bool
    
    @State private var salesTargetString: String = ""
    
    @State private var appointmentsVM = AssociateAppointmentsViewModel()
    @State private var showAllAppointments = false
    @State private var isShowingUnassigned = false
    @State private var showingLeaveRequestSheet = false
    @State private var editingAppointment: Appointment? = nil
    
    @State private var showingShiftConflictAlert = false
    @State private var pendingShiftType: ShiftType? = nil
    @State private var conflictingAppointment: Appointment? = nil
    @State private var isCheckingShift = false
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard

                monthlyGoalsSection
                checklistSection
                appointmentsSection

                monthlySalesSection

                salesHistorySection
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Associate Details")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: isNewItemFocused) { isFocused in
            if !isFocused {
                if newChecklistItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    isAddingChecklistItem = false
                } else {
                    let titleToSave = newChecklistItemTitle
                    Task { await detailsVM.addTask(userID: user.id, date: date, title: titleToSave) }
                    isAddingChecklistItem = false
                    newChecklistItemTitle = ""
                }
            }
        }
        .task(id: date) {
            if let storeID = AuthManager.shared.currentUser?.assignedStoreID {
                await detailsVM.fetchData(userID: user.id, storeID: storeID, date: date)
                if let target = detailsVM.monthlyTarget {
                    salesTargetString = String(format: "%.0f", target.targetAmount)
                } else {
                    salesTargetString = ""
                }
            }
            await appointmentsVM.fetch(for: user.id)
        }
        .sheet(isPresented: $isShowingUnassigned) {
            if let storeID = AuthManager.shared.currentUser?.assignedStoreID {
                UnassignedAppointmentsSheet(
                    associate: user,
                    storeID: storeID,
                    onAssign: {
                        Task { await appointmentsVM.fetch(for: user.id) }
                    }
                )
            } else {
                Text("Error: No store assigned")
            }
        }
        .sheet(isPresented: $showingLeaveRequestSheet) {
            LeaveRequestSheet(
                user: user,
                currentViewDate: date,
                detailsVM: detailsVM,
                isPresented: $showingLeaveRequestSheet,
                onLeaveAssigned: {
                    Task { await appointmentsVM.fetch(for: user.id) }
                }
            )
        }
        .alert("Conflicting Appointment", isPresented: $showingShiftConflictAlert) {
            Button("Proceed", role: .destructive) {
                if let type = pendingShiftType {
                    saveShift(type: type)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingShiftType = nil
                conflictingAppointment = nil
            }
        } message: {
            if let appt = conflictingAppointment {
                Text("Next conflicting appointment is with \(appt.client_profiles?.name ?? "Unknown") on \(appt.date.formatted(date: .abbreviated, time: .shortened)). Do you want to proceed?")
            }
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.themeAccent.opacity(0.15))
                    .frame(width: 72, height: 72)
                
                Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.themeAccent)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Sales Associate")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                
                Menu {
                    Button("Morning (9:00 AM - 2:00 PM)") { initiateShiftChange(type: .morning) }
                    Button("Evening (2:00 PM - 7:00 PM)") { initiateShiftChange(type: .evening) }
                    Button(role: .destructive, action: { showingLeaveRequestSheet = true }) {
                        Label("On Leave", systemImage: "xmark.circle")
                    }
                    } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 13))
                        Text(detailsVM.leave != nil ? "On Leave" : (detailsVM.shift?.shiftType.displayName ?? "Assign Shift"))
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(detailsVM.leave != nil ? Color.red.opacity(0.1) : Color.themeAccent.opacity(0.1))
                    .foregroundColor(detailsVM.leave != nil ? .red : .themeAccent)
                    .cornerRadius(6)
                }
            }
            
            Spacer()
            }
            
            if !showIntelligenceSummary {
                Button(action: {
                    withAnimation(.spring()) {
                        showIntelligenceSummary = true
                    }
                    Task {
                        await detailsVM.generateIntelligenceSummary(associateName: user.firstName)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Summarize Performance")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .padding(.top, 4)
            } else {
                Divider()
                intelligenceSummaryCard
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    private var intelligenceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Apple Intelligence")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                    )
                Spacer()
                if detailsVM.isGeneratingSummary {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Text(detailsVM.intelligenceSummary.isEmpty ? "Analyzing performance data..." : detailsVM.intelligenceSummary)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineSpacing(4)
                .animation(.default, value: detailsVM.intelligenceSummary)
        }
    }
    
    private var monthlyGoalsSection: some View {
        SectionCard(title: "Monthly Goals", showPlus: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sales Target")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("For \(monthString)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Text(detailsVM.storeCurrency.symbol)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(salesTargetString.isEmpty ? .gray.opacity(0.5) : .themeAccent)
                        
                        TextField("0.00", text: $salesTargetString, onEditingChanged: { isEditing in
                            if !isEditing {
                                let amount = Double(salesTargetString) ?? 0.0
                                Task {
                                    if let storeID = AuthManager.shared.currentUser?.assignedStoreID {
                                        await detailsVM.saveMonthlyTarget(amount: amount, userID: user.id, storeID: storeID, date: date)
                                    }
                                }
                            }
                        })
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 32, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .frame(maxWidth: 120)
                    }
                }
                
                let targetAmount = detailsVM.monthlyTarget?.targetAmount ?? (Double(salesTargetString) ?? 0.0)
                if targetAmount > 0 {
                    let achieved = detailsVM.monthlySalesTotal
                    let percentage = min(1.0, achieved / targetAmount)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(format: "%@%.2f achieved", detailsVM.storeCurrency.symbol, achieved))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text(String(format: "%.0f%%", percentage * 100))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(percentage >= 1.0 ? .green : .themeAccent)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(percentage >= 1.0 ? Color.green : Color.themeAccent)
                                    .frame(width: max(0, geometry.size.width * CGFloat(percentage)), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
            .padding(.top, 16)
        }
    }
    
    private var checklistSection: some View {
        SectionCard(title: "Checklist", onAdd: {
            isAddingChecklistItem = true
            isNewItemFocused = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                if detailsVM.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(detailsVM.tasks) { task in
                        SwipeableChecklistItem(
                            task: task,
                            onToggle: {
                                Task { await detailsVM.toggleTask(task) }
                            },
                            onDelete: {
                                Task { await detailsVM.deleteTask(task) }
                            }
                        )
                    }
                }
                
                if isAddingChecklistItem {
                    HStack(spacing: 12) {
                        Image(systemName: "circle")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.system(size: 22))
                        
                        TextField("New item...", text: $newChecklistItemTitle)
                            .font(.system(size: 16))
                            .focused($isNewItemFocused)
                            .onSubmit {
                                if !newChecklistItemTitle.isEmpty {
                                    let titleToSave = newChecklistItemTitle
                                    Task { await detailsVM.addTask(userID: user.id, date: date, title: titleToSave) }
                                    newChecklistItemTitle = ""
                                }
                                isAddingChecklistItem = false
                            }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 16)
        }
    }
    
    private var monthlySalesSection: some View {
        SectionCard(title: "Monthly Sales - \(monthString)", showPlus: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Sales")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(detailsVM.storeCurrency.symbol + String(format: "%.2f", detailsVM.monthlySalesTotal))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if let storeID = AuthManager.shared.currentUser?.assignedStoreID {
                        NavigationLink(destination: AssociateSalesHistoryView(user: user, storeID: storeID)) {
                            Text("View All")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.themeAccent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.themeAccent.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                if !detailsVM.recentMonthlySales.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(spacing: 12) {
                        ForEach(detailsVM.recentMonthlySales) { sale in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Order #\(sale.id.uuidString.prefix(6))")
                                        .font(.system(size: 15, weight: .medium))
                                    Text(sale.saleDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(detailsVM.storeCurrency.symbol + String(format: "%.2f", sale.totalAmount))
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var appointmentsSection: some View {
        SectionCard(title: "Appointments", onAdd: {
            isShowingUnassigned = true
        }) {
            VStack(spacing: 12) {
                if appointmentsVM.appointments.isEmpty {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No appointments scheduled")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    let displayedAppts = showAllAppointments ? appointmentsVM.appointments : Array(appointmentsVM.appointments.prefix(3))
                    ForEach(displayedAppts) { appointment in
                        AppointmentRow(
                            appointment: appointment,
                            onUnassign: {
                                Task { await appointmentsVM.unassign(appointment: appointment) }
                            }
                        )
                    }
                    
                    if appointmentsVM.appointments.count > 3 {
                        Button(action: {
                            withAnimation(.spring()) {
                                showAllAppointments.toggle()
                            }
                        }) {
                            Text(showAllAppointments ? "View Less" : "View All")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.themeAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.themeAccent.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, appointmentsVM.appointments.isEmpty ? 20 : 10)
        }
    }
    
    @ViewBuilder
    private var salesHistorySection: some View {
        if !detailsVM.dailySalesDisplayData.isEmpty {
            SectionCard(title: "Sales History", showPlus: false) {
                VStack(spacing: 16) {
                    ForEach(detailsVM.dailySalesDisplayData) { displayData in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(displayData.saleDate.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "$%.2f", displayData.totalAmount))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.themeAccent)
                            }
                            
                            Divider()
                            
                            ForEach(displayData.items) { item in
                                SaleItemRowView(item: item, products: displayData.products)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 16)
            }
        }
    }
    
    private func initiateShiftChange(type: ShiftType) {
        guard !isCheckingShift else { return }
        isCheckingShift = true
        Task {
            if let conflict = await detailsVM.getNextConflictingAppointment(userID: user.id, newShiftType: type) {
                conflictingAppointment = conflict
                pendingShiftType = type
                showingShiftConflictAlert = true
            } else {
                saveShift(type: type)
            }
            isCheckingShift = false
        }
    }
    
    private func saveShift(type: ShiftType) {
        guard let storeID = AuthManager.shared.currentUser?.assignedStoreID else { return }
        Task {
            await detailsVM.saveShift(userID: user.id, storeID: storeID, date: date, type: type)
            await appointmentsVM.fetch(for: user.id)
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let showPlus: Bool
    let onAdd: (() -> Void)?
    let content: Content
    
    init(title: String, showPlus: Bool = true, onAdd: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.showPlus = showPlus
        self.onAdd = onAdd
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                
                if showPlus {
                    if let onAdd = onAdd {
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.themeAccent)
                                .font(.system(size: 20))
                        }
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.themeAccent)
                            .font(.system(size: 20))
                    }
                }
            }
            
            content
        }
        .padding(20)
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct ChecklistItemView: View {
    let task: DailyTask
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .themeAccent : .gray.opacity(0.5))
                    .font(.system(size: 22))
                
                Text(task.title)
                    .font(.system(size: 16, weight: task.isCompleted ? .regular : .medium))
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct SwipeableChecklistItem: View {
    let task: DailyTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete Button Background
            Button(action: {
                withAnimation {
                    onDelete()
                }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .frame(width: 60)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            .opacity(offset < -10 ? 1 : 0)
            
            // Foreground Content
            ChecklistItemView(task: task, onToggle: onToggle)
                .background(Color.themeCard)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = isSwiped ? max(-60 + value.translation.width, -80) : max(value.translation.width, -80)
                            } else if isSwiped && value.translation.width > 0 {
                                offset = min(-60 + value.translation.width, 0)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if offset < -30 {
                                    offset = -60
                                    isSwiped = true
                                } else {
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
        }
    }
}


struct AppointmentRow: View {
    let appointment: Appointment
    let onUnassign: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Unassign Background Button
            Button(action: {
                withAnimation {
                    onUnassign()
                }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .frame(width: 60)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .opacity(offset < -10 ? 1 : 0)
            
            // Foreground Content
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.client_profiles?.name ?? "Unknown Client")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(appointment.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let prefs = appointment.preferences, !prefs.isEmpty {
                        Text("Prefers: \(prefs)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.themeAccent)
                }
                Spacer()
                
                if appointment.status == .completed {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 22))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.themeBackground)
            .cornerRadius(12)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = isSwiped ? max(-60 + value.translation.width, -80) : max(value.translation.width, -80)
                        } else if isSwiped && value.translation.width > 0 {
                            offset = min(-60 + value.translation.width, 0)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if offset < -30 {
                                offset = -60
                                isSwiped = true
                            } else {
                                offset = 0
                                isSwiped = false
                            }
                        }
                    }
            )
        }
    }
}

struct LeaveRequestSheet: View {
    let user: User
    let currentViewDate: Date
    let detailsVM: AssociateDetailsViewModel
    @Binding var isPresented: Bool
    let onLeaveAssigned: () -> Void
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    @State private var isChecking = false
    @State private var showingConflictAlert = false
    @State private var showingAlreadyOnLeaveAlert = false
    @State private var conflictCount = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Leave Period")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("Assign Leave")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check & Assign") {
                        Task {
                            isChecking = true
                            
                            let alreadyOnLeave = await detailsVM.checkIfAlreadyOnLeave(userID: user.id, startDate: startDate, endDate: endDate)
                            if alreadyOnLeave {
                                isChecking = false
                                showingAlreadyOnLeaveAlert = true
                                return
                            }
                            
                            let storeID = AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
                            let count = await detailsVM.checkLeaveConflicts(userID: user.id, startDate: startDate, endDate: endDate)
                            isChecking = false
                            
                            if count > 0 {
                                conflictCount = count
                                showingConflictAlert = true
                            } else {
                                await detailsVM.assignLeave(userID: user.id, storeID: storeID, startDate: startDate, endDate: endDate, currentViewDate: currentViewDate)
                                onLeaveAssigned()
                                isPresented = false
                            }
                        }
                    }
                    .bold()
                    .disabled(isChecking)
                }
            }
            .alert("Conflicting Appointments", isPresented: $showingConflictAlert) {
                Button("Proceed anyway", role: .destructive) {
                    Task {
                        let storeID = AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
                        await detailsVM.assignLeave(userID: user.id, storeID: storeID, startDate: startDate, endDate: endDate, currentViewDate: currentViewDate)
                        onLeaveAssigned()
                        isPresented = false
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This associate has \(conflictCount) appointments scheduled during this period. If you proceed, you will need to reassign them.")
            }
            .alert("Leave Already Approved", isPresented: $showingAlreadyOnLeaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This associate already has an approved leave for these exact dates.")
            }
        }
    }
}

struct SaleItemRowView: View {
    let item: SalesItem
    let products: [Product]
    
    var body: some View {
        if let product = products.first(where: { $0.id == item.productID }) {
            HStack {
                Text("\(item.quantity)x \(product.name)")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                Spacer()
                Text(String(format: "$%.2f", item.subTotal))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}
