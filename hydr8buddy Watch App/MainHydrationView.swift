//
//  MainHydrationView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI
import WatchKit

// Define an enum to distinguish trigger events.
enum RiskTrigger: String {
    case healthKit = "HealthKit"
    case appLaunch = "App Launch"
    case notification = "Notification"
}

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
    
    // State variable to throttle HealthKit-based risk saves.
    @State private var lastRiskHealthKitSave: Date = Date.distantPast
    // State variable to throttle app-launch based risk saves.
    @State private var lastRiskAppLaunchSave: Date = Date.distantPast
    // State variable to throttle HealthKit notifications.
    @State private var lastHealthDataUpdate: Date = Date.distantPast

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
            // Initialize lastRiskAppLaunchSave from UserDefaults if available.
            let savedAppLaunch = UserDefaults.standard.double(forKey: "lastAppLaunchRiskSave")
            if savedAppLaunch > 0 {
                lastRiskAppLaunchSave = Date(timeIntervalSince1970: savedAppLaunch)
                print("Initialized lastRiskAppLaunchSave from UserDefaults: \(lastRiskAppLaunchSave)")
            } else {
                print("No persisted lastRiskAppLaunchSave found.")
            }
            // Initialize lastRiskHealthKitSave from UserDefaults if available.
            let savedHK = UserDefaults.standard.double(forKey: "lastRiskHealthKitSave")
            if savedHK > 0 {
                lastRiskHealthKitSave = Date(timeIntervalSince1970: savedHK)
                print("Initialized lastRiskHealthKitSave from UserDefaults: \(lastRiskHealthKitSave)")
            } else {
                print("No persisted lastRiskHealthKitSave found.")
            }
            // Always update the display with the latest risk score.
            updateRings(trigger: .appLaunch)
            saveRiskOnLaunchIfNeeded()
        }
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            healthDataManager.refreshData()
            updateRings(trigger: .appLaunch)
        }
        // HealthKit update: throttle to save risk score at most every 30 minutes.
        .onReceive(NotificationCenter.default.publisher(for: .healthDataUpdated)) { _ in
            let now = Date()
            if now.timeIntervalSince(lastHealthDataUpdate) > (30 * 60) {
                lastHealthDataUpdate = now
                updateRings(trigger: .healthKit)
            }
        }
        // Notification-triggered update: save risk score immediately.
        .onReceive(NotificationCenter.default.publisher(for: .waterLogged)) { _ in
            updateRings(trigger: .notification)
        }
        .background(
            NavigationLink(destination: DebugView(), isActive: $showDebugView) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    /// Updates displayed risk and water fractions, then saves a risk entry based on the trigger type.
    private func updateRings(trigger: RiskTrigger) {
        print("=== updateRings() - START for trigger: \(trigger.rawValue) ===")
        // Compute intermediate values.
        let liveHR = healthDataManager.heartRate ?? 60.0
        let liveSteps = Double(healthDataManager.stepCount ?? 0)
        let liveAE = healthDataManager.activeEnergy ?? 0.0
        let liveEX = healthDataManager.exerciseTime ?? 0.0
        let liveDist = Double(healthDataManager.distance ?? 0)
        let displayWater = waterIntakeManager.waterIntakeLast24Hours
        let riskWater = waterIntakeManager.weightedWaterIntakeLast5Days
        let recommendedWaterForRisk = computeRecommendedWater(profile: profileManager.profile) *
            (AppTheme.waterWeightSeg1 + AppTheme.waterWeightSeg2 + AppTheme.waterWeightSeg3 + AppTheme.waterWeightSeg4 + AppTheme.waterWeightSeg5)
        let recommendedWaterForDisplay = computeRecommendedWater(profile: profileManager.profile)
        
        print("Live HR: \(liveHR), Steps: \(liveSteps), AE: \(liveAE), EX: \(liveEX), Dist: \(liveDist)")
        print("Display Water: \(displayWater), Risk Water: \(riskWater)")
        
        let normSteps = min(liveSteps / 10000.0, 1.0)
        let normDistance = min(liveDist / 5000.0, 1.0)
        let normActiveEnergy = min(liveAE / 500.0, 1.0)
        let normExerciseTime = min(liveEX / 30.0, 1.0)
        let activityIndex = (normSteps + normDistance + normActiveEnergy + normExerciseTime) / 4.0
        let HR_index = min(max((liveHR - 60.0) / (180.0 - 60.0), 0.0), 1.0)
        
        let computedRisk = computeHybridDehydrationRisk(
            waterIntake: riskWater,
            recommendedWater: recommendedWaterForRisk,
            activityIndex: activityIndex,
            HR_index: HR_index,
            bodyTemperature: 37.0,
            delta: 0.0
        )
        let computedWater = min(displayWater / recommendedWaterForDisplay, 1.0)
        
        withAnimation(.easeInOut(duration: AppTheme.riskAnimationDuration)) {
            displayedRiskFraction = computedRisk
        }
        withAnimation(.easeInOut(duration: AppTheme.waterAnimationDuration)) {
            displayedWaterFraction = computedWater
        }
        
        print("Displayed risk: \(displayedRiskFraction), displayed water: \(displayedWaterFraction)")
        
        // Save risk entry based on the trigger.
        saveRiskEntry(trigger: trigger, computedRisk: computedRisk)
        
        print("=== updateRings() - END ===")
    }
    
    /// Saves a risk entry based on the trigger type.
    private func saveRiskEntry(trigger: RiskTrigger, computedRisk: Double) {
        let now = Date()
        switch trigger {
        case .notification:
            print("Saving risk entry immediately for notification trigger.")
            historyManager.saveRiskEntry(computedRisk)
        case .healthKit:
            if historyManager.riskEntries.isEmpty || now.timeIntervalSince(lastRiskHealthKitSave) > (30 * 60) {
                let diff = now.timeIntervalSince(lastRiskHealthKitSave)
                print("Saving risk entry for HealthKit trigger. Time since last save: \(diff) seconds.")
                lastRiskHealthKitSave = now
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "lastRiskHealthKitSave")
                historyManager.saveRiskEntry(computedRisk)
            } else {
                let diff = now.timeIntervalSince(lastRiskHealthKitSave)
                print("Not saving risk entry for HealthKit trigger due to throttling. Time since last save: \(diff) seconds.")
            }
        case .appLaunch:
            if historyManager.riskEntries.isEmpty || now.timeIntervalSince(lastRiskAppLaunchSave) > (30 * 60) {
                let diff = now.timeIntervalSince(lastRiskAppLaunchSave)
                print("Saving risk entry for app launch trigger. Time since last save: \(diff) seconds.")
                lastRiskAppLaunchSave = now
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "lastAppLaunchRiskSave")
                historyManager.saveRiskEntry(computedRisk)
            } else {
                let diff = now.timeIntervalSince(lastRiskAppLaunchSave)
                print("Not saving risk entry for app launch trigger due to throttling. Time since last save: \(diff) seconds.")
            }
        }
    }
    
    /// Saves a risk entry at app launch if the persisted timestamp indicates that 30 minutes have passed
    /// or if the risk entry list is empty.
    private func saveRiskOnLaunchIfNeeded() {
        let now = Date().timeIntervalSince1970
        let lastSave = UserDefaults.standard.double(forKey: "lastAppLaunchRiskSave")
        print("App launch: now = \(now), lastAppLaunchRiskSave = \(lastSave)")
        if historyManager.riskEntries.isEmpty || now - lastSave > 30 * 60 {
            print("Saving risk entry on app launch (overriding throttling if needed).")
            historyManager.saveRiskEntry(displayedRiskFraction)
            UserDefaults.standard.set(now, forKey: "lastAppLaunchRiskSave")
            lastRiskAppLaunchSave = Date(timeIntervalSince1970: now)
        } else {
            print("Not saving risk entry on app launch due to throttling. Time since last save: \(now - lastSave) seconds.")
        }
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
