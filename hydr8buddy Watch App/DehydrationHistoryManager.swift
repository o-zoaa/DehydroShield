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
/// Every computed risk is appended, and entries are trimmed to the last 30 days.
class DehydrationHistoryManager: ObservableObject {
    @Published var riskEntries: [RiskEntry] = []
    
    private let userDefaultsKey = "DehydrationRiskEntries"
    
    init() {
        loadRiskEntries()
        if riskEntries.isEmpty {
            seedSampleDataForPast30Days()
        }
    }
    
    /// Appends a new risk entry with the current timestamp.
    func saveRiskEntry(_ risk: Double) {
        let newEntry = RiskEntry(date: Date(), risk: risk)
        riskEntries.append(newEntry)
        persistRiskEntries()
        trimEntriesTo30Days()
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
            trimEntriesTo30Days() // Ensure we only keep the last 30 days
        } catch {
            print("Error decoding risk data: \(error)")
            riskEntries = []
        }
    }
    
    /// Trims risk entries to only the last 30 days.
    func trimEntriesTo30Days() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        riskEntries.removeAll { $0.date < cutoff }
        persistRiskEntries()
    }
    
    private func seedSampleDataForPast30Days() {
        let cal = Calendar.current
        let now = Date()
        // For sample purposes, generate one entry per day for the last 7 days.
        let sampleRisks: [Double] = [0.25, 0.35, 0.2, 0.55, 0.7, 0.4, 0.85]
        for i in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -i, to: now) else { continue }
            let risk = sampleRisks.reversed()[i]
            let entry = RiskEntry(date: day, risk: risk)
            riskEntries.append(entry)
        }
        riskEntries.sort(by: { $0.date < $1.date })
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
}
