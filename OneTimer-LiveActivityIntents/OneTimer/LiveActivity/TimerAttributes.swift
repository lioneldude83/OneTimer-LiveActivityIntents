//
//  TimerAttributes.swift
//  OneTimer
//
//  Created by Lionel Ng on 20/5/25.
//

import Foundation
import ActivityKit

struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endTime: Date?
        var isPaused: Bool
        var adjustedRemainingTime: TimeInterval?
        var totalDuration: TimeInterval
    }
    
    var uniqueID: String
}
