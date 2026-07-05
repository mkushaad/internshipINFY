import SwiftUI

struct InventoryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("work in progress")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Inventory")
        }
    }
}

#Preview {
    InventoryView()
}
