# OneTimer-LiveActivityIntents

## MyChronoPro

Download [MyChronoPro](https://apps.apple.com/us/app/mychronopro/id6746975883) on the App Store now!

## Documentation

Completed on May 22, 2025.

A simple timer app that has one instance of a view model.

The app supports Live Activity and Dynamic Island.

Main timer app

Settings icon on top to set timer duration and sound selector. Sound created using garage band.

Start/Pause/Reset buttons in the main app, where functions are also duplicated in the Timer Intents.

The timer state is persisted to SwiftData and will act as the source of truth for the app. The view model is reloaded on change of scene phase. This will allow the timer to have persistence, so that when the user quits the app, a running timer will be maintained without losing track of the end time.

Live Activity Intents for the Widget will save the TimerState to SwiftData, and post a notification. On the main app, the receiver receives the notification to trigger reloading of the view model. This will ensure the single source of truth for the view model.

Make sure perform() in the Intents is on MainActor, as publishing changes from the background thread is not allowed.

## Recreating/Targets for the Files in this Project

Make sure to set the target membership to both the main app and widget extension for the following:

TimerAttributes
TimerLiveActivityManager
NotificationManager
TimerState (SwiftData model)
TimerIntents <- If not added to main app target, the intents will not work!
TimerIntents+Extension

## Important

Make sure the intents are set to the Live Activity Intents protocol!

In project settings, under the main app target, make sure on the info tab, add "Supports Live Activities" and set to Yes.

For the SwiftData to sync across both the main app and widget extension, add App Groups under signing & capabilities and set to the same group name, e.g. "group.com.example.yourappname"
