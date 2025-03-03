//
//  NotificationManager.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 02/22/2025.
//

import Foundation
import UserNotifications
import SwiftUI

/// NotificationManager is a singleton that handles notification setup, scheduling, and action responses.
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        // Set ourselves as the UNUserNotificationCenter delegate.
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// Requests notification authorization from the user.
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            } else {
                print("Notification authorization granted: \(granted)")
            }
        }
    }
    
    /// Schedules a debug water reminder notification with a given reason,
    /// using a delay (e.g. 10 seconds) so that the notification appears after the app is backgrounded.
    func scheduleDebugWaterReminder(reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder (Debug)"
        content.body = reason
        content.categoryIdentifier = "WATER_LOG_CATEGORY"
        content.sound = .default

        // Post pre-notification event.
        NotificationCenter.default.post(name: .waterReminderScheduled, object: nil)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling debug water reminder: \(error.localizedDescription)")
            } else {
                print("Debug water reminder scheduled with reason: \(reason)")
            }
        }
    }
    
    /// Schedules a water reminder notification with a given reason.
    func scheduleWaterReminder(reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder"
        content.body = reason
        content.categoryIdentifier = "WATER_LOG_CATEGORY"
        content.sound = .default
        
        // Post pre-notification event.
        NotificationCenter.default.post(name: .waterReminderScheduled, object: nil)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling water reminder: \(error.localizedDescription)")
            } else {
                print("Water reminder scheduled with reason: \(reason)")
            }
        }
    }
    
    /// Schedules a repeating water inactivity notification.
    func scheduleWaterInactivityNotification(withDelay delay: TimeInterval? = nil) {
        var delayTime = delay ?? (AppTheme.waterInactivityThreshold / 2)
        if delayTime < 60 { delayTime = 60 }
        
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder"
        content.body = "You haven't logged water consumption in a while. Please log your water intake."
        content.categoryIdentifier = "WATER_LOG_CATEGORY"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delayTime, repeats: true)
        let request = UNNotificationRequest(identifier: "WATER_INACTIVITY_NOTIFICATION", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling water inactivity notification: \(error.localizedDescription)")
            } else {
                print("Repeating water inactivity notification scheduled to fire every \(delayTime) seconds.")
            }
        }
    }
    
    /// Cancels any pending water inactivity notification.
    func cancelWaterInactivityNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["WATER_INACTIVITY_NOTIFICATION"])
        print("Water inactivity notification cancelled.")
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier.hasPrefix("LOG_") {
            let amountString = response.actionIdentifier.replacingOccurrences(of: "LOG_", with: "")
            if let amount = Int(amountString) {
                NotificationCenter.default.post(name: .didLogWater, object: amount)
                print("User selected to log \(amount) ml of water.")
            }
        } else {
            switch response.actionIdentifier {
            case UNNotificationDismissActionIdentifier:
                print("Notification dismissed.")
            case UNNotificationDefaultActionIdentifier:
                print("Default notification tapped.")
            default:
                break
            }
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let didLogWater = Notification.Name("didLogWater")
    static let waterReminderScheduled = Notification.Name("waterReminderScheduled")
    static let waterLogged = Notification.Name("waterLogged")
    // 'healthDataUpdated' is declared in HealthDataManager.swift.
}
