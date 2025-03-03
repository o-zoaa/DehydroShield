//
//  DehydrationHistoryManager.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import Foundation
import SwiftUI

/// Represents a single risk entry computed at a specific time.
struct RiskEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var risk: Double
    
    init(date: Date, risk: Double) {
        self.id = UUID()
        self.date = date
        self.risk = risk
    }
}

/// Manages the history of dehydration risk entries.
/// Only risk entries from the past 5 days are retained.
class DehydrationHistoryManager: ObservableObject {
    @Published var riskEntries: [RiskEntry] = []
    
    private let userDefaultsKey = "DehydrationRiskEntries"
    
    init() {
        loadRiskEntries()
        trimEntriesTo5Days()
    }
    
    /// Appends a new risk entry with the current timestamp.
    func saveRiskEntry(_ risk: Double) {
        let newEntry = RiskEntry(date: Date(), risk: risk)
        riskEntries.append(newEntry)
        persistRiskEntries()
        trimEntriesTo5Days()
    }
    
    func loadRiskEntries() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: userDefaultsKey) else {
            riskEntries = []
            return
        }
        do {
            let decoder = JSONDecoder()
            riskEntries = try decoder.decode([RiskEntry].self, from: data)
            trimEntriesTo5Days()
        } catch {
            print("Error decoding risk data: \(error)")
            riskEntries = []
        }
    }
    
    /// Trims risk entries to only those from the past 5 days.
    func trimEntriesTo5Days() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        riskEntries.removeAll { $0.date < cutoff }
        persistRiskEntries()
    }
    
    private func persistRiskEntries() {
        let defaults = UserDefaults.standard
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(riskEntries)
            defaults.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error encoding risk data: \(error)")
        }
    }
    
    // Dedicated function to clear all risk entries.
    func clearRiskEntries() {
        riskEntries.removeAll()
        // Remove the risk entries from persistent storage.
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

}
