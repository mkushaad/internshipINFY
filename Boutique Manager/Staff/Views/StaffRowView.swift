//
//  StaffRowView.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//


//
//  StaffRowView.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct StaffRowView: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            // Avatar initials
            ZStack {
                Circle()
                    .fill(Color.themeAccent.opacity(0.18))
                    .frame(width: 42, height: 42)
                Text(initials)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.themeAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.themeText)
                Text(user.email)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Active badge
            if user.isActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Active")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Not Active")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }

    private var initials: String {
        let f = user.firstName.prefix(1).uppercased()
        let l = user.lastName.prefix(1).uppercased()
        return "\(f)\(l)"
    }
}

#Preview {
    StaffRowView(user: User(
        id: UUID(),
        firstName: "Sarah",
        lastName: "Chen",
        email: "sarah@boutique.com",
        phoneNumber: "+1 555 0101",
        role: .salesAssociate,
        assignedStoreID: UUID(),
        isActive: true
    ))
    .padding()
}