//
//  TimerView.swift
//  OneTimer
//
//  Created by Lionel Ng on 19/5/25.
//

import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(TimerViewModel.self) var viewModel
    @Environment(\.modelContext) private var modelContext
    
    // Selection for user to display circle or rounded rectangle
    @AppStorage("displayCircle") private var isCircleDisplay: Bool = true
    
    @AppStorage("timerHours") private var hours: Int = 0
    @AppStorage("timerMinutes") private var minutes: Int = 0
    @AppStorage("timerSeconds") private var seconds: Int = 0
    
    @State private var selectedSound: Sound = .chord
    let soundOptions: [Sound] = [.chord, .gong]
    
    @State private var showSettingsSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    if isCircleDisplay {
                        circleDisplay()
                    } else {
                        roundedRectangleDisplay()
                    }
                    
                    // Display end time in localized format, else display emptry string
                    if let endTime = viewModel.endTime {
                        Label("\(formattedEndTime(from: endTime))", systemImage: "bell.fill")
                            .foregroundColor(.gray)
                            .offset(y: -40) // Shifted upwards
                    }
                    
                    // Timer Display centered in ZStack
                    Text(formatTimeRoundUp(viewModel.remainingTime))
                        .font(.system(size: 48, design: .rounded))
                        .monospacedDigit()
                        .onTapGesture {
                            if viewModel.isPaused {
                                showSettingsSheet = true
                            }
                        }
                    
                    Label(viewModel.selectedSound.rawValue.capitalized, systemImage: "speaker.wave.3.fill")
                        .foregroundColor(.gray)
                        .offset(y: 40) // Shifted downwards
                    
                }
                .frame(width: 328, height: 328)
                
                // Control buttons
                HStack(spacing: 128) {
                    // Reset button
                    Button(action: {
                        viewModel.reset()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.85))
                                .frame(width: 80, height: 80)
                            Image(systemName: "xmark")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    // Play/Pause toggle button
                    Button(action: {
                        if viewModel.isPaused {
                            viewModel.start()
                        } else {
                            viewModel.pause()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isPaused ? Color.green.opacity(0.85) : Color.blue.opacity(0.85))
                                .frame(width: 80, height: 80)
                            Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(viewModel.remainingTime <= 0)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Timer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showSettingsSheet = true
                    }) {
                        Image(systemName: "gear")
                    }
                    .disabled(!viewModel.isPaused)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            isCircleDisplay = true
                        }) {
                            Label("Circle", systemImage: "circle")
                        }
                        Button(action: {
                            isCircleDisplay = false
                        }) {
                            Label("Rectangle", systemImage: "rectangle")
                        }
                    } label: {
                        Label("Shape", systemImage: isCircleDisplay ? "circle" : "rectangle")
                    }
                    .help("Select the display shape of the timer")
                }
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView(hours: $hours, minutes: $minutes, seconds: $seconds, selectedSound: $selectedSound)
            }
        }
        // End of NavigationStack
    }
    
    @ViewBuilder
    private func circleDisplay() -> some View {
        Circle()
            .stroke(lineWidth: 10)
            .opacity(0.4)
            .foregroundColor(.orange)
        
        Circle()
            .trim(from: 0, to: 1 - viewModel.progress)
            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
            .foregroundColor(.orange)
            .rotationEffect(.degrees(-90))
            .animation(viewModel.remainingTime > 0 ? .linear : nil, value: viewModel.progress)
    }
    
    @ViewBuilder
    private func roundedRectangleDisplay() -> some View {
        RoundedRectangle(cornerRadius: 80)
            .stroke(lineWidth: 10)
            .opacity(0.4)
            .foregroundColor(.orange)
        
        RoundedRectangle(cornerRadius: 80)
            .trim(from: 0, to: 1 - viewModel.progress)
            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
            .foregroundColor(.orange)
            .rotationEffect(.degrees(-90))
            .animation(viewModel.remainingTime > 0 ? .linear : nil, value: viewModel.progress)
    }
    
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
    
    // HH:MM:SS formatter that rounds UP seconds for display (updated logic)
    private func formatTimeRoundUp(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else {
            return "00:00:00"
        }
        
        let totalSeconds = Int(ceil(seconds)) // Round up total seconds
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
    
    // Display end time in localized format
    private func formattedEndTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleTimer = TimerState(duration: 60, remainingTime: 60, isPaused: true)
    let viewModel = TimerViewModel(timer: sampleTimer)
    
    TimerView()
        .environment(viewModel)
}
