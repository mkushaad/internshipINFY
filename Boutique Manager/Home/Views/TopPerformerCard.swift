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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Header
            HStack(spacing: 4) {
                Image(systemName: "trophy")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Text("Top Performer")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }

            // Profile row — gauge replaces the $12.5k block
            Group {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 26, height: 26)
                        .foregroundColor(.gray.opacity(0.5))

                    VStack(alignment: .leading, spacing: 0) {
                        Text(topPerformerName ?? "N/A")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.themeText)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 2)

                    // Gauge in place of the sales figure
                    SemiCircularGauge(progress: progress, size: 64)
                        .padding(.trailing, -10)
                }
            }.padding(.top, 4)

            Spacer(minLength: 0)

            // Sales figure + insight merged into one block
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "$%.1fk", topPerformerSales / 1000.0))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.themeText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text("Outstanding client service driving high-end results.")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 170, maxHeight: .infinity, alignment: .top)
        .background(Color.themeCard)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    TopPerformerCard(topPerformerName: "Mock Name", topPerformerSales: 50000, progress: 0.8)
        .preferredColorScheme(.light)
}
