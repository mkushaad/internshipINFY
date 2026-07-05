//
//  HomeView.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import Foundation
import SwiftUI
internal import Combine
import Supabase

@MainActor
class HomeViewModel: ObservableObject {
    @Published var targetPercentage: Int = 0
    @Published var storeLocation: String = "Loading..."
    @Published var storeFlag: String = "🇺🇸"
    @Published var topPerformerName: String? = nil
    @Published var topPerformerSales: Double = 0
    @Published var topPerformerProgress: Double = 0
    @Published var recentSales: [RecentSaleItem] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var hasUnassignedAppointments = false
    
    private let weeklyTargetAmount: Double = 8500000
    
    func fetchDashboardData(forStoreID storeID: UUID) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let now = Date()
            var calendar = Calendar.current
            calendar.firstWeekday = 2 // Monday
            
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            let startOfWeek = calendar.date(from: components) ?? now
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? now
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            
            // 1. Fetch Sales for the current week
            let fetchedSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .gte("salesDate", value: startString)
                .lt("salesDate", value: endString)
                .execute()
                .value
            
            let totalSales = fetchedSales.reduce(0) { $0 + $1.totalAmount }
            self.targetPercentage = Int((totalSales / weeklyTargetAmount) * 100)
            
            // 1.5 Fetch Store Details
            do {
                struct StoreLocationData: Codable {
                    let location: String?
                    let region: String?
                }
                
                let store: StoreLocationData = try await SupabaseService.shared.client
                    .from("Store")
                    .select()
                    .eq("id", value: storeID.uuidString)
                    .single()
                    .execute()
                    .value
                
                self.storeLocation = store.location ?? "Unknown Location"
                
                let loc = (store.location ?? "").lowercased()
                let reg = (store.region ?? "").lowercased()
                
                if loc.contains("mumbai") || loc.contains("delhi") || loc.contains("pune") || loc.contains("chennai") || loc.contains("jaipur") || loc.contains("bangalore") || reg.contains("india") {
                    self.storeFlag = "🇮🇳"
                } else if reg.contains("northamerica") || loc.contains("cupertino") || loc.contains("new york") || loc.contains("san francisco") {
                    self.storeFlag = "🇺🇸"
                } else if reg.contains("europe") || loc.contains("london") || loc.contains("paris") {
                    self.storeFlag = "🇪🇺"
                } else if reg.contains("asiapacific") {
                    self.storeFlag = "🌏"
                } else if reg.contains("latinamerica") {
                    self.storeFlag = "🌎"
                } else if reg.contains("middleeast") || loc.contains("dubai") {
                    self.storeFlag = "🌍"
                } else {
                    self.storeFlag = "🏳️"
                }
            } catch {
                self.storeLocation = "Unknown Location"
                self.storeFlag = "🏳️"
                print("Failed to fetch store details: \(error)")
            }
            
            // 2. Top Performer
            var associateSales: [UUID: Double] = [:]
            for sale in fetchedSales {
                associateSales[sale.salesAssociateID, default: 0] += sale.totalAmount
            }
            
            if let topAssociateID = associateSales.max(by: { $0.value < $1.value })?.key {
                let salesAmount = associateSales[topAssociateID] ?? 0
                self.topPerformerSales = salesAmount
                self.topPerformerProgress = min(salesAmount / 2000000.0, 1.0)
                
                // Fetch User exactly
                do {
                    let user: User = try await SupabaseService.shared.client
                        .from("User")
                        .select()
                        .eq("id", value: topAssociateID)
                        .single()
                        .execute()
                        .value
                    
                    self.topPerformerName = "\(user.firstName) \(user.lastName)"
                } catch {
                    self.topPerformerName = "Unknown Associate"
                }
            } else {
                self.topPerformerName = nil
                self.topPerformerSales = 0
                self.topPerformerProgress = 0
            }
            
