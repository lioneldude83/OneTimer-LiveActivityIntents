//
//  TimerIntents.swift
//  OneTimerWidgetExtension
//
//  Created by Lionel Ng on 21/5/25.
//

import AppIntents
import ActivityKit
import SwiftData
import UserNotifications

struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    
    init() {}
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let uniqueID = "singleTimer"
        
        let schema = Schema([TimerState.self])
        let modelConfiguration = ModelConfiguration(schema: schema, allowsSave: true)
        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            print("Pause Timer Intent: Fail to load model container")
            throw TimerIntentsError.modelContainerLoadingFailed
        }
        
        let context = ModelContext(container)
        let predicate = #Predicate<TimerState> { $0.uniqueID == uniqueID }
        let descriptor = FetchDescriptor<TimerState>(predicate: predicate)
        
        guard let timer = try context.fetch(descriptor).first else {
            print("Pause Timer Intent: No timer found")
            throw TimerIntentsError.timerNotFound
        }
        
        guard !timer.isPaused else {
            print("Pause Timer Intent: Timer is already paused")
            throw TimerIntentsError.timerWrongMode
        }
        
        let pauseTime = Date()
        timer.isPaused = true
        timer.remainingTime = timer.endTime?.timeIntervalSince(pauseTime) ?? timer.remainingTime
        timer.endTime = nil
        
        // Cancel notification when paused
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [uniqueID])
        
        try context.save()
        
        // Pause Live Activity
        TimerLiveActivityManager.shared.pauseLiveActivity(uniqueID: uniqueID)
        print("Pause Timer Intent: Live Activity paused")
        
        // Post notification for "OneTimerIntentsNotify"
        NotificationCenter.default.post(name: NSNotification.Name("OneTimerIntentsNotify"), object: nil)
        
        return .result()
    }
}

struct ResumeTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    
    init() {}
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let uniqueID = "singleTimer"
        
        let schema = Schema([TimerState.self])
        let modelConfiguration = ModelConfiguration(schema: schema, allowsSave: true)
        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            print("Resume Timer Intent: Fail to load model container")
            throw TimerIntentsError.modelContainerLoadingFailed
        }
        
        let context = ModelContext(container)
        let predicate = #Predicate<TimerState> { $0.uniqueID == uniqueID }
        let descriptor = FetchDescriptor<TimerState>(predicate: predicate)
        
        guard let timer = try context.fetch(descriptor).first else {
            print("Resume Timer Intent: No timer found")
            throw TimerIntentsError.timerNotFound
        }
        
        guard timer.isPaused else {
            print("Resume Timer Intent: Timer is already running")
            throw TimerIntentsError.timerWrongMode
        }
        
        let resumeTime = Date()
        timer.isPaused = false
        timer.endTime = resumeTime.addingTimeInterval(timer.remainingTime)
        
        guard let endTime = timer.endTime else {
            print("Resume Timer Intent: End Time is nil")
            throw TimerIntentsError.timerEndTimeNil
        }
        
        // Reconstruct sound file name with the extension
        let soundFileName: String?
        if let soundRawValue = timer.sound, !soundRawValue.isEmpty {
            soundFileName = "\(soundRawValue).wav"
        } else {
            soundFileName = nil
        }
        
        // Reschedule notification when resumed
        if let interval = timer.endTime?.timeIntervalSinceNow, interval > 0 {
            // Schedule Notification
            NotificationManager.shared.scheduleNotification(
                id: timer.uniqueID,
                title: "One Timer",
                timeInterval: interval,
                sound: soundFileName
            )
        } else {
            print("Skipped scheduling notification, interval less than or equal to zero")
        }
        
        try context.save()
        
        // Resume Live Activity
        TimerLiveActivityManager.shared.resumeLiveActivity(uniqueID: timer.uniqueID, endTime: endTime, duration: timer.duration)
        print("Resume Timer Intent: Live Activity resumed")
        
        // Post notification for "OneTimerIntentsNotify"
        NotificationCenter.default.post(name: NSNotification.Name("OneTimerIntentsNotify"), object: nil)
        
        return .result()
    }
}

struct CancelTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Cancel Timer"
    
    init() {}
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let uniqueID = "singleTimer"
        
        let schema = Schema([TimerState.self])
        let modelConfiguration = ModelConfiguration(schema: schema, allowsSave: true)
        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            print("Cancel Timer Intent: Fail to load model container")
            throw TimerIntentsError.modelContainerLoadingFailed
        }
        
        let context = ModelContext(container)
        let predicate = #Predicate<TimerState> { $0.uniqueID == uniqueID }
        let descriptor = FetchDescriptor<TimerState>(predicate: predicate)
        
        guard let timer = try context.fetch(descriptor).first else {
            print("Cancel Timer Intent: No timer found")
            throw TimerIntentsError.timerNotFound
        }
        
        guard timer.remainingTime != timer.duration else {
            print("Cancel Timer Intent: Timer already reset")
            throw TimerIntentsError.timerAlreadyReset
        }
        
        timer.isPaused = true
        timer.remainingTime = timer.duration // Reset duration
        timer.endTime = nil
        timer.startTime = nil
        
        // Cancel Notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [uniqueID])
        
        try context.save()
        
        // End Live Activity
        TimerLiveActivityManager.shared.endLiveActivity(uniqueID: timer.uniqueID)
        print("Cancel Timer Intent: Live Activity cancelled")
        
        // Post notification for "OneTimerIntentsNotify"
        NotificationCenter.default.post(name: NSNotification.Name("OneTimerIntentsNotify"), object: nil)
        
        return .result()
    }
}
