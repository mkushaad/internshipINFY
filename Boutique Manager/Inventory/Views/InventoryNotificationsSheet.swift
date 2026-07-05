import SwiftUI

struct InventoryNotificationsSheet: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: NotificationTab = .unread

    enum NotificationTab: String, CaseIterable, Identifiable {
        case unread = "Unread"
        case all = "History"
        var id: String { self.rawValue }
    }

    var displayedNotifications: [InventoryNotification] {
        switch selectedTab {
        case .unread:
            return notificationManager.unreadNotifications
        case .all:
            return notificationManager.readNotifications
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented Filter Picker
                    Picker("Notifications", selection: $selectedTab) {
                        ForEach(NotificationTab.allCases) { tab in
                            Text(tab == .unread ? "Unread (\(notificationManager.unreadCount))" : "History (\(notificationManager.readCount))")
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if displayedNotifications.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.themeAccent.opacity(0.1))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.themeAccent)
                            }

                            Text(selectedTab == .unread ? "No Unread Notifications" : "No Notification History")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.themeText)

                            Text(selectedTab == .unread ? "You are all caught up! New alerts created during refresh will appear here." : "Viewed or dismissed notifications will be stored here.")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(displayedNotifications) { notification in
                                    NotificationCardRow(notification: notification) {
                                        notificationManager.markAsRead(id: notification.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Inventory Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        notificationManager.markAllAsRead()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeAccent)
                }
            }
            .onDisappear {
                // Automatically transition unread notifications to read status upon closing/viewing
                notificationManager.markAllAsRead()
            }
        }
    }
}

// MARK: - Notification Card Row Component (Clean, Untruncated Product Name & Details)
struct NotificationCardRow: View {
    let notification: InventoryNotification
    let onTap: () -> Void

    var badgeColor: Color {
        switch notification.type {
        case .outOfStock:
            return .red
        case .lowStock:
            return .orange
        case .stockTransfer:
            return .themeAccent
        }
    }

    var badgeIcon: String {
        switch notification.type {
        case .outOfStock:
            return "exclamationmark.triangle.fill"
        case .lowStock:
            return "shippingbox.fill"
        case .stockTransfer:
            return "arrow.left.arrow.right.circle.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                // Category Icon Container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(badgeColor.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: badgeIcon)
                        .font(.system(size: 20))
                        .foregroundColor(badgeColor)
                }

                // Untruncated Product Name & Relative Sent Timestamp
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(notification.productName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.themeText)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        if notification.status == .unread {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 7, height: 7)
                        }
                    }

                    Text(notification.createdAt.timeAgoString())
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Spacer(minLength: 8)

                // Alert Type Tag (Low Stock / Out of Stock / Stock Transfer)
                Text(notification.type.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(badgeColor)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(badgeColor.opacity(0.12))
                    .cornerRadius(12)
            }
            .padding(14)
            .background(notification.status == .unread ? Color.white : Color.white.opacity(0.75))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(notification.status == .unread ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    InventoryNotificationsSheet()
}
