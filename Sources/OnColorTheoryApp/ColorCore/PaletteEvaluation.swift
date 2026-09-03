import Foundation

/// The four named jobs a color does in the palette a person builds.
enum InterfacePaletteRole: String, CaseIterable, Identifiable, Sendable {
    case background
    case text
    case accent
    case accentText

    var id: Self { self }

    var title: String {
        switch self {
        case .background: "Canvas"
        case .text: "Body text"
        case .accent: "Accent"
        case .accentText: "Accent text"
        }
    }

    var explanation: String {
        switch self {
        case .background: "The main surface behind content."
        case .text: "Ordinary reading text on the canvas."
        case .accent: "A repeated color for actions or meaningful cues."
        case .accentText: "Text placed directly on the accent color."
        }
    }

    var cssName: String {
        switch self {
        case .background: "--color-canvas"
        case .text: "--color-text"
        case .accent: "--color-accent"
        case .accentText: "--color-accent-text"
        }
    }

    var codeName: String {
        switch self {
        case .background: "canvas"
        case .text: "text"
        case .accent: "accent"
        case .accentText: "accentText"
        }
    }
}

/// A palette a person is working on, held as roles rather than loose swatches.
struct InterfacePalette: Codable, Hashable, Sendable {
    var background: SRGBColor
    var text: SRGBColor
    var accent: SRGBColor
    var accentText: SRGBColor

    subscript(role: InterfacePaletteRole) -> SRGBColor {
        get {
            switch role {
            case .background: background
            case .text: text
            case .accent: accent
            case .accentText: accentText
            }
        }
        set {
            switch role {
            case .background: background = newValue.opaque
            case .text: text = newValue.opaque
            case .accent: accent = newValue.opaque
            case .accentText: accentText = newValue.opaque
            }
        }
    }

    var cssCustomProperties: String {
        let declarations = InterfacePaletteRole.allCases.map { role in
            "  \(role.cssName): \(self[role].hex);"
        }
        return ([":root {"] + declarations + ["}"]).joined(separator: "\n")
    }
}

/// Starting palettes offered before a person has built one.
enum InterfacePalettePreset: String, CaseIterable, Identifiable, Sendable {
    case light = "Soft neutral · light"
    case dark = "Soft neutral · dark"
    case warm = "Terracotta · light"
    case ocean = "Ocean · light"
    case midnight = "Midnight · dark"
    case plum = "Plum · dark"

    var id: Self { self }

    var palette: InterfacePalette {
        switch self {
        case .light:
            InterfacePalette(
                background: .from8Bit(red: 247, green: 244, blue: 238),
                text: .from8Bit(red: 32, green: 33, blue: 36),
                accent: .from8Bit(red: 23, green: 107, blue: 91),
                accentText: .from8Bit(red: 255, green: 255, blue: 255)
            )
        case .dark:
            InterfacePalette(
                background: .from8Bit(red: 23, green: 25, blue: 28),
                text: .from8Bit(red: 244, green: 241, blue: 234),
                accent: .from8Bit(red: 113, green: 208, blue: 186),
                accentText: .from8Bit(red: 16, green: 36, blue: 31)
            )
        case .warm:
            InterfacePalette(
                background: .from8Bit(red: 255, green: 248, blue: 240),
                text: .from8Bit(red: 53, green: 35, blue: 24),
                accent: .from8Bit(red: 163, green: 60, blue: 40),
                accentText: .from8Bit(red: 255, green: 255, blue: 255)
            )
        case .ocean:
            InterfacePalette(
                background: .from8Bit(red: 242, green: 248, blue: 250),
                text: .from8Bit(red: 24, green: 40, blue: 48),
                accent: .from8Bit(red: 0, green: 102, blue: 133),
                accentText: .from8Bit(red: 255, green: 255, blue: 255)
            )
        case .midnight:
            InterfacePalette(
                background: .from8Bit(red: 18, green: 29, blue: 42),
                text: .from8Bit(red: 238, green: 244, blue: 248),
                accent: .from8Bit(red: 75, green: 151, blue: 185),
                accentText: .from8Bit(red: 8, green: 25, blue: 34)
            )
        case .plum:
            InterfacePalette(
                background: .from8Bit(red: 31, green: 24, blue: 35),
                text: .from8Bit(red: 246, green: 239, blue: 247),
                accent: .from8Bit(red: 211, green: 140, blue: 188),
                accentText: .from8Bit(red: 43, green: 20, blue: 36)
            )
        }
    }
}

