import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }

    var palette: AppThemePalette {
        switch self {
        case .dark:
            return AppThemePalette(
                background: Color.black,
                elevatedBackground: Color(red: 18 / 255, green: 19 / 255, blue: 24 / 255),
                surface: Color(red: 20 / 255, green: 21 / 255, blue: 29 / 255),
                surfaceSecondary: Color(red: 30 / 255, green: 31 / 255, blue: 40 / 255),
                primaryText: .white,
                secondaryText: Color.white.opacity(0.66),
                divider: Color.white.opacity(0.08),
                accent: Color(red: 36 / 255, green: 155 / 255, blue: 1),
                destructive: Color(red: 1, green: 0.33, blue: 0.33),
                destructiveBackground: Color(red: 58 / 255, green: 14 / 255, blue: 20 / 255),
                iconBackground: Color.white.opacity(0.06)
            )
        case .light:
            return AppThemePalette(
                background: Color(red: 244 / 255, green: 246 / 255, blue: 250 / 255),
                elevatedBackground: Color.white,
                surface: Color.white,
                surfaceSecondary: Color(red: 237 / 255, green: 241 / 255, blue: 247 / 255),
                primaryText: Color(red: 17 / 255, green: 24 / 255, blue: 39 / 255),
                secondaryText: Color(red: 88 / 255, green: 97 / 255, blue: 116 / 255),
                divider: Color.black.opacity(0.08),
                accent: Color(red: 28 / 255, green: 115 / 255, blue: 240 / 255),
                destructive: Color(red: 210 / 255, green: 45 / 255, blue: 45 / 255),
                destructiveBackground: Color(red: 255 / 255, green: 236 / 255, blue: 238 / 255),
                iconBackground: Color.black.opacity(0.05)
            )
        }
    }
}

func appPalette(for colorScheme: ColorScheme) -> AppThemePalette {
    colorScheme == .dark ? AppThemeMode.dark.palette : AppThemeMode.light.palette
}

struct AppThemePalette {
    let background: Color
    let elevatedBackground: Color
    let surface: Color
    let surfaceSecondary: Color
    let primaryText: Color
    let secondaryText: Color
    let divider: Color
    let accent: Color
    let destructive: Color
    let destructiveBackground: Color
    let iconBackground: Color
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"
    case french = "fr"
    case german = "de"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .english: return "en_US"
        case .russian: return "ru_RU"
        case .french: return "fr_FR"
        case .german: return "de_DE"
        }
    }

    var displayName: String {
        switch self {
        case .english: return "English (US)"
        case .russian: return "Русский"
        case .french: return "Français"
        case .german: return "Deutsch"
        }
    }
}

func appLanguage(for locale: Locale) -> AppLanguage {
    let identifier = locale.identifier.lowercased()
    if identifier.hasPrefix("ru") {
        return .russian
    }
    if identifier.hasPrefix("fr") {
        return .french
    }
    if identifier.hasPrefix("de") {
        return .german
    }
    return .english
}

enum AppTextKey {
    case tabMatches
    case tabLeagues
    case tabAlerts
    case tabSettings
    case launchLoadingTitle
    case launchLoadingSubtitle
    case settingsTitle
    case settingsPreferences
    case settingsDarkMode
    case settingsLanguage
    case settingsSupportAbout
    case settingsHelpSupport
    case settingsPrivacyPolicy
    case settingsTerms
    case settingsResetData
    case settingsResetTitle
    case settingsResetMessage
    case settingsCancel
    case settingsConfirmReset
    case alertsTitle
    case alertsFilterAll
    case alertsFilterMatches
    case alertsFilterScheduled
    case alertsFilterDelivered
    case alertsMarkAllRead
    case alertsToday
    case alertsYesterday
    case alertsOpenMatch
    case alertsEmptyTitle
    case alertsEmptySubtitle
}

func appText(_ key: AppTextKey, languageCode: String) -> String {
    appText(key, language: AppLanguage(rawValue: languageCode) ?? .english)
}

