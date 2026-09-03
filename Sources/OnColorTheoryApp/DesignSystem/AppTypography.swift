import CoreText
import SwiftUI

@MainActor
/// Registers the bundled face at launch so it can be asked for by name.
enum FontRegistrar {
    private static var didRegister = false

    static func registerBundledFonts() {
        guard !didRegister else { return }
        didRegister = true

        if let appURL = Bundle.main.url(
            forResource: "AtkinsonHyperlegibleNext-Variable",
            withExtension: "ttf",
            subdirectory: "Fonts"
        ) {
            CTFontManagerRegisterFontsForURL(appURL as CFURL, .process, nil)
            return
        }

        let packageURL = Bundle.module.url(
            forResource: "AtkinsonHyperlegibleNext-Variable",
            withExtension: "ttf"
        )
        if let packageURL {
            CTFontManagerRegisterFontsForURL(packageURL as CFURL, .process, nil)
        }
    }
}

/// The named text roles, each with its own size and weight.
///
/// Sizes are multiplied by the text scale preference rather than set directly,
/// so enlarging text moves the whole hierarchy together instead of flattening
/// it.
///
/// The steps rise by roughly an eighth each time, which is enough that two
/// neighboring roles are told apart by size alone. Packing several roles into
/// the same one or two point band leaves weight and color carrying the whole
/// hierarchy, and everything below a title then reads as one flat level.
enum AppFontRole {
    case largeTitle
    case title
    case title2
    case headline
    case body
    case callout
    case caption
    case value

    var baseSize: CGFloat {
        switch self {
        case .largeTitle: 30
        case .title: 25
        case .title2: 21
        case .headline: 18
        case .body: 16
        case .callout: 14
        case .caption: 12
        case .value: 16
        }
    }

    var weight: Font.Weight {
        switch self {
        case .largeTitle, .title: .bold
        case .title2, .headline: .semibold
        case .body, .callout, .caption, .value: .regular
        }
    }

    var systemStyle: Font.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title
        case .title2: .title2
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .caption: .caption
        case .value: .callout
        }
    }
}

/// Carries the text size preference down the view tree.
private struct AppTextScaleKey: EnvironmentKey {
    static let defaultValue = 1.0
}

/// Carries the choice between the bundled face and the system font.
private struct UseSystemFontKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var appTextScale: Double {
        get { self[AppTextScaleKey.self] }
        set { self[AppTextScaleKey.self] = newValue }
    }

    var useSystemFont: Bool {
        get { self[UseSystemFontKey.self] }
        set { self[UseSystemFontKey.self] = newValue }
    }
}

/// Applies a role, honoring both the text scale and the system font
/// preference.
private struct AppFontModifier: ViewModifier {
    @Environment(\.appTextScale) private var textScale
    @Environment(\.useSystemFont) private var useSystemFont
    let role: AppFontRole

    func body(content: Content) -> some View {
        let size = role.baseSize * textScale
        if useSystemFont {
            content.font(.system(size: size, weight: role.weight))
        } else {
            content.font(
                .custom(
                    "Atkinson Hyperlegible Next",
                    size: size,
                    relativeTo: role.systemStyle
                )
                .weight(role.weight)
            )
        }
    }
}

extension View {
    func appFont(_ role: AppFontRole) -> some View {
        modifier(AppFontModifier(role: role))
    }
}
