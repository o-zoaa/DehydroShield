//
//  DehydrationCalculator.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/17/25.
//

import SwiftUI

/// Computes a hybrid dehydration risk score based on multiple factors.
func computeHybridDehydrationRisk(
    waterIntake: Double,
    recommendedWater: Double,
    activityIndex: Double,
    HR_index: Double,
    bodyTemperature: Double,
    normalBodyTemperature: Double = 37.0,
    maxBodyTemperature: Double = 39.0,
    delta: Double = 0.0,
    weights: (W_water: Double, W_activity: Double, W_hr: Double, W_temp: Double, W_delta: Double)
        = (AppTheme.W_water, AppTheme.W_activity, AppTheme.W_hr, AppTheme.W_temp, AppTheme.W_delta)
) -> Double {
    
    // Print logs
    print("=== computeHybridDehydrationRisk ===")
    print("waterIntake: \(waterIntake), recommendedWater: \(recommendedWater)")
    print("activityIndex: \(activityIndex), HR_index: \(HR_index)")
    print("bodyTemperature: \(bodyTemperature), normal: \(normalBodyTemperature), max: \(maxBodyTemperature)")
    print("delta: \(delta)")
    print("weights: \(weights)")
    
    // waterDeficit = shortfall in water intake (0 if user meets or exceeds recommended)
    let waterDeficit = 1 - min(waterIntake / recommendedWater, 1.0)
    // Print waterDeficit
    print("waterDeficit: \(waterDeficit)")
    
    // tempIndex normalizes body temp (0=normal, 1=max)
    let tempIndex = max(0, min((bodyTemperature - normalBodyTemperature) / (maxBodyTemperature - normalBodyTemperature), 1.0))
    print("tempIndex: \(tempIndex)")
    
    // Weighted sum of the factors
    let risk = (weights.W_water * waterDeficit) +
               (weights.W_activity * activityIndex) +
               (weights.W_hr * HR_index) +
               (weights.W_temp * tempIndex) +
               (weights.W_delta * delta)
    
    // Print the unclamped risk
    print("Unclamped risk: \(risk)")
    
    // Clamp the final risk to [0..1]
    let finalRisk = max(0, min(risk, 1.0))
    print("finalRisk (clamped): \(finalRisk)")
    print("-----------------------------------")
    
    return finalRisk
}

func computeRecommendedWater(profile: UserProfile?, defaultWater: Double = 2000.0) -> Double {
    if let profile = profile {
        return profile.weight * AppTheme.lbToKg * AppTheme.recommendedWaterMultiplier
    } else {
        return defaultWater
    }
}
