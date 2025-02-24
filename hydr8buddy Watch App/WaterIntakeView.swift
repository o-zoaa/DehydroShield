//
//  WaterIntakeView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI
import WatchKit

struct WaterIntakeView: View {
    @EnvironmentObject var waterIntakeManager: WaterIntakeManager
    
    // A list of possible water amounts.
    private let possibleAmounts = Array(stride(from: 10, through: 300, by: 10))
    
    // Currently selected amount in the picker.
    @State private var selectedAmount: Int = 10
    // State variable to track whether water was just logged.
    @State private var waterLogged: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 10)
            
            // Wheel picker for water amounts.
            Picker("", selection: $selectedAmount) {
                ForEach(possibleAmounts, id: \.self) { amount in
                    Text("\(amount) ml")
                        .font(.body)
                        .padding(4)
                        .background(amount == selectedAmount ? Color.orange.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                        .tag(amount)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: AppTheme.waterPickerWidth, height: AppTheme.waterPickerHeight)
            
            Spacer(minLength: 10)
            
            // Water logging button.
            Button(action: {
                waterIntakeManager.addWater(amount: Double(selectedAmount))
                WKInterfaceDevice.current().play(.failure) // Stronger haptic feedback.
                waterLogged = true
                // After 5 seconds, revert the button back.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    waterLogged = false
                }
            }) {
                Text(waterLogged ? "Water Intake Logged" : "+ Water")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(waterLogged ? Color.green : Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(waterLogged)
            
            Spacer(minLength: 8)
        }
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
