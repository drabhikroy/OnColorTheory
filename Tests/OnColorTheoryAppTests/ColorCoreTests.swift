import Foundation
import AppKit
import CoreText
import SwiftUI
import Testing
@testable import OnColorTheoryApp

struct ColorCoreTests {
    private let core = ColorCore()

    @Test("Six-digit HEX parses as encoded sRGB")
    func parsesSixDigitHex() throws {
        let analysis = try core.analyze("#C58F63")
        #expect(analysis.parsed.color.red8 == 197)
        #expect(analysis.parsed.color.green8 == 143)
        #expect(analysis.parsed.color.blue8 == 99)
        #expect(analysis.parsed.color.alpha8 == 255)
        #expect(analysis.parsed.color.hex == "#C58F63")
    }

    @Test("Short RGBA HEX expands each nibble")
    func parsesShortRGBA() throws {
        let analysis = try core.analyze("#0F08")
        #expect(analysis.parsed.color.hex == "#00FF0088")
        #expect(abs(analysis.parsed.color.alpha - (136.0 / 255.0)) < 0.000_001)
    }

    @Test("Invalid lengths explain the accepted syntax")
    func rejectsUnsupportedLength() {
        #expect(throws: ColorParseError.unsupportedLength(5)) {
            try core.analyze("#12345")
        }
    }

    @Test("Modern CSS rgb() parses number components and percentage alpha")
    func parsesModernRGB() throws {
        let analysis = try core.analyze("rgb(197 143 99 / 50%)")
        #expect(analysis.parsed.notationID == .rgb)
        #expect(analysis.parsed.color.hex == "#C58F6380")
        #expect(analysis.parsed.color.cssRGB == "rgb(197 143 99 / 50.0%)")
    }

    @Test("Legacy CSS rgba() remains accepted and visibly identified")
    func parsesLegacyRGBA() throws {
        let analysis = try core.analyze("rgba(197, 143, 99, 0.5)")
        #expect(analysis.parsed.color.red8 == 197)
        #expect(analysis.parsed.color.alpha8 == 128)
        #expect(analysis.parsed.notation.contains("Legacy CSS"))
    }

    @Test("RGB percentage components use the full zero-to-one range")
    func parsesRGBPercentages() throws {
        let color = try core.analyze("rgb(100% 0% 50%)").parsed.color
        #expect(color.red == 1)
        #expect(color.green == 0)
        #expect(color.blue == 0.5)
    }

    @Test("Out-of-range RGB is reported instead of silently clamped")
    func rejectsOutOfRangeRGB() {
        #expect(throws: ColorParseError.rgbComponentOutOfRange("256")) {
            try core.analyze("rgb(256 0 0)")
        }
    }

    @Test("sRGB red converts to known D65 XYZ coordinates")
    func convertsRedToXYZ() throws {
        let xyz = try core.analyze("#FF0000").xyzD65
        #expect(abs(xyz.x - 0.4123907993) < 0.000_000_1)
        #expect(abs(xyz.y - 0.2126390059) < 0.000_000_1)
        #expect(abs(xyz.z - 0.0193308187) < 0.000_000_1)
    }

    @Test("sRGB transfer functions match the CSS Color breakpoints and round trip")
    func transferFunctionsMatchPublishedValues() {
        let encodedBreakpoint = 0.04045
        let linearBreakpoint = encodedBreakpoint / 12.92

        #expect(abs(TransferFunctions.sRGBToLinear(encodedBreakpoint) - linearBreakpoint) < 0.000_000_000_001)
        #expect(abs(TransferFunctions.sRGBToLinear(0.5) - 0.214_041_140_482_232_55) < 0.000_000_000_001)
        #expect(abs(TransferFunctions.linearToSRGB(0.214_041_140_482_232_55) - 0.5) < 0.000_000_000_001)

        for component in stride(from: 0.0, through: 1.0, by: 0.01) {
            let roundTrip = TransferFunctions.linearToSRGB(TransferFunctions.sRGBToLinear(component))
            #expect(abs(roundTrip - component) < 0.000_000_000_001)
        }
    }

    @Test("sRGB white lands on the D65 and D50 reference whites")
    func whiteMatchesReferenceWhites() throws {
        let white = try ColorCore().analyze("#FFFFFF")

        #expect(abs(white.xyzD65.x - 0.950_455_927_051_671_6) < 0.000_000_001)
        #expect(abs(white.xyzD65.y - 1) < 0.000_000_001)
        #expect(abs(white.xyzD65.z - 1.089_057_750_759_878_4) < 0.000_000_001)
        #expect(abs(white.labD50.lightness - 100) < 0.000_001)
        #expect(abs(white.labD50.a) < 0.000_01)
        #expect(abs(white.labD50.b) < 0.000_01)
        #expect(abs(white.relativeLuminance - 1) < 0.000_000_001)
    }

    @Test("sRGB red adapts from D65 and converts to D50 CIELAB")
    func convertsRedToLab() throws {
        let lab = try core.analyze("#FF0000").labD50
        #expect(abs(lab.lightness - 54.2905) < 0.001)
        #expect(abs(lab.a - 80.8049) < 0.001)
        #expect(abs(lab.b - 69.8910) < 0.001)
    }

    @Test("sRGB red converts to published Oklab coordinates")
    func convertsRedToOKLab() throws {
        let lab = try core.analyze("#FF0000").okLab
        #expect(abs(lab.lightness - 0.6279554) < 0.000_001)
        #expect(abs(lab.a - 0.2248629) < 0.000_001)
        #expect(abs(lab.b - 0.1258460) < 0.000_001)
    }

    @Test("The same sRGB red receives different Display P3 components")
    func convertsRedToDisplayP3() throws {
        let p3 = try core.analyze("#FF0000").displayP3
        #expect(abs(p3.red - 0.9174876) < 0.000_001)
        #expect(abs(p3.green - 0.2002868) < 0.000_001)
        #expect(abs(p3.blue - 0.1385606) < 0.000_001)
    }

    @Test("Encoded sRGB gray remains achromatic in HSL")
    func convertsGrayToHSL() throws {
        let hsl = try core.analyze("#808080").hsl
        #expect(hsl.hue == 0)
        #expect(hsl.saturation == 0)
        #expect(abs(hsl.lightness - (128.0 / 255.0)) < 0.000_001)
        #expect(try core.analyze("#808080").okLCh.hue == nil)
    }

    @Test("Every conversion stage contains valid LaTeX and a spoken equivalent")
    func validatesConversionMath() throws {
        let analyses = [
            try core.analyze("#C58F63"),
            try core.analyze("rgb(50% 50% 50%)")
        ]

        let stages = analyses.flatMap { analysis in
            ConversionTargetID.allCases.flatMap { analysis.stages(for: $0) }
        }

        for stage in stages {
            let equation = try #require(stage.equationLaTeX)
            let substitution = try #require(stage.substitutionLaTeX)
            #expect(MathEquationValidator.errorDescription(in: equation) == nil)
            #expect(MathEquationValidator.errorDescription(in: substitution) == nil)
            #expect(!(stage.equationAccessibilityLabel ?? "").isEmpty)
            #expect(!(stage.substitutionAccessibilityLabel ?? "").isEmpty)
            #expect(!stage.whatChanges.isEmpty)
            #expect(!stage.whyItMatters.isEmpty)
            #expect(!stage.title.localizedCaseInsensitiveContains("Oklab"))
            #expect(stage.definitionIDs.allSatisfy { definitionID in
                ReferenceCatalog.concepts.contains { $0.id == definitionID }
            })
        }
    }

    @Test("Conversion routes follow the selected representation")
    func buildsTargetSpecificRoutes() throws {
        let analysis = try core.analyze("#C58F63")

        #expect(analysis.stages(for: .rgb).map(\.id) == ["notation-to-srgb", "serialize-rgb"])
        #expect(analysis.stages(for: .hexadecimal).map(\.id) == ["notation-to-srgb", "serialize-hex"])
        #expect(analysis.stages(for: .hsl).map(\.id) == ["notation-to-srgb", "srgb-to-hsl"])
        #expect(analysis.stages(for: .linearSRGB).last?.id == "srgb-to-linear")
        #expect(analysis.stages(for: .xyzD65).last?.id == "linear-to-xyz-d65")
        #expect(analysis.stages(for: .xyzD50).last?.id == "d65-to-d50")
        #expect(analysis.stages(for: .labD50).last?.id == "xyz-d50-to-lab")
        #expect(analysis.stages(for: .lchD50).last?.id == "lab-to-lch")
        #expect(analysis.stages(for: .okLab).last?.id == "xyz-d65-to-oklab")
        #expect(analysis.stages(for: .okLCh).last?.id == "oklab-to-oklch")
        #expect(analysis.stages(for: .displayP3).last?.id == "xyz-d65-to-display-p3")

        #expect(!analysis.stages(for: .okLab).contains { $0.id == "d65-to-d50" })
        #expect(analysis.stages(for: .labD50).contains { $0.id == "d65-to-d50" })
        #expect(Set(OutputRepresentation.allCases.map(\.conversionTarget)).count == OutputRepresentation.allCases.count)
    }
}

struct ColorMixerTests {
    private let mixer = ColorMixer()

    @Test("Encoded and linear-light mixing produce their published black-white midpoints")
    func blackWhiteMidpoints() {
        let black = SRGBColor(red: 0, green: 0, blue: 0)
        let white = SRGBColor(red: 1, green: 1, blue: 1)
        let comparison = mixer.compare(black, white, position: 0.5)

        #expect(comparison.encodedSRGB.red == 0.5)
        #expect(comparison.encodedSRGB.hex == "#808080")
        #expect(abs(comparison.linearSRGB.red - 0.735356983) < 0.000_001)
        #expect(comparison.linearSRGB.hex == "#BCBCBC")
    }

    @Test("Mix positions preserve both endpoints")
    func preservesEndpoints() {
        let first = SRGBColor(red: 0.15, green: 0.35, blue: 0.75)
        let second = SRGBColor(red: 0.8, green: 0.25, blue: 0.1)

        for space in ColorMixingSpace.allCases {
            #expect(mixer.mix(first, second, position: 0, in: space) == first)
            #expect(mixer.mix(first, second, position: 1, in: space) == second)
        }
    }

    @Test("Transparent endpoints are interpolated in premultiplied form")
    func premultipliesAlpha() {
        let transparentRed = SRGBColor(red: 1, green: 0, blue: 0, alpha: 0)
        let opaqueBlue = SRGBColor(red: 0, green: 0, blue: 1)
        let result = mixer.mix(
            transparentRed,
            opaqueBlue,
            position: 0.5,
            in: .encodedSRGB
        )

        #expect(result == SRGBColor(red: 0, green: 0, blue: 1, alpha: 0.5))
    }

