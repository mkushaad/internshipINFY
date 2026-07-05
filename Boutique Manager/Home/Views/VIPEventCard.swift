//
//  UpcomingVIPEventCard.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//
import SwiftUI
struct VIPEventCard: View {
    private var vipEvent: VIPEvent? {
        let now = Date()
        return ([VIPEvent]())
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
            .first
    }
    private var eventName: String { vipEvent?.title ?? "" }
    
    private var eventMonth: String {
        guard let date = vipEvent?.date else { return "" }
        let f = DateFormatter(); f.dateFormat = "MMM"
        return f.string(from: date).uppercased()
    }
    
    private var eventDay: Int {
        guard let date = vipEvent?.date else { return 0 }
        return Calendar.current.component(.day, from: date)
    }
    private var acceptedCount: Int {
        guard let eventID = vipEvent?.id else { return 0 }
        return ([EventInvitation]())
            .filter { $0.eventID == eventID && $0.rsvpStatus == .accepted }
            .count
    }
    private var summary: String { "\(acceptedCount) guests confirmed" }
    private var rsvpData: [RSVPDataPoint] {
        let final = acceptedCount
        return [
            .init(week: 1, count: Int(Double(final) * 0.1)),
            .init(week: 2, count: Int(Double(final) * 0.3)),
            .init(week: 3, count: Int(Double(final) * 0.6)),
            .init(week: 4, count: final)
        ]
    }
    private var currentWeekIndex: Int { 3 }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Section label
            HStack(spacing: 6) {
                Text("Upcoming VIP Event")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            if let _ = vipEvent {
                // ── Event exists ──
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        // Calendar badge
                        VStack(spacing: 0) {
                            Text(eventMonth)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 2)
                                .background(Color.themeAccent)
                            
                            Text("\(eventDay)")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 4)
                        }
                        .frame(width: 36)
                        .background(Color.themeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(eventName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        Label("\(acceptedCount) guests confirmed", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // RSVP sparkline
                VStack(alignment: .leading, spacing: 6) {
                    Text("RSVP Progress")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    RSVPSparkline(data: rsvpData, currentWeekIndex: currentWeekIndex)
                        .frame(height: 30)
                }
                
            } else {
                // ── No events ──
                VStack(alignment: .leading, spacing: 6) {
                    Text("No events scheduled")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Tap to schedule next.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(Color.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}
#Preview {
    VIPEventCard()
        .padding()
        .background(Color.themeBackground)
}
