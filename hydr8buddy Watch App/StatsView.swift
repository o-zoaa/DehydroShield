//
//  StatsView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        ZStack {
            // Use AppTheme's statsGradient for the background.
            AppTheme.statsGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    Text("Stats")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let hr = healthDataManager.heartRate {
                        Text("Heart Rate: \(Int(hr)) BPM")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    if let hrv = healthDataManager.heartRateVariability {
                        Text(String(format: "HRV: %.1f ms", hrv))
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    if let steps = healthDataManager.stepCount {
                        Text("Steps: \(Int(steps))")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    if let ae = healthDataManager.activeEnergy {
                        Text(String(format: "Active Energy: %.0f kcal", ae))
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    if let ex = healthDataManager.exerciseTime {
                        Text(String(format: "Exercise: %.0f min", ex))
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    if let dist = healthDataManager.distance {
                        let miles = dist / 1609.34
                        Text(String(format: "Distance: %.2f mi", miles))
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    if let temp = healthDataManager.bodyTemperature {
                        Text(String(format: "Body Temp: %.1f °C", temp))
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environmentObject(HealthDataManager())
    }
}