    @Test("Mixing equations contain valid LaTeX and readable equivalents")
    func validatesMixingEquations() {
        #expect(MathEquationValidator.errorDescription(in: ColorMixingMath.encodedEquation) == nil)
        #expect(MathEquationValidator.errorDescription(in: ColorMixingMath.linearEquation) == nil)
        #expect(!ColorMixingMath.encodedReading.isEmpty)
        #expect(!ColorMixingMath.linearReading.isEmpty)
    }
}

struct SourceOverCompositorTests {
    private let compositor = SourceOverCompositor()

    @Test("Half-transparent blue over opaque red produces encoded sRGB purple")
    func knownSourceOverResult() throws {
        let result = try compositor.composite(
            source: SRGBColor(red: 0, green: 0, blue: 1, alpha: 0.5),
            overOpaque: SRGBColor(red: 1, green: 0, blue: 0)
        )

        #expect(result.result == SRGBColor(red: 0.5, green: 0, blue: 0.5))
        #expect(result.result.hex == "#800080")
        #expect(result.sourceContribution == 0.5)
        #expect(result.backdropContribution == 0.5)
    }

    @Test("Source-over preserves both opacity endpoints")
    func preservesOpacityEndpoints() throws {
        let source = SRGBColor(red: 0.2, green: 0.7, blue: 0.4)
        let backdrop = SRGBColor(red: 0.9, green: 0.1, blue: 0.3)

        let transparent = try compositor.composite(
            source: SRGBColor(red: source.red, green: source.green, blue: source.blue, alpha: 0),
            overOpaque: backdrop
        )
        let opaque = try compositor.composite(source: source, overOpaque: backdrop)

        #expect(transparent.result == backdrop)
        #expect(opaque.result == source)
    }

    @Test("Simple source-over lesson requires an opaque backdrop")
    func rejectsTranslucentBackdrop() {
        #expect(throws: AlphaCompositingError.backdropMustBeOpaque) {
            try compositor.composite(
                source: SRGBColor(red: 0, green: 0, blue: 1, alpha: 0.5),
                overOpaque: SRGBColor(red: 1, green: 0, blue: 0, alpha: 0.5)
            )
        }
    }

    @Test("Source-over equation is valid LaTeX with a readable equivalent")
    func validatesEquation() {
        #expect(MathEquationValidator.errorDescription(in: AlphaCompositingMath.opaqueBackdropEquation) == nil)
        #expect(!AlphaCompositingMath.opaqueBackdropReading.isEmpty)
    }
}

struct ReferenceCatalogTests {
    @Test("Reference terms have unique stable identifiers")
    func uniqueConceptIdentifiers() {
        let identifiers = ReferenceCatalog.concepts.map(\.id)
        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test("Every reference citation resolves through the evidence registry")
    func evidenceLinksResolve() {
        let evidenceIdentifiers = ReferenceCatalog.concepts.flatMap(\.evidenceIDs)
        #expect(evidenceIdentifiers.allSatisfy { EvidenceRegistry.record(withID: $0) != nil })
    }

    @Test("Reference topics cover every term exactly once")
    func topicCoverageIsComplete() {
        let catalogIdentifiers = ReferenceCatalog.concepts.map(\.id)
        let topicIdentifiers = ReferenceTopicID.allCases.flatMap(\.conceptIDs)

        #expect(topicIdentifiers.count == catalogIdentifiers.count)
        #expect(Set(topicIdentifiers).count == topicIdentifiers.count)
        #expect(Set(topicIdentifiers) == Set(catalogIdentifiers))
        #expect(ReferenceTopicID.allCases.allSatisfy { $0.concepts.count == $0.conceptIDs.count })
    }

    @Test("Reference search includes definitions and distinctions")
    func searchesMeaningNotOnlyTitles() {
        #expect(ReferenceCatalog.search("not cone responses").map(\.id) == ["cie-xyz"])
        #expect(ReferenceCatalog.search("lightness").count >= 3)
        #expect(ReferenceCatalog.search("  ") == ReferenceCatalog.concepts)
    }

    @Test("Reference equations are valid LaTeX with visible readings")
    func validatesReferenceEquations() {
        let equations = ReferenceCatalog.concepts.compactMap(\.equation)

        #expect(equations.count == 5)
        #expect(equations.allSatisfy { MathEquationValidator.errorDescription(in: $0.latex) == nil })
        #expect(equations.allSatisfy { !$0.title.isEmpty && !$0.reading.isEmpty })
    }

    @Test("Every representation definition resolves to the reference catalog")
    func representationDefinitionsResolve() {
        let identifiers = Set(ReferenceCatalog.concepts.map(\.id))
        #expect(OutputRepresentation.allCases.flatMap(\.definitionIDs).allSatisfy(identifiers.contains))
    }
}

struct ContrastCheckerTests {
    private let checker = WCAGContrastChecker()

    @Test("Opaque black and white produce the maximum WCAG ratio")
    func blackOnWhite() throws {
        let result = try checker.evaluate(
            foreground: SRGBColor(red: 0, green: 0, blue: 0),
            background: SRGBColor(red: 1, green: 1, blue: 1)
        )
        #expect(abs(result.ratio - 21) < 0.000_001)
        #expect(WCAGContrastCriterion.allCases.allSatisfy(result.passes))
    }

    @Test("Threshold decisions use the unrounded ratio")
    func doesNotRoundIntoPassing() throws {
        let gray = try ColorCore().analyze("#777777").parsed.color
        let white = try ColorCore().analyze("#FFFFFF").parsed.color
        let result = try checker.evaluate(foreground: gray, background: white)
        #expect(Format.decimal(result.ratio, places: 2) == "4.48")
        #expect(!result.passes(.normalTextAA))
        #expect(result.passes(.largeTextAA))
    }

    @Test("Displayed WCAG equations are valid LaTeX with spoken equivalents")
    func validatesContrastEquations() {
        #expect(MathEquationValidator.errorDescription(in: ContrastMath.relativeLuminanceEquation) == nil)
        #expect(MathEquationValidator.errorDescription(in: ContrastMath.ratioEquation) == nil)
        #expect(!ContrastMath.relativeLuminanceReading.isEmpty)
        #expect(!ContrastMath.ratioReading.isEmpty)
    }

    @Test("Translucent foreground is composited over the opaque background")
    func compositesForegroundAlpha() throws {
        let result = try checker.evaluate(
            foreground: SRGBColor(red: 0, green: 0, blue: 0, alpha: 0.5),
            background: SRGBColor(red: 1, green: 1, blue: 1)
        )
        #expect(result.effectiveForeground == SRGBColor(red: 0.5, green: 0.5, blue: 0.5))
        #expect(abs(result.ratio - 3.976653) < 0.000_001)
    }

    @Test("A translucent background requires another backdrop")
    func rejectsTranslucentBackground() {
        #expect(throws: ContrastCheckError.translucentBackground) {
            try checker.evaluate(
                foreground: SRGBColor(red: 0, green: 0, blue: 0),
                background: SRGBColor(red: 1, green: 1, blue: 1, alpha: 0.5)
            )
        }
    }
}

struct ColorReliancePreviewTests {
    private let previewer = ColorReliancePreviewer()
    private let converter = DefaultColorSpaceConverter()

    @Test("The neutral preview uses equal encoded channels and preserves relative luminance")
    func preservesRelativeLuminance() {
        let first = SRGBColor(red: 199.0 / 255, green: 70.0 / 255, blue: 105.0 / 255)
        let second = SRGBColor(red: 43.0 / 255, green: 140.0 / 255, blue: 130.0 / 255)
        let result = previewer.evaluate(first: first, second: second)

        #expect(result.firstNeutral.red == result.firstNeutral.green)
        #expect(result.firstNeutral.green == result.firstNeutral.blue)
        #expect(result.secondNeutral.red == result.secondNeutral.green)
        #expect(result.secondNeutral.green == result.secondNeutral.blue)
        #expect(abs(luminance(of: result.firstNeutral) - result.firstRelativeLuminance) < 0.000_000_1)
        #expect(abs(luminance(of: result.secondNeutral) - result.secondRelativeLuminance) < 0.000_000_1)
    }

    @Test("The neutral preview preserves black and white endpoints")
    func preservesEndpoints() {
        let black = SRGBColor(red: 0, green: 0, blue: 0)
        let white = SRGBColor(red: 1, green: 1, blue: 1)
        let result = previewer.evaluate(first: black, second: white)

        #expect(result.firstNeutral == black)
        #expect(result.secondNeutral == white)
        #expect(result.luminanceSeparation == 1)
    }

    @Test("The displayed neutral equation is valid LaTeX with a readable equivalent")
    func validatesNeutralEquation() {
        #expect(MathEquationValidator.errorDescription(in: ColorRelianceMath.neutralEquation) == nil)
        #expect(!ColorRelianceMath.neutralReading.isEmpty)
    }

    @Test("Check exposes four distinct analysis tasks")
    func exposesFourCheckTasks() {
        #expect(CheckAnalysisID.allCases.count == 4)
        #expect(Set(CheckAnalysisID.allCases.map(\.rawValue)).count == 4)
    }

    private func luminance(of color: SRGBColor) -> Double {
        converter.analyze(
            ParsedColor(
                originalRepresentation: color.hex,
                notation: "Test sRGB",
                notationID: .hexadecimal,
                colorSpace: .sRGB,
                color: color
            )
        ).relativeLuminance
    }
}

struct DisplayP3GamutTests {
    private let parser = DisplayP3Parser()
    private let analyzer = DisplayP3GamutAnalyzer()

    @Test("Display P3 input accepts CSS numbers and percentages")
    func parsesDisplayP3Input() throws {
        let numbers = try parser.parse("color(display-p3 1 0.2 0.1)")
        let percentages = try parser.parse("100% 20% 10%")

        #expect(numbers == DisplayP3Color(red: 1, green: 0.2, blue: 0.1))
        #expect(percentages == numbers)
    }

