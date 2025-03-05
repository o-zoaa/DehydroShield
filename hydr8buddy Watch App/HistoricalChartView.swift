//
//  HistoricalChartView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI
import Charts  // watchOS 9+ for Chart APIs
import WatchKit

// Data model for combo chart (for water bars)
struct ComboDay: Identifiable {
    let id = UUID()
    let date: Date
    let water: Double   // ml
    let risk: Double    // (not used here)
}

struct HistoricalChartView: View {
    @EnvironmentObject var historyManager: DehydrationHistoryManager
    @EnvironmentObject var waterIntakeManager: WaterIntakeManager
    
    private let maxWater: Double = 3000.0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                if #available(watchOS 9.0, *) {
                    let waterBars = makeComboData()
                    // Use the daily average risk data from the manager.
                    let avgRiskData = historyManager.dailyAvgRiskLast5Days
                    
                    if waterBars.isEmpty && avgRiskData.isEmpty {
                        Text("No Data Available")
                            .foregroundColor(.white)
                    } else {
                        let yDomain: ClosedRange<Double> = 0...maxWater
                        let trailingTickValues = stride(from: 0, through: maxWater, by: maxWater / 5).map { $0 }
                        
                        Chart {
                            // Water Intake Bars (unchanged)
                            ForEach(waterBars) { day in
                                let displayedWater = min(day.water, maxWater)
                                BarMark(
                                    x: .value("Day", formattedWeekday(day.date)),
                                    y: .value("Water", displayedWater)
                                )
                                .foregroundStyle(
                                    day.water > maxWater
                                    ? Color.green.opacity(0.8)
                                    : Color.blue.opacity(0.8)
                                )
                            }
                            
                            // Average Risk Line (red) based on the manager’s computed daily average.
                            ForEach(avgRiskData, id: \.date) { stats in
                                let dayLabel = formattedWeekday(stats.date)
                                let scaledRisk = stats.avgRisk * maxWater
                                LineMark(
                                    x: .value("Day", dayLabel),
                                    y: .value("Scaled Risk", scaledRisk)
                                )
                                .foregroundStyle(Color.red)
                            }
                            
                            // Average Risk Points (red)
                            ForEach(avgRiskData, id: \.date) { stats in
                                let dayLabel = formattedWeekday(stats.date)
                                let scaledRisk = stats.avgRisk * maxWater
                                PointMark(
                                    x: .value("Day", dayLabel),
                                    y: .value("Scaled Risk", scaledRisk)
                                )
                                .foregroundStyle(Color.red)
                            }
                        }
                        .chartYScale(domain: yDomain)
                        .chartYAxis {
                            AxisMarks(position: .leading) {
                                AxisGridLine()
                                AxisValueLabel()
                            }
                            AxisMarks(position: .trailing, values: trailingTickValues) { val in
                                AxisGridLine()
                                AxisValueLabel {
                                    let fraction = (val.as(Double.self) ?? 0) / maxWater
                                    Text(String(format: "%.1f", fraction))
                                }
                            }
                        }
                        .frame(height: 100)
                    }
                } else {
                    Text("Charts require watchOS 9+")
                        .foregroundColor(.yellow)
                }
                
                // Legend below the chart.
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.8))
                            .frame(width: 12, height: 12)
                        Text("Water Intake (ml)")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        Text("Avg Dehydration Risk")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
            
            Spacer()
        }
        .padding(.top, AppTheme.chartTopPadding)
        .navigationTitle("Historical Charts")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
    
    // Merge water data into water bars (risk value is ignored here).
    private func makeComboData() -> [ComboDay] {
        let waterDays = last5DaysWater()
        return waterDays.map { (date, water) in
            ComboDay(date: date, water: water, risk: 0)
        }
        .sorted { $0.date < $1.date }
    }
    
    // Load water data for the last 5 days.
    private func last5DaysWater() -> [(date: Date, water: Double)] {
        let raw = waterIntakeManager.last5DaysDailyTotalsDetailed()
        return raw.map { day in
            let dayStart = Calendar.current.startOfDay(for: day.date)
            return (dayStart, day.total)
        }
    }
    
    // Helper: Format a date as an abbreviated weekday.
    private func formattedWeekday(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }
}

struct HistoricalChartView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoricalChartView()
                .environmentObject(DehydrationHistoryManager())
                .environmentObject(WaterIntakeManager())
        }
    }
}
