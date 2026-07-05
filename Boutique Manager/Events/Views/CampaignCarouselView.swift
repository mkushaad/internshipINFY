import SwiftUI

struct CampaignCarouselView: View {
    let campaigns: [Campaign]
    let createdCampaignIDs: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Suggested by HQ", systemImage: "megaphone.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.themeAccent)
                Spacer()
                Text("\(campaigns.count) active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(campaigns) { campaign in
                        CampaignCard(
                            campaign: campaign,
                            isEventCreated: createdCampaignIDs.contains(campaign.id)
                        )
                        .containerRelativeFrame(.horizontal, count: 1, spacing: 32)
                    }
                }
                .scrollTargetLayout()
            }
            .safeAreaPadding(.horizontal, 16)
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

struct CampaignCard: View {
    let campaign: Campaign
    let isEventCreated: Bool
    
    private var gradientColors: [Color] {
        switch (campaign.type ?? "").lowercased() {
        case "seasonal":    return [Color(hex: "2D2A26"), Color(hex: "1A1714")]
        case "product launch": return [Color(hex: "3B2F1E"), Color(hex: "1A1410")]
        case "loyalty":     return [Color(hex: "2A2018"), Color(hex: "14100B")]
        default:            return [Color(hex: "2D2318"), Color(hex: "1A1510")]
        }
    }
    
    private var typeIcon: String {
        switch (campaign.type ?? "").lowercased() {
        case "seasonal": return "snowflake"
        case "product launch": return "sparkles"
        case "loyalty": return "crown.fill"
        case "discount": return "tag.fill"
        default: return "megaphone.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top gradient area
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Decorative circles
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 120, height: 120)
                    .offset(x: 140, y: -30)
                
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 80, height: 80)
                    .offset(x: -20, y: 60)
                
                VStack(alignment: .leading, spacing: 10) {
                    // Type badge
                    HStack(spacing: 5) {
                        Image(systemName: typeIcon)
                            .font(.system(size: 10, weight: .bold))
                        Text((campaign.type ?? "Campaign").uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(Color.boutiqueGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.boutiqueGold.opacity(0.15))
                    .cornerRadius(6)
                    
                    // Title
                    Text(campaign.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Description
                    if let desc = campaign.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    // Discount chip
                    if let discountValue = campaign.discountValue, discountValue > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                            Text(campaign.discountType?.lowercased() == "percentage"
                                 ? "\(Int(discountValue))% OFF"
                                 : "₹\(Int(discountValue)) OFF")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(6)
                    }
                }
                .padding(16)
            }
            .frame(height: 160)
            .clipped()
            
            // Bottom action area
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let theme = campaign.themeName, !theme.isEmpty {
                        Text("Theme: \(theme)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let till = campaign.created_till, !till.isEmpty {
                        Text("Till: \(formattedDate(till))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status indicator
                if isEventCreated {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                        Text("Event Scheduled")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(10)
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.system(size: 13))
                        Text("Not scheduled")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.themeCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
    
    private func formattedDate(_ str: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        if let date = iso.date(from: str) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return str
    }
}


