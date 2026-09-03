import Foundation

/// Turns a parsed color into every representation the app reports.
///
/// The protocol exists so views depend on the result rather than on one
/// particular set of matrices, and so tests can substitute a fixed converter.
protocol ColorSpaceConverting: Sendable {
    func analyze(_ parsed: ParsedColor) -> ColorAnalysis
}

/// The sRGB electro-optical transfer function and its inverse.
///
/// Both branches carry the sign through, because conversions out of a wider
/// space regularly produce components below zero. Clamping here would hide the
/// out-of-range result the gamut check is meant to report.
enum TransferFunctions {
    static func sRGBToLinear(_ component: Double) -> Double {
        let sign = component < 0 ? -1.0 : 1.0
        let magnitude = abs(component)
        if magnitude <= 0.04045 {
            return component / 12.92
        }
        return sign * pow((magnitude + 0.055) / 1.055, 2.4)
    }

    static func linearToSRGB(_ component: Double) -> Double {
        let sign = component < 0 ? -1.0 : 1.0
        let magnitude = abs(component)
        if magnitude > 0.0031308 {
            return sign * ((1.055 * pow(magnitude, 1 / 2.4)) - 0.055)
        }
        return 12.92 * component
    }
}

/// The converter the shipping app uses.
///
/// The chain runs sRGB to linear light, then to XYZ under D65, and branches
/// from there. Lab and LCh are calculated under D50 because that is the white
/// point CSS Color 4 specifies for them, while Oklab and Display P3 stay under
/// D65. Mixing the two white points silently is a common source of wrong Lab
/// values, so the adaptation between them is a separate, named step.
struct DefaultColorSpaceConverter: ColorSpaceConverting {
    func analyze(_ parsed: ParsedColor) -> ColorAnalysis {
        let encoded = parsed.color
        let linear = LinearRGBColor(
            red: TransferFunctions.sRGBToLinear(encoded.red),
            green: TransferFunctions.sRGBToLinear(encoded.green),
            blue: TransferFunctions.sRGBToLinear(encoded.blue)
        )

        // CSS Color 4's rational, 64-bit sRGB-to-XYZ D65 matrix.
        let xyzD65 = XYZColor(
            x: ((506752.0 / 1228815.0) * linear.red)
                + ((87881.0 / 245763.0) * linear.green)
                + ((12673.0 / 70218.0) * linear.blue),
            y: ((87098.0 / 409605.0) * linear.red)
                + ((175762.0 / 245763.0) * linear.green)
                + ((12673.0 / 175545.0) * linear.blue),
            z: ((7918.0 / 409605.0) * linear.red)
                + ((87881.0 / 737289.0) * linear.green)
                + ((1001167.0 / 1053270.0) * linear.blue)
        )

        let xyzD50 = Self.d65ToD50(xyzD65)
        let labD50 = Self.xyzD50ToLab(xyzD50)
        let lchD50 = Self.polar(
            lightness: labD50.lightness,
            a: labD50.a,
            b: labD50.b,
            epsilon: 0.0015
        )
        let okLab = Self.xyzD65ToOKLab(xyzD65)
        let okLCh = Self.polar(
            lightness: okLab.lightness,
            a: okLab.a,
            b: okLab.b,
            epsilon: 0.000004
        )
        let displayP3 = Self.xyzD65ToDisplayP3(xyzD65)
        let hsl = Self.sRGBToHSL(encoded)
        let luminance = (0.2126 * linear.red) + (0.7152 * linear.green) + (0.0722 * linear.blue)

        return ColorAnalysis(
            parsed: parsed,
            linear: linear,
            xyzD65: xyzD65,
            xyzD50: xyzD50,
            labD50: labD50,
            lchD50: lchD50,
            displayP3: displayP3,
            okLab: okLab,
            okLCh: okLCh,
            hsl: hsl,
            relativeLuminance: luminance
        )
    }

