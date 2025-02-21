//
//  DehydrationHistoryManager.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import Foundation
import SwiftUI

struct DailyRiskEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var risk: Double
    
    init(date: Date, risk: Double) {
        self.id = UUID()
        self.date = date
        self.risk = risk
    }
}

class DehydrationHistoryManager: ObservableObject {
    @Published var dailyEntries: [DailyRiskEntry] = []
    
    private let userDefaultsKey = "DehydrationDailyRisk"
    
    init() {
        loadDailyRiskHistory()
        if dailyEntries.isEmpty {
            seedSampleDataForPastWeek()
        }
    }
    
    func saveTodayRisk(_ risk: Double) {
        let today = startOfDay(Date())
        loadDailyRiskHistory()
        if let index = dailyEntries.firstIndex(where: { isSameDay($0.date, today) }) {
            dailyEntries[index].risk = risk
        } else {
            let newEntry = DailyRiskEntry(date: today, risk: risk)
            dailyEntries.append(newEntry)
        }
        persistDailyRiskHistory()
        trimHistoryTo7Days()
    }
    
    func loadDailyRiskHistory() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: userDefaultsKey) else {
            dailyEntries = []
            return
        }
        do {
            let decoder = JSONDecoder()
            dailyEntries = try decoder.decode([DailyRiskEntry].self, from: data)
        } catch {
            print("Error decoding daily risk data: \(error)")
            dailyEntries = []
        }
    }
    
    func trimHistoryTo7Days() {
        let cutOff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        dailyEntries.removeAll { $0.date < startOfDay(cutOff) }
        persistDailyRiskHistory()
    }
    
    private func seedSampleDataForPastWeek() {
        let cal = Calendar.current
        let now = Date()
        let sampleRisks: [Double] = [0.25, 0.35, 0.2, 0.55, 0.7, 0.4, 0.85]
        for i in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -i, to: now) else { continue }
            let dayStart = startOfDay(day)
            let risk = sampleRisks.reversed()[i]
            let entry = DailyRiskEntry(date: dayStart, risk: risk)
            dailyEntries.append(entry)
        }
        dailyEntries.sort(by: { $0.date < $1.date })
        persistDailyRiskHistory()
    }
    
    private func persistDailyRiskHistory() {
        let defaults = UserDefaults.standard
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(dailyEntries)
            defaults.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error encoding daily risk data: \(error)")
        }
    }
    
    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    private func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
}

