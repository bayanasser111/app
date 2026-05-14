//
//  ContentView.swift
//  Lume Skincare App
//
//  Main tab view container
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea() // Background color
            
            VStack(spacing: 0) {
                // Tab Content
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tag(0)
                    
                    RoutineMainView()
                        .tag(1)
                    
                    ProductCatalogView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                BottomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}