            // 3. Recent Sales (Top 3 across all time, typically means today/yesterday)
            let recentFetchedSales: [Sale] = try await SupabaseService.shared.client
                .from("Sales")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .order("salesDate", ascending: false)
                .limit(3)
                .execute()
                .value
            
            if !recentFetchedSales.isEmpty {
                let saleIDs = recentFetchedSales.map { $0.id.uuidString }
                let items: [SalesItem] = try await SupabaseService.shared.client
                    .from("SalesItem")
                    .select()
                    .in("saleID", values: saleIDs)
                    .execute()
                    .value
                
                let productIDs = Set(items.map { $0.productID.uuidString })
                var fetchedProducts: [Product] = []
                if !productIDs.isEmpty {
                    fetchedProducts = try await SupabaseService.shared.client
                        .from("Product")
                        .select()
                        .in("id", values: Array(productIDs))
                        .execute()
                        .value
                }
                
                let relFormatter = RelativeDateTimeFormatter()
                relFormatter.unitsStyle = .abbreviated
                
                var newRecentSales: [RecentSaleItem] = []
                
                for sale in recentFetchedSales {
                    if let item = items.first(where: { $0.saleID == sale.id }),
                       let product = fetchedProducts.first(where: { $0.id == item.productID }) {
                        
                        let saleDate = sale.saleDate
                        
                        newRecentSales.append(RecentSaleItem(
                            name: product.name,
                            category: product.category.rawValue.capitalized,
                            timeAgo: relFormatter.localizedString(for: saleDate, relativeTo: now),
                            price: sale.totalAmount
                        ))
                    }
                }
                self.recentSales = newRecentSales
            } else {
                self.recentSales = []
            }
            
            // 4. Check for Unassigned Appointments Today & Tomorrow
            let todayStart = calendar.startOfDay(for: now)
            guard let twoDaysLater = calendar.date(byAdding: .day, value: 2, to: todayStart) else { return }
            
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
            
            let unassignedAppts: [Appointment] = try await SupabaseService.shared.client
                .from("Appointment")
                .select()
                .eq("storeID", value: storeID.uuidString)
                .is("salesAssociateID", value: nil)
                .gte("date", value: isoFormatter.string(from: todayStart))
                .lt("date", value: isoFormatter.string(from: twoDaysLater))
                .limit(1)
                .execute()
                .value
            
            self.hasUnassignedAppointments = !unassignedAppts.isEmpty
            
        } catch {
            print("Failed to fetch dashboard data: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        self.isLoading = false
    }
}

struct HomeView: View {
    @State private var showSettings = false
    @StateObject private var viewModel = HomeViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        NavigationLink(destination: SalesPerformanceView()) {
                            SalesTargetCard(percentage: viewModel.targetPercentage, location: viewModel.storeLocation, flag: viewModel.storeFlag)
                        }
                        .buttonStyle(.plain)
                        TopPerformerCard(topPerformerName: viewModel.topPerformerName, topPerformerSales: viewModel.topPerformerSales, progress: CGFloat(viewModel.topPerformerProgress))
                        VIPEventCard()
                        RecentSalesCard(items: viewModel.recentSales)
                    }
                    .padding()
                    
                    NavigationLink(destination: StoreAppointmentsView(initialTab: viewModel.hasUnassignedAppointments ? 3 : 0)
                        .onDisappear {
                            Task {
                                let storeID = AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
                                await viewModel.fetchDashboardData(forStoreID: storeID)
                            }
                        }
                    ) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Manage Appointments")
                                .font(.system(size: 17, weight: .bold))
                            
                            if viewModel.hasUnassignedAppointments {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .padding(.leading, 4)
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .opacity(0.7)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.themeAccent, Color.themeAccent.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.themeAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .navigationTitle("Dashboard")
                .toolbarColorScheme(.light, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
        .task {
            let storeID = AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
            await viewModel.fetchDashboardData(forStoreID: storeID)
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    HomeView()
}
