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
    
    // A list of possible water amounts (adjust as needed).
    private let possibleAmounts = Array(stride(from: 10, through: 300, by: 10))
    
    // Currently selected amount in the picker.
    @State private var selectedAmount: Int = 10
    
    var body: some View {
        VStack(spacing: 0) {
            
            Spacer(minLength: 10)
            
            // The picker without a surrounding green box.
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
            
            Button(action: {
                waterIntakeManager.addWater(amount: Double(selectedAmount))
                WKInterfaceDevice.current().play(.click)
            }) {
                Text("+ Water")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
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
