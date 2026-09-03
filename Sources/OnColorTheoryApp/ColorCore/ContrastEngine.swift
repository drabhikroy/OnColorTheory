import Foundation

/// Why a contrast check could not run.
enum ContrastCheckError: LocalizedError, Equatable {
    case translucentBackground

    var errorDescription: String? {
        switch self {
        case .translucentBackground:
            "Use an opaque background. A translucent background needs another backdrop before its visible contrast can be determined."
        }
    }
}

/// The WCAG 2.2 success criteria this app evaluates a color pair against.
///
/// Each case carries its own threshold. Grouping them here keeps the numbers in
/// one place rather than scattered through the views that report them.
enum WCAGContrastCriterion: String, CaseIterable, Identifiable, Sendable {
    case normalTextAA
    case largeTextAA
    case nonTextAA
    case normalTextAAA
    case largeTextAAA

    var id: Self { self }

    var title: String {
        switch self {
        case .normalTextAA: "Normal text"
        case .largeTextAA: "Large text"
        case .nonTextAA: "UI and graphics"
        case .normalTextAAA: "Normal text"
        case .largeTextAAA: "Large text"
        }
    }

    var level: String {
        switch self {
        case .normalTextAA, .largeTextAA, .nonTextAA: "AA"
        case .normalTextAAA, .largeTextAAA: "AAA"
        }
    }

    var threshold: Double {
        switch self {
        case .normalTextAA, .largeTextAAA: 4.5
        case .largeTextAA, .nonTextAA: 3
        case .normalTextAAA: 7
        }
    }

    var scope: String {
        switch self {
        case .normalTextAA:
            "WCAG 1.4.3 minimum for normal text"
        case .largeTextAA:
            "WCAG 1.4.3 minimum for large text"
        case .nonTextAA:
            "WCAG 1.4.11 for required UI and graphical cues"
        case .normalTextAAA:
            "WCAG 1.4.6 enhanced for normal text"
        case .largeTextAAA:
            "WCAG 1.4.6 enhanced for large text"
        }
    }
}

/// The result of one contrast check, holding the ratio and every criterion
/// verdict calculated from it.
struct ContrastEvaluation: Hashable, Sendable {
    let foreground: SRGBColor
    let background: SRGBColor
    let effectiveForeground: SRGBColor
    let foregroundLuminance: Double
    let backgroundLuminance: Double
    let ratio: Double

    func passes(_ criterion: WCAGContrastCriterion) -> Bool {
        // WCAG thresholds are exact. The displayed ratio may be rounded, but this comparison is not.
        ratio >= criterion.threshold
    }
}

/// Calculates the WCAG contrast ratio for a pair of opaque sRGB colors.
///
/// Verdicts compare the unrounded ratio. Rounding first would let a pair at
/// 4.4995 report as passing, which is the wrong side of the line.
struct WCAGContrastChecker: ContrastCalculating {
    private let compositor = SourceOverCompositor()

    func evaluate(foreground: SRGBColor, background: SRGBColor) throws -> ContrastEvaluation {
        guard background.alpha >= 1 else {
            throw ContrastCheckError.translucentBackground
        }
        return evaluateOverOpaqueBackground(foreground: foreground, background: background)
    }

    func evaluateOverOpaqueBackground(
        foreground: SRGBColor,
        background: SRGBColor
    ) -> ContrastEvaluation {
        let opaqueBackground = background.opaque
        let effectiveForeground = compositor
            .compositeOverOpaqueBackdrop(source: foreground, backdrop: opaqueBackground)
            .result
        let foregroundLuminance = relativeLuminance(of: effectiveForeground)
        let backgroundLuminance = relativeLuminance(of: opaqueBackground)
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)

        return ContrastEvaluation(
            foreground: foreground,
            background: opaqueBackground,
            effectiveForeground: effectiveForeground,
            foregroundLuminance: foregroundLuminance,
            backgroundLuminance: backgroundLuminance,
            ratio: (lighter + 0.05) / (darker + 0.05)
        )
    }

    private func relativeLuminance(of color: SRGBColor) -> Double {
        let red = TransferFunctions.sRGBToLinear(color.red)
        let green = TransferFunctions.sRGBToLinear(color.green)
        let blue = TransferFunctions.sRGBToLinear(color.blue)
        return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    }
}

/// The equations behind the contrast ratio, kept as text for display.
enum ContrastMath {
    static let relativeLuminanceEquation = #"L=0.2126R_{\mathrm{lin}}+0.7152G_{\mathrm{lin}}+0.0722B_{\mathrm{lin}}"#
    static let relativeLuminanceReading = "Relative luminance is zero point two one two six times linear red, plus zero point seven one five two times linear green, plus zero point zero seven two two times linear blue."

    static let ratioEquation = #"\mathrm{CR}=\frac{L_{\mathrm{lighter}}+0.05}{L_{\mathrm{darker}}+0.05}"#
    static let ratioReading = "Contrast ratio is the lighter relative luminance plus zero point zero five, divided by the darker relative luminance plus zero point zero five."
}
