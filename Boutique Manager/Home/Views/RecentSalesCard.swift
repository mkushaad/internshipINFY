//
//  RecentSalesCard.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct RecentSaleItem {
    let name: String
    let category: String
    let timeAgo: String
    let price: Double
}

struct RecentSalesCard: View {
    let items: [RecentSaleItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header
            HStack(spacing: 4) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.themeAccent) 
                Text("Recent Sales")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            .padding(.bottom, 8)

            // Sales rows
            VStack(spacing: 8) {
                if items.isEmpty {
                    Text("No sales as of now")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.vertical, 30)
                } else {
                    ForEach(items.indices, id: \.self) { i in
                        RecentSaleRow(item: items[i])
                        if i < items.count - 1 {
                            Divider()
                            .background(Color.themeText.opacity(0.1))
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 170, maxHeight: .infinity, alignment: .top)
        .background(Color.themeCard)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct RecentSaleRow: View {
    let item: RecentSaleItem
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.category)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.0f", item.price))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeAccent)
                Text(item.timeAgo)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.themeBackground.ignoresSafeArea()
        RecentSalesCard(items: [
            RecentSaleItem(name: "Mock Item", category: "Bag", timeAgo: "2m", price: 2500)
        ])
    }
}