    private static func d65ToD50(_ xyz: XYZColor) -> XYZColor {
        XYZColor(
            x: (1.0479297925449969 * xyz.x)
                + (0.022946870601609652 * xyz.y)
                - (0.05019226628920524 * xyz.z),
            y: (0.02962780877005599 * xyz.x)
                + (0.9904344267538799 * xyz.y)
                - (0.017073799063418826 * xyz.z),
            z: (-0.009243040646204504 * xyz.x)
                + (0.015055191490298152 * xyz.y)
                + (0.7518742814281371 * xyz.z)
        )
    }

    private static func xyzD50ToLab(_ xyz: XYZColor) -> LabColor {
        let d50 = XYZColor(
            x: 0.3457 / 0.3585,
            y: 1,
            z: (1 - 0.3457 - 0.3585) / 0.3585
        )
        let fx = labTransform(xyz.x / d50.x)
        let fy = labTransform(xyz.y / d50.y)
        let fz = labTransform(xyz.z / d50.z)
        return LabColor(
            lightness: (116 * fy) - 16,
            a: 500 * (fx - fy),
            b: 200 * (fy - fz)
        )
    }

    private static func labTransform(_ value: Double) -> Double {
        let epsilon = 216.0 / 24389.0
        let kappa = 24389.0 / 27.0
        if value > epsilon {
            return cbrt(value)
        }
        return ((kappa * value) + 16) / 116
    }

    private static func xyzD65ToOKLab(_ xyz: XYZColor) -> OKLabColor {
        let l = (0.8190224379967030 * xyz.x)
            + (0.3619062600528904 * xyz.y)
            - (0.1288737815209879 * xyz.z)
        let m = (0.0329836539323885 * xyz.x)
            + (0.9292868615863434 * xyz.y)
            + (0.0361446663506424 * xyz.z)
        let s = (0.0481771893596242 * xyz.x)
            + (0.2642395317527308 * xyz.y)
            + (0.6335478284694309 * xyz.z)
        let lRoot = cbrt(l)
        let mRoot = cbrt(m)
        let sRoot = cbrt(s)

        return OKLabColor(
            lightness: (0.2104542683093140 * lRoot)
                + (0.7936177747023054 * mRoot)
                - (0.0040720430116193 * sRoot),
            a: (1.9779985324311684 * lRoot)
                - (2.4285922420485799 * mRoot)
                + (0.4505937096174110 * sRoot),
            b: (0.0259040424655478 * lRoot)
                + (0.7827717124575296 * mRoot)
                - (0.8086757549230774 * sRoot)
        )
    }

    private static func polar(
        lightness: Double,
        a: Double,
        b: Double,
        epsilon: Double
    ) -> LCHColor {
        let chroma = hypot(a, b)
        guard chroma > epsilon else {
            return LCHColor(lightness: lightness, chroma: chroma, hue: nil)
        }
        let rawHue = atan2(b, a) * 180 / .pi
        return LCHColor(
            lightness: lightness,
            chroma: chroma,
            hue: rawHue < 0 ? rawHue + 360 : rawHue
        )
    }

    private static func xyzD65ToDisplayP3(_ xyz: XYZColor) -> DisplayP3Color {
        let linearRed = ((446124.0 / 178915.0) * xyz.x)
            - ((333277.0 / 357830.0) * xyz.y)
            - ((72051.0 / 178915.0) * xyz.z)
        let linearGreen = ((-14852.0 / 17905.0) * xyz.x)
            + ((63121.0 / 35810.0) * xyz.y)
            + ((423.0 / 17905.0) * xyz.z)
        let linearBlue = ((11844.0 / 330415.0) * xyz.x)
            - ((50337.0 / 660830.0) * xyz.y)
            + ((316169.0 / 330415.0) * xyz.z)
        return DisplayP3Color(
            red: TransferFunctions.linearToSRGB(linearRed),
            green: TransferFunctions.linearToSRGB(linearGreen),
            blue: TransferFunctions.linearToSRGB(linearBlue)
        )
    }

