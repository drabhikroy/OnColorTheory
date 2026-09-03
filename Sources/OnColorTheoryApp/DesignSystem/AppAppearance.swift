import AppKit
import SwiftUI

/// Light, Dark, or whatever the Mac is set to.
///
/// The choice is pushed to `NSApplication` as well as to SwiftUI, because
/// secondary windows and the menu bar do not follow a SwiftUI color scheme on
/// their own.
enum AppAppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "Follow Mac"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon.stars"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    @MainActor
    func applyToApplication() {
        let resolvedAppearance: NSAppearance?
        switch self {
        case .system:
            resolvedAppearance = nil
        case .light:
            resolvedAppearance = NSAppearance(named: .aqua)
        case .dark:
            resolvedAppearance = NSAppearance(named: .darkAqua)
        }
        guard NSApplication.shared.appearance?.name != resolvedAppearance?.name else { return }
        NSApplication.shared.appearance = resolvedAppearance
        NSApplication.shared.windows.forEach { window in
            window.appearance = resolvedAppearance
            window.contentView?.needsDisplay = true
            window.invalidateShadow()
        }
    }
}

/// The interface cue palettes.
///
/// Each named mode avoids the distinction its condition makes unreliable, and
/// separates its five roles by lightness and chroma as well as hue, since hue
/// is the channel these conditions take away.
///
/// `Scripts/standards/palette_audit.py` reads these values directly and fails
/// the build if any pair collapses under simulation or falls below the contrast
/// floor. Separation is measured in Oklab rather than with CIEDE2000, which is
/// specified for small differences under reference conditions and is the wrong
/// instrument for asking whether two cues are categorically distinct.
///
/// These are design hypotheses, not treatments. Passing the audit does not
/// establish that a particular reader can tell two cues apart, and every role
/// carries a label, a symbol, or a position as well.
enum AppColorVisionPalette: String, CaseIterable, Identifiable, Sendable {
    case system
    case universal
    case protan
    case deutan
    case tritan
    case monochrome

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System accent"
        case .universal: "Blue and orange"
        case .protan: "Protan-aware cues"
        case .deutan: "Deutan-aware cues"
        case .tritan: "Tritan-aware cues"
        case .monochrome: "Monochrome"
        }
    }

    var shortTitle: String {
        switch self {
        case .system: "System"
        case .universal: "Universal"
        case .protan: "Protan"
        case .deutan: "Deutan"
        case .tritan: "Tritan"
        case .monochrome: "Mono"
        }
    }

    var explanation: String {
        switch self {
        case .system:
            "Uses the accent selected in macOS. Labels, shapes, and symbols still carry essential meaning."
        case .universal:
            "Uses a restrained blue-led interface palette with orange and magenta supporting cues."
        case .protan:
            "Avoids using red as the primary interface cue and emphasizes blue, gold, and magenta distinctions."
        case .deutan:
            "Avoids a red and green primary distinction and emphasizes violet, cyan, gold, and magenta cues."
        case .tritan:
            "Avoids a blue and yellow primary distinction and emphasizes magenta, teal, green, and red cues."
        case .monochrome:
            "Uses neutral interface cues so hierarchy depends on contrast, text, borders, and symbols."
        }
    }

    func resolved(for colorScheme: ColorScheme) -> AppSemanticPalette {
        switch self {
        case .system:
            AppSemanticPalette(
                accent: .accentColor,
                positive: .green,
                warning: .orange,
                critical: .red,
                secondaryCue: .purple
            )
        case .universal:
            AppSemanticPalette(
                accent: colorScheme == .dark ? Self.color(67, 194, 248) : Self.color(24, 69, 89),
                positive: colorScheme == .dark ? Self.color(179, 235, 219) : Self.color(36, 134, 93),
                warning: colorScheme == .dark ? Self.color(230, 184, 104) : Self.color(105, 72, 4),
                critical: colorScheme == .dark ? Self.color(241, 72, 9) : Self.color(77, 30, 12),
                secondaryCue: colorScheme == .dark ? Self.color(177, 111, 163) : Self.color(179, 48, 179)
            )
        case .protan:
            AppSemanticPalette(
                accent: colorScheme == .dark ? Self.color(64, 127, 255) : Self.color(10, 84, 133),
                positive: colorScheme == .dark ? Self.color(9, 245, 166) : Self.color(0, 135, 101),
                warning: colorScheme == .dark ? Self.color(198, 158, 79) : Self.color(105, 70, 0),
                critical: colorScheme == .dark ? Self.color(255, 22, 131) : Self.color(89, 0, 45),
                secondaryCue: colorScheme == .dark ? Self.color(203, 177, 249) : Self.color(98, 18, 236)
            )
        case .deutan:
            AppSemanticPalette(
                accent: colorScheme == .dark ? Self.color(192, 163, 244) : Self.color(92, 0, 250),
                positive: colorScheme == .dark ? Self.color(12, 154, 149) : Self.color(0, 129, 158),
                warning: colorScheme == .dark ? Self.color(224, 203, 160) : Self.color(153, 105, 6),
                critical: colorScheme == .dark ? Self.color(255, 45, 73) : Self.color(112, 0, 37),
                secondaryCue: colorScheme == .dark ? Self.color(0, 131, 254) : Self.color(0, 41, 124)
            )
        case .tritan:
            AppSemanticPalette(
                accent: colorScheme == .dark ? Self.color(255, 33, 107) : Self.color(212, 0, 81),
                positive: colorScheme == .dark ? Self.color(26, 224, 125) : Self.color(0, 62, 42),
                warning: colorScheme == .dark ? Self.color(252, 213, 185) : Self.color(119, 78, 39),
                critical: colorScheme == .dark ? Self.color(196, 148, 146) : Self.color(93, 0, 3),
                secondaryCue: colorScheme == .dark ? Self.color(53, 142, 200) : Self.color(43, 122, 161)
            )
        case .monochrome:
            AppSemanticPalette(
                accent: colorScheme == .dark ? Self.color(150, 150, 154) : Self.color(76, 76, 80),
                positive: colorScheme == .dark ? Self.color(190, 190, 194) : Self.color(60, 60, 67),
                warning: colorScheme == .dark ? Self.color(174, 174, 178) : Self.color(86, 86, 92),
                critical: colorScheme == .dark ? Self.color(210, 210, 214) : Self.color(44, 44, 46),
                secondaryCue: colorScheme == .dark ? Self.color(135, 135, 139) : Self.color(96, 96, 101)
            )
        }
    }

    private static func color(_ red: Int, _ green: Int, _ blue: Int) -> Color {
        Color(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}

/// The five resolved role colors for one mode and one appearance.
struct AppSemanticPalette {
    let accent: Color
    let positive: Color
    let warning: Color
    let critical: Color
    let secondaryCue: Color
}

/// Carries the resolved palette down the view tree.
private struct AppSemanticPaletteKey: EnvironmentKey {
    static let defaultValue = AppColorVisionPalette.system.resolved(for: .light)
}

extension EnvironmentValues {
    var appSemanticPalette: AppSemanticPalette {
        get { self[AppSemanticPaletteKey.self] }
        set { self[AppSemanticPaletteKey.self] = newValue }
    }
}

/// Resolves the palette for the current appearance and supplies it, tinting
/// standard controls to match unless the system accent was chosen.
private struct AppInterfaceThemeModifier: ViewModifier {
    let choice: AppColorVisionPalette
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let palette = choice.resolved(for: colorScheme)
        content
            .environment(\.appSemanticPalette, palette)
            .tint(choice == .system ? nil : palette.accent)
    }
}

/// Keeps the application appearance in step with the stored preference.
private struct ApplicationAppearanceModifier: ViewModifier {
    let mode: AppAppearanceMode

    func body(content: Content) -> some View {
        content
            .onAppear { mode.applyToApplication() }
            .onChange(of: mode) { _, updatedMode in
                updatedMode.applyToApplication()
            }
    }
}

extension View {
    func appInterfaceTheme(_ choice: AppColorVisionPalette) -> some View {
        modifier(AppInterfaceThemeModifier(choice: choice))
    }

    func syncApplicationAppearance(_ mode: AppAppearanceMode) -> some View {
        modifier(ApplicationAppearanceModifier(mode: mode))
    }
}
