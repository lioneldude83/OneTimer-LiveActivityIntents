//
//  SettingsView.swift
//  OneTimer
//
//  Created by Lionel Ng on 19/5/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(TimerViewModel.self) var viewModel
    @Environment(\.modelContext) private var modelContext
    
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedSound: Sound
    let soundOptions: [Sound] = [.chord, .gong]
    
    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Apply") {
                    let duration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                    viewModel.setDuration(duration, sound: selectedSound)
                    dismiss()
                }
                .disabled(hours == 0 && minutes == 0 && seconds == 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            Text("Set Timer Duration")
                .font(.title3)
                .padding(.bottom, 12)
            PickerView(hours: $hours, minutes: $minutes, seconds: $seconds)
            
            HStack {
                Text("Select Sound")
                
                Spacer()
                Picker("", selection: $selectedSound) {
                    ForEach(soundOptions, id: \.self) { sound in
                        Text(sound.rawValue.replacingOccurrences(of: ".wav", with: "").capitalized)
                            .tag(sound)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal, 24)
        }
        .padding()
        .presentationDetents([.height(320)])
        .onAppear {
            
        }
    }
}

#Preview {
    let sampleTimer = TimerState(duration: 60, remainingTime: 60, isPaused: true)
    let viewModel = TimerViewModel(timer: sampleTimer)
    
    SettingsView(
        hours: .constant(0),
        minutes: .constant(1),
        seconds: .constant(0),
        selectedSound: .constant(.chord)
    )
    .environment(viewModel)
}
