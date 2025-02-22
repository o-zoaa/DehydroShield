//
//  DebugView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/17/25.
//

import SwiftUI
import WatchKit

struct DebugView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var waterIntakeManager: WaterIntakeManager
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var debugSettings: DebugSettings
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Toggle Section
                Section {
                    Toggle("Use Debug Values", isOn: $debugSettings.isDebugMode)
                        .onChange(of: debugSettings.isDebugMode) { newValue in
                            if newValue {
                                // When turning debug ON, initialize debug metrics from live data.
                                resetDebugMetricsToLive()
                            } else {
                                // When turning debug OFF, reset to live sensor data.
                                resetDebugMetricsToLive()
                            }
                        }
                }
                
                // MARK: - Current Metrics (always live)
                Section(header: Text("Current Metrics")) {
                    HStack {
                        Text("Heart Rate:")
                        Spacer()
                        Text("\(Int(healthDataManager.heartRate ?? 60)) BPM")
                    }
                    HStack {
                        Text("Step Count:")
                        Spacer()
                        Text("\(Int(healthDataManager.stepCount ?? 0))")
                    }
                    HStack {
                        Text("Active Energy:")
                        Spacer()
                        Text("\(Int(healthDataManager.activeEnergy ?? 0)) cal")
                    }
                    HStack {
                        Text("Exercise Time:")
                        Spacer()
                        Text("\(Int(healthDataManager.exerciseTime ?? 0)) min")
                    }
                    HStack {
                        Text("Distance:")
                        Spacer()
                        let liveDist = Double(healthDataManager.distance ?? 0)
                        Text(String(format: "%.2f mi", liveDist / 1609.34))
                    }
                    HStack {
                        Text("Water Intake (5 days):")
                        Spacer()
                        // Use weighted water intake over the last 5 days.
                        Text("\(Int(waterIntakeManager.weightedWaterIntakeLast5Days)) ml")
                    }
                }
                
                // MARK: - Adjust Metrics (for debugging)
                Section(header: Text("Adjust Metrics")) {
                    VStack(alignment: .leading) {
                        Text("Heart Rate").font(.subheadline)
                        Stepper(value: $debugSettings.debugHeartRate, in: 50...150, step: 1) {
                            Text("\(Int(debugSettings.debugHeartRate)) BPM")
                                .font(.subheadline)
                        }
                        .disabled(!debugSettings.isDebugMode)
                        .onChange(of: debugSettings.debugHeartRate) { newValue in
                            let live = healthDataManager.heartRate ?? 60
                            if newValue != live { debugSettings.isPreviewDirty = true }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Step Count").font(.subheadline)
                        Stepper(value: $debugSettings.debugStepCount, in: 0...20000, step: 100) {
                            Text("\(Int(debugSettings.debugStepCount))")
                                .font(.subheadline)
                        }
                        .disabled(!debugSettings.isDebugMode)
                        .onChange(of: debugSettings.debugStepCount) { newValue in
                            let live = Double(healthDataManager.stepCount ?? 0)
                            if newValue != live { debugSettings.isPreviewDirty = true }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Active Energy").font(.subheadline)
                        Stepper(value: $debugSettings.debugActiveEnergy, in: 0...1000, step: 10) {
                            Text("\(Int(debugSettings.debugActiveEnergy)) cal")
                                .font(.subheadline)
                        }
                        .disabled(!debugSettings.isDebugMode)
                        .onChange(of: debugSettings.debugActiveEnergy) { newValue in
                            let live = healthDataManager.activeEnergy ?? 0
                            if newValue != live { debugSettings.isPreviewDirty = true }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Exercise Time (min)").font(.subheadline)
                        Stepper(value: $debugSettings.debugExerciseTime, in: 0...120, step: 1) {
                            Text("\(Int(debugSettings.debugExerciseTime)) min")
                                .font(.subheadline)
                        }
                        .disabled(!debugSettings.isDebugMode)
                        .onChange(of: debugSettings.debugExerciseTime) { newValue in
                            let live = healthDataManager.exerciseTime ?? 0
                            if newValue != live { debugSettings.isPreviewDirty = true }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Distance (m)").font(.subheadline)
                        Stepper(value: $debugSettings.debugDistance, in: 0...10000, step: 100) {
                            Text("\(Int(debugSettings.debugDistance)) m")
                                .font(.subheadline)
                        }
                        .disabled(!debugSettings.isDebugMode)
                        .onChange(of: debugSettings.debugDistance) { newValue in
                            let live = Double(healthDataManager.distance ?? 0)
                            if newValue != live { debugSettings.isPreviewDirty = true }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Water Intake (ml)").font(.subheadline)
                        Stepper(value: $debugSettings.debugWaterIntake, in: 0...5000, step: 50) {
                            Text("\(Int(debugSettings.debugWaterIntake)) ml")
                                .font(.subheadline)
                        }
                        .disabled(!debugSettings.isDebugMode)
                        .onChange(of: debugSettings.debugWaterIntake) { newValue in
                            // Use weighted water intake over the last 5 days.
                            let live = waterIntakeManager.weightedWaterIntakeLast5Days
                            if newValue != live { debugSettings.isPreviewDirty = true }
                        }
                    }
                }
                
                // MARK: - Ring Preview and Update Button
                Section {
                    if debugSettings.isDebugMode {
                        if debugSettings.isPreviewDirty {
                            Button("Update Preview") {
                                updatePreviewRings()
                                debugSettings.isPreviewDirty = false
                            }
                            .font(.subheadline)
                        }
                        DualRingView(riskFraction: debugSettings.previewRisk,
                                     waterFraction: debugSettings.previewWater)
                            .frame(maxWidth: .infinity, maxHeight: 200)
                    } else {
                        DualRingView(riskFraction: computeLiveRisk(),
                                     waterFraction: computeLiveWater())
                            .frame(maxWidth: .infinity, maxHeight: 200)
                    }
                }
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Only reset debug metrics to live sensor data when debug mode is OFF.
                if !debugSettings.isDebugMode {
                    resetDebugMetricsToLive()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func resetDebugMetricsToLive() {
        let liveHR = healthDataManager.heartRate ?? 60
        let liveSteps = Double(healthDataManager.stepCount ?? 0)
        let liveAE = healthDataManager.activeEnergy ?? 0
        let liveEX = healthDataManager.exerciseTime ?? 0
        let liveDist = Double(healthDataManager.distance ?? 0)
        // Use weighted water intake over the last 5 days.
        let liveWater = waterIntakeManager.waterIntakeLast24Hours
        
        debugSettings.debugHeartRate = liveHR
        debugSettings.debugStepCount = liveSteps
        debugSettings.debugActiveEnergy = liveAE
        debugSettings.debugExerciseTime = liveEX
        debugSettings.debugDistance = liveDist
        debugSettings.debugWaterIntake = liveWater
        
        let recommendedWater = computeRecommendedWater(profile: profileManager.profile)
        
        let normSteps = min(liveSteps / 10000.0, 1.0)
        let normDistance = min(liveDist / 5000.0, 1.0)
        let normActiveEnergy = min(liveAE / 500.0, 1.0)
        let normExerciseTime = min(liveEX / 30.0, 1.0)
        let activityIndex = (normSteps + normDistance + normActiveEnergy + normExerciseTime) / 4.0
        
        let HR_index = min(max((liveHR - 60.0) / (180.0 - 60.0), 0.0), 1.0)
        
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
            debugSettings.previewRisk = computedRisk
        }
        withAnimation(.easeInOut(duration: AppTheme.waterAnimationDuration)) {
            debugSettings.previewWater = computedWater
        }
        debugSettings.isPreviewDirty = false
    }
    
    private func updatePreviewRings() {
        let risk = computeHybridDehydrationRisk(
            waterIntake: debugSettings.debugWaterIntake,
            recommendedWater: computeRecommendedWater(profile: profileManager.profile) * 5,
            activityIndex: {
                let normSteps = min(debugSettings.debugStepCount / 10000.0, 1.0)
                let normDistance = min(debugSettings.debugDistance / 5000.0, 1.0)
                let normActiveEnergy = min(debugSettings.debugActiveEnergy / 500.0, 1.0)
                let normExerciseTime = min(debugSettings.debugExerciseTime / 30.0, 1.0)
                return (normSteps + normDistance + normActiveEnergy + normExerciseTime) / 4.0
            }(),
            HR_index: min(max((debugSettings.debugHeartRate - 60.0) / (180.0 - 60.0), 0.0), 1.0),
            bodyTemperature: 37.0,
            delta: 0.0
        )
        let recommendedWater = computeRecommendedWater(profile: profileManager.profile) * 5
        let waterFrac = min(debugSettings.debugWaterIntake / recommendedWater, 1.0)
        
        withAnimation(.easeInOut(duration: AppTheme.riskAnimationDuration)) {
            debugSettings.previewRisk = risk
        }
        withAnimation(.easeInOut(duration: AppTheme.waterAnimationDuration)) {
            debugSettings.previewWater = waterFrac
        }
    }
    
    private func computeLiveRisk() -> Double {
        let liveHR = healthDataManager.heartRate ?? 60
        let liveSteps = Double(healthDataManager.stepCount ?? 0)
        let liveAE = healthDataManager.activeEnergy ?? 0
        let liveEX = healthDataManager.exerciseTime ?? 0
        let liveDist = Double(healthDataManager.distance ?? 0)
        // Use weighted water intake over the last 5 days.
        let liveWater = waterIntakeManager.waterIntakeLast24Hours
        
        let recommendedWater = computeRecommendedWater(profile: profileManager.profile)
        
        let normSteps = min(liveSteps / 10000.0, 1.0)
        let normDistance = min(liveDist / 5000.0, 1.0)
        let normActiveEnergy = min(liveAE / 500.0, 1.0)
        let normExerciseTime = min(liveEX / 30.0, 1.0)
        let activityIndex = (normSteps + normDistance + normActiveEnergy + normExerciseTime) / 4.0
        
        let HR_index = min(max((liveHR - 60.0) / (180.0 - 60.0), 0.0), 1.0)
        
        let bodyTemperature = 37.0
        let delta = 0.0
        
        return computeHybridDehydrationRisk(
            waterIntake: liveWater,
            recommendedWater: recommendedWater,
            activityIndex: activityIndex,
            HR_index: HR_index,
            bodyTemperature: bodyTemperature,
            delta: delta
        )
    }
    
    private func computeLiveWater() -> Double {
        let liveWater = waterIntakeManager.waterIntakeLast24Hours
        let recommendedWater = computeRecommendedWater(profile: profileManager.profile)
        return min(liveWater / recommendedWater, 1.0)
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
            .environmentObject(HealthDataManager())
            .environmentObject(WaterIntakeManager())
            .environmentObject(ProfileManager())
            .environmentObject(DebugSettings())
    }
}
