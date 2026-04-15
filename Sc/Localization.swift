import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case system
    case english
    case simplifiedChinese

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            L10n.string("language.system")
        case .english:
            L10n.string("language.english")
        case .simplifiedChinese:
            L10n.string("language.simplified_chinese")
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            Locale.autoupdatingCurrent
        case .english:
            Locale(identifier: "en")
        case .simplifiedChinese:
            Locale(identifier: "zh-Hans")
        }
    }

    fileprivate var localizationCode: String? {
        switch self {
        case .system:
            nil
        case .english:
            "en"
        case .simplifiedChinese:
            "zh-Hans"
        }
    }
}

enum L10n {
    private static let supportedLocalizationCodes = ["en", "zh-Hans"]
    private static let appLanguageDefaultsKey = "Sc.AppLanguage"

    static func setAppLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: appLanguageDefaultsKey)
    }

    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: localizedBundle(), comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: currentAppLanguage().locale, arguments: arguments)
    }

    private static func localizedBundle() -> Bundle {
        let code = resolvedLocalizationCode()
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return .main
        }

        return bundle
    }

    private static func resolvedLocalizationCode() -> String {
        if let overrideCode = currentAppLanguage().localizationCode {
            return overrideCode
        }

        return Bundle.preferredLocalizations(
            from: supportedLocalizationCodes,
            forPreferences: Locale.preferredLanguages
        ).first ?? "en"
    }

    private static func currentAppLanguage() -> AppLanguage {
        guard let rawValue = UserDefaults.standard.string(forKey: appLanguageDefaultsKey),
              let language = AppLanguage(rawValue: rawValue)
        else {
            return .system
        }

        return language
    }
}
