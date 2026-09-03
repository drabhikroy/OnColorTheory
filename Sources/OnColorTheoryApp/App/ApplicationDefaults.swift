import Foundation

/// The preference keys, named in one place so a typo cannot silently create a
/// second setting.
enum AppPreferenceKeys {
    static let textScale = "app.textScale"
    static let useSystemFont = "app.useSystemFont"
    static let appearance = "app.appearance"
    static let colorVisionPalette = "app.colorVisionPalette"
    static let completedInitialWalkthrough = "app.completedInitialWalkthrough"
}

/// Registers the starting values for every preference at launch.
enum ApplicationDefaults {
    static func register(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            AppPreferenceKeys.textScale: 1.0,
            AppPreferenceKeys.useSystemFont: false,
            AppPreferenceKeys.appearance: AppAppearanceMode.dark.rawValue,
            AppPreferenceKeys.colorVisionPalette: AppColorVisionPalette.system.rawValue,
            AppPreferenceKeys.completedInitialWalkthrough: false
        ])
    }

    static func reset(
        in defaults: UserDefaults = .standard,
        showInitialWalkthrough: Bool
    ) {
        defaults.set(1.0, forKey: AppPreferenceKeys.textScale)
        defaults.set(false, forKey: AppPreferenceKeys.useSystemFont)
        defaults.set(AppAppearanceMode.dark.rawValue, forKey: AppPreferenceKeys.appearance)
        defaults.set(AppColorVisionPalette.system.rawValue, forKey: AppPreferenceKeys.colorVisionPalette)
        defaults.set(!showInitialWalkthrough, forKey: AppPreferenceKeys.completedInitialWalkthrough)

        for key in defaults.dictionaryRepresentation().keys
            where key.hasPrefix(AppWindowContinuity.frameKeyPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
