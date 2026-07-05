import SwiftUI

struct CategorySalesDetailView: View {
    @StateObject private var viewModel = SalesPerformanceViewModel()
    @State private var salesTargetViewModel = SalesTargetViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: String = "All"
    @State private var sortBy: String = "Date" // "Date" or "Amount"
    @State private var sortDescending: Bool = true
    
    let categories = ["All", "Handbags", "Fragrances", "Accessories", "Jewellery", "Watches", "Footware"]
    
    private var currentStoreID: UUID {
        AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
    }
    
    private var filteredAndSortedSales: [DetailedSaleItem] {
        var result = viewModel.detailedSalesList
        
        if selectedCategory != "All" {
            result = result.filter { $0.category.rawValue == selectedCategory }
        }
        
        result.sort { a, b in
            if sortBy == "Date" {
                return sortDescending ? a.date > b.date : a.date < b.date
            } else {
                return sortDescending ? a.amount > b.amount : a.amount < b.amount
            }
        }
        
        return result
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category)
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.boutiqueGold : Color.white)
                                .foregroundColor(selectedCategory == category ? .white : Color.boutiqueDarkBrown)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: selectedCategory == category ? 0 : 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color.boutiqueWarmWhite)
            
            // Sort Controls
            HStack {
                Text("Sort by:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.boutiqueDarkBrown)
                
                Menu {
                    Button("Date") { sortBy = "Date" }
                    Button("Amount") { sortBy = "Amount" }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortBy)
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.boutiqueGold.opacity(0.15))
                    .foregroundColor(Color.boutiqueDarkBrown)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    sortDescending.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: sortDescending ? "arrow.down" : "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                        Text(sortDescending ? "Descending" : "Ascending")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.boutiqueGold.opacity(0.15))
                    .foregroundColor(Color.boutiqueGold)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            .background(Color.boutiqueWarmWhite)
            
            // Sales List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredAndSortedSales) { item in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.boutiqueGold.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: item.iconName)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.boutiqueGold)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.productName)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.boutiqueDarkBrown)
                                
                                HStack(spacing: 6) {
                                    Text(formatDate(item.date))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 3, height: 3)
                                    
                                    Text("\(item.units) Unit\(item.units > 1 ? "s" : "")")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Text(formatAmount(item.amount))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.boutiqueDarkBrown)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(Color.boutiqueWarmWhite)
        }
        .background(Color.boutiqueWarmWhite.ignoresSafeArea())
        .navigationTitle("All Sales")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(Color.boutiqueGold)
                }
            }
        }
        .task {
            await salesTargetViewModel.fetchSalesTargets(forStoreID: currentStoreID)
            let customTarget = salesTargetViewModel.weeklyTarget(for: viewModel.currentWeekStartDate)
            viewModel.selectWeek(viewModel.selectedWeek, customWeeklyTarget: customTarget, storeID: currentStoreID)
        }
    }
}