    private static func sRGBToHSL(_ color: SRGBColor) -> HSLColor {
        let maximum = max(color.red, color.green, color.blue)
        let minimum = min(color.red, color.green, color.blue)
        let delta = maximum - minimum
        let lightness = (maximum + minimum) / 2

        guard delta != 0 else {
            return HSLColor(hue: 0, saturation: 0, lightness: lightness)
        }

        let saturation = delta / (1 - abs((2 * lightness) - 1))
        let hueSector: Double
        if maximum == color.red {
            hueSector = ((color.green - color.blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maximum == color.green {
            hueSector = ((color.blue - color.red) / delta) + 2
        } else {
            hueSector = ((color.red - color.green) / delta) + 4
        }
        let hue = (hueSector * 60 + 360).truncatingRemainder(dividingBy: 360)
        return HSLColor(hue: hue, saturation: saturation, lightness: lightness)
    }

}

/// Parsing and conversion together, which is what the rest of the app asks
/// for whenever text becomes a color.
struct ColorCore: Sendable {
    let parser: any RepresentationParser
    let converter: any ColorSpaceConverting

    init(
        parser: any RepresentationParser = CompositeColorParser(),
        converter: any ColorSpaceConverting = DefaultColorSpaceConverter()
    ) {
        self.parser = parser
        self.converter = converter
    }

    func analyze(_ representation: String) throws -> ColorAnalysis {
        converter.analyze(try parser.parse(representation))
    }

    func analyze(_ representation: String, as notation: ColorNotationID) throws -> ColorAnalysis {
        let parsed: ParsedColor
        switch notation {
        case .hexadecimal:
            parsed = try HexColorParser().parse(representation)
        case .rgb:
            parsed = try RGBColorParser().parse(representation)
        }
        return converter.analyze(parsed)
    }

    /// Analyzes a color that is already normalized to sRGB without serializing
    /// and parsing it again. This is used by interactive color pickers and the
    /// screen sampler, where the source value is already typed and validated.
    func analyze(_ color: SRGBColor, as notation: ColorNotationID) -> ColorAnalysis {
        let normalized = SRGBColor(
            red: Double(color.red8) / 255,
            green: Double(color.green8) / 255,
            blue: Double(color.blue8) / 255,
            alpha: Double(color.alpha8) / 255
        )
        let representation = notation == .hexadecimal ? normalized.hex : normalized.cssRGB
        let description: String
        switch notation {
        case .hexadecimal:
            description = normalized.alpha8 == 255 ? "CSS hexadecimal" : "CSS hexadecimal with alpha"
        case .rgb:
            description = normalized.alpha8 == 255
                ? "CSS rgb() functional notation"
                : "CSS rgb() functional notation with alpha"
        }
        return converter.analyze(
            ParsedColor(
                originalRepresentation: representation,
                notation: description,
                notationID: notation,
                colorSpace: .sRGB,
                color: normalized
            )
        )
    }
}

/// Number formatting for display.
///
/// The POSIX locale is fixed rather than taken from the system, so a color
/// value is written the same way everywhere and can be pasted into code.
enum Format {
    static func decimal(_ value: Double, places: Int = 5) -> String {
        String(format: "%.*f", locale: Locale(identifier: "en_US_POSIX"), places, value)
    }

    static func signed(_ value: Double, places: Int = 2) -> String {
        String(format: "%+.*f", locale: Locale(identifier: "en_US_POSIX"), places, value)
    }

    static func percent(_ value: Double, places: Int = 1) -> String {
        String(format: "%.*f%%", locale: Locale(identifier: "en_US_POSIX"), places, value * 100)
    }

    static func hue(_ value: Double?, places: Int = 2) -> String {
        guard let value else { return "undefined for a neutral color" }
        return "\(decimal(value, places: places))°"
    }
}
