import Foundation

/// The workspaces in the sidebar, in the order they appear.
///
/// Raw values are the visible titles and are also written into the saved
/// session, so renaming a case changes what an existing session restores to.
enum AppSection: String, Codable, CaseIterable, Identifiable, Sendable {
    case home = "Home"
    case learn = "Learn"
    case explore = "Explore"
    case convert = "Convert"
    case build = "Build"
    case check = "Check"
    case reference = "Reference"

    var id: Self { self }

    var symbolName: String {
        switch self {
        case .home: "house"
        case .learn: "book.pages"
        case .explore: "slider.horizontal.3"
        case .convert: "arrow.left.arrow.right"
        case .build: "swatchpalette"
        case .check: "checkmark.shield"
        case .reference: "books.vertical"
        }
    }

    /// The two kinds of work the app supports.
    ///
    /// Grouping matters more than it looks. Three of these workspaces answer a
    /// question about a color you already have, and three teach you something
    /// about color in general. Listed as six equals, a reader has to compare
    /// six things that are not comparable; split in two, the first decision is
    /// between two obviously different intents.
    enum Group: String, CaseIterable, Identifiable, Sendable {
        case work = "Work on a color"
        case understand = "Understand color"

        var id: Self { self }
    }

    var group: Group? {
        switch self {
        case .home: nil
        case .convert, .check, .build: .work
        case .learn, .explore, .reference: .understand
        }
    }

    /// The question a reader arrives with, in their words rather than the
    /// app's.
    ///
    /// A workspace name alone carries almost no information scent. Someone
    /// wondering whether their text is readable has no reason to guess that
    /// "Check" is where readability lives, because the word they are holding
    /// does not appear in the label. The question supplies the words they are
    /// actually searching for.
    var question: String {
        switch self {
        case .home: "Where should I start?"
        case .learn: "Why do these numbers behave this way?"
        case .explore: "What happens if I change this?"
        case .convert: "What is this color in another notation?"
        case .build: "I need a palette that holds up."
        case .check: "Can people actually read this?"
        case .reference: "What does this term mean?"
        }
    }

    /// The one action that starts the work here.
    ///
    /// A workspace that opens with a title, a paragraph, and a wall of cards
    /// leaves the reader to infer where to begin. Naming the first step costs
    /// one line and removes that inference.
    var firstStep: String {
        switch self {
        case .home: "Pick the task closest to what you need."
        case .learn: "Pick a lesson. Each one runs three short parts."
        case .explore: "Pick an experiment, then predict before you change anything."
        case .convert: "Enter a color, then choose the notation you want it in."
        case .build: "Start from a preset palette or ask for a suggestion."
        case .check: "Pick the question you need answered about your two colors."
        case .reference: "Search a term, or browse by topic."
        }
    }

    var summary: String {
        switch self {
        case .home: "Every workspace, and the color you carry between them."
        case .learn: "Light, vision, measurement, and reproduction, four lessons of three short parts."
        case .explore: "Change one thing, then compare what you saw against the calculation."
        case .convert: "Read one color back in any supported notation, with every stage open."
        case .build: "Design named roles, check the relationships they use, export to code."
        case .check: "Contrast, color-space limits, perceived difference, and reliance on color alone."
        case .reference: "Definitions, equations, and standards, each with its source and its limits."
        }
    }
}

/// Every color space the app reports, named the way the standards name them.
///
/// The white point is part of the name because Lab under D50 and Lab under D65
/// give different coordinates for the same color, and leaving it implicit is
/// what makes those two sets of numbers look like a bug.
enum ColorSpaceID: String, Codable, CaseIterable, Sendable {
    case sRGB = "sRGB"
    case linearSRGB = "linear sRGB"
    case xyzD65 = "CIE XYZ (D65)"
    case xyzD50 = "CIE XYZ (D50)"
    case labD50 = "CIELAB (D50)"
    case lchD50 = "CIE LCh (D50)"
    case displayP3 = "Display P3"
    case okLab = "Oklab (D65)"
    case okLCh = "OkLCh (D65)"
    case hslSRGB = "HSL (sRGB)"
}

/// The syntaxes a person can type a color in.
enum ColorNotationID: String, Codable, CaseIterable, Identifiable, Sendable {
    case hexadecimal = "HEX"
    case rgb = "RGB / RGBA"

    var id: Self { self }

    var inputPrompt: String {
        switch self {
        case .hexadecimal: "#C58F63 or #C58F6380"
        case .rgb: "rgb(197 143 99 / 50%)"
        }
    }
}

/// The output a conversion is asked for.
///
/// Each target has its own route, since the useful stopping point differs. RGB
/// and hexadecimal finish at serialization, while Lab and LCh continue through
/// the white point adaptation first.
enum ConversionTargetID: String, CaseIterable, Identifiable, Sendable {
    case rgb
    case hexadecimal
    case hsl
    case okLCh
    case labD50
    case lchD50
    case okLab
    case displayP3
    case linearSRGB
    case xyzD65
    case xyzD50

    var id: Self { self }
}