    @Test("Focused Display P3 input rejects values outside its source gamut")
    func rejectsOutOfRangeSource() {
        #expect(throws: DisplayP3ParseError.componentOutOfRange("1.1")) {
            try parser.parse("color(display-p3 1.1 0 0)")
        }
        #expect(throws: DisplayP3ParseError.invalidSyntax) {
            try parser.parse("color(display-p3 1 0 0 / 0.5)")
        }
    }

    @Test("Display P3 primary red crosses the sRGB boundary and clips to sRGB red")
    func findsOutOfGamutPrimary() {
        let result = analyzer.evaluate(DisplayP3Color(red: 1, green: 0, blue: 0))

        #expect(!result.isInSRGBGamut)
        #expect(result.encodedSRGB.red > 1)
        #expect(result.encodedSRGB.green < 0)
        #expect(result.encodedSRGB.blue < 0)
        #expect(result.clippedSRGB == SRGBColor(red: 1, green: 0, blue: 0))
        #expect(result.clippedChannelCount == 3)
    }

    @Test("A neutral Display P3 coordinate remains inside sRGB")
    func keepsNeutralInGamut() {
        let result = analyzer.evaluate(DisplayP3Color(red: 0.5, green: 0.5, blue: 0.5))

        #expect(result.isInSRGBGamut)
        #expect(abs(result.encodedSRGB.red - 0.5) < 0.000_000_001)
        #expect(abs(result.encodedSRGB.green - 0.5) < 0.000_000_001)
        #expect(abs(result.encodedSRGB.blue - 0.5) < 0.000_000_001)
        #expect(result.clippedChannelCount == 0)
    }

    @Test("Displayed gamut equations are valid LaTeX with readable equivalents")
    func validatesGamutEquations() {
        let equations = [
            GamutMath.p3ToXYZEquation,
            GamutMath.xyzToSRGBEquation,
            GamutMath.clippingEquation
        ]
        #expect(equations.allSatisfy { MathEquationValidator.errorDescription(in: $0) == nil })
        #expect(!GamutMath.p3ToXYZReading.isEmpty)
        #expect(!GamutMath.xyzToSRGBReading.isEmpty)
        #expect(!GamutMath.clippingReading.isEmpty)
    }
}

struct CIEDE2000DifferenceTests {
    private let calculator = CIEDE2000DifferenceCalculator()

    @Test("CIEDE2000 matches all 34 Sharma-Wu-Dalal supplemental pairs")
    func matchesSupplementalReferenceData() {
        let cases: [(LabColor, LabColor, Double)] = [
            (lab(50, 2.6772, -79.7751), lab(50, 0, -82.7485), 2.0425),
            (lab(50, 3.1571, -77.2803), lab(50, 0, -82.7485), 2.8615),
            (lab(50, 2.8361, -74.0200), lab(50, 0, -82.7485), 3.4412),
            (lab(50, -1.3802, -84.2814), lab(50, 0, -82.7485), 1.0000),
            (lab(50, -1.1848, -84.8006), lab(50, 0, -82.7485), 1.0000),
            (lab(50, -0.9009, -85.5211), lab(50, 0, -82.7485), 1.0000),
            (lab(50, 0, 0), lab(50, -1, 2), 2.3669),
            (lab(50, -1, 2), lab(50, 0, 0), 2.3669),
            (lab(50, 2.4900, -0.0010), lab(50, -2.4900, 0.0009), 7.1792),
            (lab(50, 2.4900, -0.0010), lab(50, -2.4900, 0.0010), 7.1792),
            (lab(50, 2.4900, -0.0010), lab(50, -2.4900, 0.0011), 7.2195),
            (lab(50, 2.4900, -0.0010), lab(50, -2.4900, 0.0012), 7.2195),
            (lab(50, -0.0010, 2.4900), lab(50, 0.0009, -2.4900), 4.8045),
            (lab(50, -0.0010, 2.4900), lab(50, 0.0010, -2.4900), 4.8045),
            (lab(50, -0.0010, 2.4900), lab(50, 0.0011, -2.4900), 4.7461),
            (lab(50, 2.5000, 0), lab(50, 0, -2.5000), 4.3065),
            (lab(50, 2.5000, 0), lab(73, 25, -18), 27.1492),
            (lab(50, 2.5000, 0), lab(61, -5, 29), 22.8977),
            (lab(50, 2.5000, 0), lab(56, -27, -3), 31.9030),
            (lab(50, 2.5000, 0), lab(58, 24, 15), 19.4535),
            (lab(50, 2.5000, 0), lab(50, 3.1736, 0.5854), 1.0000),
            (lab(50, 2.5000, 0), lab(50, 3.2972, 0), 1.0000),
            (lab(50, 2.5000, 0), lab(50, 1.8634, 0.5757), 1.0000),
            (lab(50, 2.5000, 0), lab(50, 3.2592, 0.3350), 1.0000),
            (lab(60.2574, -34.0099, 36.2677), lab(60.4626, -34.1751, 39.4387), 1.2644),
            (lab(63.0109, -31.0961, -5.8663), lab(62.8187, -29.7946, -4.0864), 1.2630),
            (lab(61.2901, 3.7196, -5.3901), lab(61.4292, 2.2480, -4.9620), 1.8731),
            (lab(35.0831, -44.1164, 3.7933), lab(35.0232, -40.0716, 1.5901), 1.8645),
            (lab(22.7233, 20.0904, -46.6940), lab(23.0331, 14.9730, -42.5619), 2.0373),
            (lab(36.4612, 47.8580, 18.3852), lab(36.2715, 50.5065, 21.2231), 1.4146),
            (lab(90.8027, -2.0831, 1.4410), lab(91.1528, -1.6435, 0.0447), 1.4441),
            (lab(90.9257, -0.5406, -0.9208), lab(88.6381, -0.8985, -0.7239), 1.5381),
            (lab(6.7747, -0.2908, -2.4247), lab(5.8714, -0.0985, -2.2286), 0.6377),
            (lab(2.0776, 0.0795, -1.1350), lab(0.9033, -0.0636, -0.5514), 0.9082)
        ]

        for (first, second, expected) in cases {
            let result = calculator.difference(between: first, and: second)
            #expect(abs(result - expected) < 0.000_05)
        }
    }

    @Test("CIEDE2000 is symmetric and zero for identical coordinates")
    func symmetryAndIdentity() {
        let first = lab(42.4, 17.2, -31.8)
        let second = lab(68.1, -4.6, 22.7)
        let forward = calculator.difference(between: first, and: second)
        let reverse = calculator.difference(between: second, and: first)
        #expect(abs(forward - reverse) < 0.000_000_000_1)
        #expect(calculator.difference(between: first, and: first) == 0)
    }

    @Test("Displayed CIEDE2000 equations are valid LaTeX with spoken equivalents")
    func validatesDifferenceEquations() {
        #expect(MathEquationValidator.errorDescription(in: ColorDifferenceMath.normalizedTermsEquation) == nil)
        #expect(MathEquationValidator.errorDescription(in: ColorDifferenceMath.combinationEquation) == nil)
        #expect(!ColorDifferenceMath.normalizedTermsReading.isEmpty)
        #expect(!ColorDifferenceMath.combinationReading.isEmpty)
    }

    private func lab(_ lightness: Double, _ a: Double, _ b: Double) -> LabColor {
        LabColor(lightness: lightness, a: a, b: b)
    }
}

struct InterfacePaletteEvaluatorTests {
    private let evaluator = InterfacePaletteEvaluator()

    @Test("Starter palettes meet the three relationships they are designed to demonstrate")
    func starterPalettesMeetNamedRelationships() {
        for preset in InterfacePalettePreset.allCases {
            let results = evaluator.evaluate(preset.palette)
            #expect(results.count == 3)
            #expect(results.allSatisfy { $0.passes })
        }
    }

    @Test("Palette checks keep text and non-text thresholds distinct")
    func usesRelationshipSpecificCriteria() {
        let results = evaluator.evaluate(InterfacePalettePreset.light.palette)
        #expect(results.first { $0.id == .bodyText }?.criterion == .normalTextAA)
        #expect(results.first { $0.id == .accentText }?.criterion == .normalTextAA)
        #expect(results.first { $0.id == .accentCue }?.criterion == .nonTextAA)
    }

    @Test("Higher-contrast text chooses between exact black and white results")
    func choosesHigherContrastText() {
        let white = SRGBColor(red: 1, green: 1, blue: 1)
        let black = SRGBColor(red: 0, green: 0, blue: 0)
        #expect(evaluator.higherContrastText(on: white) == black)
        #expect(evaluator.higherContrastText(on: black) == white)
    }

    @Test("Palette export uses stable role names and exact HEX values")
    func exportsCSSCustomProperties() {
        let export = InterfacePalettePreset.light.palette.cssCustomProperties
        #expect(export.contains("--color-canvas: #F7F4EE;"))
        #expect(export.contains("--color-text: #202124;"))
        #expect(export.contains("--color-accent: #176B5B;"))
        #expect(export.contains("--color-accent-text: #FFFFFF;"))
    }
}

struct CodeExportTests {
    @Test("Adaptive CSS exports distinct light and dark role sets")
    func adaptiveAppearanceCSS() {
        let value = ColorCodeExporter.adaptiveCSS(
            light: InterfacePalettePreset.light.palette,
            dark: InterfacePalettePreset.dark.palette
        )

        #expect(value.contains(":root {"))
        #expect(value.contains("@media (prefers-color-scheme: dark)"))
        #expect(value.contains(InterfacePalettePreset.light.palette.background.hex))
        #expect(value.contains(InterfacePalettePreset.dark.palette.background.hex))
        #expect(value.components(separatedBy: "--color-canvas:").count == 3)
    }

    private let color = SRGBColor(
        red: 197.0 / 255,
        green: 143.0 / 255,
        blue: 99.0 / 255,
        alpha: 0.5
    )

    @Test("Color export offers stable snippets for every supported language")
    func exportsColorForEveryLanguage() {
        #expect(CodeExportLanguage.allCases == [.css, .swift, .javascript, .python, .r, .json])

        for language in CodeExportLanguage.allCases {
            let value = ColorCodeExporter.colorSnippet(
                color: color,
                cssValue: color.cssRGB,
                language: language
            )
            #expect(!value.isEmpty)
        }

        #expect(
            ColorCodeExporter.colorSnippet(
                color: color,
                cssValue: color.cssRGB,
                language: .r
            ) == "color <- rgb(197, 143, 99, alpha = 128, maxColorValue = 255)"
        )
    }

    @Test("Palette exports preserve the same role names and values across languages")
    func exportsPaletteRoles() {
        let palette = InterfacePalettePreset.light.palette
        for language in CodeExportLanguage.allCases {
            let value = ColorCodeExporter.paletteSnippet(palette, language: language)
            #expect(value.contains("canvas"))
            #expect(value.contains("#F7F4EE"))
            #expect(value.contains("accent"))
        }
    }
}

struct LearningLessonTests {
    @Test("The lesson library has unique, usable destinations")
    func lessonLibraryDestinations() {
        #expect(LearningLessonID.allCases.count == 4)
        #expect(Set(LearningLessonID.allCases.map(\.rawValue)).count == LearningLessonID.allCases.count)
        #expect(LearningLessonID.allCases.allSatisfy { !$0.title.isEmpty && !$0.summary.isEmpty })
    }

    @Test("The first relationship example separates color difference from text contrast")
    func relationshipExampleMakesTheDistinctionVisible() throws {
        let colors = LearningRelationshipExample.differentHueSimilarLightness.colors
        let contrast = try WCAGContrastChecker().evaluate(
            foreground: colors.0,
            background: colors.1
        )
        let core = ColorCore()
        let difference = CIEDE2000DifferenceCalculator().evaluate(
            reference: try core.analyze(colors.0.hex).labD50,
            sample: try core.analyze(colors.1.hex).labD50
        )

        #expect(contrast.ratio < 3)
        #expect(difference.deltaE00 > 20)
    }

