//
//  NotificationManager.swift
//  OneTimer
//
//  Created by Lionel Ng on 20/5/25.
//

import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    func scheduleNotification(id: String, title: String, timeInterval: TimeInterval, sound: String?) {
        let content = UNMutableNotificationContent()
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        content.title = title
        content.body = "Timer finished!"
        if let sound = sound {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
        } else {
            content.sound = .default
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
