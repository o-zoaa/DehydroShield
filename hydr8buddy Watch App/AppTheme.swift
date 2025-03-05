//
//  AppTheme.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI

/// A central place to store all configurable style values for the app.
struct AppTheme {
    static let chartTopPadding: CGFloat = 25

    // MARK: - Water Inactivity Threshold
    static let waterInactivityThreshold: TimeInterval = 6 * 3600 // 6 hours
    
    // MARK: - Water Options for Notification Actions
    // These are the same options used in WaterIntakeView.
    static let waterOptions: [Int] = Array(stride(from: 10, through: 300, by: 10))

    static let riskPointerScale: CGFloat = 12.0 / 16.0
    // Arc parameters
    static let riskArcStartAngle = Angle(degrees: 135)
    static let riskArcDegrees: Double = 270
    static let riskArcThickness: CGFloat = 18
    static let riskArcScaleFactor: CGFloat = 0.95

    // Full arc gradient from green (start) to red (end)
    static let riskArcFullGradient = AngularGradient(
        gradient: Gradient(stops: [
            .init(color: .green,  location: 0.0),
            .init(color: .yellow, location: 0.5),
            .init(color: .red,    location: 1.0)
        ]),
        center: .center,
        startAngle: .degrees(135),
        endAngle: .degrees(405)
    )
    
    // Adjustable icon size for bottom navigation icons
    static let bottomIconSize: CGFloat = 20
    static let bottomIconColor: Color = .white
    
    static let waterPickerWidth: CGFloat = 120
    static let waterPickerHeight: CGFloat = 100

    static let riskChartLabelOffset: CGFloat = 0  // Adjust positive values to shift right, negative to shift left.
    // Add these lines near the other AppTheme properties:
    static let waterWeightSeg1: CGFloat = 0.50  // Last 12 hours
    static let waterWeightSeg2: CGFloat = 0.25  // Previous 12 hours
    static let waterWeightSeg3: CGFloat = 0.13  // Day 2
    static let waterWeightSeg4: CGFloat = 0.07  // Day 3
    static let waterWeightSeg5: CGFloat = 0.035  // Day 4
    static let waterWeightSeg6: CGFloat = 0.015  // Day 5

    // Animation duration for the bar graph (in seconds)
    static let barAnimationDuration: Double = 1.5
    // Custom animation for the bar graph that accelerates toward the end.
    // Adjust the control points (0.4, 0.0, 1.0, 1.0) as needed.
    
    /*
         The cubic Bézier curve for the bar graph animation is defined by four parameters:
         
         - x1, y1: Control how the animation starts.
           - x1 (0 to 1): A lower value delays the progress at the beginning.
           - y1 (0 to 1): A lower value means the animation’s progress stays lower longer.
         
         - x2, y2: Control how the animation ends.
           - x2 (0 to 1): A higher value speeds up the animation toward the end.
           - y2 (0 to 1): A higher value makes the final part of the animation complete more rapidly.
         
         To make the rate go up significantly as the ring begins filling (i.e., a slow start followed by a rapid finish),
         you could try a timing curve like (0.2, 0.0, 0.8, 1.0). This means:
         
           - The animation will start slowly (because x1 is low and y1 is 0),
           - Then accelerate quickly (because x2 is higher and y2 is 1).
        */
    
    static var barAnimation: Animation {
        //Animation.timingCurve(0.4, 0.0, 1.0, 1.0, duration: barAnimationDuration)
        Animation.timingCurve(0.2, 0.0, 0.8, 1.0, duration: barAnimationDuration)
    }
    
    // MARK: - Lime Green Background
    /// Lime green at 60% opacity (top)
    static let backgroundTopColor: Color = Color(
        red: 0.8,   // Adjust these RGB values to fine-tune "lime" hue
        green: 1.0,
        blue: 0.0,
        opacity: 0.6
    )
    /// Lime green at 20% opacity (bottom)
    static let backgroundBottomColor: Color = Color(
        red: 0.8,
        green: 1.0,
        blue: 0.0,
        opacity: 0.2
    )
    // Bar styling
    static let barHeight: CGFloat = 20           // Thicker bar
    static let barHorizontalInset: CGFloat = 16  // Inset from screen edges
    static let barTopPadding: CGFloat = 10       // Distance below header
    
    // New: Graph vertical offset adjustment (additional space below header)
    static let graphVerticalOffset: CGFloat = 20    // Adjust this value to move the graph lower

    // Data card size
    static let cardWidth: CGFloat = 80
    static let cardHeight: CGFloat = 60
    
