import Foundation

/// Builds the stage list for a conversion, given the output asked for.
///
/// Each output has its own route because the useful stopping point differs.
/// Showing every stage for every output would put four irrelevant steps in
/// front of someone who asked for hexadecimal.
enum ConversionRouteBuilder {
    static func stages(
        for target: ConversionTargetID,
        analysis: ColorAnalysis
    ) -> [ConversionStage] {
        let input = inputStage(analysis)

        switch target {
        case .rgb:
            return [input, rgbNotationStage(analysis)]
        case .hexadecimal:
            return [input, hexadecimalStage(analysis)]
        case .hsl:
            return [input, hslStage(analysis)]
        case .linearSRGB:
            return [input, linearStage(analysis)]
        case .xyzD65:
            return [input, linearStage(analysis), xyzD65Stage(analysis)]
        case .xyzD50:
            return [input, linearStage(analysis), xyzD65Stage(analysis), adaptationStage(analysis)]
        case .labD50:
            return labPath(analysis)
        case .lchD50:
            return labPath(analysis) + [cieLChStage(analysis)]
        case .okLab:
            return okLabPath(analysis)
        case .okLCh:
            return okLabPath(analysis) + [okLChStage(analysis)]
        case .displayP3:
            return [input, linearStage(analysis), xyzD65Stage(analysis), displayP3Stage(analysis)]
        }
    }

    private static func labPath(_ analysis: ColorAnalysis) -> [ConversionStage] {
        [
            inputStage(analysis),
            linearStage(analysis),
            xyzD65Stage(analysis),
            adaptationStage(analysis),
            labStage(analysis)
        ]
    }

    private static func okLabPath(_ analysis: ColorAnalysis) -> [ConversionStage] {
        [
            inputStage(analysis),
            linearStage(analysis),
            xyzD65Stage(analysis),
            okLabStage(analysis)
        ]
    }

    private static func inputStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let parsed = analysis.parsed
        let encoded = parsed.color
        let equation = parsed.notationID == .hexadecimal
            ? #"c_{\mathrm{encoded}}=\frac{\mathrm{hex}_{16}}{255}"#
            : #"c_{\mathrm{encoded}}=\frac{n}{255}\quad\mathrm{or}\quad c_{\mathrm{encoded}}=\frac{p}{100}"#
        let equationDescription = parsed.notationID == .hexadecimal
            ? "An encoded component equals its hexadecimal integer divided by 255."
            : "An encoded component equals its numeric value divided by 255, or its percentage divided by 100."

