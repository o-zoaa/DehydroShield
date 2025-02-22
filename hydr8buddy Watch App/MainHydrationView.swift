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
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: AppTheme.bottomIconSize, height: AppTheme.bottomIconSize)
                            .foregroundColor(AppTheme.bottomIconColor)
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
                
                // Bottom row with navigation icons
                HStack {
                    NavigationLink(destination: WaterIntakeView()) {
                        Image(systemName: AppTheme.chartIconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: AppTheme.bottomIconSize, height: AppTheme.bottomIconSize)
                            .foregroundColor(AppTheme.bottomIconColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: AppTheme.profileIconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: AppTheme.bottomIconSize, height: AppTheme.bottomIconSize)
                            .foregroundColor(AppTheme.bottomIconColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            // Trigger an immediate refresh when the view appears.
            healthDataManager.refreshData()
            updateRings()
        }
        // Use a task to trigger another update after a short delay.
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay
            healthDataManager.refreshData()
            updateRings()
        }
        .background(
            NavigationLink(destination: DebugView(), isActive: $showDebugView) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    private func updateRings() {
        // Compute intermediate values for the hybrid formula:
        let liveHR = healthDataManager.heartRate ?? 60.0
        let liveSteps = Double(healthDataManager.stepCount ?? 0)
        let liveAE = healthDataManager.activeEnergy ?? 0.0
        let liveEX = healthDataManager.exerciseTime ?? 0.0
        let liveDist = Double(healthDataManager.distance ?? 0)
        // Use 24-hour water intake for ring display.
        let liveWater = waterIntakeManager.waterIntakeLast24Hours
        let recommendedWater = computeRecommendedWater(profile: profileManager.profile)
        
        // Compute normalized activity metrics.
        let normSteps = min(liveSteps / 10000.0, 1.0)
        let normDistance = min(liveDist / 5000.0, 1.0)
        let normActiveEnergy = min(liveAE / 500.0, 1.0)
        let normExerciseTime = min(liveEX / 30.0, 1.0)
        let activityIndex = (normSteps + normDistance + normActiveEnergy + normExerciseTime) / 4.0
        
        // Compute HR index assuming resting HR = 60 and max HR = 180.
        let HR_index = min(max((liveHR - 60.0) / (180.0 - 60.0), 0.0), 1.0)
        
        // Assume normal body temperature (37°C) and no change (delta = 0).
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
        
        let computedWater = min(liveWater / recommendedWater, 1.0)
        
        withAnimation(.easeInOut(duration: AppTheme.riskAnimationDuration)) {
            displayedRiskFraction = computedRisk
        }
        withAnimation(.easeInOut(duration: AppTheme.waterAnimationDuration)) {
            displayedWaterFraction = computedWater
        }
        
        // Vibration logic: if risk transitions from below high threshold to at/above, vibrate.
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