    @Test("The surroundings lesson keeps both targets numerically identical")
    func surroundingsExampleKeepsTargetFixed() throws {
        let example = SurroundingsLessonExample.self
        let firstTarget = example.target
        let secondTarget = example.target

        #expect(firstTarget == secondTarget)
        #expect(firstTarget.hex == "#808080")
        #expect(example.darkSurround != example.lightSurround)

        let core = ColorCore()
        #expect(try core.analyze(firstTarget.hex).labD50 == core.analyze(secondTarget.hex).labD50)
    }

    @Test("The gamut lesson example crosses the sRGB boundary before mapping")
    func gamutExampleCrossesDestinationBoundary() {
        let result = GamutLessonExample.evaluation

        #expect(result.source == GamutLessonExample.source)
        #expect(!result.isInSRGBGamut)
        #expect(result.clippedChannelCount == 3)
        #expect(result.clippedSRGB == SRGBColor(red: 1, green: 0, blue: 0))
        #expect(GamutLessonExample.sameComponentsInSRGB != result.clippedSRGB)
    }
}

struct ExploreExperimentTests {
    @Test("The Explore library has distinct experiments with scannable descriptions")
    func experimentLibraryDestinations() {
        #expect(ExploreExperimentID.allCases.count == 2)
        #expect(Set(ExploreExperimentID.allCases.map(\.rawValue)).count == ExploreExperimentID.allCases.count)
        #expect(ExploreExperimentID.allCases.allSatisfy { !$0.title.isEmpty && !$0.summary.isEmpty })
    }

    @Test("A partly transparent source changes across the default backdrop pair")
    func transparentSourceDependsOnBackdrop() throws {
        let source = SRGBColor(red: 197.0 / 255, green: 143.0 / 255, blue: 99.0 / 255, alpha: 0.55)
        let firstBackdrop = SRGBColor(red: 250.0 / 255, green: 250.0 / 255, blue: 248.0 / 255)
        let secondBackdrop = SRGBColor(red: 24.0 / 255, green: 36.0 / 255, blue: 51.0 / 255)
        let compositor = SourceOverCompositor()

        let first = try compositor.composite(source: source, overOpaque: firstBackdrop).result
        let second = try compositor.composite(source: source, overOpaque: secondBackdrop).result

        #expect(first != second)
        #expect(first.hex == "#DDBFA6")
        #expect(second.hex == "#775F4D")
    }
}

struct HelpTopicTests {
    @Test("Help topics are distinct and searchable by the tasks they explain")
    func helpTopicsCoverTaskLanguage() {
        #expect(HelpTopic.allCases.count == 7)
        #expect(Set(HelpTopic.allCases.map(\.rawValue)).count == HelpTopic.allCases.count)
        #expect(HelpTopic.allCases.allSatisfy { !$0.summary.isEmpty })
        #expect(HelpTopic.allCases.filter { $0.matches("screen") }.contains(.inspect))
        #expect(HelpTopic.allCases.filter { $0.matches("dark mode") } == [.appearances])
        #expect(HelpTopic.allCases.filter { $0.matches("privacy") } == [.ollama])
        #expect(HelpTopic.allCases.filter { $0.matches("custom text") } == [.ollama])
        #expect(HelpTopic.allCases.filter { $0.matches("contrast") } == [.appearances, .results])
        #expect(HelpTopic.allCases.filter { $0.matches("reset") } == [.reset])
    }
}

struct AccessibilityDesignTests {
    @Test("The app exposes a release version and distinct workspace icon identities")
    func exposesVersionAndIconIdentities() {
        #expect(AppVersionInfo.formatted(shortVersion: "1.0.0", build: "1") == "Version 1.0.0 (1)")
        #expect(Set(AppSection.allCases.map(\.designedIconMotif)).count == AppSection.allCases.count)
    }

    @Test("The walkthrough uses distinct consumable steps")
    func walkthroughSteps() {
        #expect(WalkthroughStep.all.count == 7)
        #expect(Set(WalkthroughStep.all.map(\.id)).count == WalkthroughStep.all.count)
        #expect(WalkthroughStep.all.allSatisfy {
            !$0.title.isEmpty && !$0.summary.isEmpty && $0.points.count == 3
        })
    }

    @Test("Edit commands use the standard macOS responder actions")
    func editCommandSelectors() {
        #expect(AppTextEditingAction.cut.selector == #selector(NSText.cut(_:)))
        #expect(AppTextEditingAction.copy.selector == #selector(NSText.copy(_:)))
        #expect(AppTextEditingAction.paste.selector == #selector(NSText.paste(_:)))
        #expect(AppTextEditingAction.pasteAsPlainText.selector == #selector(NSTextView.pasteAsPlainText(_:)))
        #expect(AppTextEditingAction.delete.selector == #selector(NSText.delete(_:)))
        #expect(AppTextEditingAction.selectAll.selector == #selector(NSText.selectAll(_:)))
    }

    @Test("Every app-owned scene has one unique single-instance window identity")
    func singleInstanceWindowIdentities() {
        #expect(Set(AppWindowID.singleInstanceIDs).count == AppWindowID.singleInstanceIDs.count)
        #expect(AppWindowID.singleInstanceIDs.contains(AppWindowID.main))
        #expect(AppWindowID.singleInstanceIDs.contains(AppWindowID.walkthrough))
        #expect(AppWindowID.singleInstanceIDs.contains(AppWindowID.definition))
    }

    @Test("Window continuity uses stable sanitized autosave names")
    func windowAutosaveNames() {
        #expect(AppWindowContinuity.autosaveName(for: "Color Inspector") == "OnColorTheory.color-inspector")
        #expect(AppWindowContinuity.autosaveName(for: "definition-CIE L*a*b*") == "OnColorTheory.definition-cie-l-a-b-")
    }

    @Test("The frame key prefix matches the names windows are actually saved under")
    func windowFrameKeyPrefixMatchesAutosaveNames() {
        // Resetting preferences finds saved frames by prefix. Should this
        // prefix and the autosave name disagree, the reset silently clears
        // nothing and every window reopens at its old position.
        let autosaveName = AppWindowContinuity.autosaveName(for: AppWindowID.main)
        let frameKey = "NSWindow Frame " + autosaveName
        #expect(frameKey.hasPrefix(AppWindowContinuity.frameKeyPrefix))
    }

    @Test("Every workspace belongs to a group and carries a question and a first step")
    func sectionWayfinding() {
        for section in AppSection.allCases where section != .home {
            #expect(section.group != nil)
            #expect(!section.question.isEmpty)
            #expect(!section.firstStep.isEmpty)
            #expect(!section.summary.isEmpty)
        }
        // Home is the router, so it sits outside both groups rather than
        // inside one of them.
        #expect(AppSection.home.group == nil)
    }

    @Test("The two groups partition every workspace exactly once")
    func sectionGroupsPartition() {
        let grouped = AppSection.Group.allCases.flatMap { group in
            AppSection.allCases.filter { $0.group == group }
        }
        let expected = AppSection.allCases.filter { $0 != .home }
        #expect(grouped.count == expected.count)
        #expect(Set(grouped) == Set(expected))
    }

    @Test("Each workspace question is distinct, so no two cards read alike")
    func sectionQuestionsAreDistinct() {
        let questions = AppSection.allCases.map(\.question)
        #expect(Set(questions).count == questions.count)
    }

    @Test("About is a single-instance window and its links are well formed")
    func aboutWindowIdentity() {
        #expect(AppWindowID.singleInstanceIDs.contains(AppWindowID.about))
        #expect(AppVersionInfo.releasesURL.absoluteString.hasSuffix("/releases"))
        #expect(AppVersionInfo.releasesURL.host() == "github.com")
        #expect(AppVersionInfo.repositoryURL.host() == "github.com")
        #expect(AppVersionInfo.attribution.contains("Abhik Roy"))
        #expect(AppVersionInfo.license.contains("PolyForm Noncommercial License 1.0.0"))
    }

    @Test("The framework audit profile activates every supported appearance preference")
    func frameworkAuditPreferences() {
        let preferences = AppAccessibilityPreferences.frameworkAudit
        #expect(preferences.increasedContrast)
        #expect(preferences.differentiateWithoutColor)
        #expect(preferences.reduceMotion)
        #expect(preferences.reduceTransparency)
        #expect(preferences != .standard)
    }

    @Test("Appearance and interface cue preferences expose explicit persisted choices")
    func appearancePreferences() {
        #expect(AppAppearanceMode.allCases == [.system, .light, .dark])
        #expect(AppColorVisionPalette.allCases.count == 6)
        #expect(AppColorVisionPalette.allCases.allSatisfy { !$0.title.isEmpty && !$0.explanation.isEmpty })
        #expect(AppAppearanceMode.system.preferredColorScheme == nil)
        #expect(AppAppearanceMode.light.preferredColorScheme == .light)
        #expect(AppAppearanceMode.dark.preferredColorScheme == .dark)
    }
}

@MainActor
struct ApplicationResetTests {
    @Test("Registered and reset appearance defaults use Dark")
    func darkAppearanceIsTheDefault() throws {
        let suiteName = "OnColorTheory.Defaults." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        ApplicationDefaults.register(in: defaults)
        #expect(defaults.string(forKey: AppPreferenceKeys.appearance) == AppAppearanceMode.dark.rawValue)

        defaults.set(AppAppearanceMode.light.rawValue, forKey: AppPreferenceKeys.appearance)
        defaults.set("saved frame", forKey: "NSWindow Frame OnColorTheory.main")
        ApplicationDefaults.reset(in: defaults, showInitialWalkthrough: false)

        #expect(defaults.string(forKey: AppPreferenceKeys.appearance) == AppAppearanceMode.dark.rawValue)
        #expect(defaults.bool(forKey: AppPreferenceKeys.completedInitialWalkthrough))
        #expect(defaults.object(forKey: "NSWindow Frame OnColorTheory.main") == nil)

        ApplicationDefaults.reset(in: defaults, showInitialWalkthrough: true)
        #expect(!defaults.bool(forKey: AppPreferenceKeys.completedInitialWalkthrough))
    }

