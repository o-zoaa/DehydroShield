//
//  HueEffectExampleView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/19/25.
//


import SwiftUI

struct HueEffectExampleView: View {
    // You can dynamically control the hue shift with a @State variable.
    @State private var hueAngle: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            // A linear gradient background.
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.20),
                    Color(red: 0.04, green: 0.05, blue: 0.10)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            // Apply a hue rotation of `hueAngle` degrees to the gradient.
            .hueRotation(Angle(degrees: hueAngle))
            .frame(height: 200) // Example frame height

            // A slider to change the hueAngle, demonstrating how hue rotation changes the colors in real time.
            Slider(value: $hueAngle, in: 0...360, step: 1) {
                Text("Hue Rotation")
            }
            .padding(.horizontal)

            Text("Hue Rotation: \(Int(hueAngle))°")
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

struct HueEffectExampleView_Previews: PreviewProvider {
    static var previews: some View {
        HueEffectExampleView()
    }
}
