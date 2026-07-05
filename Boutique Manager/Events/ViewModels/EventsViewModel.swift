import Foundation
import Observation
import Supabase

struct VIPEventDisplayData: Identifiable {
    let event: VIPEvent
    var rsvps: [EventInvitation]
    
    var id: UUID { event.id }
    
    var attendingCount: Int {
        rsvps.filter { $0.rsvpStatus == .accepted }.count
    }
    var pendingCount: Int {
        rsvps.filter { $0.rsvpStatus == .pending }.count
    }
    var declinedCount: Int {
        rsvps.filter { $0.rsvpStatus == .declined }.count
    }
}

@Observable
class EventsViewModel {
    var upcomingEvents: [VIPEventDisplayData] = []
    var pastEvents: [VIPEventDisplayData] = []
    var activeCampaigns: [Campaign] = []
    var storeRegion: String? = nil
    var isLoading = false
    var errorMessage: String? = nil
    
    func fetchEvents(forStoreID storeID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        // Fetch events and campaigns concurrently
        async let eventsTask: Void = _fetchEvents(forStoreID: storeID)
        async let campaignsTask: Void = fetchCampaigns(forStoreID: storeID)
        _ = await (eventsTask, campaignsTask)
        
        await MainActor.run { self.isLoading = false }
    }
    
    private func _fetchEvents(forStoreID storeID: UUID) async {
        do {
            let events: [VIPEvent] = try await SupabaseService.shared.client
                .from("VIPEvent")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .order("date", ascending: false)
                .execute()
                .value
            
            var displayDataList: [VIPEventDisplayData] = []
            
            for event in events {
                let rsvps: [EventInvitation] = try await SupabaseService.shared.client
                    .from("EventInvitation")
                    .select("*, client_profiles(*)")
                    .eq("eventID", value: event.id.uuidString)
                    .execute()
                    .value
                
                displayDataList.append(VIPEventDisplayData(event: event, rsvps: rsvps))
            }
            
            let now = Date()
            
            await MainActor.run {
                self.upcomingEvents = displayDataList.filter { $0.event.date >= now }.sorted(by: { $0.event.date < $1.event.date })
                self.pastEvents = displayDataList.filter { $0.event.date < now }
            }
        } catch {
            print("Failed to fetch events: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load events."
            }
        }
    }
    
    func fetchCampaigns(forStoreID storeID: UUID) async {
        do {
            // Step 1: Get the store's region
            struct StoreRegionData: Codable { let region: String? }
            let store: StoreRegionData = try await SupabaseService.shared.client
                .from("Store")
                .select("region")
                .eq("id", value: storeID.uuidString)
                .single()
                .execute()
                .value
            
            guard let region = store.region, !region.isEmpty else { return }
            
            await MainActor.run { self.storeRegion = region }
            
            // Step 2: Fetch campaigns matching this region and filter out expired ones
            let campaigns: [Campaign] = try await SupabaseService.shared.client
                .from("Campaign")
                .select()
                .ilike("sentToRegion", value: "%\(region)%")
                .execute()
                .value
            
            let today = Calendar.current.startOfDay(for: Date())
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withFullDate]
            
            let activeCampaigns = campaigns.filter { campaign in
                guard let tillString = campaign.created_till,
                      let tillDate = isoFormatter.date(from: tillString) else {
                    return true // No expiry = always active
                }
                return tillDate >= today
            }
            
            await MainActor.run { self.activeCampaigns = activeCampaigns }
        } catch {
            print("Failed to fetch campaigns: \(error)")
        }
    }
    
    func createEvent(title: String, date: Date, maxCapacity: Int, targetTier: String?, campaignID: UUID? = nil, storeID: UUID) async {
        guard let currentUserID = AuthManager.shared.currentUser?.id else { return }
        
        let newEvent = VIPEvent(
            id: UUID(),
            storeID: storeID,
            organizerID: currentUserID,
            title: title,
            date: date,
            maxCapacity: maxCapacity,
            campaignID: campaignID,
            targetTier: targetTier
        )
        
        do {
            try await SupabaseService.shared.client
                .from("VIPEvent")
                .insert(newEvent)
                .execute()
                
            // Automatically generate RSVPs if tiers are selected
            if let targetTier = targetTier, !targetTier.isEmpty {
                let selectedTiers = targetTier.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                
                // Fetch clients matching these tiers
                let clients: [ClientProfile] = try await SupabaseService.shared.client
                    .from("client_profiles")
                    .select()
                    .in("tier", values: selectedTiers)
                    .execute()
                    .value
                
                let invitations = clients.map { client in
                    EventInvitation(
                        id: UUID(),
                        eventID: newEvent.id,
                        customerID: client.id,
                        rsvpStatus: .pending
                    )
                }
                
                if !invitations.isEmpty {
                    try await SupabaseService.shared.client
                        .from("EventInvitation")
                        .insert(invitations)
                        .execute()
                }
            }
                
            await fetchEvents(forStoreID: storeID)
        } catch {
            print("Failed to create event: \(error)")
        }
    }
}
