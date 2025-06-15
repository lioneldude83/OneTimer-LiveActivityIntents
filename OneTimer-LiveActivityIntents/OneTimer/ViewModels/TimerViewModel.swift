//
//  TimerViewModel.swift
//  OneTimer
//
//  Created by Lionel Ng on 19/5/25.
//

import Foundation
import Combine
import SwiftData
import UIKit

@Observable
class TimerViewModel {
    var timer: TimerState
    var context: ModelContext?
    
    private var cancellable: AnyCancellable?
    
    init(timer: TimerState, context: ModelContext? = nil) {
        assert(timer.uniqueID == "singleTimer")
        self.timer = timer
        self.context = context
    }
    
    var selectedSound: Sound {
        Sound(rawValue: timer.sound ?? "") ?? .chord
    }
    
    var suppressSound = false
    
    var duration: TimeInterval {
        timer.duration
    }
    
    var remainingTime: TimeInterval {
        timer.remainingTime
    }
    
    var endTime: Date? {
        timer.endTime
    }
    
    var isPaused: Bool {
        timer.isPaused
    }
    
    var progress: Double {
        timer.progress
    }
    
    func setDuration(_ duration: TimeInterval, sound: Sound) {
        // Only set duration if timer is not running
        guard timer.isPaused else { return }
        timer.duration = duration
        timer.remainingTime = duration
        timer.sound = sound.rawValue
        
        // If Live Activity is active when setting duration, end it first
        if TimerLiveActivityManager.shared.isLiveActivityActive(for: timer.uniqueID) {
            TimerLiveActivityManager.shared.endLiveActivity(uniqueID: timer.uniqueID)
        }
        
        // Save changes to context
        try? context?.save()
    }
    
    func setSound(sound: Sound) {
        timer.sound = sound.rawValue
        try? context?.save()
    }
    
