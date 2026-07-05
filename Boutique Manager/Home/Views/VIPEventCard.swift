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

    private var eventName: String { vipEvent?.title ?? "N/A" }
    
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

    private var summary: String { "\(acceptedCount) guests confirmed." }

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
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(spacing: 4) {
                Image(systemName: "star")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Text("Upcoming VIP Event")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            .padding(.bottom, 8)

            // Date + Event Name
            HStack(alignment: .firstTextBaseline, spacing: 8) {

                Text(eventName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.themeText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: -2) {
                    Group {
                        Text("\(eventDay)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.themeText)
                        Text(eventMonth)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                    } .padding(.leading, 10)
                    
                }
            }
            .padding(.bottom, 10)

            // Full-width Sparkline
            RSVPSparkline(data: rsvpData, currentWeekIndex: currentWeekIndex)
                .frame(maxWidth: .infinity, maxHeight: 68)
                .padding(.bottom, 8)

            // Summary
            Text(summary)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(2)
                .padding(.leading, 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 170, maxHeight: .infinity, alignment: .top)
        .background(Color.themeCard)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ZStack {
        Color.themeBackground.ignoresSafeArea()
        VIPEventCard()
    }
}
