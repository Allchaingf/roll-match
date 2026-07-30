//
//  RollMatchApp.swift
//  RollMatch
//
//  App entry point. Injects app-wide state and applies the persisted theme.
//

import SwiftUI

@main
struct RollMatchApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var store = AppStore()
    @StateObject private var notifier = NotificationManager()

    init() {
        // White nav-bar titles + transparent bar to sit on the dark background.
        let ap = UINavigationBarAppearance()
        ap.configureWithTransparentBackground()
        ap.titleTextAttributes = [.foregroundColor: UIColor.white]
        ap.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = ap
        UINavigationBar.appearance().scrollEdgeAppearance = ap
        UINavigationBar.appearance().compactAppearance = ap
        UINavigationBar.appearance().tintColor = UIColor(red: 0xF7/255, green: 0x7A/255, blue: 0x1E/255, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .environmentObject(notifier)
                .preferredColorScheme(settings.themeMode.colorScheme)
                .accentColor(settings.accent)
        }
    }
}