    @Test("Reset clears app-owned work while preserving the requested walkthrough state")
    func resetsAppOwnedState() throws {
        let suiteName = "OnColorTheory.AppReset." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let trayURL = temporaryDirectory.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let ollama = OllamaController(defaults: defaults)
        let model = AppModel(
            tray: ColorTrayStore(fileURL: trayURL),
            sessionStore: .ephemeral(),
            ollama: ollama,
            defaults: defaults
        )
        model.updateRepresentation("#123456")
        model.selectedSection = .build
        model.addColorToTray(
            SRGBColor(red: 0.2, green: 0.4, blue: 0.6),
            label: "Saved color",
            source: "Test"
        )
        ollama.isEnabled = true
        ollama.connectionMode = .external
        ollama.externalAddress = "https://example.com"
        defaults.set(AppAppearanceMode.light.rawValue, forKey: AppPreferenceKeys.appearance)

        model.resetToDefaults(showInitialWalkthrough: false)

        #expect(model.selectedSection == .home)
        #expect(model.analysis.parsed.color.hex == "#C58F63")
        #expect(model.resumableSection == nil)
        #expect(model.tray.colors.isEmpty)
        #expect(!ollama.isEnabled)
        #expect(ollama.connectionMode == .guidedLocal)
        #expect(ollama.externalAddress == "http://127.0.0.1:11434")
        #expect(defaults.string(forKey: AppPreferenceKeys.appearance) == AppAppearanceMode.dark.rawValue)
        #expect(defaults.bool(forKey: AppPreferenceKeys.completedInitialWalkthrough))
    }

    @Test("Local cleanup targets only the standard Ollama locations")
    func localCleanupTargets() {
        let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)
        let modelDirectory = LocalOllamaAssets.modelDirectoryCandidate(homeDirectory: home)

        #expect(modelDirectory.path == "/Users/example/.ollama/models")
        #expect(LocalOllamaAssets.applicationCandidates.count == 2)
        #expect(LocalOllamaAssets.applicationCandidates.allSatisfy { $0.lastPathComponent == "Ollama.app" })
    }
}

struct WorkspaceSessionMigrationTests {
    @Test("Custom palette preview copy persists with the Build workspace")
    func persistsPalettePreviewCopy() {
        let customCopy = PalettePreviewCopy(
            title: "A custom heading",
            bodyText: "A paragraph supplied by the person testing this palette.",
            cueTitle: "Important cue",
            cueDetail: "Supporting information remains visible here.",
            actionTitle: "Take action"
        )
        var session = WorkspaceSession()
        session.buildPreviewCopy = customCopy
        let store = WorkspaceSessionStore.ephemeral()

        store.save(session)

        #expect(store.load().buildPreviewCopy == customCopy)
    }

    @Test("Build 018 sessions migrate to the current schema without losing work")
    func migratesVersionOneSession() throws {
        let suiteName = "OnColorTheory.SessionMigration." + UUID().uuidString
        let key = "session"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var oldSession = WorkspaceSession()
        oldSession.schemaVersion = 1
        oldSession.convertInput = "#123456"
        oldSession.buildLightPalette = nil
        oldSession.buildDarkPalette = nil
        defaults.set(try JSONEncoder().encode(oldSession), forKey: key)

        let store = WorkspaceSessionStore(defaults: defaults, key: key)
        let result = store.loadResult()

        #expect(result.migratedFromVersion == 1)
        #expect(result.recoveryIssue == nil)
        #expect(result.session.schemaVersion == WorkspaceSession.currentSchemaVersion)
        #expect(result.session.convertInput == "#123456")
        #expect(result.session.buildLightPalette == InterfacePalettePreset.light.palette)
        #expect(result.session.buildDarkPalette == InterfacePalettePreset.dark.palette)
        #expect(store.load().schemaVersion == WorkspaceSession.currentSchemaVersion)
    }

    @Test("Unreadable saved state opens fresh and preserves a recovery copy")
    func recoversFromCorruptedSession() throws {
        let suiteName = "OnColorTheory.SessionCorruption." + UUID().uuidString
        let key = "session"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data("not-json".utf8), forKey: key)

        let store = WorkspaceSessionStore(defaults: defaults, key: key)
        let result = store.loadResult()

        #expect(result.session == WorkspaceSession())
        #expect(result.recoveryIssue == .unreadableSavedState)
        #expect(store.hasRecoveryCopy)
        #expect(store.load().schemaVersion == WorkspaceSession.currentSchemaVersion)
    }

    @Test("Oversized saved workspace data is rejected before decoding")
    func rejectsOversizedWorkspaceData() throws {
        let suiteName = "OnColorTheory.SessionSizeLimit." + UUID().uuidString
        let key = "session"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data(count: (2 * 1_024 * 1_024) + 1), forKey: key)

        let result = WorkspaceSessionStore(defaults: defaults, key: key).loadResult()

        #expect(result.session == WorkspaceSession())
        #expect(result.recoveryIssue == .unreadableSavedState)
    }

    @Test("Newer saved state is not interpreted by an older schema")
    func protectsNewerSchema() throws {
        let suiteName = "OnColorTheory.SessionFuture." + UUID().uuidString
        let key = "session"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var future = WorkspaceSession()
        future.schemaVersion = WorkspaceSession.currentSchemaVersion + 5
        future.convertInput = "#ABCDEF"
        defaults.set(try JSONEncoder().encode(future), forKey: key)

        let store = WorkspaceSessionStore(defaults: defaults, key: key)
        let result = store.loadResult()

        #expect(result.recoveryIssue == .newerSavedState(version: WorkspaceSession.currentSchemaVersion + 5))
        #expect(result.session.convertInput == WorkspaceSession().convertInput)
        #expect(store.hasRecoveryCopy)
        #expect(store.load().schemaVersion == WorkspaceSession.currentSchemaVersion)
    }
}

