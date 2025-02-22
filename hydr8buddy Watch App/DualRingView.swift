//
//  DualRingView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI

struct DualRingView: View {
    let riskFraction: Double  // risk fraction in [0..1] (calculated using weighted water intake over 5 days, etc.)
    let waterFraction: Double // water fraction in [0..1] (using water intake over past 24 hours)

    var body: some View {
        ZStack {
            // =======================================
            // FULL COLOR ARC (Green→Yellow→Red)
            // =======================================
            ZStack {
                // Draw the full arc from 135° to 405°
                PartialArcShape(
                    startAngle: AppTheme.riskArcStartAngle,
                    totalArcDegrees: AppTheme.riskArcDegrees,
                    fraction: 1.0 // Always full arc
                )
                .stroke(
                    {
                        let appliedGradient = AppTheme.riskArcFullGradient
                        print("DualRingView - Applying UI Color (arc gradient):", appliedGradient)
                        return appliedGradient
                    }(),
                    style: StrokeStyle(
                        lineWidth: AppTheme.riskArcThickness,
                        lineCap: .round
                    )
                )
                .scaleEffect(AppTheme.riskArcScaleFactor)
            }
            
            // =======================================
            // POINTER / MARKER FOR CURRENT RISK
            // =======================================
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let radius = (size / 2) * AppTheme.riskArcScaleFactor
                // Clamp riskFraction to [0,1] then convert to an angle (degrees)
                let clampedFraction = max(0, min(riskFraction, 1))
                let pointerAngle = 135.0 + (AppTheme.riskArcDegrees * clampedFraction)
                let pointerSize = AppTheme.riskArcThickness * AppTheme.riskPointerScale
                
                // Use our custom modifier to animate the pointer along the arc.
                Circle()
                    //.fill(Color.white)
                    .stroke(Color.white, lineWidth: 1.5  )  // Adjust the lineWidth as needed
                    .frame(width: pointerSize, height: pointerSize)
                    .modifier(ArcPositionModifier(angle: pointerAngle,
                                                   radius: radius,
                                                   center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)))
            }
            
            // =======================================
            // RISK LABELS (Low, Med, High)
            // =======================================
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let radius = (size / 2) * AppTheme.riskArcScaleFactor
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let labelRadius = radius + 14.0 // Offset labels 14 points beyond the arc
                
                // Low Risk label (at startAngle: 135°)
                let lowAngleDeg = 135.0
                let lowAngleRad = lowAngleDeg * (.pi / 180)
                let lowX = center.x + labelRadius * cos(lowAngleRad)
                let lowY = center.y + labelRadius * sin(lowAngleRad)
                Text("Low Risk")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.green)
                    .position(x: lowX, y: lowY)
                    .offset(y: 8)
                
                // Medium Risk label (at the midpoint of the arc)
                let medAngleDeg = 135.0 + (AppTheme.riskArcDegrees * 0.5)
                let medAngleRad = medAngleDeg * (.pi / 180)
                let medX = center.x + labelRadius * cos(medAngleRad)
                let medY = center.y + labelRadius * sin(medAngleRad)
                Text("Medium Risk")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.yellow)
                    .position(x: medX, y: medY)
                    .offset(y: -4)
                
                // High Risk label (at the end of the arc: 405°)
                let highAngleDeg = 135.0 + AppTheme.riskArcDegrees
                let highAngleRad = highAngleDeg * (.pi / 180)
                let highX = center.x + labelRadius * cos(highAngleRad)
                let highY = center.y + labelRadius * sin(highAngleRad)
                Text("High Risk")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.red)
                    .position(x: highX, y: highY)
                    .offset(y: 8)
            }
            
            // =======================================
            // INNER RING (Water)
            // =======================================
            ZStack {
                let innerSize = AppTheme.ringSize * 0.65
                let innerLineWidth = AppTheme.innerRingLineWidth
                
                Circle()
                    .stroke(lineWidth: innerLineWidth)
                    .foregroundColor(AppTheme.waterColor.opacity(0.2))
                
                if waterFraction > 0 {
                    let clampedWater = min(waterFraction, Double(AppTheme.ringCapTrim))
                    Circle()
                        .trim(from: 0, to: CGFloat(clampedWater))
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: innerLineWidth,
                                lineCap: .round
                            )
                        )
                        .foregroundColor(AppTheme.waterColor)
                        .rotationEffect(Angle(degrees: -90))
                } else {
                    Circle()
                        .fill(AppTheme.waterRingZeroDotColor)
                        .frame(width: AppTheme.waterRingZeroDotSize,
                               height: AppTheme.waterRingZeroDotSize)
                        .offset(y: -(innerSize * AppTheme.waterRingZeroDotOffsetFraction))
                }
            }
            .frame(width: AppTheme.ringSize * 0.65, height: AppTheme.ringSize * 0.65)
            .overlay(
                Image(systemName: "drop.circle")
                    .font(.system(size: AppTheme.innerRingIconFontSize, weight: AppTheme.innerRingIconWeight))
                    .foregroundColor(.white)
                    .offset(y: -((AppTheme.ringSize * 0.65) * AppTheme.innerRingIconOffsetFraction))
            )
            
            // =======================================
            // ALERT ICON / CHECK – optional
            // =======================================
            if riskFraction >= AppTheme.highRiskThreshold {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: AppTheme.alertIconSize))
                    .foregroundColor(.red)
                    .transition(.scale)
            } else if riskFraction >= AppTheme.midRiskThreshold {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: AppTheme.alertIconSize))
                    .foregroundColor(.yellow)
                    .transition(.scale)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: AppTheme.alertIconSize))
                    .foregroundColor(.green)
                    .transition(.scale)
            }
        }
        .frame(width: AppTheme.ringSize, height: AppTheme.ringSize)
    }
}

// MARK: - Animatable Modifier to position a view along a circular arc

struct ArcPositionModifier: AnimatableModifier {
    var angle: Double  // in degrees
    var radius: CGFloat
    var center: CGPoint
    
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    
    func body(content: Content) -> some View {
        let radian = angle * (.pi / 180)
        let newX = center.x + radius * cos(radian)
        let newY = center.y + radius * sin(radian)
        return content.position(x: newX, y: newY)
    }
}

struct DualRingView_Previews: PreviewProvider {
    static var previews: some View {
        DualRingView(riskFraction: 0.6, waterFraction: 0.5)
            .previewLayout(.sizeThatFits)
    }
}
