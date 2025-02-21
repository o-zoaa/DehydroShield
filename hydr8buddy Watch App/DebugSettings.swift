//
//  DebugSettings.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI

class DebugSettings: ObservableObject {
    init() {
        print("DebugSettings initialized: \(ObjectIdentifier(self))")
    }
    
    @Published var isDebugMode: Bool = false
    
    // Persistent debug metric values (defaults are live values; these get updated on toggle)
    @Published var debugHeartRate: Double = 60
    @Published var debugStepCount: Double = 0
    @Published var debugActiveEnergy: Double = 0
    @Published var debugExerciseTime: Double = 0
    @Published var debugDistance: Double = 0
    @Published var debugWaterIntake: Double = 0
    
    // Persistent preview values for the rings
    @Published var previewRisk: Double = 0
    @Published var previewWater: Double = 0
    
    // Flag that indicates the debug metrics have been changed since the last preview update.
    @Published var isPreviewDirty: Bool = false
}
