import SwiftUI
import Supabase
import Observation

struct BookAppointmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = BookAppointmentViewModel()
    
    @State private var selectedDate = Date()
    @State private var appointmentType: AppointmentType = .walkIn
    @State private var preferences: String = ""
    
    @State private var selectedCustomer: ClientProfile?
    @State private var selectedAssociateID: UUID?
    @State private var appointmentStatus: AppointmentStatus = .scheduled
    
    @State private var showingShiftAlert = false
    
    @State private var existingAppointment: Appointment?
    
    init(existingAppointment: Appointment? = nil) {
        self._existingAppointment = State(initialValue: existingAppointment)
        if let appt = existingAppointment {
            self._selectedDate = State(initialValue: appt.date)
            self._appointmentType = State(initialValue: appt.type)
            self._preferences = State(initialValue: appt.preferences ?? "")
            self._selectedAssociateID = State(initialValue: appt.salesAssociateID)
            self._appointmentStatus = State(initialValue: appt.status)
        }
    }
    
    // The store ID used for fetching associates
    private var currentStoreID: UUID {
        AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Client Details")) {
                    if let customer = selectedCustomer {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(customer.name)
                                    .font(.headline)
                            }
                            Spacer()
                            if existingAppointment == nil {
                                Button {
                                    selectedCustomer = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search client by name...", text: $viewModel.searchName)
                                .autocorrectionDisabled()
                                .onChange(of: viewModel.searchName) { _ in
                                    Task { await viewModel.searchCustomers() }
                                }
                        }
                        
                        if viewModel.isSearchingCustomers {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if !viewModel.customerResults.isEmpty {
                            ForEach(viewModel.customerResults) { customer in
                                Button(action: {
                                    selectedCustomer = customer
                                    viewModel.searchName = ""
                                    viewModel.customerResults = []
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(customer.name).foregroundColor(.primary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(.themeAccent)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Appointment Details")) {
                    DatePicker("Date & Time", selection: $selectedDate, in: min(existingAppointment?.date ?? Date(), Date())...)
                        .tint(Color.themeAccent)
                        .onChange(of: selectedDate) { newDate in
                            viewModel.filterAvailableAssociates(for: newDate, keeping: selectedAssociateID)
                        }
                    
                    Picker("Type", selection: $appointmentType) {
                        Text("Walk-In").tag(AppointmentType.walkIn)
                        Text("Video Consultation").tag(AppointmentType.videoConsultation)
                    }
                    .tint(Color.themeAccent)
                    
                    if viewModel.storeAssociates.isEmpty {
                        Text("Loading associates...")
                            .foregroundColor(.secondary)
                    } else if viewModel.availableAssociates.isEmpty {
                        HStack {
                            Text("Sales Associate")
                            Spacer()
                            Text("Not Available")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Sales Associate", selection: $selectedAssociateID) {
                            Text("Unassigned").tag(UUID?(nil))
                            ForEach(viewModel.availableAssociates) { associate in
                                Text("\(associate.firstName) \(associate.lastName)")
                                    .tag(UUID?(associate.id))
                            }
                        }
                        .tint(Color.themeAccent)
                    }
                    
                    if existingAppointment != nil {
                        Picker("Status", selection: $appointmentStatus) {
                            Text("Scheduled").tag(AppointmentStatus.scheduled)
                            if appointmentStatus == .completed || selectedDate <= Date() {
                                Text("Completed").tag(AppointmentStatus.completed)
                            }
                            Text("Cancelled").tag(AppointmentStatus.cancelled)
                            Text("No Show").tag(AppointmentStatus.noShow)
                        }
                        .tint(Color.themeAccent)
                    }
                    
                    TextField("Specific product preferences (Optional)", text: $preferences, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(existingAppointment != nil ? "Edit Appointment" : "Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingAppointment != nil ? "Save" : "Book") {
                        guard let customer = selectedCustomer else { return }
                        let newAppointment = Appointment(
                            id: existingAppointment?.id ?? UUID(),
                            storeID: currentStoreID,
                            customerID: customer.id,
                            salesAssociateID: selectedAssociateID,
                            date: selectedDate,
                            type: appointmentType,
                            status: existingAppointment != nil ? appointmentStatus : .scheduled,
                            preferences: preferences.isEmpty ? nil : preferences
                        )
                        
                        Task {
                            // Check shift if assigning to an associate and status is scheduled
                            if newAppointment.status == .scheduled, let associateID = selectedAssociateID {
                                let isAvailable = await viewModel.checkShiftAvailability(associateID: associateID, date: selectedDate)
                                if !isAvailable {
                                    showingShiftAlert = true
                                    return
                                }
                            }
                            
                            if existingAppointment != nil {
                                await viewModel.update(appointment: newAppointment)
                            } else {
                                await viewModel.insert(appointment: newAppointment)
                            }
                            dismiss()
                        }
                    }
                    .bold()
                    .foregroundColor(selectedCustomer == nil ? .gray : Color.themeAccent)
                    .disabled(selectedCustomer == nil || viewModel.isSaving)
                }
            }
        }
        .alert("Associate Unavailable", isPresented: $showingShiftAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The selected associate is not available during this timing. Please try changing their shift or selecting a different associate.")
        }
        .task {
            await viewModel.fetchAssociates(storeID: currentStoreID, date: selectedDate, keeping: selectedAssociateID)
            if let existing = existingAppointment, selectedCustomer == nil {
                await viewModel.fetchCustomer(id: existing.customerID)
                if let cust = viewModel.customerResults.first {
                    selectedCustomer = cust
                }
            }
        }
    }
}
