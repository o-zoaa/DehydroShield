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
    
    /// Schedules a debug water reminder notification with a given reason,
    /// using a delay (e.g. 10 seconds) so that the notification appears after the app is backgrounded.
    func scheduleDebugWaterReminder(reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder (Debug)"
        content.body = reason
        content.categoryIdentifier = "WATER_LOG_CATEGORY"
        content.sound = .default

        // For debug simulation, trigger after 10 seconds.
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
    
    /// Request authorization for notifications.
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if granted {
                print("Notification authorization granted.")
                self.setupNotificationCategories()
            } else {
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                } else {
                    print("Notification authorization denied.")
                }
            }
        }
    }
    
    /// Set up the notification category and actions using the same water options as WaterIntakeView.
    func setupNotificationCategories() {
        // Dynamically create actions from the waterOptions array in AppTheme.
        var actions: [UNNotificationAction] = []
        for amount in AppTheme.waterOptions {
            let identifier = "LOG_\(amount)"
            let title = "\(amount) ml"
            let action = UNNotificationAction(identifier: identifier, title: title, options: [])
            actions.append(action)
        }
        
        // Create a notification category that uses these actions.
        let category = UNNotificationCategory(identifier: "WATER_LOG_CATEGORY",
                                              actions: actions,
                                              intentIdentifiers: [],
                                              options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("Notification categories set up with actions: \(actions.map { $0.title })")
    }
    
    /// Schedules a water reminder notification with a given reason.
    func scheduleWaterReminder(reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder"
        content.body = reason
        content.categoryIdentifier = "WATER_LOG_CATEGORY"
        content.sound = .default
        
        // For demonstration, trigger after 1 second.
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
    
    /// Schedules a repeating water inactivity notification that fires every half the normal time.
    /// If the computed delay is less than 60 seconds (the system minimum), it uses 60 seconds.
    /// This will continue until water is logged and cancelWaterInactivityNotification() is called.
    func scheduleWaterInactivityNotification(withDelay delay: TimeInterval? = nil) {
        // Calculate half of the normal inactivity threshold.
        var delayTime = delay ?? (AppTheme.waterInactivityThreshold / 2)
        // Enforce a minimum of 60 seconds for repeating notifications.
        if delayTime < 60 {
            delayTime = 60
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder"
        content.body = "You haven't logged water consumption in a while. Please log your water intake."
        content.categoryIdentifier = "WATER_LOG_CATEGORY"
        content.sound = .default
        
        // Create a repeating trigger.
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
    
    /// Called when the user responds to a notification action.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // If the action identifier starts with "LOG_", log water accordingly.
        if response.actionIdentifier.hasPrefix("LOG_") {
            let amountString = response.actionIdentifier.replacingOccurrences(of: "LOG_", with: "")
            if let amount = Int(amountString) {
                NotificationCenter.default.post(name: .didLogWater, object: amount)
                print("User selected to log \(amount) ml of water.")
            }
        }
        else {
            // For other cases (dismissal or default tap), just log the event.
            switch response.actionIdentifier {
            case UNNotificationDismissActionIdentifier:
                print("Notification dismissed.")
                // Here we do not reschedule a new notification because the repeating trigger will continue.
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
    /// Post this notification when a water log action is triggered.
    static let didLogWater = Notification.Name("didLogWater")
}

