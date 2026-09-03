import Foundation

/// A set of colors together with the neutral values they reduce to.
struct ColorRelianceEvaluation: Hashable, Sendable {
    let first: SRGBColor
    let second: SRGBColor
    let firstRelativeLuminance: Double
    let secondRelativeLuminance: Double
    let firstNeutral: SRGBColor
    let secondNeutral: SRGBColor

    var luminanceSeparation: Double {
        abs(firstRelativeLuminance - secondRelativeLuminance)
    }
}

/// Replaces each color with a neutral of the same calculated relative
/// luminance.
///
/// Meaning that survives this preview does not depend on hue alone. Meaning
/// that disappears is meaning WCAG 2.2 Success Criterion 1.4.1 asks to be
/// carried some other way as well.
struct ColorReliancePreviewer: Sendable {
    func evaluate(first: SRGBColor, second: SRGBColor) -> ColorRelianceEvaluation {
        let opaqueFirst = SRGBColor(red: first.red, green: first.green, blue: first.blue)
        let opaqueSecond = SRGBColor(red: second.red, green: second.green, blue: second.blue)
        let firstLuminance = relativeLuminance(of: opaqueFirst)
        let secondLuminance = relativeLuminance(of: opaqueSecond)

        return ColorRelianceEvaluation(
            first: opaqueFirst,
            second: opaqueSecond,
            firstRelativeLuminance: firstLuminance,
            secondRelativeLuminance: secondLuminance,
            firstNeutral: neutralColor(preservingRelativeLuminance: firstLuminance),
            secondNeutral: neutralColor(preservingRelativeLuminance: secondLuminance)
        )
    }

    func neutralColor(preservingRelativeLuminance luminance: Double) -> SRGBColor {
        let clamped = min(max(luminance, 0), 1)
        let encoded: Double
        if clamped == 0 {
            encoded = 0
        } else if clamped == 1 {
            encoded = 1
        } else {
            encoded = TransferFunctions.linearToSRGB(clamped)
        }
        return SRGBColor(red: encoded, green: encoded, blue: encoded)
    }

    private func relativeLuminance(of color: SRGBColor) -> Double {
        let red = TransferFunctions.sRGBToLinear(color.red)
        let green = TransferFunctions.sRGBToLinear(color.green)
        let blue = TransferFunctions.sRGBToLinear(color.blue)
        return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    }
}

/// The luminance to neutral equations, kept for display.
enum ColorRelianceMath {
    static let neutralEquation = #"R'_{\mathrm{neutral}}=G'_{\mathrm{neutral}}=B'_{\mathrm{neutral}}=f_{\mathrm{sRGB}}(Y)"#
    static let neutralReading = "Each encoded neutral channel equals the sRGB encoding function applied to relative luminance Y."
}
