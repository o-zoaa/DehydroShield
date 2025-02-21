//
//  MainHydrationView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI
import WatchKit  // Needed for haptic feedback

struct MainHydrationView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var historyManager: DehydrationHistoryManager
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var waterIntakeManager: WaterIntakeManager
    
    // For debug nav
    @State private var showDebugView = false
    
    // Default recommended water intake if no profile is available (ml)
    private let defaultRecommendedWaterIntake: Double = 2000
    
    // State variables for animating the rings
    @State private var displayedRiskFraction: Double = 0
    @State private var displayedWaterFraction: Double = 0
    
    // State variable to track previous risk fraction for vibration logic.
    @State private var previousRiskFraction: Double? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Top row with gear icon at top left
                HStack {
                    // Gear icon => toggles DebugView
                    Button(action: {
                        showDebugView = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.leading, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Dual ring view
                DualRingView(riskFraction: displayedRiskFraction, waterFraction: displayedWaterFraction)
                    .padding()
                
                // Optional sensor stats
                if let ex = healthDataManager.exerciseTime {
                    Text(String(format: "Exercise: %.0f min", ex))
                        .font(.caption)
                        .foregroundColor(.white)
                }
                if let dist = healthDataManager.distance {
                    let miles = dist / 1609.34
                    Text(String(format: "Distance: %.2f mi", miles))
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Bottom row with weekly risk icon (left) and profile icon (right)
                HStack {
                    NavigationLink(destination: WeeklyRiskView()) {
                        Image(systemName: AppTheme.chartIconName)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: AppTheme.profileIconName)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            // Compute ring fractions on appear
            DispatchQueue.main.async {
                healthDataManager.refreshData()
                
                // Compute intermediate values for the hybrid formula:
                let liveHR = healthDataManager.heartRate ?? 60.0
                let liveSteps = Double(healthDataManager.stepCount ?? 0)
                let liveAE = healthDataManager.activeEnergy ?? 0.0
                let liveEX = healthDataManager.exerciseTime ?? 0.0
                let liveDist = Double(healthDataManager.distance ?? 0)
                // Use the 5-day rolling window for water intake:
                let liveWater = waterIntakeManager.waterIntakeLast5Days
                // Multiply recommended water by 5 for a 5-day period:
                let recommendedWater = computeRecommendedWater(profile: profileManager.profile) * 5
                
                // Compute an activity index as the average of normalized activity metrics.
                let normSteps = min(liveSteps / 10000.0, 1.0)
                let normDistance = min(liveDist / 5000.0, 1.0)
                let normActiveEnergy = min(liveAE / 500.0, 1.0)
                let normExerciseTime = min(liveEX / 30.0, 1.0)
                let activityIndex = (normSteps + normDistance + normActiveEnergy + normExerciseTime) / 4.0
                
                // Compute HR_index assuming resting HR = 60 and max HR = 180.
                let HR_index = min(max((liveHR - 60.0) / (180.0 - 60.0), 0.0), 1.0)
                
                // For now, assume body temperature is normal (e.g., 37.0°C) and delta is 0.
                let bodyTemperature = 37.0
                let delta = 0.0
                
                let computedRisk = computeHybridDehydrationRisk(
                    waterIntake: liveWater,
                    recommendedWater: recommendedWater,
                    activityIndex: activityIndex,
                    HR_index: HR_index,
                    bodyTemperature: bodyTemperature,
                    delta: delta
                )
                
                // Compute the water fraction based on a 5-day window.
                let computedWater = min(liveWater / recommendedWater, 1.0)
                
                // Debug prints to check water intake and risk calculation
                print("Live Water (5 days): \(liveWater) ml")
                print("Recommended Water (5 days): \(recommendedWater) ml")
                print("Water Deficit: \(1 - min(liveWater / recommendedWater, 1.0))")
                print("Activity Index: \(activityIndex)")
                print("HR Index: \(HR_index)")
                print("Overall Risk: \(computedRisk)")
                print("Computed Water Fraction: \(computedWater)")
                
                // Animate the outer (risk) and inner (water) rings with adjustable durations.
                withAnimation(.easeInOut(duration: AppTheme.riskAnimationDuration)) {
                    displayedRiskFraction = computedRisk
                }
                withAnimation(.easeInOut(duration: AppTheme.waterAnimationDuration)) {
                    displayedWaterFraction = computedWater
                }
                
                // Vibration logic:
                // Vibrate on app launch if no previous risk exists and computedRisk is high,
                // or if risk transitions from below to at/above the high risk threshold.
                if let prev = previousRiskFraction {
                    if prev < AppTheme.highRiskThreshold && computedRisk >= AppTheme.highRiskThreshold {
                        WKInterfaceDevice.current().play(.notification)
                    }
                } else {
                    if computedRisk >= AppTheme.highRiskThreshold {
                        WKInterfaceDevice.current().play(.notification)
                    }
                }
                previousRiskFraction = computedRisk
                
                historyManager.saveTodayRisk(computedRisk)
            }
        }
        // Hidden NavigationLink for DebugView
        .background(
            NavigationLink(destination: DebugView(), isActive: $showDebugView) {
                EmptyView()
            }
            .hidden()
        )
    }
}

struct MainHydrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainHydrationView()
                .environmentObject(HealthDataManager())
                .environmentObject(DehydrationHistoryManager())
                .environmentObject(ProfileManager())
                .environmentObject(WaterIntakeManager())
        }
    }
}
