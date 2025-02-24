import SwiftUI

@main
struct Hydr8BuddyApp: App {
    @StateObject private var healthDataManager = HealthDataManager()
    @StateObject private var historyManager = DehydrationHistoryManager()
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var waterIntakeManager = WaterIntakeManager()
    @StateObject private var debugSettings = DebugSettings() // Added DebugSettings
    
    var body: some Scene {
        WindowGroup {
            if profileManager.profile == nil {
                OnboardingView()
                    .environmentObject(profileManager)
                    .environmentObject(debugSettings) // Inject DebugSettings here
                    .background(Color.black)
                    .onAppear {
                        healthDataManager.requestAuthorization()
                        NotificationManager.shared.requestAuthorization()
                    }
            } else {
                ContentView()
                    .environmentObject(healthDataManager)
                    .environmentObject(historyManager)
                    .environmentObject(profileManager)
                    .environmentObject(waterIntakeManager)
                    .environmentObject(debugSettings) // Inject DebugSettings here
                    .onAppear {
                        healthDataManager.requestAuthorization()
                        NotificationManager.shared.requestAuthorization()
                    }
            }
        }
    }
}
