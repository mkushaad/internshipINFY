import SwiftUI

struct StoreInventoryView: View {
    @StateObject private var viewModel: StoreInventoryViewModel
    @State private var showFilterPanel: Bool = false

    init(initialFilterLowStock: Bool = false) {
        _viewModel = StateObject(wrappedValue: StoreInventoryViewModel(initialFilterLowStock: initialFilterLowStock))
    }

    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Search & Filter Control Bar
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        // Search Input Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))

                            TextField("Search product or SKU...", text: $viewModel.searchText)
                                .font(.system(size: 14))
                                .foregroundColor(.themeText)

                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    viewModel.searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.themeBackground)
                        .cornerRadius(12)

                        // Gold Slider Filter Toggle Button (Matching Screenshot Aesthetic)
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showFilterPanel.toggle()
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.themeAccent)
                                    .frame(width: 40, height: 40)

                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                if viewModel.selectedFilter != .all || viewModel.selectedSortOption != .alphabetical || viewModel.sortDirection != .ascending {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 12, y: -12)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, showFilterPanel ? 4 : 10)

                    // Collapsible Filter Panel (Styled precisely like screenshot)
                    if showFilterPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            // Section 1: STOCK AVAILABILITY / ALERT TYPE
                            VStack(alignment: .leading, spacing: 8) {
                                Text("STOCK AVAILABILITY")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(InventoryFilterOption.allCases) { option in
                                            PillFilterTag(
                                                title: option.rawValue,
                                                isSelected: viewModel.selectedFilter == option
                                            ) {
                                                viewModel.selectedFilter = option
                                            }
                                        }
                                    }
                                }
                            }

                            // Section 2: SORT BY
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SORT BY")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(StoreInventorySortOption.allCases) { option in
                                            PillFilterTag(
                                                title: option.rawValue,
                                                isSelected: viewModel.selectedSortOption == option
                                            ) {
                                                viewModel.selectedSortOption = option
                                            }
                                        }
                                    }
                                }
                            }

                            // Section 3: SORT ORDER (Ascending / Descending)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SORT ORDER")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)

                                HStack(spacing: 8) {
                                    ForEach(SortDirection.allCases) { direction in
                                        PillFilterTag(
                                            title: direction.rawValue,
                                            isSelected: viewModel.sortDirection == direction
                                        ) {
                                            viewModel.sortDirection = direction
                                        }
                                    }
                                }
                            }

                            if viewModel.selectedFilter != .all || !viewModel.searchText.isEmpty || viewModel.selectedSortOption != .alphabetical || viewModel.sortDirection != .ascending {
                                HStack {
                                    Spacer()
                                    Button("Reset All Filters") {
                                        viewModel.clearFilters()
                                        viewModel.selectedSortOption = .alphabetical
                                        viewModel.sortDirection = .ascending
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.red)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)

                // Main Content Area
                if viewModel.isLoading && viewModel.inventoryItems.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .themeAccent))
                            .scaleEffect(1.2)
                        Text("Loading store inventory...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMsg = viewModel.errorMessage, viewModel.inventoryItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.orange)

                        Text("Error Loading Inventory")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.themeText)

                        Text(errorMsg)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button(action: {
                            Task {
                                await viewModel.fetchStoreInventory()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(Color.themeAccent)
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.inventoryItems.isEmpty {
                    // Store Has No Products Empty State
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.themeAccent.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "shippingbox")
                                .font(.system(size: 36))
                                .foregroundColor(.themeAccent)
                        }

                        Text("No products available for this store.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.themeText)

                        Text("Products assigned to your boutique store will appear here.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredAndSortedItems.isEmpty {
                    // Search Empty State
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 40)

                        Text("No matching products found")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)

                        Button("Clear Filters & Search") {
                            viewModel.clearFilters()
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeAccent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Store Inventory Scrollable Product Card List (No List Chevrons)
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredAndSortedItems) { item in
                                NavigationLink(destination: ProductDetailView(item: item)) {
                                    StoreInventoryRow(item: item)
                                }
                                .buttonStyle(InteractiveCardButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .refreshable {
                        await viewModel.fetchStoreInventory()
                    }
                }
            }
        }
        .navigationTitle("Store Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await viewModel.fetchStoreInventory()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.themeAccent)
                    }
                    
                    NavigationLink(destination: AddProductView()) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.themeAccent)
                    }
                }
            }
        }
    }
}

// MARK: - Interactive Tappable Card Button Style
struct InteractiveCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Store Inventory Row Component (No SKU, No Brand, No Chevron)
struct StoreInventoryRow: View {
    let item: StoreInventoryItem

    var body: some View {
        HStack(spacing: 14) {
            // Product Image Container
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.themeAccent.opacity(0.08))
                    .frame(width: 58, height: 58)

                if let imageUrlString = item.product.imageUrl,
                   let url = URL(string: imageUrlString),
                   !imageUrlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .cornerRadius(10)
                        default:
                            fallbackIcon
                        }
                    }
                } else {
                    fallbackIcon
                }
            }

            // Product Title and Quantity Subtitle
            VStack(alignment: .leading, spacing: 6) {
                Text(item.product.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 4) {
                    Image(systemName: "box.truck.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    Text("\(item.inventory.currentquantity) Available")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Dynamic Availability Badge (Top Right)
            VStack(alignment: .trailing, spacing: 0) {
                Text(item.availabilityStatus.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(item.availabilityStatus.badgeColor)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(item.availabilityStatus.badgeColor.opacity(0.12))
                    .cornerRadius(14)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
    }

    private var fallbackIcon: some View {
        Image(systemName: "shippingbox.fill")
            .font(.system(size: 26))
            .foregroundColor(.themeAccent)
    }
}

// MARK: - Pill Filter Tag Component (Matching Design Screenshot)
struct PillFilterTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .themeText)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    isSelected ? Color.themeAccent : Color.gray.opacity(0.1)
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        StoreInventoryView()
    }
}
