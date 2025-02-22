//
//  PartialArcShape.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/21/25.
//


import SwiftUI

/// Draws a partial arc (e.g., 270º) from startAngle to startAngle + fraction * arcLength.
struct PartialArcShape: Shape {
    let startAngle: Angle       // e.g., 135º
    let totalArcDegrees: Double // e.g., 270
    let fraction: Double        // e.g., risk fraction in [0..1]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Clamp fraction to [0..1].
        let clamped = max(0, min(fraction, 1))
        
        // The arc’s end angle in degrees.
        let arcEndDegrees = startAngle.degrees + totalArcDegrees * clamped
        
        // Determine center & radius.
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: .degrees(arcEndDegrees),
            clockwise: false
        )
        
        return path
    }
}
