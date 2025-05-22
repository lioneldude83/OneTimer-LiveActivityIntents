//
//  TimerIntents+Extension.swift
//  OneTimer
//
//  Created by Lionel Ng on 22/5/25.
//

import Foundation

extension TimerIntentsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .modelContainerLoadingFailed:
            return "Failed to load model container"
        case .timerNotFound:
            return "Timer not found"
        case .timerEndTimeNil:
            return "Timer end time is nil"
        }
    }
}

enum TimerIntentsError: Error {
    case modelContainerLoadingFailed
    case timerNotFound
    case timerEndTimeNil
}