/// A color in encoded sRGB, components held from zero to one with alpha.
///
/// Components are stored unclamped. A value outside the range is a real result
/// from a conversion out of a wider space, and the gamut check reports it.
struct SRGBColor: Codable, Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var red8: Int { Self.component8(red) }
    var green8: Int { Self.component8(green) }
    var blue8: Int { Self.component8(blue) }
    var alpha8: Int { Self.component8(alpha) }

    var hex: String {
        if alpha8 == 255 {
            return String(format: "#%02X%02X%02X", red8, green8, blue8)
        }
        return String(format: "#%02X%02X%02X%02X", red8, green8, blue8, alpha8)
    }

    var cssRGB: String {
        if alpha8 == 255 {
            return "rgb(\(red8) \(green8) \(blue8))"
        }
        return "rgb(\(red8) \(green8) \(blue8) / \(Format.percent(alpha)))"
    }

    private static func component8(_ value: Double) -> Int {
        Int((min(max(value, 0), 1) * 255).rounded())
    }
}

/// sRGB primaries with the transfer function removed, so the components are
/// proportional to light rather than to encoded value.
struct LinearRGBColor: Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
}

/// CIE XYZ tristimulus values. The white point is not carried here, so any
/// value has to be read together with the field that names it.
struct XYZColor: Hashable, Sendable {
    let x: Double
    let y: Double
    let z: Double
}

/// CIELAB coordinates. Lightness runs zero to one hundred; a and b run through
/// zero in both directions and have no fixed bounds.
struct LabColor: Hashable, Sendable {
    let lightness: Double
    let a: Double
    let b: Double
}

/// CIELAB in polar form.
///
/// Hue is optional rather than zero, because a neutral color has no hue at all
/// and reporting zero would name it red.
struct LCHColor: Hashable, Sendable {
    let lightness: Double
    let chroma: Double
    let hue: Double?
}

/// Oklab coordinates, calculated under D65 rather than the D50 that CIELAB
/// uses here.
struct OKLabColor: Hashable, Sendable {
    let lightness: Double
    let a: Double
    let b: Double
}

/// A color in Display P3, which shares the sRGB white point and transfer curve
/// but reaches wider primaries.
struct DisplayP3Color: Codable, Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    func css(alpha: Double) -> String {
        let components = "\(Format.decimal(red)) \(Format.decimal(green)) \(Format.decimal(blue))"
        if alpha >= 1 {
            return "color(display-p3 \(components))"
        }
        return "color(display-p3 \(components) / \(Format.decimal(alpha, places: 3)))"
    }
}

/// HSL over encoded sRGB. It is a rearrangement of the same numbers rather
/// than a perceptual space, which is why lightness here and lightness in Lab
/// disagree.
struct HSLColor: Hashable, Sendable {
    let hue: Double
    let saturation: Double
    let lightness: Double
}

/// A color read from text, keeping what was typed alongside what it resolved
/// to, so an error message can quote the input back.
struct ParsedColor: Hashable, Sendable {
    let originalRepresentation: String
    let notation: String
    let notationID: ColorNotationID
    let colorSpace: ColorSpaceID
    let color: SRGBColor
}

/// One step of a conversion, carrying its value, what the step changes, and
/// why that change matters.
struct ConversionStage: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let value: String
    let whatChanges: String
    let whyItMatters: String
    let equationLaTeX: String?
    let equationAccessibilityLabel: String?
    let substitutionLaTeX: String?
    let substitutionAccessibilityLabel: String?
    let evidenceIDs: [String]
}

/// One color in every representation the app reports, calculated once.
///
/// Views read from this rather than converting for themselves, so two screens
/// cannot show different numbers for the same color.
struct ColorAnalysis: Hashable, Sendable {
    let parsed: ParsedColor
    let linear: LinearRGBColor
    let xyzD65: XYZColor
    let xyzD50: XYZColor
    let labD50: LabColor
    let lchD50: LCHColor
    let displayP3: DisplayP3Color
    let okLab: OKLabColor
    let okLCh: LCHColor
    let hsl: HSLColor
    let relativeLuminance: Double

    var stages: [ConversionStage] {
        stages(for: .lchD50)
    }

    func stages(for target: ConversionTargetID) -> [ConversionStage] {
        ConversionRouteBuilder.stages(for: target, analysis: self)
    }
}

/// A color saved to the tray, with its label, its lock, and when it was
/// added.
struct ColorRecord: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let createdAt: Date
    var label: String
    let originalRepresentation: String
    let originalColorSpace: ColorSpaceID
    let color: SRGBColor
    let profileDescription: String
    let conversionHistory: [String]
    let source: String
    var isLocked: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        label: String,
        originalRepresentation: String,
        originalColorSpace: ColorSpaceID,
        color: SRGBColor,
        profileDescription: String = "IEC 61966-2-1 sRGB, D65",
        conversionHistory: [String],
        source: String,
        isLocked: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.label = label
        self.originalRepresentation = originalRepresentation
        self.originalColorSpace = originalColorSpace
        self.color = color
        self.profileDescription = profileDescription
        self.conversionHistory = conversionHistory
        self.source = source
        self.isLocked = isLocked
    }
}
