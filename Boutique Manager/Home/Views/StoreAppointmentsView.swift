import SwiftUI
import Supabase
import Observation

struct StoreAppointmentsView: View {
    @State private var viewModel = StoreAppointmentsViewModel()
    @State private var selectedTab: Int
    @State private var showBookingSheet = false
    @State private var editingAppointment: Appointment? = nil
    
    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    private var currentStoreID: UUID {
        AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Tabs", selection: $selectedTab) {
                Text("Upcoming").tag(0)
                Text("Ongoing").tag(1)
                Text("Completed").tag(2)
                Text("Unassigned").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.themeBackground)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                List {
                    let appointments = getAppointments(for: selectedTab)
                    if appointments.isEmpty {
                        Text("No appointments found.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(appointments) { appt in
                            Button {
                                editingAppointment = appt
                            } label: {
                                StoreAppointmentRow(appointment: appt)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.themeBackground)
            }
        }
        .navigationTitle("Store Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingAppointment = nil
                    showBookingSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.fetchAppointments(for: currentStoreID)
        }
        .sheet(isPresented: $showBookingSheet) {
            BookAppointmentSheet(existingAppointment: nil)
                .onDisappear {
                    Task { await viewModel.fetchAppointments(for: currentStoreID) }
                }
        }
        .sheet(item: $editingAppointment) { appt in
            BookAppointmentSheet(existingAppointment: appt)
                .onDisappear {
                    Task { await viewModel.fetchAppointments(for: currentStoreID) }
                }
        }
    }
    
    private func getAppointments(for tab: Int) -> [Appointment] {
        switch tab {
        case 0: return viewModel.upcomingAppointments
        case 1: return viewModel.ongoingAppointments
        case 2: return viewModel.completedAppointments
        case 3: return viewModel.unassignedAppointments
        default: return []
        }
    }
}

struct StoreAppointmentRow: View {
    let appointment: Appointment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.client_profiles?.name ?? "Unknown Client")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(appointment.type.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.themeAccent.opacity(0.1))
                        .foregroundColor(.themeAccent)
                        .cornerRadius(6)
                    
                    if let status = getStatusText() {
                        Text(status.text)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.color.opacity(0.1))
                            .foregroundColor(status.color)
                            .cornerRadius(6)
                    }
                }
                
                if let prefs = appointment.preferences, !prefs.isEmpty {
                    Text("Prefers: \(prefs)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let associate = appointment.associate {
                    ZStack {
                        Circle()
                            .fill(Color.themeAccent.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Text(String(associate.firstName.prefix(1) + associate.lastName.prefix(1)))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.themeAccent)
                    }
                    Text(associate.firstName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    Text("Unassigned")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    
    private func getStatusText() -> (text: String, color: Color)? {
        switch appointment.status {
        case .completed: return ("Completed", .green)
        case .cancelled: return ("Cancelled", .red)
        case .noShow: return ("No Show", .orange)
        case .scheduled: return nil // Just use the tab context
        }
    }
}
