//
//  SemiGaugeView.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import Foundation

//
//  TopPerformerCard.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct SemiCircularGauge: View {
    let progress: CGFloat // 0.0 to 1.0
    let size: CGFloat

    private var startAngle: Angle { .degrees(180) }
    private var endAngle: Angle { .degrees(0) }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(Color.themeText.opacity(0.08), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(180))

            // Fill
            Circle()
                .trim(from: 0, to: progress * 0.5)
                .stroke(
                    LinearGradient(
                        colors: [Color.themeAccent.opacity(0.6), Color.themeAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(180))

            // Percentage label
            VStack(spacing: 0) {
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.themeText)
            }
            .frame(height: size / 2 + 4)
        }
        .frame(width: size, height: size / 2)
    }
}


