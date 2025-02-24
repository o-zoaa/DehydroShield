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
        // Observe water log actions from notifications.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDidLogWater(_:)),
                                               name: .didLogWater,
                                               object: nil)
        
        // Upon initialization, schedule a water inactivity notification.
        if let lastLog = lastWaterLogDate {
            let elapsed = Date().timeIntervalSince(lastLog)
            if elapsed < AppTheme.waterInactivityThreshold {
                let remaining = AppTheme.waterInactivityThreshold - elapsed
                NotificationManager.shared.scheduleWaterInactivityNotification(withDelay: remaining)
            } else {
                NotificationManager.shared.scheduleWaterInactivityNotification(withDelay: 1)
            }
        } else {
            // No water log exists, schedule notification immediately.
            NotificationManager.shared.scheduleWaterInactivityNotification(withDelay: 1)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Called when a water log action is triggered from a notification.
    @objc private func handleDidLogWater(_ notification: Notification) {
        if let amount = notification.object as? Int {
            // Logging water from notification updates the water logs and resets the inactivity timer.
            addWater(amount: Double(amount))
        }
    }
    
    /// Adds a new water entry with the current timestamp and saves the updated logs.
    func addWater(amount: Double) {
        let newEntry = WaterLogEntry(amount: amount, date: Date())
        print("addWater() - New water entry added:", newEntry)
        waterLogs.append(newEntry)
        saveWaterLogs()
        
        // When water is logged, cancel any existing inactivity notification and schedule a new one.
        NotificationManager.shared.cancelWaterInactivityNotification()
        NotificationManager.shared.scheduleWaterInactivityNotification()
    }
    
    /// Computes the total water intake within the last 24 hours.
    var waterIntakeLast24Hours: Double {
        let now = Date()
        let cutoff = now.addingTimeInterval(-24 * 60 * 60)
        return waterLogs
            .filter { $0.date >= cutoff }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Computes the total water intake over the last 5 days.
    var waterIntakeLast5Days: Double {
        let now = Date()
        let cutoff = now.addingTimeInterval(-5 * 24 * 60 * 60)
        return waterLogs
            .filter { $0.date >= cutoff }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Computes the weighted water intake over the last 5 days using exponential weights.
    var weightedWaterIntakeLast5Days: Double {
        let now = Date()
        // Define segment durations (in seconds):
        let seg1: TimeInterval = 12 * 3600  // Last 12 hours
        let seg2: TimeInterval = 12 * 3600  // Previous 12 hours
        let seg3: TimeInterval = 24 * 3600  // Day 2
        let seg4: TimeInterval = 24 * 3600  // Day 3
        let seg5: TimeInterval = 24 * 3600  // Day 4
        let seg6: TimeInterval = 24 * 3600  // Day 5
        
        // Use adjustable weights from AppTheme:
        let w1 = AppTheme.waterWeightSeg1
        let w2 = AppTheme.waterWeightSeg2
        let w3 = AppTheme.waterWeightSeg3
        let w4 = AppTheme.waterWeightSeg4
        let w5 = AppTheme.waterWeightSeg5
        let w6 = AppTheme.waterWeightSeg6
        
        let water1 = waterLogs.filter { now.timeIntervalSince($0.date) <= seg1 }
            .reduce(0) { $0 + $1.amount }
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
    
    // MARK: - Persistence Methods
    
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
            print("loadWaterLogs() - Loaded water logs:", waterLogs)
        } catch {
            print("Error loading water logs: \(error)")
        }
    }
}

extension WaterIntakeManager {
    /// Provides the date of the last water log entry.
    var lastWaterLogDate: Date? {
        waterLogs.last?.date
    }
}

/// A water log entry that records the water amount (ml) and the timestamp.
struct WaterLogEntry: Codable {
    let amount: Double
    let date: Date
}

/// New data models for detailed daily water breakdown.
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
    /// Returns an array of DailyWaterDetail for each of the last 5 days (including today).
    func last5DaysDailyTotalsDetailed() -> [DailyWaterDetail] {
        let calendar = Calendar.current
        let now = Date()
        guard let cutoff = calendar.date(byAdding: .day, value: -5, to: now) else { return [] }
        
        // Filter logs for the last 5 days.
        let filteredLogs = waterLogs.filter { $0.date >= cutoff }
        
        // Group logs by day (using the start-of-day)
        let groupedByDay = Dictionary(grouping: filteredLogs, by: { calendar.startOfDay(for: $0.date) })
        
        var details: [DailyWaterDetail] = []
        for (day, dayLogs) in groupedByDay {
            // Group each day's logs by hour.
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