    // MARK: - Custom Header Styling
    static let customHeaderFontSize: CGFloat = 14
    static let customHeaderFontWeight: Font.Weight = .semibold
    static let customHeaderColor: Color = .yellow
    
    /// Use negative or zero to shift the header up.
    static let customHeaderOffsetY: CGFloat = 22
    
    // Bar settings
    
    // MARK: - Hybrid Risk Formula Weights
    // These weights determine how sensitive the overall dehydration risk score is to each factor.
    // Adjusting these values will change the computed risk as follows:
    //
    // W_water (e.g., 0.4): The weight for the water deficit component.
    //   - A higher W_water means that a shortfall in water intake will contribute more to the risk score,
    //     making dehydration risk rise more quickly if the user isn't drinking enough water.
    //   - A lower W_water reduces the influence of water intake on the risk score.
    static let W_water: Double = 0.6
    //
    // W_activity (e.g., 0.25): The weight for the activity index.
    //   - Increasing W_activity makes the risk score more sensitive to high levels of physical activity.
    //     This reflects the idea that dehydration can occur more rapidly with increased activity.
    //   - Decreasing W_activity reduces the impact of physical activity on the overall risk.
    static let W_activity: Double = 0.2
    //
    // W_hr (e.g., 0.2): The weight for the heart rate index.
    //   - A higher W_hr means that elevated heart rate (beyond resting levels) will have a greater impact on risk.
    //   - Lowering W_hr reduces the effect of heart rate changes on the risk score.
    static let W_hr: Double = 0.15
    //
    // W_temp (e.g., 0.1): The weight for the temperature index.
    //   - Increasing W_temp will amplify the contribution of body temperature deviations (from normal) to the risk score.
    //     This means that if a user’s body temperature rises (a sign of dehydration), the risk score will increase more steeply.
    //   - Decreasing W_temp lessens the effect of body temperature on the risk.
    static let W_temp: Double = 0.0
    //
    // W_delta (e.g., 0.05): The weight for the rate-of-change (delta) factor.
    //   - This factor captures how quickly the risk score is changing.
    //   - A higher W_delta makes the risk score more reactive to rapid changes (for example, if activity suddenly spikes),
    //     thus flagging dehydration risk faster.
    //   - A lower W_delta will make the risk score less sensitive to rapid changes.
    static let W_delta: Double = 0.05
    
    // MARK: - Animation Durations
    /// Duration for the outer (risk) ring animation (in seconds).
    static let riskAnimationDuration: Double = 1.5
    /// Duration for the inner (water) ring animation (in seconds).
    static let waterAnimationDuration: Double = 1.75
    
    // MARK: - Ring Cap Segment
    /// When a ring is full, overlay a cap arc segment representing a "snake-head" effect.
    static let ringCapSegment: CGFloat = 0.05
    
    // MARK: - Ring Configuration
    static let ringLineWidth: CGFloat = 18
    static let ringSize: CGFloat = 130
    static let waterOpacity: Double = 0.4
    /// Inner ring line width (configurable; default same as outer ring)
    static let innerRingLineWidth: CGFloat = ringLineWidth
    
    // Outer ring icon adjustments
    static let outerRingIconSize: CGFloat = 8
    static let outerRingIconOffsetFractionAdjusted: CGFloat = 0.4
    
    // MARK: - Icon Offsets for Dual Rings
    /// Fraction of the outer ring’s radius at which to place the risk icon.
    static let outerRingIconOffsetFraction: CGFloat = 0.505

    /// Fraction of the inner ring’s radius at which to place the water icon.
    static let innerRingIconOffsetFraction: CGFloat = 0.5
    
    // MARK: - Icon Font Sizes for Rings
    static let outerRingIconFont: Font = .caption
    static let innerRingIconFont: Font = .caption
    
    // MARK: - Icon Font Settings for Rings
    // Font size for the outer (risk) icon. Adjust as needed.
    static let outerRingIconFontSize: CGFloat = 15
    // Font weight for the outer (risk) icon.
    static let outerRingIconWeight: Font.Weight = .bold
    // Font size for the inner (water) icon. Adjust as needed.
    static let innerRingIconFontSize: CGFloat = 15
    static let innerRingIconWeight: Font.Weight = .regular
    
    // New properties for icon positioning within the rings
    static let outerRingIconPadding: CGFloat = 20
    static let innerRingIconPadding: CGFloat = 20
    
