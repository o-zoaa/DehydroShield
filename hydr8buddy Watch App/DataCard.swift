//
//  DataCard.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/19/25.
//


import SwiftUI

struct DataCard: View {
    let iconName: String
    let label: String
    let value: String
    let cardColor: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(cardColor.opacity(0.2))
            
            VStack(spacing: 2) {
                Image(systemName: iconName)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
                Text(value)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .padding(4)
        }
        // Use the new AppTheme.cardWidth/cardHeight
        .frame(width: AppTheme.cardWidth, height: AppTheme.cardHeight)
    }
}
