import SwiftUI

struct StaffScheduleView: View {
    let storeID: UUID
    @State private var viewModel = StaffViewModel()
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    enum ScheduleFilter: String, CaseIterable, Hashable {
        case morning = "Morning"
        case evening = "Evening"
        case unassigned = "Unassigned"
    }
    
    @State private var selectedFilter: ScheduleFilter = .morning
    
    private var weekDates: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Start from Monday of the current week
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        guard let startOfWeek = calendar.date(from: components) else {
            return [today]
        }
        
        // Show 14 days
        for i in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }
    
    private var filteredAndSortedStaff: [User] {
        guard let staff = viewModel.liveStaff?.filter({ $0.role == .salesAssociate }) else { return [] }
        
        let sortedStaff = staff.sorted { u1, u2 in
            let onLeave1 = viewModel.leaves[u1.id] != nil
            let onLeave2 = viewModel.leaves[u2.id] != nil
            
            if u1.isActive != u2.isActive {
                return u1.isActive // Active first
            }
            if u1.isActive {
                if onLeave1 != onLeave2 {
                    return !onLeave1 // Not on leave first
                }
            }
            return u1.firstName < u2.firstName
        }
        
        return sortedStaff.filter { user in
            let shift = viewModel.shifts[user.id]?.shiftType
            let onLeave = viewModel.leaves[user.id] != nil
            
            switch selectedFilter {
            case .unassigned:
                return shift == nil && !onLeave
            case .morning:
                return shift == .morning
            case .evening:
                return shift == .evening
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Horizontal Date Picker
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(weekDates, id: \.self) { date in
                            DateSelectButton(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            ) {
                                withAnimation {
                                    selectedDate = date
                                    proxy.scrollTo(date, anchor: .center)
                                }
                            }
                            .id(date)
                        }
                    }
                    .padding()
                }
                .background(Color.themeBackground)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Find the exact matching date in the array to scroll to it
                        if let match = weekDates.first(where: { Calendar.current.isDate($0, inSameDayAs: selectedDate) }) {
                            proxy.scrollTo(match, anchor: .center)
                        }
                    }
                }
                .onChange(of: selectedDate) { newDate in
                    if let match = weekDates.first(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
                        withAnimation {
                            proxy.scrollTo(match, anchor: .center)
                        }
                    }
                }
            }
            
            // Shift Filter Segmented Control
            Picker("Shift Filter", selection: $selectedFilter) {
                ForEach(ScheduleFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Staff List
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.isLoading && viewModel.liveStaff == nil {
                        ProgressView("Loading Staff...")
                            .padding()
                    } else if !filteredAndSortedStaff.isEmpty {
                        if viewModel.isScheduleLoading {
                            ProgressView("Loading Schedule...")
                                .padding()
                        } else {
                            ForEach(filteredAndSortedStaff) { user in
                                NavigationLink(destination: AssociateDetailsView(user: user, date: selectedDate)) {
                                    StaffScheduleRowView(
                                        user: user,
                                        date: selectedDate,
                                        shift: viewModel.shifts[user.id],
                                        leave: viewModel.leaves[user.id],
                                        tasks: viewModel.tasks[user.id] ?? [],
                                        apptCount: viewModel.appointmentCounts[user.id] ?? 0
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        Text("No staff found.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .background(Color.themeBackground)
        }
        .navigationTitle("Staff Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.themeBackground.ignoresSafeArea())
        .onChange(of: selectedDate) { _ in
            Task {
                await viewModel.fetchScheduleData(forStoreID: storeID, date: selectedDate)
            }
        }
        .task {
            await viewModel.fetchStaff(forStoreID: storeID)
            await viewModel.fetchAlerts(forStoreID: storeID)
            await viewModel.fetchScheduleData(forStoreID: storeID, date: selectedDate)
        }
    }
}

struct DateSelectButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Text(dayOfWeek)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                Text(dayOfMonth)
                    .font(.system(size: 20, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .padding(.horizontal, 4)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.themeAccent : Color.clear)
            .cornerRadius(12)
        }
    }
}

struct StaffScheduleRowView: View {
    let user: User
    let date: Date
    let shift: Shift?
    let leave: Leave?
    let tasks: [DailyTask]
    let apptCount: Int
    
    private func formattedLeaveEndDate(from dateString: String) -> String? {
        let parseFormatter = DateFormatter()
        parseFormatter.dateFormat = "yyyy-MM-dd"
        if let endDate = parseFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: endDate)
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Circle()
                            .fill((user.isActive && leave == nil) ? Color.themeAccent : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                    
                    if let leave = leave {
                        if let displayString = formattedLeaveEndDate(from: leave.endDate) {
                            Text("On Leave (until \(displayString))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                        } else {
                            Text("On Leave")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    } else if let shift = shift {
                        Text(shift.shiftType.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.themeAccent)
                    } else {
                        Text("No Shift Assigned")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            
            Divider()
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.themeAccent)
                    Text("\(apptCount) Appts")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.square")
                        .foregroundColor(.themeAccent)
                    Text("\(tasks.filter { $0.isCompleted }.count)/\(tasks.count) Tasks")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
