import SwiftUI

struct AddVIPEventSheet: View {
    @Environment(\.dismiss) var dismiss
    let storeID: UUID
    var availableCampaigns: [Campaign] = []
    var prefilledCampaign: Campaign? = nil
    let onAdd: (String, Date, Int, String?, UUID?) -> Void
    
    @State private var eventName: String = ""
    @State private var eventDate: Date = Date()
    @State private var maxCapacity: String = ""
    @State private var capacityError: String? = nil
    @State private var selectedCampaignID: UUID? = nil
    @State private var selectedTiers: Set<String> = []
    
    let tiers = ["Normal", "Gold", "Platinum"]
    
    // MARK: - Computed helpers
    
    private var selectedCampaign: Campaign? {
        guard let id = selectedCampaignID else { return nil }
        return availableCampaigns.first { $0.id == id }
    }
    
    private var campaignDeadline: Date? {
        guard let tillStr = selectedCampaign?.created_till else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        return iso.date(from: tillStr)
    }
    
    private var tiersLabel: String {
        selectedTiers.isEmpty ? "None selected" : selectedTiers.sorted().joined(separator: ", ")
    }
    
    private var isValid: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedTiers.isEmpty &&
        Int(maxCapacity) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Event Details
                Section(header: Text("Event Details")) {
                    TextField("Event Name", text: $eventName)
                    
                    // Date picker — constrained to campaign deadline if one is selected
                    if let deadline = campaignDeadline {
                        DatePicker(
                            "Date & Time",
                            selection: $eventDate,
                            in: Date()...deadline
                        )
                        .datePickerStyle(.compact)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                            Text("Must be before campaign end: \(deadline.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    } else {
                        DatePicker("Date & Time", selection: $eventDate, in: Date()...)
                            .datePickerStyle(.compact)
                    }
                    
                    // Capacity with integer validation
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Max Capacity", text: $maxCapacity)
                            .keyboardType(.numberPad)
                            .onChange(of: maxCapacity) { _, newValue in
                                // Strip non-digits
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue {
                                    maxCapacity = filtered
                                }
                                // Validate
                                if filtered.isEmpty {
                                    capacityError = nil
                                } else if let val = Int(filtered), val > 0 {
                                    capacityError = nil
                                } else {
                                    capacityError = "Must be a whole number greater than 0"
                                }
                            }
                        
                        if let error = capacityError {
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // MARK: Marketing & Audience
                Section(header: Text("Marketing & Audience")) {
                    
                    // Campaign picker (clean menu style)
                    if !availableCampaigns.isEmpty {
                        Picker("Campaign", selection: $selectedCampaignID) {
                            Text("None").tag(UUID?.none)
                            ForEach(availableCampaigns) { campaign in
                                Text(campaign.title).tag(UUID?.some(campaign.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedCampaignID) { _, _ in
                            // Clamp date if new deadline is earlier than current selection
                            if let deadline = campaignDeadline, eventDate > deadline {
                                eventDate = deadline
                            }
                        }
                    }
                    
                    // Multi-select guest tiers
                    DisclosureGroup {
                        ForEach(tiers, id: \.self) { tier in
                            Button {
                                if selectedTiers.contains(tier) {
                                    selectedTiers.remove(tier)
                                } else {
                                    selectedTiers.insert(tier)
                                }
                            } label: {
                                HStack {
                                    Text(tier)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedTiers.contains(tier) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.themeAccent)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Guest Tiers")
                            Spacer()
                            Text(tiersLabel)
                                .font(.subheadline)
                                .foregroundColor(selectedTiers.isEmpty ? .secondary : .themeAccent)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .navigationTitle("New VIP Event")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let campaign = prefilledCampaign {
                    selectedCampaignID = campaign.id
                    if eventName.isEmpty {
                        eventName = campaign.title
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard let capacity = Int(maxCapacity), capacity > 0 else { return }
                        let tierString = selectedTiers.sorted().joined(separator: ", ")
                        onAdd(eventName, eventDate, capacity, tierString.isEmpty ? nil : tierString, selectedCampaignID)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
