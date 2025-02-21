//
//  WaterIntakeView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI
import WatchKit

struct WaterIntakeView: View {
    @EnvironmentObject var waterIntakeManager: WaterIntakeManager  // Provided from a separate file
    
    // Common water intake options in milliliters
    let commonAmounts: [Double] = [100, 150, 200, 250, 300]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                // Header text (center-aligned)
                Text("Water consumed in the last 24 hours: \(Int(waterIntakeManager.waterIntakeLast24Hours)) ml")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                
                // Horizontal scroll of water intake option boxes using ProfileDataBox
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(commonAmounts, id: \.self) { amount in
                            Button(action: {
                                waterIntakeManager.addWater(amount: amount)
                                WKInterfaceDevice.current().play(.click)
                            }) {
                                ProfileDataBox(
                                    label: "+\(Int(amount)) ml", // Changed label to include '+'
                                    value: "",
                                    boxGradient: AppTheme.boxGradientTeal,
                                    onEdit: {},
                                    showEditIcon: false,
                                    textAlignment: .center
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(width: 60, height: 60)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer(minLength: 8)
            }
            .padding(.vertical, 8)
        }
        .scrollDisabled(true)
        .navigationTitle("Water Intake")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
}

struct WaterIntakeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WaterIntakeView()
                .environmentObject(WaterIntakeManager())
        }
    }
}
