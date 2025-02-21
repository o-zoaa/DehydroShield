//
//  ProfileView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Age Box
                ProfileDataBox(
                    label: "Age",
                    value: "\(profileManager.profile?.age ?? 0)",
                    boxGradient: AppTheme.boxGradientGreen
                ) {
                    print("Edit age tapped")
                }
                .padding(.horizontal, 16)
                
                // Weight Box
                ProfileDataBox(
                    label: "Weight",
                    value: String(format: "%.1f lbs", profileManager.profile?.weight ?? 0),
                    boxGradient: AppTheme.boxGradientOrange
                ) {
                    print("Edit weight tapped")
                }
                .padding(.horizontal, 16)
                
                // Sex Box
                ProfileDataBox(
                    label: "Sex",
                    value: profileManager.profile?.sex ?? "Male",
                    boxGradient: AppTheme.boxGradientBlue
                ) {
                    print("Edit sex tapped")
                }
                .padding(.horizontal, 16)
                
                // Location Box
                ProfileDataBox(
                    label: "Location",
                    value: profileManager.profile?.location ?? "Unknown",
                    boxGradient: AppTheme.boxGradientPurple
                ) {
                    print("Edit location tapped")
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 8)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(ProfileManager())
        }
    }
}
