//
//  SoundManager.swift
//  OneTimer
//
//  Created by Lionel Ng on 19/5/25.
//

import AVFoundation

enum Sound: String, CaseIterable {
    case chord
    case gong
}

class SoundManager {
    static let shared = SoundManager()
    private var players: [Sound: AVAudioPlayer] = [:]
    
    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }
        
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
                print("Sound file \\(sound.rawValue).wav not found.")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[sound] = player
            } catch {
                print("Failed to load sound \\(sound.rawValue): \\(error)")
            }
        }
    }
    
    func play(_ sound: Sound) {
        players[sound]?.play()
    }
    
    func stop(_ sound: Sound) {
        players[sound]?.stop()
        players[sound]?.currentTime = 0
    }
}
