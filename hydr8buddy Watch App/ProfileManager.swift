//
//  ProfileManager.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import Foundation
import SwiftUI

struct UserProfile: Codable {
    var age: Int
    var weight: Double
    var sex: String      // New property for sex (e.g., "Male" or "Female")
    var location: String // New property for location (e.g., "New York")
}

class ProfileManager: ObservableObject {
    @Published var profile: UserProfile?
    
    private let userDefaultsKey = "UserProfile"
    
    init() {
        loadProfile()
    }
    
    private func loadProfile() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: userDefaultsKey) else {
            profile = nil
            return
        }
        do {
            let decoder = JSONDecoder()
            profile = try decoder.decode(UserProfile.self, from: data)
        } catch {
            print("Error decoding profile: \(error)")
            profile = nil
        }
    }
    
    func saveProfile() {
        guard let profile = profile else { return }
        let defaults = UserDefaults.standard
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            defaults.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error encoding profile: \(error)")
        }
    }
}
