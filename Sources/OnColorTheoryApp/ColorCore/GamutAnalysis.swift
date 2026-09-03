import Foundation

/// Why a Display P3 color could not be read from what was typed.
enum DisplayP3ParseError: LocalizedError, Equatable {
    case empty
    case invalidSyntax
    case invalidComponent(String)
    case componentOutOfRange(String)

    var errorDescription: String? {
        switch self {
        case .empty:
            "Enter a Display P3 color."
        case .invalidSyntax:
            "Use color(display-p3 R G B) or three component values."
        case let .invalidComponent(component):
            "\(component) is not a valid Display P3 component."
        case let .componentOutOfRange(component):
            "Display P3 component \(component) is outside 0 to 1 or 0% to 100%."
        }
    }
}

/// Reads a Display P3 color from numbers or percentages.
struct DisplayP3Parser: Sendable {
    func parse(_ input: String) throws -> DisplayP3Color {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DisplayP3ParseError.empty }

        let body: String
        if trimmed.lowercased().hasPrefix("color(") {
            guard trimmed.hasSuffix(")"),
                  let opening = trimmed.firstIndex(of: "(") else {
                throw DisplayP3ParseError.invalidSyntax
            }
            let inner = trimmed[trimmed.index(after: opening)..<trimmed.index(before: trimmed.endIndex)]
            let tokens = inner.split(whereSeparator: \.isWhitespace).map(String.init)
            guard tokens.count == 4, tokens[0].lowercased() == "display-p3" else {
                throw DisplayP3ParseError.invalidSyntax
            }
            body = tokens.dropFirst().joined(separator: " ")
        } else {
            body = trimmed
        }

        guard !body.contains("/") else { throw DisplayP3ParseError.invalidSyntax }
        let components = body.split(whereSeparator: \.isWhitespace).map(String.init)
        guard components.count == 3 else { throw DisplayP3ParseError.invalidSyntax }

        return DisplayP3Color(
            red: try parseComponent(components[0]),
            green: try parseComponent(components[1]),
            blue: try parseComponent(components[2])
        )
    }

    private func parseComponent(_ token: String) throws -> Double {
        let isPercentage = token.hasSuffix("%")
        let numberText = isPercentage ? String(token.dropLast()) : token
        guard let number = Double(numberText), number.isFinite else {
            throw DisplayP3ParseError.invalidComponent(token)
        }
        let upperBound = isPercentage ? 100.0 : 1.0
        guard (0...upperBound).contains(number) else {
            throw DisplayP3ParseError.componentOutOfRange(token)
        }
        return number / upperBound
    }
}

/// The three channels a gamut result is reported per.
enum RGBChannelID: String, CaseIterable, Identifiable, Sendable {
    case red
    case green
    case blue

    var id: Self { self }

    var title: String { rawValue.capitalized }
}

/// Where one converted channel falls relative to the destination range.
enum GamutChannelPosition: String, Sendable {
    case below = "Below 0"
    case inside = "In range"
    case above = "Above 1"
}

/// One channel's converted value and its position against the sRGB range.
struct GamutChannelEvaluation: Identifiable, Hashable, Sendable {
    let id: RGBChannelID
    let encodedValue: Double
    let position: GamutChannelPosition
}

/// Whether a Display P3 color survives conversion into sRGB, per channel.
struct GamutEvaluation: Hashable, Sendable {
    let source: DisplayP3Color
    let linearP3: LinearRGBColor
    let xyzD65: XYZColor
    let linearSRGB: LinearRGBColor
    let encodedSRGB: SRGBColor
    let clippedSRGB: SRGBColor
    let channels: [GamutChannelEvaluation]

    var isInSRGBGamut: Bool {
        channels.allSatisfy { $0.position == .inside }
    }

    var clippedChannelCount: Int {
        channels.filter { $0.position != .inside }.count
    }
}

/// Converts a Display P3 color into sRGB and reports which channels leave the
/// range.
///
/// Values outside zero to one are kept rather than clamped. They are what says
/// which boundary was crossed and by how much, and clamping would turn an
/// answerable question into a flat report that the color does not fit.
struct DisplayP3GamutAnalyzer: GamutAnalyzing, Sendable {
    private let boundaryTolerance = 0.000_000_001