        return ConversionStage(
            id: "notation-to-srgb",
            title: "Interpret the entered value",
            value: "R \(encoded.red8)   G \(encoded.green8)   B \(encoded.blue8)   A \(encoded.alpha8)",
            whatChanges: "The entered \(parsed.notation) value is read as encoded red, green, blue, and alpha components in sRGB.",
            whyItMatters: "The same numbers can mean different colors in different color spaces. This step fixes their meaning before another representation is calculated. Alpha records opacity and is not a fourth color coordinate.",
            equationLaTeX: equation,
            equationAccessibilityLabel: equationDescription,
            substitutionLaTeX: #"\left(R_{8},\,G_{8},\,B_{8},\,A_{8}\right)=\left(\#(encoded.red8),\;\#(encoded.green8),\;\#(encoded.blue8),\;\#(encoded.alpha8)\right)"#,
            substitutionAccessibilityLabel: "For this color, red is \(encoded.red8), green is \(encoded.green8), blue is \(encoded.blue8), and alpha is \(encoded.alpha8).",
            evidenceIDs: ["w3c-css-color-4", "iec-srgb"]
        )
    }

    private static func rgbNotationStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let color = analysis.parsed.color
        return ConversionStage(
            id: "serialize-rgb",
            title: "Write the decimal notation",
            value: color.cssRGB,
            whatChanges: "Each encoded sRGB component is written on the 0-to-255 RGB scale. Alpha is included only when the color is not fully opaque.",
            whyItMatters: "This is a change in notation, not a conversion to a different color space. The intended sRGB color remains the same.",
            equationLaTeX: #"n_{8}=\mathrm{round}\!\left(255\,c_{\mathrm{encoded}}\right)"#,
            equationAccessibilityLabel: "The 8-bit channel number equals 255 times the encoded component, rounded to the nearest integer.",
            substitutionLaTeX: #"\left(R_8,\,G_8,\,B_8\right)=\left(\#(color.red8),\;\#(color.green8),\;\#(color.blue8)\right)"#,
            substitutionAccessibilityLabel: "The RGB channel numbers are \(color.red8), \(color.green8), and \(color.blue8).",
            evidenceIDs: ["w3c-css-color-4", "iec-srgb"]
        )
    }

    private static func hexadecimalStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let color = analysis.parsed.color
        return ConversionStage(
            id: "serialize-hex",
            title: "Write the hexadecimal notation",
            value: color.hex,
            whatChanges: "Each 8-bit sRGB channel number is written as a two-digit base-16 pair. A fourth pair is added when alpha is not fully opaque.",
            whyItMatters: "Hexadecimal is a compact notation for encoded channel values. It does not define a separate color space.",
            equationLaTeX: #"h_{16}=\mathrm{base16}\!\left(\mathrm{round}\!\left(255\,c_{\mathrm{encoded}}\right)\right)"#,
            equationAccessibilityLabel: "Each hexadecimal pair is the base-16 form of 255 times the encoded component, rounded to the nearest integer.",
            substitutionLaTeX: #"\left(R_{16},\,G_{16},\,B_{16}\right)=\left(\mathrm{\#(String(format: "%02X", color.red8))},\;\mathrm{\#(String(format: "%02X", color.green8))},\;\mathrm{\#(String(format: "%02X", color.blue8))}\right)"#,
            substitutionAccessibilityLabel: "The hexadecimal channel pairs are \(String(format: "%02X", color.red8)), \(String(format: "%02X", color.green8)), and \(String(format: "%02X", color.blue8)).",
            evidenceIDs: ["w3c-css-color-4"]
        )
    }

    private static func hslStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let hsl = analysis.hsl
        return ConversionStage(
            id: "srgb-to-hsl",
            title: "Rearrange the encoded channels",
            value: "H \(Format.decimal(hsl.hue, places: 1))°   S \(Format.percent(hsl.saturation))   L \(Format.percent(hsl.lightness))",
            whatChanges: "The largest and smallest encoded sRGB components are used to derive hue, saturation, and HSL lightness.",
            whyItMatters: "HSL can be convenient for editing familiar controls, but its lightness and saturation are not perceptually uniform. Equal numeric changes can look unequal.",
            equationLaTeX: #"\begin{aligned}M&=\max(R,G,B),\quad m=\min(R,G,B),\quad C=M-m\\L&=\frac{M+m}{2}\\S&=\begin{cases}0,&C=0\\\frac{C}{1-\left|2L-1\right|},&C>0\end{cases}\\H&=60^{\circ}\!\begin{cases}0,&C=0\\\left(\frac{G-B}{C}\;\mathrm{mod}\;6\right),&M=R\\\frac{B-R}{C}+2,&M=G\\\frac{R-G}{C}+4,&M=B\end{cases}\end{aligned}"#,
            equationAccessibilityLabel: "M is the largest encoded channel, m is the smallest, and C is their difference. Lightness is M plus m divided by two. Saturation and hue then follow from C and whichever channel is largest; achromatic colors use zero for hue and saturation.",
            substitutionLaTeX: #"\left(H,\,S,\,L\right)=\left(\#(Format.decimal(hsl.hue, places: 2))^{\circ},\;\#(Format.decimal(hsl.saturation, places: 4)),\;\#(Format.decimal(hsl.lightness, places: 4))\right)"#,
            substitutionAccessibilityLabel: "For this color, hue is \(Format.decimal(hsl.hue, places: 2)) degrees, saturation is \(Format.percent(hsl.saturation)), and HSL lightness is \(Format.percent(hsl.lightness)).",
            evidenceIDs: ["w3c-css-color-4"]
        )
    }

    private static func linearStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let linear = analysis.linear
        return ConversionStage(
            id: "srgb-to-linear",
            title: "Recover values proportional to light",
            value: "R \(Format.decimal(linear.red))   G \(Format.decimal(linear.green))   B \(Format.decimal(linear.blue))",
            whatChanges: "The nonlinear encoding is removed from each sRGB channel independently, producing linear-light values.",
            whyItMatters: "Encoded sRGB preserves useful numeric precision, but its channel values are not proportional to light. Matrix calculations require linear-light values.",
            equationLaTeX: #"c_{\mathrm{lin}}=\begin{cases}\frac{c}{12.92},&c\leq0.04045\\\left(\frac{c+0.055}{1.055}\right)^{2.4},&c>0.04045\end{cases}"#,
            equationAccessibilityLabel: "For encoded components up to 0.04045, the linear component equals c divided by 12.92. Above 0.04045, it equals c plus 0.055, divided by 1.055, raised to the power 2.4.",
            substitutionLaTeX: #"\left(R_{\mathrm{lin}},\,G_{\mathrm{lin}},\,B_{\mathrm{lin}}\right)=\left(\#(Format.decimal(linear.red)),\;\#(Format.decimal(linear.green)),\;\#(Format.decimal(linear.blue))\right)"#,
            substitutionAccessibilityLabel: "The linear-light red component is \(Format.decimal(linear.red)), green is \(Format.decimal(linear.green)), and blue is \(Format.decimal(linear.blue)).",
            evidenceIDs: ["w3c-css-color-4", "iec-srgb"]
        )
    }

    private static func xyzD65Stage(_ analysis: ColorAnalysis) -> ConversionStage {
        let xyz = analysis.xyzD65
        return ConversionStage(
            id: "linear-to-xyz-d65",
            title: "Move into a common coordinate space",
            value: "X \(Format.decimal(xyz.x))   Y \(Format.decimal(xyz.y))   Z \(Format.decimal(xyz.z))",
            whatChanges: "A matrix combines the three linear sRGB components into CIE XYZ coordinates referenced to D65.",
            whyItMatters: "XYZ acts as a colorimetric connection space between many color representations. The D65 label keeps the white-reference assumption explicit.",
            equationLaTeX: #"\mathbf{X}_{D65}=M_{\mathrm{sRGB}\to XYZ}\,\mathbf{c}_{\mathrm{lin}}"#,
            equationAccessibilityLabel: "The D65 X, Y, and Z vector equals the sRGB-to-XYZ matrix multiplied by the linear red, green, and blue vector.",
            substitutionLaTeX: #"\begin{aligned}Y&=0.212639R_{\mathrm{lin}}+0.715169G_{\mathrm{lin}}+0.072192B_{\mathrm{lin}}\\&=\#(Format.decimal(xyz.y))\end{aligned}"#,
            substitutionAccessibilityLabel: "For this color, Y equals 0.212639 times linear red, plus 0.715169 times linear green, plus 0.072192 times linear blue, which is \(Format.decimal(xyz.y)).",
            evidenceIDs: ["w3c-css-color-4", "cie-015-2018"]
        )
    }

    private static func adaptationStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let source = analysis.xyzD65
        let destination = analysis.xyzD50
        return ConversionStage(
            id: "d65-to-d50",
            title: "Change the white reference",
            value: "X \(Format.decimal(destination.x))   Y \(Format.decimal(destination.y))   Z \(Format.decimal(destination.z))",
            whatChanges: "The linear Bradford matrix changes the XYZ coordinates from a D65 reference white to D50.",
            whyItMatters: "CSS CIELAB and CIE LCh use D50, while sRGB begins at D65. The adaptation keeps those two reference conditions from being treated as interchangeable.",
            equationLaTeX: #"\mathbf{X}_{D50}=M_{\mathrm{Bradford}}\,\mathbf{X}_{D65}"#,
            equationAccessibilityLabel: "The D50 XYZ vector equals the linear Bradford adaptation matrix multiplied by the D65 XYZ vector.",
            substitutionLaTeX: #"\begin{aligned}\mathbf{X}_{D65}&=\left(\#(Format.decimal(source.x)),\;\#(Format.decimal(source.y)),\;\#(Format.decimal(source.z))\right)\\\mathbf{X}_{D50}&=\left(\#(Format.decimal(destination.x)),\;\#(Format.decimal(destination.y)),\;\#(Format.decimal(destination.z))\right)\end{aligned}"#,
            substitutionAccessibilityLabel: "The D65 coordinates are \(Format.decimal(source.x)), \(Format.decimal(source.y)), and \(Format.decimal(source.z)). After adaptation, the D50 coordinates are \(Format.decimal(destination.x)), \(Format.decimal(destination.y)), and \(Format.decimal(destination.z)).",
            evidenceIDs: ["w3c-css-color-4", "cie-015-2018"]
        )
    }

    private static func labStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let lab = analysis.labD50
        return ConversionStage(
            id: "xyz-d50-to-lab",
            title: "Describe lightness and color direction",
            value: "L* \(Format.decimal(lab.lightness, places: 2))   a* \(Format.signed(lab.a))   b* \(Format.signed(lab.b))",
            whatChanges: "The D50-relative XYZ coordinates are transformed into CIELAB L*, a*, and b* coordinates.",
            whyItMatters: "L* separates colorimetric lightness from two signed color directions. CIELAB supports more meaningful comparisons than raw RGB, but it remains an approximation of perception.",
            equationLaTeX: #"\begin{aligned}f(t)&=\begin{cases}t^{1/3},&t>\epsilon\\\frac{\kappa t+16}{116},&t\leq\epsilon\end{cases}\\L^*&=116f(Y/Y_n)-16\\a^*&=500\left[f(X/X_n)-f(Y/Y_n)\right]\\b^*&=200\left[f(Y/Y_n)-f(Z/Z_n)\right]\\\epsilon&=\frac{216}{24389},\quad\kappa=\frac{24389}{27}\end{aligned}"#,
            equationAccessibilityLabel: "The function f uses a cube root above epsilon and a linear expression at or below epsilon. L star is 116 times f of Y over Y n minus 16. A star and B star are scaled differences between the transformed white-relative X, Y, and Z values.",
            substitutionLaTeX: #"\left(X_n,\,Y_n,\,Z_n\right)_{D50}=\left(0.96430,\;1.00000,\;0.82510\right)"#,
            substitutionAccessibilityLabel: "The D50 reference white has X n 0.96430, Y n 1.00000, and Z n 0.82510.",
            evidenceIDs: ["cie-015-2018", "w3c-css-color-4"]
        )
    }

    private static func cieLChStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let lch = analysis.lchD50
        return polarStage(
            id: "lab-to-lch",
            title: "Separate chroma and hue",
            value: "L* \(Format.decimal(lch.lightness, places: 2))   C* \(Format.decimal(lch.chroma, places: 2))   h \(Format.hue(lch.hue))",
            whatChanges: "The CIELAB a* and b* axes are rearranged into CIE LCh chroma and hue angle. L* and the D50 reference remain unchanged.",
            whyItMatters: "The polar form makes the amount of chroma and the hue direction easier to inspect. Hue becomes undefined as chroma approaches zero.",
            lightness: lch.lightness,
            chroma: lch.chroma,
            hue: lch.hue,
            lightnessSymbol: "L^*",
            chromaSymbol: "C^*_{ab}",
            hueSymbol: "h_{ab}",
            evidenceIDs: ["cie-015-2018", "w3c-css-color-4"]
        )
    }

    private static func okLabStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let lab = analysis.okLab
        return ConversionStage(
            id: "xyz-d65-to-oklab",
            title: "Build a newer perceptual coordinate set",
            value: "L \(Format.decimal(lab.lightness, places: 5))   a \(Format.signed(lab.a, places: 5))   b \(Format.signed(lab.b, places: 5))",
            whatChanges: "The D65-relative XYZ coordinates pass through two matrices with an element-by-element cube-root step to produce Oklab L, a, and b.",
            whyItMatters: "Oklab was designed for improved perceptual behavior in image-processing tasks. It is a defined mathematical approximation, not a complete model of appearance or an official CIE color space.",
            equationLaTeX: #"\mathbf{Lab}_{\mathrm{OK}}=M_2\,\mathrm{cbrt}\!\left(M_1\,\mathbf{X}_{D65}\right)"#,
            equationAccessibilityLabel: "The Oklab vector equals matrix M two multiplied by the element-by-element cube root of matrix M one multiplied by the D65 XYZ vector.",
            substitutionLaTeX: #"\left(L,\,a,\,b\right)_{\mathrm{OK}}=\left(\#(latexCoordinate(lab.lightness)),\;\#(latexCoordinate(lab.a)),\;\#(latexCoordinate(lab.b))\right)"#,
            substitutionAccessibilityLabel: "For this color, Oklab L is \(Format.decimal(lab.lightness, places: 5)), a is \(Format.signed(lab.a, places: 5)), and b is \(Format.signed(lab.b, places: 5)).",
            evidenceIDs: ["w3c-css-color-4"]
        )
    }

    private static func okLChStage(_ analysis: ColorAnalysis) -> ConversionStage {
        let lch = analysis.okLCh
        return polarStage(
            id: "oklab-to-oklch",
            title: "Separate chroma and hue",
            value: "L \(Format.decimal(lch.lightness, places: 5))   C \(Format.decimal(lch.chroma, places: 5))   h \(Format.hue(lch.hue))",
            whatChanges: "The Oklab a and b axes are rearranged into OkLCh chroma and hue. L and the D65 reference remain unchanged.",
            whyItMatters: "The polar form can make hue and chroma adjustments easier to express. Hue becomes undefined close to a neutral color.",
            lightness: lch.lightness,
            chroma: lch.chroma,
            hue: lch.hue,
            lightnessSymbol: #"L_{\mathrm{OK}}"#,
            chromaSymbol: #"C_{\mathrm{OK}}"#,
            hueSymbol: #"h_{\mathrm{OK}}"#,
            evidenceIDs: ["w3c-css-color-4"]
        )
    }

    private static func polarStage(
        id: String,
        title: String,
        value: String,
        whatChanges: String,
        whyItMatters: String,
        lightness: Double,
        chroma: Double,
        hue: Double?,
        lightnessSymbol: String,
        chromaSymbol: String,
        hueSymbol: String,
        evidenceIDs: [String]
    ) -> ConversionStage {
        ConversionStage(
            id: id,
            title: title,
            value: value,
            whatChanges: whatChanges,
            whyItMatters: whyItMatters,
            equationLaTeX: #"\begin{aligned}C&=\sqrt{a^2+b^2}\\h&=\mathrm{atan2}(b,a)\end{aligned}"#,
            equationAccessibilityLabel: "Chroma equals the square root of a squared plus b squared. Hue equals the two-argument arctangent of b and a, expressed as an angle from zero through 360 degrees.",
            substitutionLaTeX: #"\left(\#(lightnessSymbol),\;\#(chromaSymbol),\;\#(hueSymbol)\right)=\left(\#(Format.decimal(lightness, places: 5)),\;\#(Format.decimal(chroma, places: 5)),\;\#(latexHue(hue))\right)"#,
            substitutionAccessibilityLabel: "For this color, lightness is \(Format.decimal(lightness, places: 5)), chroma is \(Format.decimal(chroma, places: 5)), and hue is \(Format.hue(hue)).",
            evidenceIDs: evidenceIDs
        )
    }

    private static func displayP3Stage(_ analysis: ColorAnalysis) -> ConversionStage {
        let p3 = analysis.displayP3
        return ConversionStage(
            id: "xyz-d65-to-display-p3",
            title: "Use another set of RGB primaries",
            value: p3.css(alpha: analysis.parsed.color.alpha),
            whatChanges: "D65-relative XYZ is transformed into linear Display P3 components, then encoded with the transfer function used by Display P3.",
            whyItMatters: "Display P3 uses a wider set of RGB primaries than sRGB. The component numbers change because the coordinate system changes, even when the intended color remains the same.",
            equationLaTeX: #"\mathbf{c}_{\mathrm{P3}}=f_{\mathrm{P3}}\!\left(M_{XYZ\to\mathrm{P3}}\,\mathbf{X}_{D65}\right)"#,
            equationAccessibilityLabel: "The encoded Display P3 vector equals the Display P3 transfer function applied to the XYZ-to-Display-P3 matrix multiplied by the D65 XYZ vector.",
            substitutionLaTeX: #"\left(R,\,G,\,B\right)_{\mathrm{P3}}=\left(\#(Format.decimal(p3.red)),\;\#(Format.decimal(p3.green)),\;\#(Format.decimal(p3.blue))\right)"#,
            substitutionAccessibilityLabel: "The Display P3 components are red \(Format.decimal(p3.red)), green \(Format.decimal(p3.green)), and blue \(Format.decimal(p3.blue)).",
            evidenceIDs: ["w3c-css-color-4"]
        )
    }

    private static func latexHue(_ value: Double?) -> String {
        guard let value else { return #"\mathrm{undefined}"# }
        return "\(Format.decimal(value, places: 2))^{\\circ}"
    }

    /// SwiftMath treats a leading plus or minus immediately after tuple punctuation as a binary
    /// operator. Positive coordinates therefore omit a redundant plus, while negative coordinates
    /// are grouped so they remain both mathematically correct and safe to typeset.
    private static func latexCoordinate(_ value: Double) -> String {
        let magnitude = Format.decimal(abs(value), places: 5)
        return value < 0 ? #"\left(-\#(magnitude)\right)"# : magnitude
    }
}