    static let highRiskThreshold: Double = 0.8
    static let midRiskThreshold: Double = 0.5
    static let alertIconSize: CGFloat = 30 // Adjust this value as needed
    
    // MARK: - Water Ring Zero Dot
    /// Color of the dot that appears on the water ring if fraction == 0
    static let waterRingZeroDotColor: Color = .blue
    // MARK: - "Snake-head" Cap
    // If you want a visible cap at 100% progress, clamp the fraction
    /// to something slightly below 1.0 so it never closes the circle.
    /// Example: 0.9999 => ~99.99% of the circle, leaving a small gap.
    static let ringCapTrim: CGFloat = 0.9999
    
    /// Size of the dot (width & height)
    static let waterRingZeroDotSize: CGFloat = 20
    
    /// Fraction of the inner ring’s radius at which to place the zero-dot
    static let waterRingZeroDotOffsetFraction: CGFloat = 0.5
    
    // MARK: - Colors & Gradients
    static let waterColor: Color = Color.blue
    static let waterIntakeGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.blue.opacity(0.6),
            Color.black
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    static let statsGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.purple.opacity(0.6),
            Color.black
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Semi-Transparent Gradients for Boxes
    // Example definitions (your actual definitions may differ):
    static let boxGradientGreen = LinearGradient(
        gradient: Gradient(colors: [Color.green.opacity(0.9), Color.green.opacity(0.6)]),
        startPoint: .top,
        endPoint: .bottom
    )
    static let boxGradientOrange = LinearGradient(
        gradient: Gradient(colors: [Color.orange.opacity(0.9), Color.orange.opacity(0.6)]),
        startPoint: .top,
        endPoint: .bottom
    )
    static let boxGradientBlue = LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.6)]),
        startPoint: .top,
        endPoint: .bottom
    )
    static let boxGradientPurple = LinearGradient(
        gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.purple.opacity(0.6)]),
        startPoint: .top,
        endPoint: .bottom
    )
    static let boxGradientTeal = LinearGradient(
        gradient: Gradient(colors: [Color.teal.opacity(0.9), Color.teal.opacity(0.6)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Font Sizes
    static let mainTabStatusFont: Font = .caption
    
    // MARK: - Icon Names
    /// Available chart icons (SF Symbols) include:
    ///  - "chart.bar.xaxis"
    ///  - "chart.bar"
    ///  - "chart.bar.fill"
    ///  - "chart.xyaxis.line"
    ///  - "chart.line.uptrend.xyaxis"
    //static let chartIconName: String = "chart.bar.xaxis"
    //static let chartIconName: String = "chart.xyaxis.line"
    //static let chartIconName: String = "cup.and.saucer.fill"
    //static let chartIconName: String = "waterbottle.fill"
    static let chartIconName: String = "mug.fill"
    //static let chartIconName: String = "wave.3.forward"
    //static let chartIconName: String = "drop.circle"
    
    /// Available profile icons (SF Symbols) include:
    ///  - "person.fill"
    ///  - "person.crop.circle"
    ///  - "person.crop.circle.fill"
    ///  - "person.circle"
    static let profileIconName: String = "person.fill"
    //static let profileIconName: String = "person.circle"
    
    // MARK: - Icon Placement Configuration
        /// Controls where the header icons (chart & profile) are placed in the MainHydrationView.
        /// Options:
        ///   .top – Icons appear at the top (default).
        ///   .bottom – Icons appear at the bottom.
        enum IconPlacement {
            case top
            case bottom
        }
        /// Set the placement of the icons in MainHydrationView.
        static let mainIconPlacement: IconPlacement = .bottom
    
    // MARK: - Ring Color Function
    static func ringColor(for risk: Double) -> Color {
        switch risk {
        case 0..<0.5:
            return .green
        case 0.5..<0.8:
            return .yellow
        default:
            return .red
        }
    }
    
    // MARK: - Water Intake and Risk Weights
    /// Recommended water multiplier in ml per kg of body weight.
    static let recommendedWaterMultiplier: Double = 35.0
    /// Conversion factor from lbs to kg.
    static let lbToKg: Double = 0.453592
    /// Weight for the water intake risk factor.
    static let weightWater: Double = 3.0
    /// Weight for heart rate risk.
    static let weightHR: Double = 1.0
    /// Weight for step count risk.
    static let weightSteps: Double = 1.0
    /// Weight for active energy risk.
    static let weightAE: Double = 1.0
    /// Weight for exercise time risk.
    static let weightEX: Double = 1.0
    /// Weight for distance risk.
    static let weightDistance: Double = 1.0
}
