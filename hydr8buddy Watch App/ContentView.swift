//
//  ContentView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            TabView {
                MainHydrationView().tag(0)
                WaterIntakeView().tag(1)
                RiskBreakdownView().tag(2)
                StatsView().tag(3)
            }
            .tabViewStyle(.carousel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
