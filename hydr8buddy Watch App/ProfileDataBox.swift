//
//  ProfileDataBox.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI

public struct ProfileDataBox: View {
    let label: String
    let value: String
    let boxGradient: LinearGradient
    let onEdit: () -> Void
    let showEditIcon: Bool
    let textAlignment: TextAlignment  // New parameter
    
    public init(label: String,
                value: String,
                boxGradient: LinearGradient,
                onEdit: @escaping () -> Void,
                showEditIcon: Bool = true,
                textAlignment: TextAlignment = .leading) {
        self.label = label
        self.value = value
        self.boxGradient = boxGradient
        self.onEdit = onEdit
        self.showEditIcon = showEditIcon
        self.textAlignment = textAlignment
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(boxGradient)
                .opacity(0.8)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            
            HStack {
                VStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(textAlignment)
                    
                    if !value.isEmpty {
                        Text(value)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                            .multilineTextAlignment(textAlignment)
                    }
                }
                .frame(maxWidth: .infinity)
                
                if showEditIcon {
                    Image(systemName: "pencil.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                        .onTapGesture { onEdit() }
                }
            }
            .padding()
        }
    }
}
