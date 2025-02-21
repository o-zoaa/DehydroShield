//
//  WeeklyRiskView.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import SwiftUI
import Charts  // Requires watchOS 9+

struct WeeklyRiskView: View {
    @EnvironmentObject var historyManager: DehydrationHistoryManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("7-Day Dehydration Risk")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if #available(watchOS 9.0, *) {
                    chartContent
                        .frame(height: 120)
                } else {
                    Text("Charts require watchOS 9+")
                        .foregroundColor(.yellow)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var chartContent: some View {
        let last7Days = loadLast7Days()
        if last7Days.isEmpty {
            Text("No Data Available")
                .foregroundColor(.white)
        } else {
            Chart(last7Days) { entry in
                BarMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Risk", entry.risk)
                )
                .foregroundStyle(riskColor(for: entry.risk))
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 0.5, 1.0]) {
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: last7Days.map { $0.date }) { date in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
        }
    }
    
    private func loadLast7Days() -> [DailyRiskEntry] {
        let cutOff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return historyManager.dailyEntries
            .filter { $0.date >= Calendar.current.startOfDay(for: cutOff) }
            .sorted(by: { $0.date < $1.date })
    }
    
    private func riskColor(for risk: Double) -> Color {
        switch risk {
        case 0..<0.5:
            return .green
        case 0.5..<0.8:
            return .yellow
        default:
            return .red
        }
    }
}

struct WeeklyRiskView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyRiskView()
            .environmentObject(DehydrationHistoryManager())
    }
}
