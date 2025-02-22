//
//  HistoricalChartView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI
import Charts  // watchOS 9+ for Chart APIs
import WatchKit

// Data model for combo chart
struct ComboDay: Identifiable {
    let id = UUID()
    let date: Date
    let water: Double   // ml
    let risk: Double    // 0..1
}

struct HistoricalChartView: View {
    @EnvironmentObject var historyManager: DehydrationHistoryManager
    @EnvironmentObject var waterIntakeManager: WaterIntakeManager
    
    private let maxWater: Double = 3000.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Combo Chart: Bars for water and line for risk.
                if #available(watchOS 9.0, *) {
                    let comboData = makeComboData()
                    
                    if comboData.isEmpty {
                        Text("No Data Available")
                            .foregroundColor(.white)
                    } else {
                        let yDomain: ClosedRange<Double> = 0...maxWater
                        let trailingTickValues = stride(from: 0, through: maxWater, by: maxWater / 5).map { $0 }
                        
                        Chart {
                            // Bars for water intake
                            ForEach(comboData) { day in
                                BarMark(
                                    x: .value("Day", formattedWeekday(day.date)),
                                    y: .value("Water", day.water)
                                )
                                .foregroundStyle(Color.blue.opacity(0.8))
                            }
                            
                            // Line and points for scaled risk
                            ForEach(comboData) { day in
                                let scaledRisk = day.risk * maxWater
                                LineMark(
                                    x: .value("Day", formattedWeekday(day.date)),
                                    y: .value("Scaled Risk", scaledRisk)
                                )
                                .foregroundStyle(Color.red)
                                
                                PointMark(
                                    x: .value("Day", formattedWeekday(day.date)),
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
                
                // Legend moved below the chart.
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
                        Text("Dehydration Risk")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Historical Charts")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
    
    // Merge water and risk data into a single combo array.
    private func makeComboData() -> [ComboDay] {
        let waterDays = last5DaysWater()
        let riskDays = last5DaysRisk()
        
        let allDates = Set(waterDays.map { $0.date } + riskDays.map { $0.date })
        
        var combo: [ComboDay] = []
        for d in allDates {
            let wVal = waterDays.first(where: { $0.date == d })?.water ?? 0
            let rVal = riskDays.first(where: { $0.date == d })?.risk ?? 0
            combo.append(ComboDay(date: d, water: wVal, risk: rVal))
        }
        return combo.sorted { $0.date < $1.date }
    }
    
    // Example water loader using detailed 5-day totals.
    private func last5DaysWater() -> [(date: Date, water: Double)] {
        let raw = waterIntakeManager.last5DaysDailyTotalsDetailed()
        return raw.map { day in
            let dayStart = Calendar.current.startOfDay(for: day.date)
            return (dayStart, day.total)
        }
    }
    
    // Example risk loader.
    private func last5DaysRisk() -> [(date: Date, risk: Double)] {
        let calendar = Calendar.current
        let now = Date()
        guard let cutoff = calendar.date(byAdding: .day, value: -4, to: now) else { return [] }
        
        let raw = historyManager.dailyEntries
            .filter { $0.date >= calendar.startOfDay(for: cutoff) }
            .sorted { $0.date < $1.date }
        
        return raw.map { entry in
            let dayStart = Calendar.current.startOfDay(for: entry.date)
            return (dayStart, entry.risk)
        }
    }
    
    // Helper function to format a date as an abbreviated weekday.
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