/// The three pairings the app checks inside a palette.
enum PaletteRelationshipID: String, CaseIterable, Identifiable, Sendable {
    case bodyText
    case accentText
    case accentCue

    var id: Self { self }
}

/// One pairing's contrast result and the verdict taken from it.
struct PaletteRelationshipResult: Identifiable, Hashable, Sendable {
    let id: PaletteRelationshipID
    let title: String
    let explanation: String
    let foregroundRole: InterfacePaletteRole
    let backgroundRole: InterfacePaletteRole
    let criterion: WCAGContrastCriterion
    let evaluation: ContrastEvaluation

    var passes: Bool { evaluation.passes(criterion) }
}

/// Checks the three named relationships in a palette.
///
/// Three passing relationships do not make a whole interface accessible, and
/// the interface says so. Font rendering, size, weight, and content around the
/// pair all matter and none of them are visible from here.
struct InterfacePaletteEvaluator: Sendable {
    private let checker = WCAGContrastChecker()

    func evaluate(_ palette: InterfacePalette) -> [PaletteRelationshipResult] {
        [
            relationship(
                id: .bodyText,
                title: "Body text on canvas",
                explanation: "Ordinary reading text is checked against the WCAG 2.2 minimum of 4.5:1.",
                foregroundRole: .text,
                backgroundRole: .background,
                criterion: .normalTextAA,
                palette: palette
            ),
            relationship(
                id: .accentText,
                title: "Text on accent",
                explanation: "The button label is treated as ordinary text, so the same 4.5:1 minimum is used.",
                foregroundRole: .accentText,
                backgroundRole: .accent,
                criterion: .normalTextAA,
                palette: palette
            ),
            relationship(
                id: .accentCue,
                title: "Accent cue on canvas",
                explanation: "If this color is the required shape or state cue, WCAG 2.2 uses a 3:1 minimum against adjacent colors.",
                foregroundRole: .accent,
                backgroundRole: .background,
                criterion: .nonTextAA,
                palette: palette
            )
        ]
    }

    func higherContrastText(on background: SRGBColor) -> SRGBColor {
        let black = SRGBColor(red: 0, green: 0, blue: 0)
        let white = SRGBColor(red: 1, green: 1, blue: 1)
        let blackRatio = checker.evaluateOverOpaqueBackground(foreground: black, background: background).ratio
        let whiteRatio = checker.evaluateOverOpaqueBackground(foreground: white, background: background).ratio
        return blackRatio >= whiteRatio ? black : white
    }

    private func relationship(
        id: PaletteRelationshipID,
        title: String,
        explanation: String,
        foregroundRole: InterfacePaletteRole,
        backgroundRole: InterfacePaletteRole,
        criterion: WCAGContrastCriterion,
        palette: InterfacePalette
    ) -> PaletteRelationshipResult {
        let evaluation = checker.evaluateOverOpaqueBackground(
            foreground: palette[foregroundRole].opaque,
            background: palette[backgroundRole].opaque
        )
        return PaletteRelationshipResult(
            id: id,
            title: title,
            explanation: explanation,
            foregroundRole: foregroundRole,
            backgroundRole: backgroundRole,
            criterion: criterion,
            evaluation: evaluation
        )
    }
}

private extension SRGBColor {
    static func from8Bit(red: Int, green: Int, blue: Int) -> SRGBColor {
        SRGBColor(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}
