//
//  WaterIntakeManager.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI

/// A simple model that stores water log entries (amount + timestamp) and persists them using UserDefaults.
class WaterIntakeManager: ObservableObject {
    
    /// Each entry records an amount (in ml) and the time it was added.
    @Published private var waterLogs: [WaterLogEntry] = []
    
    private let userDefaultsKey = "WaterLogs"
    
    init() {
        loadWaterLogs()
    }
    
    /// Adds a new water entry with the current timestamp and saves the updated logs.
    func addWater(amount: Double) {
        let newEntry = WaterLogEntry(amount: amount, date: Date())
        waterLogs.append(newEntry)
        saveWaterLogs()
    }
    
    /// Computes the total water intake within the last 24 hours.
    var waterIntakeLast24Hours: Double {
        let now = Date()
        let cutoff = now.addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        return waterLogs
            .filter { $0.date >= cutoff }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// NEW: Computes the total water intake over the last 5 days.
    var waterIntakeLast5Days: Double {
        let now = Date()
        let cutoff = now.addingTimeInterval(-5 * 24 * 60 * 60) // 5 days ago
        return waterLogs
            .filter { $0.date >= cutoff }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Persistence Methods
    
    /// Saves the waterLogs array to UserDefaults.
    private func saveWaterLogs() {
        do {
            let data = try JSONEncoder().encode(waterLogs)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error saving water logs: \(error)")
        }
    }
    
    /// Loads the waterLogs array from UserDefaults.
    private func loadWaterLogs() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            waterLogs = try JSONDecoder().decode([WaterLogEntry].self, from: data)
        } catch {
            print("Error loading water logs: \(error)")
        }
    }
}

/// A water log entry that records the water amount (ml) and the timestamp.
struct WaterLogEntry: Codable {
    let amount: Double
    let date: Date
}
