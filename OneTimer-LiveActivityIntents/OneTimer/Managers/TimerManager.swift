//
//  TimerManager.swift
//  OneTimer
//
//  Created by Lionel Ng on 19/5/25.
//

import Foundation
import SwiftData

final class TimerManager {
    static let shared = TimerManager()
    
    private init() {}
    
    func loadOrCreateTimer(in context: ModelContext) -> TimerState {
        let descriptor = FetchDescriptor<TimerState>(predicate: #Predicate { $0.uniqueID == "singleTimer" })
        if let timer = try? context.fetch(descriptor).first {
            return timer
        } else {
            let newTimer = TimerState(duration: 60, remainingTime: 60, isPaused: true)
            context.insert(newTimer)
            try? context.save()
            return newTimer
        }
    }
}
