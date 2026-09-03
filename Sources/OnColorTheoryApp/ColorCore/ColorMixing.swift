import Foundation

/// The two spaces a mix can be calculated in.
///
/// Mixing in encoded sRGB and mixing in linear light give visibly different
/// midpoints. Only the linear result models what happens when light is added,
/// which is the point the Explore experiment makes.
enum ColorMixingSpace: String, CaseIterable, Identifiable, Sendable {
    case encodedSRGB
    case linearSRGB

    var id: Self { self }
}

/// The interpolation equations, kept for display.
enum ColorMixingMath {
    static let encodedEquation = #"c_{\mathrm{mix}}=(1-t)c_1+t c_2"#
    static let encodedReading = "The mixed component equals one minus the position times the first encoded component, plus the position times the second encoded component."

    static let linearEquation = #"c_{\mathrm{mix}}=f^{-1}\left((1-t)f(c_1)+t f(c_2)\right)"#
    static let linearReading = "Decode both components with the sRGB transfer function, average them at the chosen position, then apply the inverse function to encode the result."
}

/// The same mix calculated both ways, for side by side comparison.
struct ColorMixComparison: Sendable {
    let encodedSRGB: SRGBColor
    let linearSRGB: SRGBColor
    let position: Double
}

/// Deterministic interpolation kept separate from explanatory copy and model output.
/// Interpolates between two colors in either space.
struct ColorMixer: Sendable {
    func mix(
        _ first: SRGBColor,
        _ second: SRGBColor,
        position: Double,
        in space: ColorMixingSpace
    ) -> SRGBColor {
        let t = min(max(position, 0), 1)
        if t == 0 { return first }
        if t == 1 { return second }
        let alpha = interpolate(first.alpha, second.alpha, at: t)

        func component(_ firstValue: Double, _ secondValue: Double) -> Double {
            let firstWorking = workingValue(firstValue, in: space) * first.alpha
            let secondWorking = workingValue(secondValue, in: space) * second.alpha
            let premultiplied = interpolate(firstWorking, secondWorking, at: t)
            let unpremultiplied = alpha == 0 ? 0 : premultiplied / alpha
            return min(max(encodedValue(unpremultiplied, from: space), 0), 1)
        }

        return SRGBColor(
            red: component(first.red, second.red),
            green: component(first.green, second.green),
            blue: component(first.blue, second.blue),
            alpha: alpha
        )
    }

    func compare(
        _ first: SRGBColor,
        _ second: SRGBColor,
        position: Double
    ) -> ColorMixComparison {
        ColorMixComparison(
            encodedSRGB: mix(first, second, position: position, in: .encodedSRGB),
            linearSRGB: mix(first, second, position: position, in: .linearSRGB),
            position: min(max(position, 0), 1)
        )
    }

    private func interpolate(_ first: Double, _ second: Double, at position: Double) -> Double {
        ((1 - position) * first) + (position * second)
    }

    private func workingValue(_ encoded: Double, in space: ColorMixingSpace) -> Double {
        switch space {
        case .encodedSRGB: encoded
        case .linearSRGB: TransferFunctions.sRGBToLinear(encoded)
        }
    }

    private func encodedValue(_ working: Double, from space: ColorMixingSpace) -> Double {
        switch space {
        case .encodedSRGB: working
        case .linearSRGB: TransferFunctions.linearToSRGB(working)
        }
    }
}
