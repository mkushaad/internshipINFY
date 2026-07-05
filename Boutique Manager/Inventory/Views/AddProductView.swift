import SwiftUI

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddProductViewModel()
    @State private var showFilterPanel: Bool = false
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Search & Filter Bar
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        // Search Field
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                            
                            TextField("Search product, SKU, or brand...", text: $viewModel.searchText)
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
                        
                        // Filter Panel Toggle Button
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
                                
                                if viewModel.hasActiveFilters {
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
                    
                    // Collapsible Filter Panel
                    if showFilterPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            // Section 1: SORT BY
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SORT BY")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(AddProductSortOption.allCases) { option in
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
                            
                            // Clear Filters Button
                            if viewModel.hasActiveFilters {
                                Button(action: {
                                    withAnimation {
                                        viewModel.resetFilters()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Clear Filters")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.05))
                                    .cornerRadius(8)
                                }
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
                
                // Content List Area
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .themeAccent))
                            .scaleEffect(1.2)
                        Text("Checking product catalog...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.unstockedProducts.isEmpty {
                    // Empty State: All available products are already stocked
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 52))
                            .foregroundColor(.green.opacity(0.8))
                            .padding(.top, 60)
                        
                        Text("All available products are already stocked or pending request.")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.themeText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Text("Your store inventory currently stocks or has requested all items in the master catalog.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else if viewModel.filteredAndSortedProducts.isEmpty {
                    // Empty State: Search filter result empty
                    VStack(spacing: 14) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 60)
                        
                        Text("No matching unstocked products found.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredAndSortedProducts) { product in
                                NavigationLink(
                                    destination: NewProductRequestView(
                                        product: product,
                                        onRequestCompleted: {
                                            dismiss()
                                        }
                                    )
                                ) {
                                    UnstockedProductRowCard(product: product)
                                }
                                .buttonStyle(InteractiveCardButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .refreshable {
                        await viewModel.fetchUnstockedProducts()
                    }
                }
            }
        }
        .navigationTitle("Add Product to Store")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Unstocked Product Row Card Component
struct UnstockedProductRowCard: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeAccent.opacity(0.08))
                    .frame(width: 54, height: 54)
                
                if let imageUrlString = product.imageUrl,
                   let url = URL(string: imageUrlString),
                   !imageUrlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .cornerRadius(8)
                        default:
                            Image(systemName: "plus.square.fill")
                                .foregroundColor(.themeAccent)
                                .font(.system(size: 22))
                        }
                    }
                } else {
                    Image(systemName: "plus.square.fill")
                        .foregroundColor(.themeAccent)
                        .font(.system(size: 22))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeText)
                    .lineLimit(1)
                
                Text("SKU: \(product.sku)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                HStack(spacing: 6) {
                    Text(product.brand.isEmpty ? "Brand" : product.brand)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.themeAccent)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(Color.themeAccent.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text(product.category.rawValue.capitalized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(6)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}
