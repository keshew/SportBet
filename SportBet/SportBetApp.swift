import SwiftUI
import UserNotifications
import UIKit

final class SportBetAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct SportBetApp: App {
    @UIApplicationDelegateAdaptor(SportBetAppDelegate.self) private var appDelegate
    @AppStorage("app.hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("settings.theme") private var themeSelection = AppThemeMode.dark.rawValue
    @AppStorage("settings.language") private var languageCode = AppLanguage.english.rawValue

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    AppShellView()
                } else {
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                }
            }
            .preferredColorScheme((AppThemeMode(rawValue: themeSelection) ?? .dark).colorScheme)
            .environment(
                \.locale,
                Locale(identifier: (AppLanguage(rawValue: languageCode) ?? .english).localeIdentifier)
            )
        }
    }
}
