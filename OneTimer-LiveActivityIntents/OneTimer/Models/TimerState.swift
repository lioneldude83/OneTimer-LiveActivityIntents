//
//  Timer.swift
//  OneTimer
//
//  Created by Lionel Ng on 19/5/25.
//

import Foundation
import SwiftData

@Model
class TimerState: Identifiable {
    var duration: TimeInterval
    var remainingTime: TimeInterval
    var startTime: Date?
    var endTime: Date?
    var isPaused: Bool = true
    var uniqueID: String
    var sound: String?
    
    var progress: Double {
        guard duration > 0 else {
            return 0
        }
        return 1 - (remainingTime / duration)
    }
    
    init(
        duration: TimeInterval,
        remainingTime: TimeInterval,
        startTime: Date? = nil,
        endTime: Date? = nil,
        isPaused: Bool,
        uniqueID: String = "singleTimer",
        sound: String? = nil
    ) {
        self.duration = duration
        self.remainingTime = remainingTime
        self.startTime = startTime
        self.endTime = endTime
        self.isPaused = isPaused
        self.uniqueID = uniqueID
        self.sound = sound
    }
}