    @MainActor
    func update(with model: TimerState) {
        guard let context else {
            print("ViewModel update: Context not found!")
            return
        }
        print("ViewModel update: Fetching model uniqueID: \(model.uniqueID)")
        // Force context to discard its in-memory cache
        context.rollback()
        
        // Fetch updated timer state (source of truth)
        let descriptor = FetchDescriptor<TimerState>(predicate: #Predicate { $0.uniqueID == "singleTimer" })
        if let storedTimer = try? context.fetch(descriptor).first {
            self.timer = storedTimer
        }
        
        if !self.timer.isPaused {
            // Timer is running
            if cancellable == nil {
                let timeLeft = self.timer.endTime?.timeIntervalSinceNow ?? self.timer.remainingTime
                
                if timeLeft > 0 {
                    self.timer.remainingTime = timeLeft // Update remaining time for the UI display
                    startCountdown()
                    print("ViewModel update: Started countdown")
                    
                    // Restore running Live Activity if none found
                    if !TimerLiveActivityManager.shared.isLiveActivityActive(for: timer.uniqueID) {
                        if let endTime = timer.endTime {
                            TimerLiveActivityManager.shared.startLiveActivity(uniqueID: timer.uniqueID, endTime: endTime, duration: timer.duration)
                            print("ViewModel updated: Recreated running Live Activity with remaining time \(timeLeft)")
                        } else {
                            print("Warning: Attempted to start Live Activity for a timer without an end time")
                        }
                    }
                } else {
                    suppressSound = true // Suppress sound for expired timer
                    Task { @MainActor in
                        // Call timer did finish
                        self.timerDidFinish()
                        print("Time left \(timeLeft), called timerDidFinish")
                    }
                }
            } else {
                print("ViewModel update: Timer is already running internally.")
            }
        } else {
            // Timer is paused
            // Ensure internal Combine timer is stopped
            if cancellable != nil {
                cancellable?.cancel()
                cancellable = nil
                print("ViewModel update: Stopped internal timer")
            } else {
                print("ViewModel update: Internal timer is already stopped internally.")
            }
            
            // If model has no time left, ensure finish is applied
            if self.timer.remainingTime <= 0 {
                suppressSound = true // Suppress sound for expired timer
                Task { @MainActor in
                    self.timerDidFinish()
                    print("Timer expired with remaining time \(self.remainingTime)")
                }
            } else if self.timer.remainingTime != self.timer.duration { // Check for reset state
                // Restore paused Live Activity if none found
                if !TimerLiveActivityManager.shared.isLiveActivityActive(for: timer.uniqueID) {
                    TimerLiveActivityManager.shared.startPausedLiveActivity(uniqueID: timer.uniqueID, remainingDuration: self.timer.remainingTime, totalDuration: self.timer.duration)
                    print("ViewModel update: Recreated paused Live Activity with remaining time \(timer.remainingTime)")
                }
            }
        }
    }
    
    
    @MainActor
    func start() {
        guard timer.isPaused else { return }
        timer.startTime = Date()
        // Since remainingTime is set in setDuration, check if remainingTime is same as duration
        if timer.remainingTime == timer.duration {
            // Start timer from fresh
            timer.endTime = Date().addingTimeInterval(timer.duration)
            
            guard let endTime = timer.endTime else { return }
            let duration = timer.duration
            
            // Start Live Activity
            TimerLiveActivityManager.shared.startLiveActivity(uniqueID: timer.uniqueID, endTime: endTime, duration: duration)
            
        } else {
            // Resume timer
            timer.endTime = Date().addingTimeInterval(timer.remainingTime)
            
            guard let endTime = timer.endTime else { return }
            let duration = timer.duration
            
            // Resume Live Activity
            TimerLiveActivityManager.shared.resumeLiveActivity(uniqueID: timer.uniqueID, endTime: endTime, duration: duration)
        }
        timer.isPaused = false
        
        // Start Countdown
        startCountdown()
        
        // Check interval greater than 0 before scheduling notification
        if let interval = timer.endTime?.timeIntervalSinceNow, interval > 0 {
            // Schedule Notification
            NotificationManager.shared.scheduleNotification(
                id: timer.uniqueID,
                title: "One Timer",
                timeInterval: interval,
                sound: "\(selectedSound.rawValue).wav"
            )
        } else {
            print("Skipped scheduling notification, interval less than or equal to zero")
        }
        
        try? context?.save()
        print("ViewModel: Started timer for \(timer.duration) seconds, endTime \(String(describing: timer.endTime))")
        
    }
    
    @MainActor
    func pause() {
        guard !timer.isPaused else { return }
        timer.isPaused = true
        timer.remainingTime = timer.endTime?.timeIntervalSinceNow ?? timer.remainingTime
        timer.endTime = nil
        
        // Cancel Timer
        cancellable?.cancel()
        cancellable = nil
        // Cancel Notification
        NotificationManager.shared.cancelNotification(id: timer.uniqueID)
        try? context?.save()
        print("ViewModel: Paused timer, remaining time: \(timer.remainingTime) seconds")
        
        // Pause Live Activity
        TimerLiveActivityManager.shared.pauseLiveActivity(uniqueID: timer.uniqueID)
    }
    
    @MainActor
    func reset() {
        guard timer.remainingTime != timer.duration else { return }
        timer.isPaused = true
        timer.remainingTime = timer.duration // Reset duration
        timer.endTime = nil // Clear end time
        timer.startTime = nil // Clear start time
        
        // Cancel Timer
        cancellable?.cancel()
        cancellable = nil
        // Cancel Notification
        NotificationManager.shared.cancelNotification(id: timer.uniqueID)
        try? context?.save()
        print("ViewModel: Reset timer, duration restored to \(timer.duration) seconds")
        
        // End Live Activity for Reset
        TimerLiveActivityManager.shared.endLiveActivity(uniqueID: timer.uniqueID)
    }
    
    private func startCountdown() {
        cancellable?.cancel()
        cancellable = Timer
            .publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tick()
            }
    }
    
    private func tick() {
        // Ensure timer is actively running, end time is not nil, else cancel the Combine timer
        guard !timer.isPaused, let endTime = timer.endTime else {
            cancellable?.cancel()
            cancellable = nil
            return
        }
        
        let timeLeft = endTime.timeIntervalSinceNow
        
        if timeLeft <= 0 {
            // Timer finished
            timer.remainingTime = 0
            print("ViewModel: Timer ended")
            
            Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(nanoseconds: 250_000_000)
                } catch {
                    print("Task sleep cancelled \(error)")
                    return
                }
                
                if self?.timer.isPaused == false {
                    print("ViewModel: Tick completed, calling timerDidFinish")
                    self?.timerDidFinish()
                }
            }
        } else {
            timer.remainingTime = timeLeft
        }
    }
    
    private func timerDidFinish() {
        timer.isPaused = true
        timer.endTime = nil
        timer.startTime = nil
        cancellable?.cancel()
        cancellable = nil
        
        let state = UIApplication.shared.applicationState
        if !suppressSound, state == .active || state == .inactive {
            SoundManager.shared.play(selectedSound)
        }
        
        timer.remainingTime = timer.duration // Reset duration
        suppressSound = false // Reset suppressSound to false
        print("ViewModel: Timer did finish, resetting timer to \(timer.duration)")
        try? context?.save()
        
        // Show "Timer Done" in Live Activity
        TimerLiveActivityManager.shared.completeLiveActivity(uniqueID: timer.uniqueID)
        
        Task {
            // Delay 1 second before ending Live Activity
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            TimerLiveActivityManager.shared.endLiveActivity(uniqueID: timer.uniqueID)
        }
    }
}
