import SwiftUI

struct ProductDetailView: View {
    let item: StoreInventoryItem

    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    
                    // Large Product Image Hero Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)

                        VStack(spacing: 16) {
                            if let imageUrlString = item.product.imageUrl,
                               let url = URL(string: imageUrlString),
                               !imageUrlString.isEmpty {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 160)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 180)
                                            .cornerRadius(16)
                                    case .failure:
                                        fallbackProductIcon
                                    @unknown default:
                                        fallbackProductIcon
                                    }
                                }
                            } else {
                                fallbackProductIcon
                            }

                            VStack(spacing: 6) {
                                Text(item.product.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.themeText)
                                    .multilineTextAlignment(.center)

                                HStack(spacing: 10) {
                                    // Availability Badge
                                    Text(item.availabilityStatus.rawValue)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(item.availabilityStatus.badgeColor)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 12)
                                        .background(item.availabilityStatus.badgeColor.opacity(0.12))
                                        .cornerRadius(16)

                                    // Current Quantity Pill
                                    Text("Qty: \(item.inventory.currentquantity)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.themeText)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 12)
                                        .background(Color.themeBackground)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(24)
                    }

                    // Information Card Section
                    DetailSection(title: "Product Specifications") {
                        InfoRow(title: "Name", value: item.product.name, isBoldValue: true)
                        Divider().background(Color.themeText.opacity(0.06))

                        InfoRow(title: "SKU", value: item.product.sku, isBoldValue: true)
                        Divider().background(Color.themeText.opacity(0.06))

                        InfoRow(title: "Brand", value: item.product.brand)
                        Divider().background(Color.themeText.opacity(0.06))

                        InfoRow(title: "Category", value: item.product.category.rawValue.capitalized)
                        Divider().background(Color.themeText.opacity(0.06))

                        InfoRow(title: "Base Price", value: formattedPrice(item.product.basePrice), isBoldValue: true, valueColor: .themeAccent)
                        Divider().background(Color.themeText.opacity(0.06))

                        InfoRow(
                            title: "Current Quantity",
                            value: "\(item.inventory.currentquantity)",
                            isBoldValue: true,
                            valueColor: item.inventory.currentquantity == 0 ? .red : .themeText
                        )
                    }

                    Spacer(minLength: 20)
                    
                    // Action Button: Add Stock
                    NavigationLink(destination: NewProductRequestView(product: item.product)) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.square.fill.on.square.fill")
                                .font(.system(size: 15))
                            Text("Add Stock")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.themeAccent)
                        .cornerRadius(12)
                        .shadow(color: Color.themeAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fallbackProductIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeBackground)
                .frame(width: 120, height: 120)

            Image(systemName: "shippingbox.fill")
                .font(.system(size: 48))
                .foregroundColor(.themeAccent)
        }
        .frame(height: 160)
    }

    private func formattedPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "₹\(price)"
    }
}
