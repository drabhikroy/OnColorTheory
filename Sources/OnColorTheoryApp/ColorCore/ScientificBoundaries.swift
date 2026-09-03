import Foundation

/// Reports whether a color survives conversion into a narrower space.
protocol GamutAnalyzing: Sendable {
    func evaluate(_ color: DisplayP3Color) -> GamutEvaluation
}

/// Reports how far apart two colors are under a named difference formula.
protocol ColorDifferenceCalculating: Sendable {
    func difference(between first: LabColor, and second: LabColor) -> Double
}

/// Reports the contrast ratio between a foreground and a background.
protocol ContrastCalculating: Sendable {
    func evaluate(foreground: SRGBColor, background: SRGBColor) throws -> ContrastEvaluation
}

/// One cited source, categorized by what kind of authority it carries.
///
/// The category matters because a technical specification, an empirical study,
/// and a piece of platform guidance do not support the same kind of claim.
struct EvidenceRecord: Identifiable, Hashable, Sendable {
    enum Category: String, Sendable {
        case scientificStandard = "Scientific standard"
        case technicalSpecification = "Technical specification"
        case empiricalResearch = "Empirical research"
        case designGuidance = "Design guidance"
    }

    let id: String
    let category: Category
    let title: String
    let version: String
    let lastReviewed: String
    let sourceURL: URL
    let limitation: String
}

/// Every source the app cites, held in one place so a citation shown beside a
/// result and one shown in Reference cannot diverge.
enum EvidenceRegistry {
    static let cssColor4 = EvidenceRecord(
        id: "w3c-css-color-4",
        category: .technicalSpecification,
        title: "CSS Color Module Level 4",
        version: "W3C Candidate Recommendation Draft, 17 July 2026",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://www.w3.org/TR/css-color-4/")!,
        limitation: "Defines web color syntax and processing; it is a technical specification, not empirical vision research."
    )

    static let cssColor4Gamut = EvidenceRecord(
        id: "w3c-css-color-4-gamut",
        category: .technicalSpecification,
        title: "CSS Color Module Level 4: Gamut Mapping",
        version: "W3C Candidate Recommendation Draft, 17 July 2026",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://www.w3.org/TR/css-color-4/#gamut-mapping")!,
        limitation: "Defines conversion and gamut mapping for individual SDR CSS colors. It does not measure a particular device gamut or prescribe mapping for images, printers, HDR content, or every color-management workflow."
    )

    static let compositing = EvidenceRecord(
        id: "w3c-compositing-1",
        category: .technicalSpecification,
        title: "Compositing and Blending Level 1: Source Over",
        version: "W3C Candidate Recommendation Draft, 21 March 2024",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://www.w3.org/TR/compositing-1/#porterduffcompositingoperators_srcover")!,
        limitation: "Defines the source-over compositing calculation. It does not predict color appearance or by itself specify every layer, blend mode, color space, and rendering step in a complete interface."
    )

    static let colorimetry = EvidenceRecord(
        id: "cie-015-2018",
        category: .scientificStandard,
        title: "CIE 015:2018 Colorimetry, 4th Edition",
        version: "CIE 015:2018",
        lastReviewed: "2026-08-27",
        sourceURL: URL(string: "https://cie.co.at/publications/colorimetry-4th-edition")!,
        limitation: "Standardized colorimetry models defined observing conditions; it does not predict every individual percept."
    )

    static let sRGB = EvidenceRecord(
        id: "iec-srgb",
        category: .scientificStandard,
        title: "IEC 61966-2-1:1999: sRGB",
        version: "IEC 61966-2-1:1999",
        lastReviewed: "2026-08-27",
        sourceURL: URL(string: "https://webstore.iec.ch/en/publication/6169")!,
        limitation: "Defines the sRGB encoding and reference conditions; a particular display can still depart from the reference behavior."
    )

    static let wcag22 = EvidenceRecord(
        id: "w3c-wcag-22-contrast",
        category: .technicalSpecification,
        title: "WCAG 2.2: Contrast (Minimum and Enhanced)",
        version: "W3C Recommendation, 12 December 2024",
        lastReviewed: "2026-08-27",
        sourceURL: URL(string: "https://www.w3.org/TR/WCAG22/#contrast-minimum")!,
        limitation: "These thresholds evaluate specified sRGB color pairs under WCAG's defined method; they do not model font rendering, ambient light, display calibration, individual vision, or every real interface state."
    )

    static let wcag22NonText = EvidenceRecord(
        id: "w3c-wcag-22-non-text",
        category: .technicalSpecification,
        title: "WCAG 2.2: Non-text Contrast",
        version: "W3C Recommendation, 12 December 2024",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html")!,
        limitation: "The 3:1 threshold applies to visual information required to identify controls, states, and meaningful graphics, not to every decorative color boundary."
    )

