//
//  OneTimerWidgetLiveActivity.swift
//  OneTimerWidget
//
//  Created by Lionel Ng on 20/5/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            HStack(spacing: 10) {
                // Control Button 1: Pause/Resume
                if !context.state.isPaused {
                    Button(intent: PauseTimerIntent()) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.8))
                                .frame(width: 52, height: 52)
                            Image(systemName: "pause.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring, value: context.state.isPaused)
                    
                } else {
                    Button(intent: ResumeTimerIntent()) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.8))
                                .frame(width: 52, height: 52)
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring, value: context.state.isPaused)
                }
                
                // Control Button 2: Cancel
                Button(intent: CancelTimerIntent()) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.8))
                            .frame(width: 52, height: 52)
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    // Label Display
                    Text("Timer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Timer Display
                    TimerWidgetTextView(
                        endTime: context.state.endTime,
                        isPaused: context.state.isPaused,
                        adjustedRemainingTime: context.state.adjustedRemainingTime
                    )
                    .frame(width: 90, alignment: .trailing)
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        // Control Button 1: Pause/Resume
                        if !context.state.isPaused {
                            Button(intent: PauseTimerIntent()) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.8))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "pause.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                            }
                            .buttonStyle(.plain)
                            .animation(.spring, value: context.state.isPaused)
                        } else {
                            Button(intent: ResumeTimerIntent()) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.8))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                            }
                            .buttonStyle(.plain)
                            .animation(.spring, value: context.state.isPaused)
                        }
                        
                        // Control Button 2: Cancel
                        Button(intent: CancelTimerIntent()) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.8))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "xmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        // Label Display
                        Text("Timer")
                            .font(.headline)
                            .foregroundColor(.cyan)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .frame(width: 100, alignment: .trailing)
                        
                        // Timer Display
                        TimerWidgetTextView(
                            endTime: context.state.endTime,
                            isPaused: context.state.isPaused,
                            adjustedRemainingTime: context.state.adjustedRemainingTime
                        )
                        .font(.title)
                        .monospacedDigit()
                        .frame(width: 100, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                    }
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Empty
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(context.state.isPaused ? .gray : .orange)
            } compactTrailing: {
                // Timer Display in the compact trailing part of Dynamic Island
                TimerWidgetTextView(
                    endTime: context.state.endTime,
                    isPaused: context.state.isPaused,
                    adjustedRemainingTime: context.state.adjustedRemainingTime
                )
                .frame(width: 52)
                .minimumScaleFactor(0.65)
            } minimal: {
                TimerWidgetTextView(
                    endTime: context.state.endTime,
                    isPaused: context.state.isPaused,
                    adjustedRemainingTime: context.state.adjustedRemainingTime,
                    useMinimalFormat: true
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }
            .keylineTint(Color.cyan)
        }
    }
}

struct TimerWidgetTextView: View {
    let endTime: Date?
    let isPaused: Bool
    let adjustedRemainingTime: TimeInterval?
    var useMinimalFormat: Bool = false
    
    var body: some View {
        if let endTime = endTime, !isPaused {
            Text(timerInterval: Date()...endTime, countsDown: true)
                .foregroundColor(.white)
        } else if let remaining = adjustedRemainingTime, remaining <= 0 {
            Text("Done")
                .foregroundColor(.white)
        } else if let remaining = adjustedRemainingTime {
            Text(
                useMinimalFormat
                ? formatTimeMinimal(remaining)
                : formatTimeLiveRoundUp(remaining)
            )
            .foregroundColor(.white)
        } else {
            Text("Paused")
        }
    }
    
    // Formatter to display time interval in Live Activity
    private func formatTimeLiveRoundUp(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else {
            return "0:00"
        }
        
        let totalSecondsDouble = seconds
        let totalSeconds = Int(ceil(totalSecondsDouble))
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    // Formatter to display time interval for Minimal view style in Live Activity
    private func formatTimeMinimal(_ time: TimeInterval) -> String {
        guard time.isFinite, time > 0 else {
            return "0:00"
        }
        
        let rounded = Int(ceil(time))
        let minutes = rounded / 60
        let seconds = rounded % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension TimerAttributes {
    fileprivate static var preview: TimerAttributes {
        TimerAttributes(uniqueID: "singleTimer")
    }
}

extension TimerAttributes.ContentState {
    fileprivate static var state1: TimerAttributes.ContentState {
        TimerAttributes.ContentState(
            endTime: Date().addingTimeInterval(600),
            isPaused: true,
            adjustedRemainingTime: 600
        )
    }
    
    fileprivate static var state2: TimerAttributes.ContentState {
        TimerAttributes.ContentState(
            endTime: Date().addingTimeInterval(1800),
            isPaused: false,
            adjustedRemainingTime: 1200
        )
    }
}

#Preview("Live Activity", as: .content, using: TimerAttributes.preview) {
    TimerWidgetLiveActivity()
} contentStates: {
    TimerAttributes.ContentState.state1
    TimerAttributes.ContentState.state2
}

#Preview("Dynamic Island", as: .dynamicIsland(.compact), using: TimerAttributes.preview) {
    TimerWidgetLiveActivity()
} contentStates: {
    TimerAttributes.ContentState.state1
    TimerAttributes.ContentState.state2
}
