//
//  StockRow.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//


//
//  StockRow.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct StockRow: View {
    let item: LowStockItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.themeText)
                        .lineLimit(1)
                    Text(item.category)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text("\(item.remaining) left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.themeText.opacity(0.08))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(item.fillRatio, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.themeBackground.ignoresSafeArea()
        StockRow(item: .init(name: "Silk Evening Gown", category: "Dresses", remaining: 2, threshold: 10))
            .padding()
    }
}