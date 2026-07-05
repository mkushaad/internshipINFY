import SwiftUI
import Supabase
import Observation

struct UnassignedAppointmentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let associate: User
    let storeID: UUID
    let onAssign: () -> Void
    
    @State private var viewModel = UnassignedAppointmentsViewModel()
    @State private var showingConflictAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else if viewModel.appointments.isEmpty {
                    Text("No unassigned appointments found.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.appointments) { appointment in
                        Button {
                            assign(appointment)
                        } label: {
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
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.themeAccent)
                                    .font(.title3)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Unassigned Appointments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await viewModel.fetchUnassigned(storeID: storeID)
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let msg = viewModel.errorMessage {
                    Text(msg)
                }
            }
            .alert("Associate Unavailable", isPresented: $showingConflictAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The associate is not available during this appointment time. Please assign to someone else or change their shift.")
            }
        }
    }
    
    private func assign(_ appointment: Appointment) {
        Task {
            let isAvailable = await viewModel.checkShiftAvailability(associateID: associate.id, date: appointment.date)
            if !isAvailable {
                showingConflictAlert = true
                return
            }
            
            let success = await viewModel.assign(appointment: appointment, to: associate.id)
            if success {
                onAssign()
                dismiss()
            }
        }
    }
}


