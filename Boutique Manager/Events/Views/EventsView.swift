import SwiftUI

struct EventsView: View {
    @State private var viewModel = EventsViewModel()
    @State private var isSettingsPresented = false
    @State private var showAddEventSheet = false
    @State private var selectedCampaign: Campaign? = nil
    
    private var currentStoreID: UUID {
        AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
    }
    
    /// Campaign IDs that already have an event created (used to show status on cards)
    private var createdCampaignIDs: Set<UUID> {
        let allEvents = viewModel.upcomingEvents + viewModel.pastEvents
        return Set(allEvents.compactMap { $0.event.campaignID })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.upcomingEvents.isEmpty && viewModel.pastEvents.isEmpty {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // MARK: - Campaign Carousel
                            if !viewModel.activeCampaigns.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    CampaignCarouselView(
                                        campaigns: viewModel.activeCampaigns,
                                        createdCampaignIDs: createdCampaignIDs
                                    )
                                }
                                .padding(.top, 8)
                            }
                            
                            // MARK: - Events List
                            if viewModel.upcomingEvents.isEmpty && viewModel.pastEvents.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "ticket")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("No VIP Events Scheduled")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    if !viewModel.activeCampaigns.isEmpty {
                                        Text("Tap a campaign above to create your first event")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            } else {
                                VStack(alignment: .leading, spacing: 16) {
                                    if !viewModel.upcomingEvents.isEmpty {
                                        SectionHeader(title: "Upcoming Events")
                                        VStack(spacing: 10) {
                                            ForEach(viewModel.upcomingEvents) { data in
                                                NavigationLink(destination: EventDetailView(displayData: data)) {
                                                    EventRow(data: data)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .padding(.horizontal)
                                            }
                                        }
                                    }
                                    
                                    if !viewModel.pastEvents.isEmpty {
                                        SectionHeader(title: "Past Events")
                                        VStack(spacing: 10) {
                                            ForEach(viewModel.pastEvents) { data in
                                                NavigationLink(destination: EventDetailView(displayData: data)) {
                                                    EventRow(data: data)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .padding(.horizontal)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("VIP Events")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            selectedCampaign = nil
                            showAddEventSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        
                        Button(action: {
                            isSettingsPresented = true
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.themeText)
                        }
                    }
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .sheet(isPresented: $showAddEventSheet, onDismiss: {
                selectedCampaign = nil
            }) {
                AddVIPEventSheet(
                    storeID: currentStoreID,
                    availableCampaigns: viewModel.activeCampaigns,
                    prefilledCampaign: selectedCampaign
                ) { name, date, capacity, tier, campaignID in
                    Task {
                        await viewModel.createEvent(
                            title: name,
                            date: date,
                            maxCapacity: capacity,
                            targetTier: tier,
                            campaignID: campaignID,
                            storeID: currentStoreID
                        )
                    }
                }
            }
            .task {
                await viewModel.fetchEvents(forStoreID: currentStoreID)
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.themeText)
            .padding(.horizontal)
            .padding(.top, 4)
    }
}

// MARK: - Event Row
struct EventRow: View {
    let data: VIPEventDisplayData
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section (Details)
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(data.event.title)
                            .font(.headline)
                            .foregroundColor(.themeText)
                            
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.themeAccent)
                            Text(data.event.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Capacity Badge
                    VStack(spacing: 2) {
                        Text("MAX")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("\(data.event.maxCapacity)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.themeText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let tierString = data.event.targetTier {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.themeAccent)
                        Text("Tiers: \(tierString.replacingOccurrences(of: ",", with: " • "))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.themeText.opacity(0.8))
                    }
                }
            }
            .padding(16)
            .background(Color.themeCard)
            
            Divider()
            
            // Bottom Section (Stats)
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .font(.system(size: 16))
                        .foregroundColor(.themeAccent)
                    Text("\(data.attendingCount) Attending")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeText)
                }
                Spacer()
                
                HStack(spacing: 4) {
                    Text("View Guest List")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.04))
            .background(Color.themeCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    EventsView()
}
