import SwiftUI

struct InventoryNotificationsSheet: View {
    @ObservedObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var activeNotifications: [StockAlertPreview] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()

                if activeNotifications.isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.themeAccent.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.themeAccent)
                        }

                        Text("No New Notifications")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.themeText)

                        Text("You're all caught up! New low stock alerts generated upon refresh will appear here.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            HStack {
                                Text("\(activeNotifications.count) NEW ALERT\(activeNotifications.count > 1 ? "S" : "")")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .padding(.top, 8)

                            ForEach(activeNotifications) { alert in
                                NotificationAlertRow(alert: alert)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Inventory Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.markNotificationsAsViewed()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeAccent)
                }
            }
            .onAppear {
                // Store active notifications for viewing
                activeNotifications = viewModel.unreadNotifications
            }
            .onDisappear {
                // Empty notifications once viewed
                viewModel.markNotificationsAsViewed()
            }
        }
    }
}

// MARK: - Notification Alert Row Component
struct NotificationAlertRow: View {
    let alert: StockAlertPreview

    var badgeColor: Color {
        switch alert.status {
        case .outOfStock, .critical: return .red
        case .warning: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(badgeColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: alert.status == .outOfStock ? "exclamationmark.triangle.fill" : "bell.badge.fill")
                    .font(.system(size: 20))
                    .foregroundColor(badgeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.productName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeText)

                Text(alert.currentQuantity == 0 ? "Current Quantity: 0 (Out of Stock)" : "Current Quantity: \(alert.currentQuantity) units")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Low Stock")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.orange)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(12)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    InventoryNotificationsSheet(viewModel: InventoryViewModel())
}
