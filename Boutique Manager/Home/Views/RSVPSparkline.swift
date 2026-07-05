//
//  RSVPSparkline.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//


//
//  RSVPSparkline.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct RSVPSparkline: View {
    let data: [RSVPDataPoint]
    let currentWeekIndex: Int

    private var maxCount: CGFloat {
        CGFloat(data.map(\.count).max() ?? 1)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let points = data.enumerated().map { i, d in
                CGPoint(
                    x: CGFloat(i) / CGFloat(data.count - 1) * w,
                    y: h - (CGFloat(d.count) / maxCount) * h
                )
            }

            ZStack(alignment: .bottomLeading) {

                // Filled area under curve
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: CGPoint(x: points[0].x, y: h))
                    path.addLine(to: points[0])
                    for i in 1..<points.count {
                        let ctrl = CGPoint(
                            x: (points[i-1].x + points[i].x) / 2,
                            y: (points[i-1].y + points[i].y) / 2
                        )
                        path.addQuadCurve(to: ctrl, control: points[i-1])
                    }
                    path.addLine(to: CGPoint(x: points.last!.x, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.themeAccent.opacity(0.35), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: points[0])
                    for i in 1..<points.count {
                        let ctrl = CGPoint(
                            x: (points[i-1].x + points[i].x) / 2,
                            y: (points[i-1].y + points[i].y) / 2
                        )
                        path.addQuadCurve(to: ctrl, control: points[i-1])
                    }
                    path.addLine(to: points.last!)
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.themeAccent.opacity(0.6), Color.themeAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )

                // Dots at key milestones
                ForEach(Array(Set([1, 3, currentWeekIndex])).sorted(), id: \.self) { idx in
                    if idx < points.count {
                        Circle()
                            .fill(Color.themeAccent)
                            .frame(width: 6, height: 6)
                            .position(points[idx])
                    }
                }

                // Vertical line at current week
                if currentWeekIndex < points.count {
                    Path { path in
                        let x = points[currentWeekIndex].x
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: h))
                    }
                    .stroke(Color.themeText.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }

                // X-axis tick marks
                HStack {
                    ForEach(0..<data.count, id: \.self) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color.themeText.opacity(0.2))
                            .frame(width: 1, height: 4)
                    }
                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.themeBackground.ignoresSafeArea()
        RSVPSparkline(
            data: [
                .init(week: 1, count: 40),
                .init(week: 2, count: 95),
                .init(week: 3, count: 180),
                .init(week: 4, count: 310),
                .init(week: 5, count: 420),
                .init(week: 6, count: 480),
                .init(week: 7, count: 550),
            ],
            currentWeekIndex: 4
        )
        .frame(height: 68)
        .padding()
    }
}