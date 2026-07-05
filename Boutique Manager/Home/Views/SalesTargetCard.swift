//
//  TopRegionCard.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct SalesTargetCard: View {
    let percentage: Int
    let location: String
    let flag: String

    var body: some View {
        ZStack(alignment: .leading) {
            // Background Base
            Color.themeCard
            
            // Subtle Background Element Layer
            // Using a native SF Symbol as a placeholder for the map
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "globe.americas.fill") // Swap with Image("customMap") if you have an asset
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.themeAccent.opacity(0.1)) // Extremely low opacity for the watermark effect
                        .offset(x: 20, y: 20)
                }
            }
            
            // Foreground Content Layer
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(location)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Text(flag)
                }
                
                // Main Metric
                Text("\(percentage)%")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.themeText)
                    .padding(.leading, -5)
                
                Spacer(minLength: 10)
                
                // Insight Subtext
                // Grouping Text views allows for inline color changes
                (Text("of the target has been ")
                                    .foregroundColor(.gray)
                                + Text("achieved.")
                                    .foregroundColor(.themeText))
                                    .font(.system(size: 12))
                                    .lineSpacing(2)
                                    // 3. Forces SwiftUI to render the full text block vertically, preventing trimming
                                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 170, maxHeight: .infinity, alignment: .top)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    SalesTargetCard(percentage: 75, location: "New York", flag: "🇺🇸")
}
