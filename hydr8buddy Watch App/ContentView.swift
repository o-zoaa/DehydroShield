//
//  ContentView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    var body: some View {
        NavigationView {
            TabView {
                MainHydrationView().tag(0)
                HistoricalChartView().tag(1)
                RiskBreakdownView().tag(2)
                StatsView().tag(3)
            }
            .tabViewStyle(.carousel)
            .id(UUID())  // Force a fresh TabView every launch
            .onAppear {
                // Force tab to 0 whenever this view appears
                selectedTab = 0
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
