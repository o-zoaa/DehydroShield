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
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - Daily Average Risk Aggregation

extension DehydrationHistoryManager {
    /// Computes and returns an array of (date, average risk) for the past 5 days.
    var dailyAvgRiskLast5Days: [(date: Date, avgRisk: Double)] {
        let calendar = Calendar.current
        let now = Date()
        // We consider the past 5 days (including today)
        guard let cutoff = calendar.date(byAdding: .day, value: -4, to: now) else { return [] }
        
        let recentEntries = riskEntries.filter { $0.date >= cutoff }
        let grouped = Dictionary(grouping: recentEntries, by: { calendar.startOfDay(for: $0.date) })
        
        var results: [(date: Date, avgRisk: Double)] = []
        for (day, entries) in grouped {
            let risks = entries.map { $0.risk }
            let avg = risks.reduce(0, +) / Double(risks.count)
            results.append((date: day, avgRisk: avg))
        }
        return results.sorted { $0.date < $1.date }
    }
}