    func evaluate(_ color: DisplayP3Color) -> GamutEvaluation {
        let linearP3 = LinearRGBColor(
            red: TransferFunctions.sRGBToLinear(color.red),
            green: TransferFunctions.sRGBToLinear(color.green),
            blue: TransferFunctions.sRGBToLinear(color.blue)
        )

        // CSS Color 4's rational Display P3-to-XYZ D65 matrix.
        let xyzD65 = XYZColor(
            x: ((608311.0 / 1250200.0) * linearP3.red)
                + ((189793.0 / 714400.0) * linearP3.green)
                + ((198249.0 / 1000160.0) * linearP3.blue),
            y: ((35783.0 / 156275.0) * linearP3.red)
                + ((247089.0 / 357200.0) * linearP3.green)
                + ((198249.0 / 2500400.0) * linearP3.blue),
            z: ((32229.0 / 714400.0) * linearP3.green)
                + ((5220557.0 / 5000800.0) * linearP3.blue)
        )

        // CSS Color 4's rational XYZ D65-to-linear-sRGB matrix.
        let linearSRGB = LinearRGBColor(
            red: ((12831.0 / 3959.0) * xyzD65.x)
                - ((329.0 / 214.0) * xyzD65.y)
                - ((1974.0 / 3959.0) * xyzD65.z),
            green: (-(851781.0 / 878810.0) * xyzD65.x)
                + ((1648619.0 / 878810.0) * xyzD65.y)
                + ((36519.0 / 878810.0) * xyzD65.z),
            blue: ((705.0 / 12673.0) * xyzD65.x)
                - ((2585.0 / 12673.0) * xyzD65.y)
                + ((705.0 / 667.0) * xyzD65.z)
        )

        let encoded = SRGBColor(
            red: TransferFunctions.linearToSRGB(linearSRGB.red),
            green: TransferFunctions.linearToSRGB(linearSRGB.green),
            blue: TransferFunctions.linearToSRGB(linearSRGB.blue)
        )
        let channels = [
            channel(.red, value: encoded.red),
            channel(.green, value: encoded.green),
            channel(.blue, value: encoded.blue)
        ]
        let clipped = SRGBColor(
            red: clip(encoded.red),
            green: clip(encoded.green),
            blue: clip(encoded.blue)
        )

        return GamutEvaluation(
            source: color,
            linearP3: linearP3,
            xyzD65: xyzD65,
            linearSRGB: linearSRGB,
            encodedSRGB: encoded,
            clippedSRGB: clipped,
            channels: channels
        )
    }

    private func channel(_ id: RGBChannelID, value: Double) -> GamutChannelEvaluation {
        let position: GamutChannelPosition
        if value < -boundaryTolerance {
            position = .below
        } else if value > 1 + boundaryTolerance {
            position = .above
        } else {
            position = .inside
        }
        return GamutChannelEvaluation(id: id, encodedValue: value, position: position)
    }

    private func clip(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

/// The conversion equations behind the gamut result, kept for display.
enum GamutMath {
    static let p3ToXYZEquation = #"\begin{bmatrix}X\\Y\\Z\end{bmatrix}=M_{\mathrm{P3}\rightarrow\mathrm{XYZ}_{D65}}\begin{bmatrix}R_{\mathrm{lin}}\\G_{\mathrm{lin}}\\B_{\mathrm{lin}}\end{bmatrix}"#
    static let p3ToXYZReading = "The linear Display P3 channels are multiplied by the Display P3 to XYZ D65 matrix."

    static let xyzToSRGBEquation = #"\begin{bmatrix}R'_{s}\\G'_{s}\\B'_{s}\end{bmatrix}=f_{\mathrm{sRGB}}\!\left(M_{\mathrm{XYZ}_{D65}\rightarrow sRGB}\begin{bmatrix}X\\Y\\Z\end{bmatrix}\right)"#
    static let xyzToSRGBReading = "XYZ D65 is converted to linear sRGB, then the sRGB encoding function produces the three encoded channels."

    static let clippingEquation = #"c_{\mathrm{clip}}=\min\!\left(1,\max\!\left(0,c\right)\right)"#
    static let clippingReading = "For this comparison, each encoded sRGB channel is limited to the interval from zero to one."
}
