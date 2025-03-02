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
    
    // For debug navigation.
    @State private var showDebugView = false
    
    // Default recommended water intake if no profile is available (ml).
    private let defaultRecommendedWaterIntake: Double = 2000
    
    // State variables for animating the rings.
    @State private var displayedRiskFraction: Double = 0
    @State private var displayedWaterFraction: Double = 0
    
    // State variable to track previous risk fraction for notification logic.
    @State private var previousRiskFraction: Double? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Top row with gear icon.
                HStack {
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
                
                // Dual ring view.
                DualRingView(riskFraction: displayedRiskFraction, waterFraction: displayedWaterFraction)
                    .padding()
                
                // Optional sensor stats.
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
                
                // Bottom row with navigation icons.
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
            healthDataManager.refreshData()
            updateRings()
        }
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
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
        print("=== updateRings() - START ===")
        // Compute intermediate values.
        let liveHR = healthDataManager.heartRate ?? 60.0
        let liveSteps = Double(healthDataManager.stepCount ?? 0)
        let liveAE = healthDataManager.activeEnergy ?? 0.0
        let liveEX = healthDataManager.exerciseTime ?? 0.0
        let liveDist = Double(healthDataManager.distance ?? 0)
        // For the water ring display, use the 24‑hour water intake.
        let displayWater = waterIntakeManager.waterIntakeLast24Hours
        // For risk calculation, use the weighted water intake over the last 5 days.
        let riskWater = waterIntakeManager.weightedWaterIntakeLast5Days
        // For risk, recommended water is for a 5‑day period.
        let recommendedWaterForRisk = computeRecommendedWater(profile: profileManager.profile) * (AppTheme.waterWeightSeg1 + AppTheme.waterWeightSeg2 + AppTheme.waterWeightSeg3 + AppTheme.waterWeightSeg4 + AppTheme.waterWeightSeg5)
        // For display, use the daily recommended water.
        let recommendedWaterForDisplay = computeRecommendedWater(profile: profileManager.profile)
        
        print("updateRings() - Live Data: HR=\(liveHR), Steps=\(liveSteps), AE=\(liveAE), EX=\(liveEX), Dist=\(liveDist), DisplayWater=\(displayWater), RiskWater=\(riskWater)")
        
        // Compute normalized activity metrics.
        let normSteps = min(liveSteps / 10000.0, 1.0)
        let normDistance = min(liveDist / 5000.0, 1.0)
        let normActiveEnergy = min(liveAE / 500.0, 1.0)
        let normExerciseTime = min(liveEX / 30.0, 1.0)
        let activityIndex = (normSteps + normDistance + normActiveEnergy + normExerciseTime) / 4.0
        
        // Compute HR index assuming resting HR = 60 and max HR = 180.
        let HR_index = min(max((liveHR - 60.0) / (180.0 - 60.0), 0.0), 1.0)
        
        // Assume normal body temperature (37°C) and no change.
        let bodyTemperature = 37.0
        let delta = 0.0
        
        let computedRisk = computeHybridDehydrationRisk(
            waterIntake: riskWater,
            recommendedWater: recommendedWaterForRisk,
            activityIndex: activityIndex,
            HR_index: HR_index,
            bodyTemperature: bodyTemperature,
            delta: delta
        )
        print("updateRings() - computedRisk: \(computedRisk)")
        
        let computedWater = min(displayWater / recommendedWaterForDisplay, 1.0)
        print("updateRings() - computedWater: \(computedWater)")
        
        withAnimation(.easeInOut(duration: AppTheme.riskAnimationDuration)) {
            displayedRiskFraction = computedRisk
        }
        withAnimation(.easeInOut(duration: AppTheme.waterAnimationDuration)) {
            displayedWaterFraction = computedWater
        }
        
        DispatchQueue.main.async {
            print("updateRings() - Main thread? \(Thread.isMainThread)")
            print("Displayed risk fraction: \(displayedRiskFraction), displayed water fraction: \(displayedWaterFraction)")
        }
        
        // -------------------------------
        // Notification for Risk Transitions
        // -------------------------------
        if let prev = previousRiskFraction {
            if prev < AppTheme.midRiskThreshold && computedRisk >= AppTheme.midRiskThreshold {
                NotificationManager.shared.scheduleWaterReminder(reason: "Your dehydration risk has increased to YELLOW. Consider drinking water.")
            } else if prev < AppTheme.highRiskThreshold && computedRisk >= AppTheme.highRiskThreshold {
                NotificationManager.shared.scheduleWaterReminder(reason: "Your dehydration risk has increased to RED. Hydrate immediately!")
            }
        } else {
            if computedRisk >= AppTheme.highRiskThreshold {
                NotificationManager.shared.scheduleWaterReminder(reason: "High dehydration risk detected. Please hydrate!")
            } else if computedRisk >= AppTheme.midRiskThreshold {
                NotificationManager.shared.scheduleWaterReminder(reason: "Dehydration risk rising. Consider hydrating.")
            }
        }
        
        // Store current risk entry (now appending instead of overwriting per day)
        historyManager.saveRiskEntry(computedRisk)
        
        // Store current risk for future comparison.
        previousRiskFraction = computedRisk
        
        print("=== updateRings() - END ===")
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
