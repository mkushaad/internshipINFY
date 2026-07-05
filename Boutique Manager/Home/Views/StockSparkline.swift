//
//  StockSparkline.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//


//
//  StockSparkline.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct StockSparkline: View {
    let data: [Int]
    let threshold: Int

    private var maxVal: CGFloat { CGFloat(data.max() ?? 1) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let points = data.enumerated().map { i, val in
                CGPoint(
                    x: CGFloat(i) / CGFloat(data.count - 1) * w,
                    y: h - (CGFloat(val) / maxVal) * h
                )
            }
            let thresholdY = h - (CGFloat(threshold) / maxVal) * h

            ZStack(alignment: .bottomLeading) {

                // Threshold line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: thresholdY))
                    path.addLine(to: CGPoint(x: w, y: thresholdY))
                }
                .stroke(Color.orange.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                // Fill under curve
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
                        colors: [Color.orange.opacity(0.25), Color.clear],
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
                        colors: [Color.orange, Color.red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )

                // Dot at current (last) point
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .position(points.last!)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.themeBackground.ignoresSafeArea()
        StockSparkline(
            data: [38, 30, 22, 15, 9, 6, 3],
            threshold: 10
        )
        .frame(height: 52)
        .padding()
    }
}