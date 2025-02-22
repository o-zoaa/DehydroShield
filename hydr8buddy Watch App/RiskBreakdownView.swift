import SwiftUI

struct RiskBreakdownView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var waterIntakeManager: WaterIntakeManager
    @EnvironmentObject var profileManager: ProfileManager

    @State private var animateGraph: Bool = false

    var body: some View {
        // Compute data from environment objects
        let liveHR = healthDataManager.heartRate ?? 60.0
        let liveSteps = Double(healthDataManager.stepCount ?? 0)
        let liveAE = healthDataManager.activeEnergy ?? 0.0
        let liveEX = healthDataManager.exerciseTime ?? 0.0
        let liveDist = Double(healthDataManager.distance ?? 0)
        let liveWater = waterIntakeManager.weightedWaterIntakeLast5Days
        let recommendedWater = computeRecommendedWater(profile: profileManager.profile) * 5
        
        let waterDeficit = 1 - min(liveWater / recommendedWater, 1.0)
        let normSteps = min(liveSteps / 10000.0, 1.0)
        let normDistance = min(liveDist / 5000.0, 1.0)
        let normActiveEnergy = min(liveAE / 500.0, 1.0)
        let normExerciseTime = min(liveEX / 30.0, 1.0)
        let activityIndex = (normSteps + normDistance + normActiveEnergy + normExerciseTime) / 4.0
        let HR_index = min(max((liveHR - 60.0) / (180.0 - 60.0), 0.0), 1.0)
        let bodyTemperature = 37.0
        let delta = 0.0
        
        let overallRisk = computeHybridDehydrationRisk(
            waterIntake: liveWater,
            recommendedWater: recommendedWater,
            activityIndex: activityIndex,
            HR_index: HR_index,
            bodyTemperature: bodyTemperature,
            delta: delta
        )
        
        let waterContribution = overallRisk > 0 ? (AppTheme.W_water * waterDeficit) / overallRisk : 0.0
        let activityContribution = overallRisk > 0 ? (AppTheme.W_activity * activityIndex) / overallRisk : 0.0
        let hrContribution = overallRisk > 0 ? (AppTheme.W_hr * HR_index) / overallRisk : 0.0
        let deltaContribution = overallRisk > 0 ? (AppTheme.W_delta * delta) / overallRisk : 0.0
        
        ZStack {
            // Full-screen gradient background (black)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 0) {
                    // Custom Header: Right-aligned using ring color from overallRisk
                    Text("Risk Breakdown")
                        .font(.system(
                            size: AppTheme.customHeaderFontSize,
                            weight: AppTheme.customHeaderFontWeight
                        ))
                        .foregroundColor(AppTheme.ringColor(for: overallRisk))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .offset(y: AppTheme.customHeaderOffsetY)
                        .padding(.bottom, 4)
                    
                    // Bar Graph: Using HStack with animated widths
                    GeometryReader { geometry in
                        let barWidth = geometry.size.width - (AppTheme.barHorizontalInset * 2)
                        
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: animateGraph ? barWidth * CGFloat(waterContribution) : 0,
                                       height: AppTheme.barHeight)
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: animateGraph ? barWidth * CGFloat(activityContribution) : 0,
                                       height: AppTheme.barHeight)
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: animateGraph ? barWidth * CGFloat(hrContribution) : 0,
                                       height: AppTheme.barHeight)
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: animateGraph ? barWidth * CGFloat(deltaContribution) : 0,
                                       height: AppTheme.barHeight)
                        }
                        .cornerRadius(0)
                        .frame(width: barWidth, height: AppTheme.barHeight)
                        .padding(.top, AppTheme.barTopPadding + AppTheme.graphVerticalOffset)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: AppTheme.barHeight + AppTheme.barTopPadding + AppTheme.graphVerticalOffset + 10)
                    .animation(AppTheme.barAnimation, value: animateGraph)
                    
                    // Data Cards Row 1: Water & Activity
                    HStack(spacing: 6) {
                        DataCard(
                            iconName: "drop.fill",
                            label: "Water",
                            value: "\(Int(waterContribution * 100))%",
                            cardColor: .blue
                        )
                        DataCard(
                            iconName: "figure.walk",
                            label: "Activity",
                            value: "\(Int(activityContribution * 100))%",
                            cardColor: .orange
                        )
                    }
                    .padding(.top, 8)
                    
                    // Data Cards Row 2: Heart & Change (conditionally)
                    if deltaContribution == 0 {
                        HStack {
                            DataCard(
                                iconName: "heart.fill",
                                label: "Heart",
                                value: "\(Int(hrContribution * 100))%",
                                cardColor: .red
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 6)
                    } else {
                        HStack(spacing: 6) {
                            DataCard(
                                iconName: "heart.fill",
                                label: "Heart",
                                value: "\(Int(hrContribution * 100))%",
                                cardColor: .red
                            )
                            DataCard(
                                iconName: "arrow.up.arrow.down",
                                label: "Change",
                                value: "\(Int(deltaContribution * 100))%",
                                cardColor: .gray
                            )
                        }
                        .padding(.top, 6)
                    }
                    
                    Spacer()
                }
                .navigationBarHidden(true)
                .onAppear {
                    withAnimation(AppTheme.barAnimation) {
                        animateGraph = true
                    }
                }
            }
        }
    }
}

struct RiskBreakdownView_Previews: PreviewProvider {
    static var previews: some View {
        RiskBreakdownView()
            .environmentObject(HealthDataManager())
            .environmentObject(WaterIntakeManager())
            .environmentObject(ProfileManager())
    }
}
