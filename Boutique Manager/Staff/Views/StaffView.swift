//
//  StaffView.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct StaffView: View {

    // Use the logged-in user's assigned store ID
    private var currentStoreID: UUID {
        AuthManager.shared.currentUser?.assignedStoreID ?? UUID()
    }

    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var showAllStaff = false

    @State private var viewModel = StaffViewModel()

    private var displayedStaff: [User] {
        let sourceList = viewModel.liveStaff ?? []
        let staffList = sourceList.filter { $0.role == .salesAssociate }
        
        // Sort alphabetically by first name since we don't have live performance metrics yet
        let sorted = staffList.sorted { $0.firstName < $1.firstName }
        
        if !searchText.isEmpty {
            return sorted.filter {
                $0.firstName.localizedCaseInsensitiveContains(searchText) ||
                $0.lastName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if showAllStaff {
            return sorted
        } else {
            return Array(sorted.prefix(3))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: StaffScheduleView(storeID: currentStoreID)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Staff Scheduling")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("View and manage associate shifts")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 28))
                                .foregroundStyle(Color(hex: "D925C6")) // Pinkish purple color matching the mockup
                        }
                        .padding(.vertical, 8)
                    }
                }

                if viewModel.isLoading && viewModel.liveStaff == nil {
                    ProgressView("Loading Staff...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if !displayedStaff.isEmpty {
                    Section {
                        ForEach(displayedStaff) { user in
                            StaffRowView(user: user)
                        }
                        .onDelete(perform: delete)
                    } header: {
                        HStack {
                            Text("Sales Associates")
                            Spacer()
                            if searchText.isEmpty && (viewModel.liveStaff?.filter({ $0.role == .salesAssociate }).count ?? 0) > 3 {
                                Button {
                                    withAnimation {
                                        showAllStaff.toggle()
                                    }
                                } label: {
                                    Text(showAllStaff ? "Show Less" : "View All")
                                        .font(.system(size: 13))
                                        .textCase(.none)
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Staff Added" : "No Results",
                        systemImage: searchText.isEmpty ? "person.3" : "magnifyingglass",
                        description: Text(searchText.isEmpty
                            ? "Tap + to add your first sales associate."
                            : "Try a different name or email.")
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .searchable(text: $searchText, prompt: "Search by name or email")
            .navigationTitle("Staff")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddStaffSheet(storeID: currentStoreID) { newUser, password in
                    Task {
                        do {
                            // Call the actual Supabase edge function
                            try await AuthenticationService.shared.createAssociate(user: newUser, password: password)
                            
                            // Update local state directly
                            await MainActor.run {
                                viewModel.addStaff(newUser)
                            }
                        } catch {
                            print("Error creating associate: \(error)")
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .task {
            await viewModel.fetchStaff(forStoreID: currentStoreID)
        }
    }

    private func delete(at offsets: IndexSet) {
        let usersToDelete = offsets.map { displayedStaff[$0] }
        Task {
            await viewModel.deleteStaff(usersToDelete: usersToDelete)
        }
    }
}

#Preview {
    StaffView()
}