func appText(_ key: AppTextKey, locale: Locale) -> String {
    appText(key, language: appLanguage(for: locale))
}

func appText(_ key: AppTextKey, language: AppLanguage) -> String {
    switch language {
    case .english:
        switch key {
        case .tabMatches: return "Matches"
        case .tabLeagues: return "Browse"
        case .tabAlerts: return "Alerts"
        case .tabSettings: return "Settings"
        case .launchLoadingTitle: return "Loading"
        case .launchLoadingSubtitle: return "Preparing the app"
        case .settingsTitle: return "Settings & Profile"
        case .settingsPreferences: return "Preferences"
        case .settingsDarkMode: return "Dark Mode"
        case .settingsLanguage: return "Language"
        case .settingsSupportAbout: return "Support & About"
        case .settingsHelpSupport: return "Help & Support"
        case .settingsPrivacyPolicy: return "Privacy Policy"
        case .settingsTerms: return "Terms of Service"
        case .settingsResetData: return "Reset data"
        case .settingsResetTitle: return "Reset app data?"
        case .settingsResetMessage: return "This will clear saved preferences, league filters, and notifications."
        case .settingsCancel: return "Cancel"
        case .settingsConfirmReset: return "Reset"
        case .alertsTitle: return "Notifications"
        case .alertsFilterAll: return "All"
        case .alertsFilterMatches: return "Match Alerts"
        case .alertsFilterScheduled: return "Scheduled"
        case .alertsFilterDelivered: return "Delivered"
        case .alertsMarkAllRead: return "Mark all read"
        case .alertsToday: return "Today"
        case .alertsYesterday: return "Yesterday"
        case .alertsOpenMatch: return "Open match"
        case .alertsEmptyTitle: return "No notifications yet"
        case .alertsEmptySubtitle: return "Tap the bell on a match card to subscribe. Scheduled and delivered alerts will appear here."
        }
    case .russian:
        switch key {
        case .tabMatches: return "Матчи"
        case .tabLeagues: return "Лиги"
        case .tabAlerts: return "Алерты"
        case .tabSettings: return "Настройки"
        case .launchLoadingTitle: return "Загрузка"
        case .launchLoadingSubtitle: return "Подготавливаем приложение"
        case .settingsTitle: return "Настройки и профиль"
        case .settingsPreferences: return "Предпочтения"
        case .settingsDarkMode: return "Темная тема"
        case .settingsLanguage: return "Язык"
        case .settingsSupportAbout: return "Поддержка и информация"
        case .settingsHelpSupport: return "Помощь и поддержка"
        case .settingsPrivacyPolicy: return "Политика конфиденциальности"
        case .settingsTerms: return "Условия использования"
        case .settingsResetData: return "Сбросить данные"
        case .settingsResetTitle: return "Сбросить данные приложения?"
        case .settingsResetMessage: return "Будут очищены сохраненные настройки, фильтры лиг и уведомления."
        case .settingsCancel: return "Отмена"
        case .settingsConfirmReset: return "Сбросить"
        case .alertsTitle: return "Уведомления"
        case .alertsFilterAll: return "Все"
        case .alertsFilterMatches: return "Матчи"
        case .alertsFilterScheduled: return "Запланировано"
        case .alertsFilterDelivered: return "Доставлено"
        case .alertsMarkAllRead: return "Прочитать все"
        case .alertsToday: return "Сегодня"
        case .alertsYesterday: return "Вчера"
        case .alertsOpenMatch: return "Открыть матч"
        case .alertsEmptyTitle: return "Уведомлений пока нет"
        case .alertsEmptySubtitle: return "Нажми на колокольчик у матча на первом экране. Запланированные и доставленные уведомления появятся здесь."
        }
    case .french:
        switch key {
        case .tabMatches: return "Matchs"
        case .tabLeagues: return "Parcourir"
        case .tabAlerts: return "Alertes"
        case .tabSettings: return "Réglages"
        case .launchLoadingTitle: return "Chargement"
        case .launchLoadingSubtitle: return "Préparation de l'application"
        case .settingsTitle: return "Réglages et profil"
        case .settingsPreferences: return "Préférences"
        case .settingsDarkMode: return "Thème sombre"
        case .settingsLanguage: return "Langue"
        case .settingsSupportAbout: return "Support et infos"
        case .settingsHelpSupport: return "Aide et support"
        case .settingsPrivacyPolicy: return "Politique de confidentialité"
        case .settingsTerms: return "Conditions d'utilisation"
        case .settingsResetData: return "Réinitialiser les données"
        case .settingsResetTitle: return "Réinitialiser les données de l'application ?"
        case .settingsResetMessage: return "Les préférences, filtres de ligue et notifications enregistrés seront effacés."
        case .settingsCancel: return "Annuler"
        case .settingsConfirmReset: return "Réinitialiser"
        case .alertsTitle: return "Notifications"
        case .alertsFilterAll: return "Tout"
        case .alertsFilterMatches: return "Alertes match"
        case .alertsFilterScheduled: return "Planifiées"
        case .alertsFilterDelivered: return "Livrées"
        case .alertsMarkAllRead: return "Tout marquer comme lu"
        case .alertsToday: return "Aujourd'hui"
        case .alertsYesterday: return "Hier"
        case .alertsOpenMatch: return "Ouvrir le match"
        case .alertsEmptyTitle: return "Aucune notification pour l'instant"
        case .alertsEmptySubtitle: return "Touchez la cloche sur un match pour vous abonner. Les alertes planifiées et livrées apparaîtront ici."
        }
    case .german:
        switch key {
        case .tabMatches: return "Spiele"
        case .tabLeagues: return "Entdecken"
        case .tabAlerts: return "Hinweise"
        case .tabSettings: return "Einstellungen"
        case .launchLoadingTitle: return "Wird geladen"
        case .launchLoadingSubtitle: return "Die App wird vorbereitet"
        case .settingsTitle: return "Einstellungen und Profil"
        case .settingsPreferences: return "Präferenzen"
        case .settingsDarkMode: return "Dunkles Design"
        case .settingsLanguage: return "Sprache"
        case .settingsSupportAbout: return "Support und Infos"
        case .settingsHelpSupport: return "Hilfe und Support"
        case .settingsPrivacyPolicy: return "Datenschutz"
        case .settingsTerms: return "Nutzungsbedingungen"
        case .settingsResetData: return "Daten zurücksetzen"
        case .settingsResetTitle: return "App-Daten zurücksetzen?"
        case .settingsResetMessage: return "Gespeicherte Einstellungen, Liga-Filter und Benachrichtigungen werden gelöscht."
        case .settingsCancel: return "Abbrechen"
        case .settingsConfirmReset: return "Zurücksetzen"
        case .alertsTitle: return "Benachrichtigungen"
        case .alertsFilterAll: return "Alle"
        case .alertsFilterMatches: return "Spielalarme"
        case .alertsFilterScheduled: return "Geplant"
        case .alertsFilterDelivered: return "Zugestellt"
        case .alertsMarkAllRead: return "Alle als gelesen"
        case .alertsToday: return "Heute"
        case .alertsYesterday: return "Gestern"
        case .alertsOpenMatch: return "Spiel öffnen"
        case .alertsEmptyTitle: return "Noch keine Benachrichtigungen"
        case .alertsEmptySubtitle: return "Tippe auf die Glocke bei einem Spiel, um es zu abonnieren. Geplante und zugestellte Hinweise erscheinen hier."
        }
    }
}

enum SettingsLinkDestination {
    case helpSupport
    case privacyPolicy
    case terms

    var url: URL {
        switch self {
        case .helpSupport:
            return URL(string: "https://www.thesportsdb.com")!
        case .privacyPolicy:
            return URL(string: "https://www.apple.com/legal/privacy/en-ww/")!
        case .terms:
            return URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
        }
    }
}