    static let wcag22UseOfColor = EvidenceRecord(
        id: "w3c-wcag-22-use-of-color",
        category: .technicalSpecification,
        title: "WCAG 2.2: Use of Color",
        version: "W3C Recommendation, 12 December 2024",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://www.w3.org/WAI/WCAG22/Understanding/use-of-color")!,
        limitation: "Whether color carries meaning is a property of the complete design and task. A two-color neutral preview can prompt review but cannot determine conformance by itself."
    )

    static let appleAccessibility = EvidenceRecord(
        id: "apple-hig-accessibility",
        category: .designGuidance,
        title: "Apple Human Interface Guidelines: Accessibility",
        version: "Living platform guidance",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://developer.apple.com/design/human-interface-guidelines/accessibility/")!,
        limitation: "Platform guidance supports implementation decisions but does not replace evaluation with disabled users or task-based usability testing."
    )

    static let appleColor = EvidenceRecord(
        id: "apple-hig-color",
        category: .designGuidance,
        title: "Apple Human Interface Guidelines: Color",
        version: "Living platform guidance",
        lastReviewed: "2026-08-29",
        sourceURL: URL(string: "https://developer.apple.com/design/human-interface-guidelines/color")!,
        limitation: "Platform guidance supports semantic, adaptive, and redundant color use. It does not validate a custom palette for every observer, viewing condition, or task."
    )

    static let cssCustomProperties = EvidenceRecord(
        id: "w3c-css-custom-properties",
        category: .technicalSpecification,
        title: "CSS Custom Properties Level 1",
        version: "W3C Candidate Recommendation Snapshot, 16 June 2022",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://www.w3.org/TR/css-variables-1/")!,
        limitation: "Defines reusable CSS variables and their syntax; it does not prescribe palette roles or assess whether a design is usable."
    )

    static let ciede2000 = EvidenceRecord(
        id: "iso-cie-11664-6-2022",
        category: .scientificStandard,
        title: "ISO/CIE 11664-6:2022: CIEDE2000",
        version: "Second edition, 2022",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://www.cie.co.at/publications/colorimetry-part-6-ciede2000-colour-difference-formula-1")!,
        limitation: "CIEDE2000 estimates the relative magnitude of color differences from CIELAB coordinates. It does not supply one universal threshold for visibility, acceptability, readability, or accessibility."
    )

    static let ciede2000Implementation = EvidenceRecord(
        id: "sharma-ciede2000-2005",
        category: .empiricalResearch,
        title: "Sharma, Wu, and Dalal: CIEDE2000 implementation notes and test data",
        version: "Color Research & Application 30(1), 2005; DOI 10.1002/col.20070",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/")!,
        limitation: "The paper and supplemental dataset validate mathematical implementation and document discontinuities; the authors explicitly do not define psychophysical applicability or universal decision thresholds."
    )

    static let contextualLightness = EvidenceRecord(
        id: "kingdom-lightness-2011",
        category: .empiricalResearch,
        title: "Kingdom: Lightness, brightness and transparency, a quarter century of new ideas, captivating demonstrations and unrelenting controversy",
        version: "Vision Research 51(7), 2011; DOI 10.1016/j.visres.2010.09.012",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://pubmed.ncbi.nlm.nih.gov/20858514/")!,
        limitation: "This peer-reviewed review describes contextual effects and competing explanations. A simple on-screen demonstration does not predict the effect's magnitude or interpretation for every observer, display, or layout."
    )

    static let ciecam16 = EvidenceRecord(
        id: "cie-248-2022-ciecam16",
        category: .scientificStandard,
        title: "CIE 248:2022: CIECAM16 color appearance model",
        version: "CIE 248:2022",
        lastReviewed: "2026-08-28",
        sourceURL: URL(string: "https://www.cie.co.at/publications/cie-2016-colour-appearance-model-colour-management-systems-ciecam16")!,
        limitation: "CIECAM16 predicts defined appearance correlates for stated viewing conditions. It is not a direct measurement of an individual's experience and does not represent every contextual effect."
    )

    static let records = [
        cssColor4,
        cssColor4Gamut,
        compositing,
        colorimetry,
        sRGB,
        wcag22,
        wcag22NonText,
        wcag22UseOfColor,
        appleAccessibility,
        appleColor,
        cssCustomProperties,
        ciede2000,
        ciede2000Implementation,
        contextualLightness,
        ciecam16
    ]

    static func record(withID id: String) -> EvidenceRecord? {
        records.first { $0.id == id }
    }
}
