//
//  RecentSalesCard.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct RecentSaleItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let timeAgo: String
    let price: Double
}

struct RecentSalesSection: View {
    let items: [RecentSaleItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Section Header
            HStack {
                Text("Recent Sales")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {}) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.themeAccent)
                }
            }

            // Rows
            VStack(spacing: 0) {
                if items.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "bag")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No recent sales to show")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    ForEach(items.indices, id: \.self) { index in
                        RecentSaleRow(item: items[index])
                        
                        if index < items.count - 1 {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
            }
            .background(Color.themeCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        }
    }
}

struct RecentSaleRow: View {
    let item: RecentSaleItem
    
    var body: some View {
        HStack(spacing: 14) {
            // Category Icon
            Image(systemName: categoryIcon)
                .font(.body)
                .foregroundColor(.themeAccent)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.themeAccent.opacity(0.10))
                )
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("\(item.category) · \(item.timeAgo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Price
            Text(String(format: "$%.0f", item.price))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    private var categoryIcon: String {
        switch item.category.lowercased() {
        case "bag", "bags", "handbags": return "bag.fill"
        case "apparel", "clothing": return "tshirt.fill"
        case "footwear", "shoes": return "shoe.fill"
        case "jewelry": return "diamond.fill"
        case "accessories": return "eyeglasses"
        case "wallet", "wallets": return "creditcard.fill"
        case "cosmetics": return "wand.and.stars"
        case "perfume": return "drop.fill"
        default: return "bag.fill"
        }
    }
}

#Preview {
    RecentSalesSection(items: [
        RecentSaleItem(name: "Classic Monogram Tote", category: "Handbags", timeAgo: "2h ago", price: 2500),
        RecentSaleItem(name: "Silk Evening Gown", category: "Apparel", timeAgo: "5h ago", price: 4200),
        RecentSaleItem(name: "Classic Wallet", category: "Wallet", timeAgo: "1d ago", price: 33000)
    ])
    .padding()
    .background(Color.themeBackground)
}
