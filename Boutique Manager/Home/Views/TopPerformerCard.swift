//
//  TopPerformerCard.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//
import SwiftUI
struct TopPerformerCard: View {
    let topPerformerName: String?
    let topPerformerSales: Double
    let progress: CGFloat
    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section label
            HStack(spacing: 6) {
                Text("Top Performer of \(currentMonthName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            if let name = topPerformerName {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // Avatar
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundStyle(.quaternary)
                        
                        Spacer()
                        
                        // Sales Amount
                        Text(formatSales(topPerformerSales))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.themeAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.themeAccent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    // Name & Label
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("Outstanding Service")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No data yet")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("No performer for this period")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(Color.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
    
    private func formatSales(_ amount: Double) -> String {
        if amount >= 100000 {
            return String(format: "$%.1fk", amount / 1000.0)
        } else if amount >= 1000 {
            return String(format: "$%.1fk", amount / 1000.0)
        } else {
            return String(format: "$%.0f", amount)
        }
    }
}
#Preview {
    TopPerformerCard(topPerformerName: "Gorish Verma", topPerformerSales: 6688000, progress: 0.8)
        .padding()
        .background(Color.themeBackground)
}
