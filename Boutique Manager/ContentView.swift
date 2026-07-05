//
//  ContentView.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                        .tag(0)
                    StaffView()
                        .tabItem {
                            Label("Staff", systemImage: "person.2.fill")
                        }
                    InventoryView()
                        .tabItem {
                            Label("Inventory", systemImage: "archivebox")
                        }
                        .tag(1)
                        .tag(2)
                    EventsView()
                        .tabItem {
                            Label("Events", systemImage: "ticket.fill")
                        }
                        .tag(3)
                }
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
}
