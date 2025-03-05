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
    // State variable to disable the button temporarily
    @State private var waterButtonDisabled: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 25)
            
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
            
            Spacer(minLength: 5)
            
            // Water logging button.
            Button(action: {
                waterIntakeManager.addWater(amount: Double(selectedAmount))
                WKInterfaceDevice.current().play(.failure) // Haptic feedback.
                waterLogged = true
                waterButtonDisabled = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    waterButtonDisabled = false
                    waterLogged = false
                }
            }) {
                Text(waterLogged ? "Water Intake Logged" : "+ Water")
                    .font(waterLogged ? .system(size: 12, weight: .semibold) : .system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 125, height: 20) // Fixed width & height to prevent layout shift
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(waterButtonDisabled ? Color.gray : Color.blue)
                    .cornerRadius(8)
                    .animation(.easeInOut(duration: 0.5), value: waterButtonDisabled)
            }
            .buttonStyle(.plain)
            .disabled(waterButtonDisabled)
            
            Spacer(minLength: 8)
        }
        .navigationTitle("Water Intake")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
        // Overlay text at the top, offset slightly downward
        .overlay(
            Text("Past 24 Hours: \(waterIntakeManager.waterIntakeLast24Hours, specifier: "%.0f") ml")
                .font(.caption)
                .foregroundColor(.white)
                .offset(y: 20),
            alignment: .top
        )
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
