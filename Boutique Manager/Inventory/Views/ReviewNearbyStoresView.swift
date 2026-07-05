import SwiftUI

struct ReviewNearbyStoresView: View {
    @StateObject private var viewModel: ReviewNearbyStoresViewModel
    @State private var showFilters: Bool = false
    
    init(alert: StockAlert) {
        self._viewModel = StateObject(wrappedValue: ReviewNearbyStoresViewModel(alert: alert))
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search & Sort Bar Row
                HStack(spacing: 12) {
                    // Search Pill
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        
                        TextField("Search store name...", text: $viewModel.searchText)
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
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.themeBackground)
                    .cornerRadius(10)
                    
                    // Filter / Sort Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showFilters.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            if viewModel.selectedSortOption != .highestQuantity || !viewModel.searchText.isEmpty {
                                Circle()
                                    .fill(Color.themeAccent)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(showFilters ? .white : .themeAccent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(showFilters ? Color.themeAccent : Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                
                // Expandable Sort Drawer
                if showFilters {
                    VStack(alignment: .leading, spacing: 12) {
                        filterSectionTitle("Sort Stores By")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(NearbyStoresSortOption.allCases) { option in
                                    filterChip(option.rawValue, isSelected: viewModel.selectedSortOption == option) {
                                        viewModel.selectedSortOption = option
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        if viewModel.selectedSortOption != .highestQuantity || !viewModel.searchText.isEmpty {
                            Button(action: {
                                withAnimation {
                                    viewModel.searchText = ""
                                    viewModel.selectedSortOption = .highestQuantity
                                }
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Reset Filters")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.05))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 4)
                }
                
                // Main Candidate List Section
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView("Searching nearby stores with stock...")
                                .tint(.themeAccent)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else if viewModel.filteredAndSortedStores.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "building.2.crop.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.top, 40)
                                
                                Text("No nearby stores in your region have sufficient inventory for this product right now.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(viewModel.filteredAndSortedStores) { candidate in
                                NavigationLink(destination: TransferConfirmationView(candidate: candidate, alert: viewModel.alert, currentStoreName: viewModel.currentStoreName)) {
                                    NearbyStoreCandidateCard(candidate: candidate)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Nearby Stores")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .task {
            await viewModel.fetchNearbyStores()
        }
    }
    
    @ViewBuilder
    private func filterSectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.gray)
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                action()
            }
        }) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .themeText)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.themeAccent : Color.themeBackground)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Color.themeAccent : Color.gray.opacity(0.15), lineWidth: 1)
                )
        }
    }
}

// MARK: - Nearby Store Candidate Card View
struct NearbyStoreCandidateCard: View {
    let candidate: NearbyStoreCandidate
    
    var displayStoreName: String {
        candidate.store.name.isEmpty ? candidate.store.location : candidate.store.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row: Store Name & Region Badge
            HStack {
                Text("Boutique — \(displayStoreName)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeText)
                    .lineLimit(1)
                
                Spacer()
                
                Text(candidate.store.region)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.themeAccent)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(Color.themeAccent.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // Product Subtitle
            Text("Product: \(candidate.productName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)
            
            Divider()
                .background(Color.themeText.opacity(0.06))
            
            // Quantity Stats Row: Available & Requested
            HStack(spacing: 12) {
                // Available Quantity Stat
                HStack(spacing: 6) {
                    Text("Available:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(candidate.availableQuantity)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(0.08))
                .cornerRadius(10)
                
                // Requested Quantity Stat
                HStack(spacing: 6) {
                    Text("Requested:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(candidate.quantityRequested)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeAccent)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.themeAccent.opacity(0.08))
                .cornerRadius(10)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.themeAccent)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        ReviewNearbyStoresView(
            alert: StockAlert(
                id: UUID(),
                productName: "Rolex Daytona 116500LN",
                sku: "RLX-DT-116500",
                currentQuantity: 2,
                alertType: .transferRequested,
                priority: .high,
                source: .salesAssociate,
                generatedAt: Date(),
                description: "Stock request",
                quantityRequested: 4,
                productID: UUID()
            )
        )
    }
}
