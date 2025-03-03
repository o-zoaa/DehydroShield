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
    
    var allWaterLogs: [WaterLogEntry] {
        waterLogs
    }
    
    private let userDefaultsKey = "WaterLogs"
    
    init() {
        loadWaterLogs()
        trimWaterLogsTo5Days()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDidLogWater(_:)),
                                               name: .didLogWater,
                                               object: nil)
        
        if let lastLog = lastWaterLogDate {
            let elapsed = Date().timeIntervalSince(lastLog)
            if elapsed < AppTheme.waterInactivityThreshold {
                let remaining = AppTheme.waterInactivityThreshold - elapsed
                NotificationManager.shared.scheduleWaterInactivityNotification(withDelay: remaining)
            } else {
                NotificationManager.shared.scheduleWaterInactivityNotification(withDelay: 1)
            }
        } else {
            NotificationManager.shared.scheduleWaterInactivityNotification(withDelay: 1)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Called when a water log action is triggered from a notification.
    @objc private func handleDidLogWater(_ notification: Notification) {
        if let amount = notification.object as? Int {
            addWater(amount: Double(amount))
        }
    }
    
    /// Adds a new water entry with the current timestamp, saves the updated logs, and posts a notification.
    func addWater(amount: Double) {
        let newEntry = WaterLogEntry(amount: amount, date: Date())
        print("addWater() - New water entry added:", newEntry)
        waterLogs.append(newEntry)
        saveWaterLogs()
        trimWaterLogsTo5Days()
        
        // Post notification that water has been logged.
        NotificationCenter.default.post(name: .waterLogged, object: nil)
        
        NotificationManager.shared.cancelWaterInactivityNotification()
        NotificationManager.shared.scheduleWaterInactivityNotification()
    }
    
    /// Computes the total water intake within the last 24 hours.
    var waterIntakeLast24Hours: Double {
        let now = Date()
        let cutoff = now.addingTimeInterval(-24 * 60 * 60)
        return waterLogs.filter { $0.date >= cutoff }.reduce(0) { $0 + $1.amount }
    }
    
    /// Computes the total water intake over the last 5 days.
    var waterIntakeLast5Days: Double {
        let now = Date()
        let cutoff = now.addingTimeInterval(-5 * 24 * 60 * 60)
        return waterLogs.filter { $0.date >= cutoff }.reduce(0) { $0 + $1.amount }
    }
    
    /// Computes the weighted water intake over the last 5 days using exponential weights.
    var weightedWaterIntakeLast5Days: Double {
        let now = Date()
        let seg1: TimeInterval = 12 * 3600
        let seg2: TimeInterval = 12 * 3600
        let seg3: TimeInterval = 24 * 3600
        let seg4: TimeInterval = 24 * 3600
        let seg5: TimeInterval = 24 * 3600
        let seg6: TimeInterval = 24 * 3600
        
        let w1 = AppTheme.waterWeightSeg1
        let w2 = AppTheme.waterWeightSeg2
        let w3 = AppTheme.waterWeightSeg3
        let w4 = AppTheme.waterWeightSeg4
        let w5 = AppTheme.waterWeightSeg5
        let w6 = AppTheme.waterWeightSeg6
        
        let water1 = waterLogs.filter { now.timeIntervalSince($0.date) <= seg1 }.reduce(0) { $0 + $1.amount }
        let water2 = waterLogs.filter {
            let t = now.timeIntervalSince($0.date)
            return t > seg1 && t <= (seg1 + seg2)
        }.reduce(0) { $0 + $1.amount }
        let water3 = waterLogs.filter {
            let t = now.timeIntervalSince($0.date)
            return t > (seg1 + seg2) && t <= (seg1 + seg2 + seg3)
        }.reduce(0) { $0 + $1.amount }
        let water4 = waterLogs.filter {
            let t = now.timeIntervalSince($0.date)
            return t > (seg1 + seg2 + seg3) && t <= (seg1 + seg2 + seg3 + seg4)
        }.reduce(0) { $0 + $1.amount }
        let water5 = waterLogs.filter {
            let t = now.timeIntervalSince($0.date)
            return t > (seg1 + seg2 + seg3 + seg4) && t <= (seg1 + seg2 + seg3 + seg4 + seg5)
        }.reduce(0) { $0 + $1.amount }
        let water6 = waterLogs.filter {
            let t = now.timeIntervalSince($0.date)
            return t > (seg1 + seg2 + seg3 + seg4 + seg5) && t <= (seg1 + seg2 + seg3 + seg4 + seg5 + seg6)
        }.reduce(0) { $0 + $1.amount }
        
        return (w1 * water1) + (w2 * water2) + (w3 * water3) + (w4 * water4) + (w5 * water5) + (w6 * water6)
    }
    
    /// Trims water log entries to only those from the past 5 days.
    private func trimWaterLogsTo5Days() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        waterLogs.removeAll { $0.date < cutoff }
        saveWaterLogs()
    }
    
    private func saveWaterLogs() {
        do {
            let data = try JSONEncoder().encode(waterLogs)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error saving water logs: \(error)")
        }
    }
    
    private func loadWaterLogs() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("loadWaterLogs() - No data found.")
            return
        }
        do {
            waterLogs = try JSONDecoder().decode([WaterLogEntry].self, from: data)
        } catch {
            print("Error loading water logs: \(error)")
        }
    }
    
    var lastWaterLogDate: Date? {
        waterLogs.last?.date
    }
}

struct WaterLogEntry: Codable {
    let amount: Double
    let date: Date
}

struct DailyWaterDetail: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let segments: [WaterSegment]
    var total: Double {
        segments.reduce(0) { $0 + $1.total }
    }
}

struct WaterSegment: Codable {
    let start: Date
    let end: Date
    let total: Double
}

extension WaterIntakeManager {
    func last5DaysDailyTotalsDetailed() -> [DailyWaterDetail] {
        let calendar = Calendar.current
        let now = Date()
        guard let cutoff = calendar.date(byAdding: .day, value: -5, to: now) else { return [] }
        
        let filteredLogs = waterLogs.filter { $0.date >= cutoff }
        let groupedByDay = Dictionary(grouping: filteredLogs, by: { calendar.startOfDay(for: $0.date) })
        
        var details: [DailyWaterDetail] = []
        for (day, dayLogs) in groupedByDay {
            let groupedByHour = Dictionary(grouping: dayLogs, by: {
                calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: $0.date))!
            })
            
            var segments: [WaterSegment] = []
            for (hour, hourLogs) in groupedByHour {
                let total = hourLogs.reduce(0) { $0 + $1.amount }
                let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hour) ?? hour
                segments.append(WaterSegment(start: hour, end: hourEnd, total: total))
            }
            segments.sort { $0.start < $1.start }
            details.append(DailyWaterDetail(date: day, segments: segments))
        }
        return details.sorted { $0.date < $1.date }
    }
}
