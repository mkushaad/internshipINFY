import SwiftUI

struct EventDetailView: View {
    let displayData: VIPEventDisplayData
    
    @State private var selectedTab: RSVPStatus = .pending
    
    // Derived filtered guests
    private var filteredGuests: [EventInvitation] {
        displayData.rsvps.filter { $0.rsvpStatus == selectedTab }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Hero Header Card
                VStack(alignment: .leading, spacing: 16) {
                    Text(displayData.event.title)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.white.opacity(0.7))
                            Text(displayData.event.date.formatted(date: .complete, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        if let tiers = displayData.event.targetTier {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Tiers: \(tiers)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(displayData.attendingCount) of \(displayData.event.maxCapacity) confirmed to attend")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.themeAccent, Color(hex: "2D2A26")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.themeAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // MARK: - Guest List with Segmented Picker
                VStack(alignment: .leading, spacing: 16) {
                    Text("Guest List")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.themeText)
                        .padding(.horizontal)
                    
                    // Segmented Control
                    Picker("Guest Status", selection: $selectedTab) {
                        Text("Pending (\(displayData.pendingCount))").tag(RSVPStatus.pending)
                        Text("Accepted (\(displayData.attendingCount))").tag(RSVPStatus.accepted)
                        Text("Declined (\(displayData.declinedCount))").tag(RSVPStatus.declined)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // List
                    if filteredGuests.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: emptyStateIcon(for: selectedTab))
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No \(selectedTab.rawValue) guests")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredGuests) { invite in
                                GuestRow(invite: invite)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
            }
            .padding(.top, 10)
            .padding(.bottom, 40)
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func emptyStateIcon(for status: RSVPStatus) -> String {
        switch status {
        case .accepted: return "checkmark.seal"
        case .declined: return "xmark.circle"
        case .maybe: return "questionmark.circle"
        case .pending: return "clock"
        }
    }
}

struct GuestRow: View {
    let invite: EventInvitation
    
    private var tierColor: Color {
        switch (invite.client_profiles?.tier ?? "").lowercased() {
        case "gold": return .themeAccent
        case "platinum": return .themeText
        default: return .secondary
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(invite.client_profiles?.name.prefix(1) ?? "?"))
                        .font(.headline)
                        .foregroundColor(.themeText)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(invite.client_profiles?.name ?? "Unknown Client")
                    .font(.headline)
                    .foregroundColor(.themeText)
                
                if let phone = invite.client_profiles?.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let tier = invite.client_profiles?.tier {
                Text(tier)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tierColor.opacity(0.15))
                    .foregroundColor(tierColor)
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.themeCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}
