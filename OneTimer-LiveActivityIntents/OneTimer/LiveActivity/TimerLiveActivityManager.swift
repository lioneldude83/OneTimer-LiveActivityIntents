//
//  TimerLiveActivityManager.swift
//  OneTimer
//
//  Created by Lionel Ng on 20/5/25.
//

import Foundation
import ActivityKit

final class TimerLiveActivityManager {
    static let shared = TimerLiveActivityManager()
    
    // Since this is a single-timer model, just declare as single optional instance
    private var activity: Activity<TimerAttributes>?
    
    private init() {}
    
    func isLiveActivityActive(for uniqueID: String) -> Bool {
        return Activity<TimerAttributes>.activities.contains(where: {
            $0.attributes.uniqueID == uniqueID &&
            ($0.activityState == .active || $0.activityState == .stale)
        })
    }
    
    func restoreLiveActivity(for uniqueID: String) {
        if let existingActivity = Activity<TimerAttributes>.activities.first(where: {
            $0.attributes.uniqueID == uniqueID
        }) {
            self.activity = existingActivity
        }
    }
    
    func startLiveActivity(uniqueID: String, endTime: Date) {
        let attributes = TimerAttributes(uniqueID: uniqueID)
        let contentState = TimerAttributes.ContentState(endTime: endTime, isPaused: false, adjustedRemainingTime: nil)
        let staleDate = endTime.addingTimeInterval(10)
        
        Task { @MainActor in
            do {
                let activity = try Activity<TimerAttributes>.request(
                    attributes: attributes,
                    content: ActivityContent(state: contentState, staleDate: staleDate),
                    pushType: nil
                )
                self.activity = activity
            } catch {
                print("Failed to start Live Activity: \(error)")
            }
        }
    }
    
    func pauseLiveActivity(uniqueID: String) {
        guard let activity = self.activity else { return }
        
        let remaining: TimeInterval
        if let endTime = activity.content.state.endTime {
            remaining = max(endTime.timeIntervalSinceNow, 0)
        } else {
            remaining = activity.content.state.adjustedRemainingTime ?? 0
        }
        
        let pausedState = TimerAttributes.ContentState(
            endTime: nil,
            isPaused: true,
            adjustedRemainingTime: remaining
        )
        
        Task {
            await activity.update(ActivityContent(state: pausedState, staleDate: nil))
        }
    }
    
    func resumeLiveActivity(uniqueID: String, endTime: Date) {
        guard let activity = self.activity else { return }
        
        let resumedState = TimerAttributes.ContentState(
            endTime: endTime,
            isPaused: false,
            adjustedRemainingTime: nil
        )
        
        Task {
            await activity.update(ActivityContent(state: resumedState, staleDate: nil))
        }
    }
    
    func startPausedLiveActivity(uniqueID: String, duration: TimeInterval) {
        let isActive = Activity<TimerAttributes>.activities.contains(where: {
            $0.attributes.uniqueID == uniqueID &&
            ($0.activityState == .active || $0.activityState == .stale)
        })
        
        guard !isActive else {
            print("Live Activity already active for \(uniqueID), skipping start.")
            return
        }
        
        let attributes = TimerAttributes(uniqueID: uniqueID)
        let contentState = TimerAttributes.ContentState(
            endTime: nil,
            isPaused: true,
            adjustedRemainingTime: duration
        )
        
        let content = ActivityContent(state: contentState, staleDate: nil)
        
        do {
            let activity = try Activity<TimerAttributes>.request(
                attributes: attributes,
                content: content
            )
            self.activity = activity
            print("Live Activity started in paused state for \(uniqueID)")
        } catch {
            print("Error starting paused Live Activity: \(error)")
        }
    }
    
    func completeLiveActivity(uniqueID: String) {
        guard let activity = self.activity else { return }
        
        let completedState = TimerAttributes.ContentState(
            endTime: nil,
            isPaused: false,
            adjustedRemainingTime: 0
        )
        
        Task {
            let staleDate = Calendar.current.date(byAdding: .second, value: 8, to: Date())
            await activity.update(ActivityContent(state: completedState, staleDate: staleDate))
        }
    }
    
    func endLiveActivity(uniqueID: String) {
        guard let activity = self.activity else { return }
        
        // Start an @MainActor Task because dictionary access needs to be on the main actor
        Task { @MainActor in
            await activity.end(nil, dismissalPolicy: .immediate)
            
            if activity.attributes.uniqueID == uniqueID {
                self.activity = nil // Set to nil if it matches uniqueID
            }
        }
    }
}