extension ConversionStage {
    var navigationTitle: String {
        switch id {
        case "notation-to-srgb": "Read input"
        case "serialize-rgb": "Write RGB"
        case "serialize-hex": "Write HEX"
        case "srgb-to-hsl": "Color controls"
        case "srgb-to-linear": "Proportional light"
        case "linear-to-xyz-d65": "Shared space"
        case "d65-to-d50": "Viewing reference"
        case "xyz-d50-to-lab": "Lightness axes"
        case "lab-to-lch", "oklab-to-oklch": "Amount and hue"
        case "xyz-d65-to-oklab": "Perceptual axes"
        case "xyz-d65-to-display-p3": "Display P3"
        default: title
        }
    }

    var symbolName: String {
        switch id {
        case "notation-to-srgb": "number"
        case "serialize-rgb", "serialize-hex": "textformat.123"
        case "srgb-to-hsl", "lab-to-lch", "oklab-to-oklch": "circle.grid.cross"
        case "srgb-to-linear": "sun.max"
        case "linear-to-xyz-d65": "move.3d"
        case "d65-to-d50": "sun.haze"
        case "xyz-d50-to-lab", "xyz-d65-to-oklab": "axis.3d"
        case "xyz-d65-to-display-p3": "display"
        default: "function"
        }
    }

    var definitionIDs: [String] {
        switch id {
        case "notation-to-srgb": ["srgb", "alpha"]
        case "serialize-rgb": ["rgb-model"]
        case "serialize-hex": ["hex-notation"]
        case "srgb-to-hsl": ["hsl"]
        case "srgb-to-linear": ["encoded-linear"]
        case "linear-to-xyz-d65": ["cie-xyz", "reference-white"]
        case "d65-to-d50": ["reference-white", "chromatic-adaptation"]
        case "xyz-d50-to-lab": ["cielab"]
        case "lab-to-lch": ["cie-lch"]
        case "xyz-d65-to-oklab", "oklab-to-oklch": ["oklab"]
        case "xyz-d65-to-display-p3": ["display-p3"]
        default: []
        }
    }
}
