//
//  OneTimerApp.swift
//  OneTimer
//
//  Created by Lionel Ng on 19/5/25.
//

import SwiftUI
import SwiftData

@main
struct OneTimerApp: App {
    @Environment(\.scenePhase) var scenePhase
    let container: ModelContainer
    
    init() {
        let schema = Schema([TimerState.self])
        let modelConfiguration = ModelConfiguration(schema: schema, allowsSave: true)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error.localizedDescription). Error: \(error)")
        }
        Task { @MainActor in
            TimerLiveActivityManager.shared.restoreLiveActivity(for: "singleTimer")
            NotificationManager.shared.requestAuthorization()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            let modelContext = container.mainContext
            let timer = TimerManager.shared.loadOrCreateTimer(in: modelContext)
            let viewModel = TimerViewModel(timer: timer, context: modelContext)
            TimerView()
                .environment(viewModel)
                .modelContainer(container)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OneTimerIntentsNotify"))) { _ in
                    print("MainApp: Notification received")
                    viewModel.update(with: timer)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        print("MainApp: Scene phase is \(newPhase)")
                        viewModel.update(with: timer)
                        print("MainApp: ViewModel updated")
                    } else {
                        print("MainApp: Scene phase is \(newPhase)")
                    }
                }
        }
    }
}
