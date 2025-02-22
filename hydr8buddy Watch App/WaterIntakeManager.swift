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
    
    /// Computes the total water intake over the last 5 days.
    var waterIntakeLast5Days: Double {
        let now = Date()
        let cutoff = now.addingTimeInterval(-5 * 24 * 60 * 60) // 5 days ago
        return waterLogs
            .filter { $0.date >= cutoff }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Computes the weighted water intake over the last 5 days using exponential weights.
    /// The weights are adjustable via AppTheme.
    var weightedWaterIntakeLast5Days: Double {
        let now = Date()
        // Define segment durations (in seconds):
        let seg1: TimeInterval = 12 * 3600  // last 12 hours
        let seg2: TimeInterval = 12 * 3600  // previous 12 hours (to complete day 1)
        let seg3: TimeInterval = 24 * 3600  // day 2
        let seg4: TimeInterval = 24 * 3600  // day 3
        let seg5: TimeInterval = 24 * 3600  // day 4
        let seg6: TimeInterval = 24 * 3600  // day 5
        
        // Use adjustable weights from AppTheme:
        let w1 = AppTheme.waterWeightSeg1
        let w2 = AppTheme.waterWeightSeg2
        let w3 = AppTheme.waterWeightSeg3
        let w4 = AppTheme.waterWeightSeg4
        let w5 = AppTheme.waterWeightSeg5
        let w6 = AppTheme.waterWeightSeg6
        
        // Calculate water sum for each segment:
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

// New data models for detailed daily water breakdown
struct DailyWaterDetail: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let segments: [WaterSegment]
    // Computed property that sums all segment totals for the day.
    var total: Double {
        segments.reduce(0) { $0 + $1.total }
    }
}

struct WaterSegment: Codable {
    let start: Date
    let end: Date
    let total: Double
}

// New extension that returns detailed daily totals for the last 5 days.
extension WaterIntakeManager {
    /// Returns an array of DailyWaterDetail for each of the last 5 days (including today),
    /// where each DailyWaterDetail contains hourly segments with the total water consumed in that hour.
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
            // Group each day's logs by hour (flooring to the start of the hour)
            let groupedByHour = Dictionary(grouping: dayLogs, by: {
                calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: $0.date))!
            })
            
            var segments: [WaterSegment] = []
            for (hour, hourLogs) in groupedByHour {
                let total = hourLogs.reduce(0) { $0 + $1.amount }
                let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hour) ?? hour
                segments.append(WaterSegment(start: hour, end: hourEnd, total: total))
            }
            // Sort segments by start time.
            segments.sort { $0.start < $1.start }
            details.append(DailyWaterDetail(date: day, segments: segments))
        }
        // Return sorted by day (oldest first)
        return details.sorted { $0.date < $1.date }
    }
}
