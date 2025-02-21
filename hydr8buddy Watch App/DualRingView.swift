import SwiftUI

struct DualRingView: View {
    
    // Outer ring fraction (0.0 = no risk, 1.0 = max risk)
    let riskFraction: Double
    // Inner ring fraction (0.0 = no water, 1.0 = recommended water)
    let waterFraction: Double
    
    var body: some View {
        ZStack {
            // =====================
            // OUTER RING (Risk)
            // =====================
            ZStack {
                // Outer ring background
                Circle()
                    .stroke(lineWidth: AppTheme.ringLineWidth)
                    .foregroundColor(AppTheme.ringColor(for: riskFraction).opacity(0.2))
                
                // Outer ring foreground arc
                // Clamp fraction so at 100% we still see the lineCap
                let clampedRisk = min(riskFraction, Double(AppTheme.ringCapTrim))
                Circle()
                    .trim(from: 0, to: CGFloat(clampedRisk))
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: AppTheme.ringLineWidth,
                            lineCap: .round
                        )
                    )
                    .foregroundColor(AppTheme.ringColor(for: riskFraction))
                    .rotationEffect(Angle(degrees: -90))
            }
            .frame(width: AppTheme.ringSize, height: AppTheme.ringSize)
            .overlay(
                // Outer ring icon at 12 o'clock
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: AppTheme.outerRingIconFontSize, weight: AppTheme.outerRingIconWeight))
                    .foregroundColor(.white)
                    .offset(y: -(AppTheme.ringSize * AppTheme.outerRingIconOffsetFraction))
            )
            
            // =====================
            // INNER RING (Water)
            // =====================
            ZStack {
                let innerSize = AppTheme.ringSize * 0.65
                let innerLineWidth = AppTheme.innerRingLineWidth
                
                // Inner ring background
                Circle()
                    .stroke(lineWidth: innerLineWidth)
                    .foregroundColor(AppTheme.waterColor.opacity(0.2))
                
                if waterFraction > 0 {
                    // Normal arc when waterFraction > 0
                    // Clamp fraction so it never reaches full 1.0 (snake-head effect)
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
                    // If fraction == 0, draw a small dot at the top
                    Circle()
                        .fill(AppTheme.waterRingZeroDotColor)
                        .frame(width: AppTheme.waterRingZeroDotSize,
                               height: AppTheme.waterRingZeroDotSize)
                        .offset(y: -(innerSize * AppTheme.waterRingZeroDotOffsetFraction))
                }
            }
            .frame(width: AppTheme.ringSize * 0.65, height: AppTheme.ringSize * 0.65)
            .overlay(
                // Icon at 12 o'clock for the inner ring
                Image(systemName: "drop") // was drop.fill
                    .font(.system(size: AppTheme.innerRingIconFontSize, weight: AppTheme.innerRingIconWeight))
                    .foregroundColor(.white)
                    .offset(y: -((AppTheme.ringSize * 0.65) * AppTheme.innerRingIconOffsetFraction))
            )
            
            // =====================
            // ALERT ICON / CHECK
            // =====================
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
    }
}
