//
//  DehydrationCalculator.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/17/25.
//

import SwiftUI

/// Computes a hybrid dehydration risk score based on multiple factors.
/// - Parameters:
///   - waterIntake: The current water intake (ml).
///   - recommendedWater: The recommended water intake (ml).
///   - activityIndex: A normalized value (0–1) representing overall activity level (e.g., average of normalized steps, distance, energy, exercise time).
///   - HR_index: A normalized heart rate metric (0–1); for example, (currentHR - restingHR) / (maxHR - restingHR).
///   - bodyTemperature: The current body temperature (°C).
///   - normalBodyTemperature: The baseline normal body temperature (°C), e.g., 37.0.
///   - maxBodyTemperature: The upper limit of safe body temperature (°C), e.g., 39.0.
///   - delta: An optional value representing the rate of change in risk (for dynamic adjustments). Typically 0 if not used.
///   - weights: A tuple containing adjustable weights for each factor:
///       - W_water: Weight for water deficit. Increasing this makes the formula more sensitive to low water intake.
///       - W_activity: Weight for activity. Increasing this emphasizes that high activity raises risk.
///       - W_hr: Weight for the heart rate index. Increasing this makes high heart rate more impactful.
///       - W_temp: Weight for the temperature index. Increasing this will accentuate deviations from normal body temperature.
///       - W_delta: Weight for the rate-of-change factor. Increasing this will cause risk to react faster when it is rising quickly.
/// - Returns: A dehydration risk score, clamped between 0 and 1.
func computeHybridDehydrationRisk(waterIntake: Double,
                                  recommendedWater: Double,
                                  activityIndex: Double,
                                  HR_index: Double,
                                  bodyTemperature: Double,
                                  normalBodyTemperature: Double = 37.0,
                                  maxBodyTemperature: Double = 39.0,
                                  delta: Double = 0.0,
                                  weights: (W_water: Double, W_activity: Double, W_hr: Double, W_temp: Double, W_delta: Double) = (AppTheme.W_water, AppTheme.W_activity, AppTheme.W_hr, AppTheme.W_temp, AppTheme.W_delta)
) -> Double {
    // waterDeficit measures the shortfall in water intake.
    // A value of 0 means waterIntake equals or exceeds recommendedWater;
    // 1 means no water intake.
    let waterDeficit = 1 - min(waterIntake / recommendedWater, 1.0)
    
    // tempIndex normalizes the current body temperature relative to a normal range.
    // If bodyTemperature equals normalBodyTemperature, tempIndex = 0.
    // If it reaches maxBodyTemperature, tempIndex = 1.
    let tempIndex = max(0, min((bodyTemperature - normalBodyTemperature) / (maxBodyTemperature - normalBodyTemperature), 1.0))
    
    // Calculate the overall risk as a weighted sum of the components.
    // Adjusting the weights will affect the sensitivity of the risk score:
    // - Increasing W_water makes low water intake (high waterDeficit) more critical.
    // - Increasing W_activity makes the risk more sensitive to high activity.
    // - Increasing W_hr emphasizes elevated heart rate.
    // - Increasing W_temp makes deviations in body temperature more impactful.
    // - Increasing W_delta makes rapid changes (delta) more influential.
    let risk = (weights.W_water * waterDeficit) +
               (weights.W_activity * activityIndex) +
               (weights.W_hr * HR_index) +
               (weights.W_temp * tempIndex) +
               (weights.W_delta * delta)
    
    // Clamp the risk between 0 and 1.
    return max(0, min(risk, 1.0))
}

func computeRecommendedWater(profile: UserProfile?, defaultWater: Double = 2000.0) -> Double {
    if let profile = profile {
        return profile.weight * AppTheme.lbToKg * AppTheme.recommendedWaterMultiplier
    } else {
        return defaultWater
    }
}