@MainActor
struct VisualCompositionTests {
    @Test("Primary screens render at the default window size")
    func rendersPrimaryScreens() throws {
        FontRegistrar.registerBundledFonts()
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let trayURL = temporaryDirectory.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let model = AppModel(tray: ColorTrayStore(fileURL: trayURL))
        let outputDirectory = ProcessInfo.processInfo.environment["COLOR_SCIENCE_SNAPSHOT_DIR"]

        let shell = try renderShell(model: model)
        #expect(!shell.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try shell.write(
                to: directoryURL.appendingPathComponent("app-shell.png"),
                options: .atomic
            )
        }

        for section in [AppSection.home, .learn, .explore, .convert, .build, .check, .reference] {
            model.selectedSection = section
            let data = try render(section: section, model: model, textScale: 1)
            #expect(!data.isEmpty)

            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                try data.write(
                    to: directoryURL.appendingPathComponent("\(section.rawValue.lowercased()).png"),
                    options: .atomic
                )
            }
        }

        model.selectedSection = .reference
        model.selectedSection = .home
        for paletteChoice in AppColorVisionPalette.allCases {
            for colorScheme in [ColorScheme.light, .dark] {
                let data = try render(
                    section: .home,
                    model: model,
                    textScale: 1,
                    colorScheme: colorScheme,
                    paletteChoice: paletteChoice
                )
                #expect(!data.isEmpty)

                if let outputDirectory {
                    let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                    let appearance = colorScheme == .dark ? "dark" : "light"
                    try data.write(
                        to: directoryURL.appendingPathComponent(
                            "home-resume-palette-\(paletteChoice.rawValue)-\(appearance).png"
                        ),
                        options: .atomic
                    )
                }
            }
        }

        for section in [AppSection.home, .learn, .explore, .convert, .build, .check, .reference] {
            let data = try render(section: section, model: model, textScale: 1.6)
            #expect(!data.isEmpty)

            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try data.write(
                    to: directoryURL.appendingPathComponent("\(section.rawValue.lowercased())-large-text.png"),
                    options: .atomic
                )
            }
        }

        for section in [AppSection.home, .learn, .explore, .convert, .build, .check, .reference] {
            let data = try render(
                section: section,
                model: model,
                textScale: 1,
                colorScheme: .dark
            )
            #expect(!data.isEmpty)

            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try data.write(
                    to: directoryURL.appendingPathComponent("\(section.rawValue.lowercased())-dark.png"),
                    options: .atomic
                )
            }
        }

        for section in [AppSection.home, .learn, .explore, .convert, .build, .check, .reference] {
            for colorScheme in [ColorScheme.light, .dark] {
                let data = try render(
                    section: section,
                    model: model,
                    textScale: 1,
                    colorScheme: colorScheme,
                    accessibilityPreferences: .frameworkAudit
                )
                #expect(!data.isEmpty)

                if let outputDirectory {
                    let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                    let appearance = colorScheme == .dark ? "dark" : "light"
                    try data.write(
                        to: directoryURL.appendingPathComponent(
                            "\(section.rawValue.lowercased())-accessibility-\(appearance).png"
                        ),
                        options: .atomic
                    )
                }
            }
        }

        for lesson in LearningLessonID.allCases {
            for partIndex in 0..<3 {
                for configuration in [
                    (suffix: "", textScale: 1.0, colorScheme: ColorScheme.light),
                    (suffix: "-dark", textScale: 1.0, colorScheme: ColorScheme.dark),
                    (suffix: "-large-text", textScale: 1.6, colorScheme: ColorScheme.light)
                ] {
                    let data = try renderLearnPart(
                        model: model,
                        lesson: lesson,
                        partIndex: partIndex,
                        textScale: configuration.textScale,
                        colorScheme: configuration.colorScheme
                    )
                    #expect(!data.isEmpty)
                    if let outputDirectory {
                        let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                        try data.write(
                            to: directoryURL.appendingPathComponent(
                                "learn-\(lesson.rawValue)-part-\(partIndex + 1)\(configuration.suffix).png"
                            ),
                            options: .atomic
                        )
                    }
                }
            }

        }

        let accessibleLesson = try renderLearnPart(
            model: model,
            lesson: .colorSpaceLimits,
            partIndex: 1,
            textScale: 1,
            colorScheme: .light,
            accessibilityPreferences: .frameworkAudit
        )
        #expect(!accessibleLesson.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try accessibleLesson.write(
                to: directoryURL.appendingPathComponent("learn-color-space-limits-accessibility.png"),
                options: .atomic
            )
        }

        for textScale in [1.0, 1.6] {
            let data = try renderExploreComparison(model: model, textScale: textScale)
            #expect(!data.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                let suffix = textScale > 1 ? "-large-text" : ""
                try data.write(
                    to: directoryURL.appendingPathComponent("explore-comparison\(suffix).png"),
                    options: .atomic
                )
            }
        }

        let darkComparison = try renderExploreComparison(
            model: model,
            textScale: 1,
            colorScheme: .dark
        )
        #expect(!darkComparison.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try darkComparison.write(
                to: directoryURL.appendingPathComponent("explore-comparison-dark.png"),
                options: .atomic
            )
        }

        for configuration in [
            (suffix: "", textScale: 1.0, colorScheme: ColorScheme.light),
            (suffix: "-dark", textScale: 1.0, colorScheme: ColorScheme.dark),
            (suffix: "-large-text", textScale: 1.6, colorScheme: ColorScheme.light)
        ] {
            let data = try renderTransparencyObservation(
                model: model,
                textScale: configuration.textScale,
                colorScheme: configuration.colorScheme
            )
            #expect(!data.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try data.write(
                    to: directoryURL.appendingPathComponent(
                        "explore-transparency\(configuration.suffix).png"
                    ),
                    options: .atomic
                )
            }
        }

        for configuration in [
            (suffix: "", textScale: 1.0, colorScheme: ColorScheme.light),
            (suffix: "-dark", textScale: 1.0, colorScheme: ColorScheme.dark),
            (suffix: "-large-text", textScale: 1.6, colorScheme: ColorScheme.light)
        ] {
            let data = try renderReferenceReader(
                model: model,
                textScale: configuration.textScale,
                colorScheme: configuration.colorScheme
            )
            #expect(!data.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try data.write(
                    to: directoryURL.appendingPathComponent(
                        "reference-contrast-reader\(configuration.suffix).png"
                    ),
                    options: .atomic
                )
            }
        }

        let referenceTopic = try renderReferenceTopic(model: model)
        #expect(!referenceTopic.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try referenceTopic.write(
                to: directoryURL.appendingPathComponent("reference-measuring-topic.png"),
                options: .atomic
            )
        }

        let referenceLibrary = try renderReferenceLibrary(model: model)
        #expect(!referenceLibrary.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try referenceLibrary.write(
                to: directoryURL.appendingPathComponent("reference-library-full.png"),
                options: .atomic
            )
        }

        for configuration in [
            (name: "build-full", textScale: 1.0, colorScheme: ColorScheme.light),
            (name: "build-full-dark", textScale: 1.0, colorScheme: ColorScheme.dark),
            (name: "build-full-large-text", textScale: 1.6, colorScheme: ColorScheme.light)
        ] {
            let data = try renderBuild(
                model: model,
                textScale: configuration.textScale,
                colorScheme: configuration.colorScheme,
                page: .design
            )
            #expect(!data.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try data.write(
                    to: directoryURL.appendingPathComponent("\(configuration.name).png"),
                    options: .atomic
                )
            }
        }


        for page in PaletteStudioPage.allCases {
            let data = try renderBuild(
                model: model,
                textScale: 1,
                colorScheme: .light,
                page: page
            )
            #expect(!data.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try data.write(
                    to: directoryURL.appendingPathComponent("build-\(page.rawValue).png"),
                    options: .atomic
                )
            }
        }

        for analysis in CheckAnalysisID.allCases {
            for configuration in [
                (suffix: "", textScale: 1.0, colorScheme: ColorScheme.light),
                (suffix: "-dark", textScale: 1.0, colorScheme: ColorScheme.dark),
                (suffix: "-large-text", textScale: 1.6, colorScheme: ColorScheme.light)
            ] {
                let data = try renderCheck(
                    model: model,
                    analysis: analysis,
                    textScale: configuration.textScale,
                    colorScheme: configuration.colorScheme
                )
                #expect(!data.isEmpty)
                if let outputDirectory {
                    let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                    try data.write(
                        to: directoryURL.appendingPathComponent(
                            "check-\(analysis.rawValue)-full\(configuration.suffix).png"
                        ),
                        options: .atomic
                    )
                }
            }


            let methodData = try renderCheck(
                model: model,
                analysis: analysis,
                textScale: 1,
                colorScheme: .light,
                page: .method
            )
            #expect(!methodData.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try methodData.write(
                    to: directoryURL.appendingPathComponent("check-\(analysis.rawValue)-method.png"),
                    options: .atomic
                )
            }
        }

        let settings = try renderSettings()
        #expect(!settings.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try settings.write(
                to: directoryURL.appendingPathComponent("settings.png"),
                options: .atomic
            )
        }

        for configuration in [
            (name: "help-start", topic: HelpTopic.start, textScale: 1.0, colorScheme: ColorScheme.light, size: CGSize(width: 940, height: 720)),
            (name: "help-inspect", topic: HelpTopic.inspect, textScale: 1.0, colorScheme: ColorScheme.light, size: CGSize(width: 940, height: 720)),
            (name: "help-light-dark", topic: HelpTopic.appearances, textScale: 1.0, colorScheme: ColorScheme.dark, size: CGSize(width: 940, height: 760)),
            (name: "help-ollama", topic: HelpTopic.ollama, textScale: 1.0, colorScheme: ColorScheme.light, size: CGSize(width: 940, height: 800)),
            (name: "help-results", topic: HelpTopic.results, textScale: 1.0, colorScheme: ColorScheme.light, size: CGSize(width: 940, height: 760)),
            (name: "help-shortcuts-large-text", topic: HelpTopic.shortcuts, textScale: 1.6, colorScheme: ColorScheme.light, size: CGSize(width: 760, height: 1_000)),
            (name: "help-reset", topic: HelpTopic.reset, textScale: 1.0, colorScheme: ColorScheme.dark, size: CGSize(width: 940, height: 900))
        ] {
            let help = try renderHelp(
                model: model,
                topic: configuration.topic,
                textScale: configuration.textScale,
                colorScheme: configuration.colorScheme,
                size: configuration.size
            )
            #expect(!help.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try help.write(
                    to: directoryURL.appendingPathComponent("\(configuration.name).png"),
                    options: .atomic
                )
            }
        }

        for stepIndex in WalkthroughStep.all.indices {
            let walkthrough = try renderWalkthrough(
                model: model,
                step: stepIndex,
                textScale: 1,
                colorScheme: .dark,
                size: CGSize(width: 780, height: 680)
            )
            #expect(!walkthrough.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try walkthrough.write(
                    to: directoryURL.appendingPathComponent("walkthrough-step-\(stepIndex + 1).png"),
                    options: .atomic
                )
            }
        }

        let largeTextWalkthrough = try renderWalkthrough(
            model: model,
            step: 4,
            textScale: 1.6,
            colorScheme: .light,
            size: CGSize(width: 780, height: 820)
        )
        #expect(!largeTextWalkthrough.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try largeTextWalkthrough.write(
                to: directoryURL.appendingPathComponent("walkthrough-build-large-text.png"),
                options: .atomic
            )
        }

        for setupStep in OllamaSetupStep.allCases {
            let ollamaSetup = try renderOllamaSetup(model: model, step: setupStep)
            #expect(!ollamaSetup.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try ollamaSetup.write(
                    to: directoryURL.appendingPathComponent("ollama-setup-\(setupStep.rawValue).png"),
                    options: .atomic
                )
            }
        }

        let compactOllamaSetup = try renderOllamaSetup(
            model: model,
            step: .model,
            textScale: 1.6,
            colorScheme: .dark,
            size: CGSize(width: 680, height: 900)
        )
        #expect(!compactOllamaSetup.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try compactOllamaSetup.write(
                to: directoryURL.appendingPathComponent("ollama-setup-model-large-text-dark.png"),
                options: .atomic
            )
        }

        var invalidSession = WorkspaceSession()
        invalidSession.convertInput = "not-a-color"
        let recoveryModel = AppModel(
            tray: ColorTrayStore(fileURL: trayURL),
            sessionStore: .ephemeral(initialSession: invalidSession)
        )
        let recoveryHome = try render(section: .home, model: recoveryModel, textScale: 1)
        #expect(!recoveryHome.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try recoveryHome.write(
                to: directoryURL.appendingPathComponent("home-workspace-recovery.png"),
                options: .atomic
            )
        }

        let ollamaDefaultsName = "OnColorTheory.VisualOllama." + UUID().uuidString
        let ollamaDefaults = try #require(UserDefaults(suiteName: ollamaDefaultsName))
        defer { ollamaDefaults.removePersistentDomain(forName: ollamaDefaultsName) }
        let configuredOllama = OllamaController(defaults: ollamaDefaults, client: VisualOllamaClient())
        configuredOllama.isEnabled = true
        configuredOllama.selectedModel = "qwen3:4b"
        let recommendationModel = AppModel(
            tray: ColorTrayStore(fileURL: trayURL),
            sessionStore: .ephemeral(),
            ollama: configuredOllama
        )
        let privacyPreview = try renderBuild(
            model: recommendationModel,
            textScale: 1,
            colorScheme: .light,
            page: .recommend,
            showsRequestPreview: true
        )
        #expect(!privacyPreview.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try privacyPreview.write(
                to: directoryURL.appendingPathComponent("build-recommend-privacy-preview.png"),
                options: .atomic
            )
        }

        let examplePalette = InterfacePalettePreset.ocean.palette
        let exampleProposal = PaletteProposal(
            provider: PaletteModelIdentity(
                name: "Visual model",
                version: "1",
                license: "Test",
                runsLocally: true
            ),
            colors: [
                ProposedColor(color: examplePalette.background, rationale: "A quiet surface keeps longer passages comfortable to scan."),
                ProposedColor(color: examplePalette.text, rationale: "Deep text creates a clear reading hierarchy on the pale canvas."),
                ProposedColor(color: examplePalette.accent, rationale: "A focused blue-green cue draws attention without overwhelming the content."),
                ProposedColor(color: examplePalette.accentText, rationale: "Light lettering keeps actions distinct inside the stronger accent shape.")
            ],
            summary: "A calm reading palette with one clear action color and restrained supporting surfaces."
        )
        let recommendationResult = try renderBuild(
            model: recommendationModel,
            textScale: 1,
            colorScheme: .light,
            page: .recommend,
            initialRecommendation: exampleProposal,
            initialRecommendedPalette: examplePalette,
            initialPreviewCopy: PalettePreviewCopy(
                title: "Understand every color decision",
                bodyText: "Use this report to explain the palette in clear language and show how the reading experience holds together.",
                cueTitle: "Review before applying",
                cueDetail: "The labeled accent remains identifiable without relying on color alone.",
                actionTitle: "Review palette"
            )
        )
        #expect(!recommendationResult.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try recommendationResult.write(
                to: directoryURL.appendingPathComponent("build-recommend-result.png"),
                options: .atomic
            )
        }

        let accessibleCheck = try renderCheck(
            model: model,
            analysis: .gamut,
            textScale: 1,
            colorScheme: .light,
            accessibilityPreferences: .frameworkAudit
        )
        #expect(!accessibleCheck.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try accessibleCheck.write(
                to: directoryURL.appendingPathComponent("check-gamut-accessibility.png"),
                options: .atomic
            )
        }

        let trayFailureDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let blockedTrayParent = trayFailureDirectory.appendingPathComponent("not-a-directory")
        defer { try? FileManager.default.removeItem(at: trayFailureDirectory) }
        try FileManager.default.createDirectory(
            at: trayFailureDirectory,
            withIntermediateDirectories: true
        )
        try Data("blocking file".utf8).write(to: blockedTrayParent)
        let failingTray = ColorTrayStore(
            fileURL: blockedTrayParent.appendingPathComponent("tray.json")
        )
        let failingModel = AppModel(tray: failingTray)
        failingModel.addCurrentColorToTray()
        let trayFailure = try renderColorTray(model: failingModel, store: failingTray)
        #expect(!trayFailure.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try trayFailure.write(
                to: directoryURL.appendingPathComponent("color-tray-storage-error.png"),
                options: .atomic
            )
        }

        let uniqueStages = Dictionary(
            ConversionTargetID.allCases
                .flatMap { model.analysis.stages(for: $0) }
                .map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        .values
        .sorted { $0.id < $1.id }

        for stage in uniqueStages {
            for textScale in [1.0, 1.6] {
                let data = try renderEquationStage(stage, textScale: textScale)
                #expect(!data.isEmpty)

                if let outputDirectory {
                    let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                    let suffix = textScale > 1 ? "-large-text" : ""
                    try data.write(
                        to: directoryURL.appendingPathComponent("equation-\(stage.id)\(suffix).png"),
                        options: .atomic
                    )
                }
            }
        }

        for representation in [OutputRepresentation.rgb, .hsl, .displayP3, .okLab, .lab] {
            let stages = model.analysis.stages(for: representation.conversionTarget)
            let data = try renderConvert(
                model: model,
                representation: representation,
                stageIndex: stages.count - 1
            )
            #expect(!data.isEmpty)

            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try data.write(
                    to: directoryURL.appendingPathComponent("convert-\(representation.conversionTarget.rawValue)-final.png"),
                    options: .atomic
                )
            }
        }

        let fullConvert = try renderConvert(
            model: model,
            representation: .rgb,
            stageIndex: 0,
            height: 1_700
        )
        #expect(!fullConvert.isEmpty)
        if let outputDirectory {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try fullConvert.write(
                to: directoryURL.appendingPathComponent("convert-workspace-full.png"),
                options: .atomic
            )
        }
    }

    @Test("Color Inspector renders in light, dark, and enlarged-text states")
    func rendersColorInspectorStates() throws {
        FontRegistrar.registerBundledFonts()
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let trayURL = temporaryDirectory.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let model = AppModel(tray: ColorTrayStore(fileURL: trayURL))
        let outputDirectory = ProcessInfo.processInfo.environment["COLOR_SCIENCE_SNAPSHOT_DIR"]

        for configuration in [
            (suffix: "", textScale: 1.0, colorScheme: ColorScheme.light),
            (suffix: "-dark", textScale: 1.0, colorScheme: ColorScheme.dark),
            (suffix: "-large-text", textScale: 1.6, colorScheme: ColorScheme.light)
        ] {
            let inspector = try renderInspector(
                model: model,
                textScale: configuration.textScale,
                colorScheme: configuration.colorScheme
            )
            #expect(!inspector.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                try inspector.write(
                    to: directoryURL.appendingPathComponent(
                        "color-inspector\(configuration.suffix).png"
                    ),
                    options: .atomic
                )
            }
        }

        for page in [InspectorPage.measurements, .context] {
            let inspector = try renderInspector(
                model: model,
                textScale: 1,
                colorScheme: .light,
                page: page
            )
            #expect(!inspector.isEmpty)
            if let outputDirectory {
                let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
                try inspector.write(
                    to: directoryURL.appendingPathComponent("color-inspector-\(page.rawValue).png"),
                    options: .atomic
                )
            }
        }
    }

    private func renderShell(model: AppModel) throws -> Data {
        let size = CGSize(width: 1_220, height: 820)
        let hostingView = NSHostingView(
            rootView: AppShellView(model: model)
                .frame(width: size.width, height: size.height)
                .environment(\.colorScheme, .light)
        )
        hostingView.appearance = NSAppearance(named: .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func render(
        section: AppSection,
        model: AppModel,
        textScale: Double,
        colorScheme: ColorScheme = .light,
        accessibilityPreferences: AppAccessibilityPreferences = .standard,
        paletteChoice: AppColorVisionPalette = .system,
        size: CGSize = CGSize(width: 900, height: 760)
    ) throws -> Data {
        let content: AnyView
        switch section {
        case .home:
            content = AnyView(HomeView(model: model))
        case .learn:
            content = AnyView(LearnView(model: model))
        case .explore:
            content = AnyView(ExploreView(model: model))
        case .convert:
            content = AnyView(ConvertView(model: model))
        case .build:
            content = AnyView(BuildView(model: model))
        case .check:
            content = AnyView(CheckView(model: model))
        case .reference:
            content = AnyView(ReferenceView(model: model))
        }

        let hostingView = NSHostingView(
            rootView: content
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
                .environment(\.appAccessibilityPreferences, accessibilityPreferences)
                .environment(\.appSemanticPalette, paletteChoice.resolved(for: colorScheme))
                .tint(paletteChoice.resolved(for: colorScheme).accent)
        )
        hostingView.appearance = NSAppearance(
            named: appearanceName(for: colorScheme, preferences: accessibilityPreferences)
        )
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let imageRepresentation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: imageRepresentation)
        guard let data = imageRepresentation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderLearnPart(
        model: AppModel,
        lesson: LearningLessonID,
        partIndex: Int,
        textScale: Double,
        colorScheme: ColorScheme,
        accessibilityPreferences: AppAccessibilityPreferences = .standard
    ) throws -> Data {
        let size = CGSize(width: 900, height: textScale > 1 ? 3_000 : 1_500)
        let hostingView = NSHostingView(
            rootView: LearnView(
                model: model,
                initialLesson: lesson,
                initialPartIndex: partIndex
            )
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
                .environment(\.appAccessibilityPreferences, accessibilityPreferences)
        )
        hostingView.appearance = NSAppearance(
            named: appearanceName(for: colorScheme, preferences: accessibilityPreferences)
        )
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderEquationStage(
        _ stage: ConversionStage,
        textScale: Double
    ) throws -> Data {
        let size = CGSize(width: 760, height: textScale > 1 ? 1_250 : 900)
        let hostingView = NSHostingView(
            rootView: ConversionStageView(stage: stage, initialPage: .calculation)
                .padding(28)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, .light)
                .environment(\.appTextScale, textScale)
        )
        hostingView.appearance = NSAppearance(named: .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderExploreComparison(
        model: AppModel,
        textScale: Double,
        colorScheme: ColorScheme = .light
    ) throws -> Data {
        let size = CGSize(width: 1_100, height: textScale > 1 ? 3_650 : 2_050)
        let hostingView = NSHostingView(
            rootView: ExploreView(model: model, showsComparison: true)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
        )
        hostingView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let imageRepresentation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: imageRepresentation)
        guard let data = imageRepresentation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderTransparencyObservation(
        model: AppModel,
        textScale: Double,
        colorScheme: ColorScheme
    ) throws -> Data {
        let size = CGSize(width: 1_100, height: textScale > 1 ? 3_900 : 2_250)
        let hostingView = NSHostingView(
            rootView: TransparencyExperimentView(model: model, showsObservation: true)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
        )
        hostingView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let imageRepresentation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: imageRepresentation)
        guard let data = imageRepresentation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderReferenceReader(
        model: AppModel,
        textScale: Double,
        colorScheme: ColorScheme
    ) throws -> Data {
        let size = CGSize(width: 1_000, height: textScale > 1 ? 2_100 : 1_400)
        let hostingView = NSHostingView(
            rootView: ReferenceView(
                model: model,
                initialTopic: .comparisonAndAccessibility,
                initialConceptID: "wcag-contrast"
            )
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
        )
        hostingView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderReferenceTopic(model: AppModel) throws -> Data {
        let size = CGSize(width: 1_100, height: 1_650)
        let hostingView = NSHostingView(
            rootView: ReferenceView(model: model, initialTopic: .measuringColor)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, .light)
                .environment(\.appTextScale, 1)
        )
        hostingView.appearance = NSAppearance(named: .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderReferenceLibrary(model: AppModel) throws -> Data {
        let size = CGSize(width: 900, height: 1_200)
        let hostingView = NSHostingView(
            rootView: ReferenceView(model: model)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, .light)
                .environment(\.appTextScale, 1)
        )
        hostingView.appearance = NSAppearance(named: .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderConvert(
        model: AppModel,
        representation: OutputRepresentation,
        stageIndex: Int,
        height: CGFloat = 900
    ) throws -> Data {
        let size = CGSize(width: 1_100, height: height)
        let hostingView = NSHostingView(
            rootView: ConvertView(
                model: model,
                initialRepresentation: representation,
                initialStageIndex: stageIndex
            )
            .frame(width: size.width, height: size.height)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, .light)
            .environment(\.appTextScale, 1)
        )
        hostingView.appearance = NSAppearance(named: .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderBuild(
        model: AppModel,
        textScale: Double,
        colorScheme: ColorScheme,
        page: PaletteStudioPage = .design,
        showsRequestPreview: Bool = false,
        initialRecommendation: PaletteProposal? = nil,
        initialRecommendedPalette: InterfacePalette? = nil,
        initialPreviewCopy: PalettePreviewCopy? = nil
    ) throws -> Data {
        let size = CGSize(width: 1_100, height: textScale > 1 ? 3_900 : 2_250)
        let hostingView = NSHostingView(
            rootView: BuildView(
                model: model,
                initialPage: page,
                initialRequestPreview: showsRequestPreview,
                initialRecommendation: initialRecommendation,
                initialRecommendedPalette: initialRecommendedPalette,
                initialPreviewCopy: initialPreviewCopy
            )
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
        )
        hostingView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderCheck(
        model: AppModel,
        analysis: CheckAnalysisID,
        textScale: Double,
        colorScheme: ColorScheme,
        page: CheckWorkspacePage = .results,
        accessibilityPreferences: AppAccessibilityPreferences = .standard
    ) throws -> Data {
        model.selectedCheckAnalysis = analysis
        if analysis == .contrast {
            model.checkForegroundColor = try ColorCore().analyze("#C58F63").parsed.color
            model.checkBackgroundColor = try ColorCore().analyze("#FFFFFF").parsed.color
        } else if analysis == .difference {
            model.checkForegroundColor = try ColorCore().analyze("#2F6FED").parsed.color
            model.checkBackgroundColor = try ColorCore().analyze("#2F73E8").parsed.color
        } else if analysis == .colorReliance {
            model.checkForegroundColor = try ColorCore().analyze("#C74669").parsed.color
            model.checkBackgroundColor = try ColorCore().analyze("#2B8C82").parsed.color
        } else {
            model.checkDisplayP3Color = DisplayP3Color(red: 1, green: 0.2, blue: 0.1)
        }

        let height: CGFloat
        switch analysis {
        case .contrast:
            height = textScale > 1 ? 2_650 : 1_750
        case .difference:
            height = textScale > 1 ? 3_600 : 2_350
        case .gamut:
            height = textScale > 1 ? 4_900 : 3_100
        case .colorReliance:
            height = textScale > 1 ? 4_500 : 2_850
        }
        let size = CGSize(width: 1_100, height: height)
        let hostingView = NSHostingView(
            rootView: CheckView(model: model, initialPage: page)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
                .environment(\.appAccessibilityPreferences, accessibilityPreferences)
        )
        hostingView.appearance = NSAppearance(
            named: appearanceName(for: colorScheme, preferences: accessibilityPreferences)
        )
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderSettings() throws -> Data {
        let size = CGSize(width: 560, height: 610)
        let hostingView = NSHostingView(
            rootView: TypographySettingsView(model: AppModel())
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, .light)
                .environment(\.appTextScale, 1)
        )
        hostingView.appearance = NSAppearance(named: .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderOllamaSetup(
        model: AppModel,
        step: OllamaSetupStep = .welcome,
        textScale: Double = 1,
        colorScheme: ColorScheme = .light,
        size: CGSize = CGSize(width: 820, height: 680)
    ) throws -> Data {
        let hostingView = NSHostingView(
            rootView: OllamaSetupView(model: model, controller: model.ollama, initialStep: step)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
                .environment(\.appAccessibilityPreferences, .standard)
        )
        hostingView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderHelp(
        model: AppModel,
        topic: HelpTopic,
        textScale: Double,
        colorScheme: ColorScheme,
        size: CGSize
    ) throws -> Data {
        let palette = AppColorVisionPalette.system.resolved(for: colorScheme)
        let hostingView = NSHostingView(
            rootView: HelpView(model: model, initialTopic: topic)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
                .environment(\.appAccessibilityPreferences, .standard)
                .environment(\.appSemanticPalette, palette)
                .tint(palette.accent)
        )
        hostingView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderWalkthrough(
        model: AppModel,
        step: Int,
        textScale: Double,
        colorScheme: ColorScheme,
        size: CGSize
    ) throws -> Data {
        let palette = AppColorVisionPalette.system.resolved(for: colorScheme)
        let hostingView = NSHostingView(
            rootView: WalkthroughView(model: model, initialStep: step, recordsCompletion: false)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
                .environment(\.appAccessibilityPreferences, .standard)
                .environment(\.appSemanticPalette, palette)
                .tint(palette.accent)
        )
        hostingView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderInspector(
        model: AppModel,
        textScale: Double,
        colorScheme: ColorScheme,
        page: InspectorPage = .values
    ) throws -> Data {
        let size = CGSize(width: 380, height: 760)
        let palette = AppColorVisionPalette.system.resolved(for: colorScheme)
        let hostingView = NSHostingView(
            rootView: ColorInspectorView(model: model, initialPage: page)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, colorScheme)
                .environment(\.appTextScale, textScale)
                .environment(\.appAccessibilityPreferences, .standard)
                .environment(\.appSemanticPalette, palette)
                .tint(palette.accent)
        )
        hostingView.appearance = NSAppearance(
            named: colorScheme == .dark ? .darkAqua : .aqua
        )
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func renderColorTray(
        model: AppModel,
        store: ColorTrayStore
    ) throws -> Data {
        let size = CGSize(width: 390, height: 470)
        let hostingView = NSHostingView(
            rootView: ColorTrayView(model: model, store: store)
                .frame(width: size.width, height: size.height)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, .light)
                .environment(\.appTextScale, 1)
                .environment(\.appAccessibilityPreferences, .frameworkAudit)
        )
        hostingView.appearance = NSAppearance(named: .accessibilityHighContrastAqua)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.cannotCreateRepresentation
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.cannotEncodePNG
        }
        return data
    }

    private func appearanceName(
        for colorScheme: ColorScheme,
        preferences: AppAccessibilityPreferences
    ) -> NSAppearance.Name {
        if preferences.increasedContrast {
            return colorScheme == .dark
                ? .accessibilityHighContrastDarkAqua
                : .accessibilityHighContrastAqua
        }
        return colorScheme == .dark ? .darkAqua : .aqua
    }

    private enum SnapshotError: Error {
        case cannotCreateRepresentation
        case cannotEncodePNG
    }
}

@MainActor
struct AppModelInputTests {
    @Test("A custom Color Tray receives an isolated workspace session by default")
    func customTrayUsesEphemeralWorkspaceSession() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let firstTrayURL = temporaryDirectory.appendingPathComponent("first-tray.json")
        let secondTrayURL = temporaryDirectory.appendingPathComponent("second-tray.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let firstModel = AppModel(tray: ColorTrayStore(fileURL: firstTrayURL))
        firstModel.updateRepresentation("#123456")

        let secondModel = AppModel(tray: ColorTrayStore(fileURL: secondTrayURL))
        #expect(secondModel.analysis.parsed.color.hex == "#C58F63")
        #expect(secondModel.workspaceSession.lastWorkspaceRawValue == nil)
    }

    @Test("An explicitly shared workspace store restores a saved session")
    func explicitWorkspaceStoreRestoresSession() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let firstTrayURL = temporaryDirectory.appendingPathComponent("first-tray.json")
        let secondTrayURL = temporaryDirectory.appendingPathComponent("second-tray.json")
        let sessionStore = WorkspaceSessionStore.ephemeral()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let firstModel = AppModel(
            tray: ColorTrayStore(fileURL: firstTrayURL),
            sessionStore: sessionStore
        )
        firstModel.updateRepresentation("#123456")
        firstModel.selectedSection = .convert

        let secondModel = AppModel(
            tray: ColorTrayStore(fileURL: secondTrayURL),
            sessionStore: sessionStore
        )
        #expect(secondModel.analysis.parsed.color.hex == "#123456")
        #expect(secondModel.resumableSection == .convert)
    }

    @Test("The single Convert field detects HEX and RGB notation automatically")
    func detectsNotationAutomatically() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let trayURL = temporaryDirectory.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let model = AppModel(tray: ColorTrayStore(fileURL: trayURL))
        model.updateRepresentation("rgb(10 20 30)")
        #expect(model.inputNotation == .rgb)
        #expect(model.analysis.parsed.color.hex == "#0A141E")

        model.updateRepresentation("#336699")
        #expect(model.inputNotation == .hexadecimal)
        #expect(model.inputError == nil)
    }

    @Test("A sampled color becomes the working color without changing workspaces")
    func sampledColorUpdatesWorkingColor() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let trayURL = temporaryDirectory.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let model = AppModel(tray: ColorTrayStore(fileURL: trayURL))
        model.selectedSection = .learn
        model.setWorkingColor(SRGBColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.25))

        #expect(model.analysis.parsed.color.hex == "#33669940")
        #expect(model.analysis.parsed.color.alpha8 == 64)
        #expect(model.selectedSection == .learn)
    }

    @Test("System screen colors are normalized into sRGB values")
    func screenColorNormalization() throws {
        let source = NSColor(
            srgbRed: 51.0 / 255,
            green: 102.0 / 255,
            blue: 153.0 / 255,
            alpha: 0.5
        )
        let sampled = try #require(ScreenColorSampler.sRGBColor(from: source))

        #expect(sampled.red8 == 51)
        #expect(sampled.green8 == 102)
        #expect(sampled.blue8 == 153)
        #expect(sampled.alpha8 == 128)
    }

    @Test("Lesson handoff preserves the pair and requested Check analysis")
    func lessonHandoffOpensTheRequestedAnalysis() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let trayURL = temporaryDirectory.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let model = AppModel(tray: ColorTrayStore(fileURL: trayURL))
        let colors = LearningRelationshipExample.differentHueSimilarLightness.colors
        model.openInCheck(
            foreground: colors.0,
            background: colors.1,
            analysis: .difference
        )

        #expect(model.selectedSection == .check)
        #expect(model.selectedCheckAnalysis == .difference)
        #expect(model.checkForegroundColor == colors.0)
        #expect(model.checkBackgroundColor == colors.1)
    }

    @Test("Gamut lesson handoff preserves the Display P3 example")
    func gamutLessonHandoffPreservesSource() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let trayURL = temporaryDirectory.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let model = AppModel(tray: ColorTrayStore(fileURL: trayURL))
        model.openInGamutCheck(GamutLessonExample.source)

        #expect(model.checkDisplayP3Color == GamutLessonExample.source)
        #expect(model.selectedCheckAnalysis == .gamut)
        #expect(model.selectedSection == .check)
    }
}

@MainActor
struct TypographyTests {
    @Test("Bundled Atkinson font registers with Core Text")
    func registersBundledFont() {
        FontRegistrar.registerBundledFonts()
        let font = CTFontCreateWithName("Atkinson Hyperlegible Next" as CFString, 15, nil)
        let family = CTFontCopyFamilyName(font) as String
        #expect(family == "Atkinson Hyperlegible Next")
    }
}

@MainActor
struct ColorTrayStoreTests {
    @Test("Color Tray persists provenance and avoids accidental duplicates")
    func persistsRecords() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let color = try ColorCore().analyze("#336699")
        let record = ColorRecord(
            label: "Test color",
            originalRepresentation: "#336699",
            originalColorSpace: .sRGB,
            color: color.parsed.color,
            conversionHistory: color.stages.map(\.id),
            source: "Unit test"
        )

        let firstStore = ColorTrayStore(fileURL: fileURL)
        firstStore.add(record)
        firstStore.add(record)
        #expect(firstStore.colors.count == 1)

        let secondStore = ColorTrayStore(fileURL: fileURL)
        #expect(secondStore.colors.count == 1)
        #expect(secondStore.colors[0].source == "Unit test")
        #expect(secondStore.colors[0].conversionHistory == color.stages.map(\.id))
    }

    @Test("Oversized Color Tray files are not loaded into memory")
    func rejectsOversizedTrayFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(count: (5 * 1_024 * 1_024) + 1).write(to: fileURL)

        let store = ColorTrayStore(fileURL: fileURL)

        #expect(store.colors.isEmpty)
        #expect(store.persistenceError?.contains("could not be read") == true)
    }

    @Test("Color Tray reports a save failure without discarding the in-memory color")
    func reportsPersistenceFailure() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let blockedParent = directory.appendingPathComponent("not-a-directory")
        let fileURL = blockedParent.appendingPathComponent("tray.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("blocking file".utf8).write(to: blockedParent)

        let color = try ColorCore().analyze("#336699")
        let record = ColorRecord(
            label: "Unsaved color",
            originalRepresentation: "#336699",
            originalColorSpace: .sRGB,
            color: color.parsed.color,
            conversionHistory: [],
            source: "Unit test"
        )

        let store = ColorTrayStore(fileURL: fileURL)
        store.add(record)

        #expect(store.colors == [record])
        #expect(store.persistenceError != nil)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))

        store.dismissPersistenceError()
        #expect(store.persistenceError == nil)

        let resetPersisted = store.removeAll()
        #expect(!resetPersisted)
        #expect(store.colors.isEmpty)
        #expect(store.persistenceError != nil)
    }
}

private struct VisualOllamaClient: OllamaRequesting {
    func serverVersion(at baseURL: URL) async throws -> String? { "0.12.0" }
    func listModels(at baseURL: URL) async throws -> [OllamaModelInfo] { [] }
    func pullModel(named model: String, at baseURL: URL) async throws {}
    func deleteModel(named model: String, at baseURL: URL) async throws {}
    func generateStructuredPalette(model: String, prompt: String, at baseURL: URL) async throws -> String { "" }
}
