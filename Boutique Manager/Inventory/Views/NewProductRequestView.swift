import SwiftUI

struct NewProductRequestView: View {
    let product: Product
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateStoreRequestViewModel
    @State private var showSuccessToast: Bool = false
    
    // Callback to dismiss parent product list screen on success
    var onRequestCompleted: (() -> Void)? = nil
    
    init(product: Product, onRequestCompleted: (() -> Void)? = nil) {
        self.product = product
        self.onRequestCompleted = onRequestCompleted
        self._viewModel = StateObject(wrappedValue: CreateStoreRequestViewModel(product: product, defaultQuantity: 1))
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Product Header Section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.themeAccent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            if let imageUrlString = product.imageUrl,
                               let url = URL(string: imageUrlString),
                               !imageUrlString.isEmpty {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 54, height: 54)
                                            .cornerRadius(10)
                                    default:
                                        Image(systemName: "shippingbox.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.themeAccent)
                                    }
                                }
                            } else {
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.themeAccent)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text(product.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.themeText)
                                .multilineTextAlignment(.center)
                            
                            Text("SKU: \(product.sku)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Product Meta Information Card
                    DetailSection(title: "Product Information") {
                        InfoRow(
                            title: "Brand",
                            value: product.brand.isEmpty ? "Luxury Brand" : product.brand,
                            isBoldValue: true,
                            valueColor: .themeText
                        )
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        InfoRow(
                            title: "Category",
                            value: product.category.rawValue.capitalized,
                            isBoldValue: false
                        )
                    }
                    
                    // Request Parameters Card
                    DetailSection(title: "Request Details") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("QUANTITY REQUESTED")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                            
                            HStack {
                                Button(action: {
                                    if viewModel.quantity > 1 {
                                        viewModel.quantity -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(viewModel.quantity > 1 ? .themeAccent : .gray.opacity(0.4))
                                }
                                .disabled(viewModel.quantity <= 1 || viewModel.isSubmitting)
                                
                                Spacer()
                                
                                Text("\(viewModel.quantity)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.themeText)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.quantity += 1
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.themeAccent)
                                }
                                .disabled(viewModel.isSubmitting)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.themeBackground)
                            .cornerRadius(12)
                        }
                        
                        Divider().background(Color.themeText.opacity(0.06))
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PRIORITY LEVEL")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Picker("Priority", selection: $viewModel.selectedPriority) {
                                Text("Normal").tag(Priority.normal)
                                Text("Urgent").tag(Priority.urgent)
                            }
                            .pickerStyle(.segmented)
                            .disabled(viewModel.isSubmitting)
                        }
                    }
                    
                    Spacer(minLength: 24)
                    
                    // Action Button: Send Request
                    Button(action: {
                        Task {
                            let success = await viewModel.submitStoreRequest()
                            if success {
                                withAnimation {
                                    showSuccessToast = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                    onRequestCompleted?()
                                    dismiss()
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 15))
                                Text("Send Request")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.isSubmitting ? Color.gray : Color.themeAccent)
                        .cornerRadius(12)
                        .shadow(color: Color.themeAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(viewModel.isSubmitting)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            
            // Success Toast Banner
            if showSuccessToast {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                        
                        Text("Product request sent successfully.")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("New Product Request")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Request Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
    }
}

#Preview {
    NavigationStack {
        NewProductRequestView(
            product: Product(
                id: UUID(),
                sku: "RLX-GMT-126710",
                name: "Rolex GMT-Master II",
                brand: "Rolex",
                category: .general,
                basePrice: 10500.0,
                imageUrl: nil
            )
        )
    }
}
