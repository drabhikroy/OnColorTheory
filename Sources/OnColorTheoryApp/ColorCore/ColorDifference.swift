import Foundation

/// The four questions the Check workspace can answer about a color pair.
enum CheckAnalysisID: String, CaseIterable, Identifiable, Sendable {
    case contrast
    case difference
    case gamut
    case colorReliance = "color-reliance"

    var id: Self { self }

    var title: String {
        switch self {
        case .contrast: "Check contrast"
        case .difference: "Compare differences"
        case .gamut: "See color-space limits"
        case .colorReliance: "Review meaning without color"
        }
    }

    var compactTitle: String {
        switch self {
        case .contrast: "Contrast"
        case .difference: "Difference"
        case .gamut: "Gamut"
        case .colorReliance: "Meaning"
        }
    }

    var summary: String {
        switch self {
        case .contrast: "Test whether a foreground and background meet named WCAG relationships."
        case .difference: "Estimate the relative perceptual difference between two colors."
        case .gamut: "Find colors that a standard web color space cannot reproduce unchanged."
        case .colorReliance: "Preview light and dark information alone and find meaning that depends only on hue."
        }
    }

    var symbolName: String {
        switch self {
        case .contrast: "circle.lefthalf.filled"
        case .difference: "circle.grid.cross"
        case .gamut: "triangle"
        case .colorReliance: "circle.bottomhalf.filled"
        }
    }

    var iconMotif: DesignedIconMotif {
        switch self {
        case .contrast: .split
        case .difference: .overlap
        case .gamut: .spectrum
        case .colorReliance: .compare
        }
    }
}

/// The three weighting factors CIEDE2000 leaves to the application.
///
/// All three default to one, which is the reference condition. They are named
/// rather than inlined because a difference reported without them stated is not
/// reproducible.
struct CIEDE2000ParametricFactors: Hashable, Sendable {
    let lightness: Double
    let chroma: Double
    let hue: Double

    static let unit = CIEDE2000ParametricFactors(lightness: 1, chroma: 1, hue: 1)
}

/// One CIEDE2000 result together with the term sizes that produced it.
struct ColorDifferenceEvaluation: Hashable, Sendable {
    let reference: LabColor
    let sample: LabColor
    let deltaE00: Double
    let deltaLightnessPrime: Double
    let deltaChromaPrime: Double
    let deltaHuePrime: Double
    let weightedLightnessTerm: Double
    let weightedChromaTerm: Double
    let weightedHueTerm: Double
    let rotationTerm: Double
    let lightnessScale: Double
    let chromaScale: Double
    let hueScale: Double
    let factors: CIEDE2000ParametricFactors
}

/// CIEDE2000 as defined in ISO/CIE 11664-6.
///
/// The hue difference branches are the part implementations usually get wrong,
/// since the shorter way around the hue circle has to be chosen before the term
/// is squared. The rotation term is likewise only active in the blue region.
struct CIEDE2000DifferenceCalculator: ColorDifferenceCalculating, Sendable {
    func difference(between first: LabColor, and second: LabColor) -> Double {
        evaluate(reference: first, sample: second).deltaE00
    }

    func evaluate(
        reference: LabColor,
        sample: LabColor,
        factors: CIEDE2000ParametricFactors = .unit
    ) -> ColorDifferenceEvaluation {
        precondition(
            factors.lightness > 0 && factors.chroma > 0 && factors.hue > 0,
            "CIEDE2000 parametric factors must be positive."
        )

        let referenceChromaAB = hypot(reference.a, reference.b)
        let sampleChromaAB = hypot(sample.a, sample.b)
        let meanChromaAB = (referenceChromaAB + sampleChromaAB) / 2
        let meanChromaPower7 = pow(meanChromaAB, 7)
        let correction = 0.5 * (
            1 - sqrt(meanChromaPower7 / (meanChromaPower7 + pow(25, 7)))
        )

        let referenceAPrime = (1 + correction) * reference.a
        let sampleAPrime = (1 + correction) * sample.a
        let referenceChromaPrime = hypot(referenceAPrime, reference.b)
        let sampleChromaPrime = hypot(sampleAPrime, sample.b)
        let chromaProduct = referenceChromaPrime * sampleChromaPrime

        let referenceHuePrime = hueRadians(a: referenceAPrime, b: reference.b)
        let sampleHuePrime = hueRadians(a: sampleAPrime, b: sample.b)

        let deltaLightnessPrime = sample.lightness - reference.lightness
        let deltaChromaPrime = sampleChromaPrime - referenceChromaPrime

        var deltaHueAngle = sampleHuePrime - referenceHuePrime
        if deltaHueAngle > .pi {
            deltaHueAngle -= 2 * .pi
        } else if deltaHueAngle < -.pi {
            deltaHueAngle += 2 * .pi
        }
        if chromaProduct == 0 {
            deltaHueAngle = 0
        }
        let deltaHuePrime = 2 * sqrt(chromaProduct) * sin(deltaHueAngle / 2)

        let meanLightnessPrime = (reference.lightness + sample.lightness) / 2
        let meanChromaPrime = (referenceChromaPrime + sampleChromaPrime) / 2

        var meanHuePrime = (referenceHuePrime + sampleHuePrime) / 2
        if abs(referenceHuePrime - sampleHuePrime) > .pi {
            meanHuePrime -= .pi
        }
        if meanHuePrime < 0 {
            meanHuePrime += 2 * .pi
        }
        if chromaProduct == 0 {
            meanHuePrime = referenceHuePrime + sampleHuePrime
        }

        let lightnessOffsetSquared = pow(meanLightnessPrime - 50, 2)
        let lightnessScale = 1 + (
            0.015 * lightnessOffsetSquared / sqrt(20 + lightnessOffsetSquared)
        )
        let chromaScale = 1 + (0.045 * meanChromaPrime)
        let hueWeight = 1
            - (0.17 * cos(meanHuePrime - (.pi / 6)))
            + (0.24 * cos(2 * meanHuePrime))
            + (0.32 * cos((3 * meanHuePrime) + (.pi / 30)))
            - (0.20 * cos((4 * meanHuePrime) - (63 * .pi / 180)))
        let hueScale = 1 + (0.015 * meanChromaPrime * hueWeight)

        let meanHueDegrees = meanHuePrime * 180 / .pi
        let deltaTheta = (.pi / 6) * exp(-pow((meanHueDegrees - 275) / 25, 2))
        let meanChromaPrimePower7 = pow(meanChromaPrime, 7)
        let chromaRotation = 2 * sqrt(
            meanChromaPrimePower7 / (meanChromaPrimePower7 + pow(25, 7))
        )
        let rotationTerm = -sin(2 * deltaTheta) * chromaRotation

        let weightedLightnessTerm = deltaLightnessPrime / (factors.lightness * lightnessScale)
        let weightedChromaTerm = deltaChromaPrime / (factors.chroma * chromaScale)
        let weightedHueTerm = deltaHuePrime / (factors.hue * hueScale)
        let squaredDifference = pow(weightedLightnessTerm, 2)
            + pow(weightedChromaTerm, 2)
            + pow(weightedHueTerm, 2)
            + (rotationTerm * weightedChromaTerm * weightedHueTerm)

        return ColorDifferenceEvaluation(
            reference: reference,
            sample: sample,
            deltaE00: sqrt(max(squaredDifference, 0)),
            deltaLightnessPrime: deltaLightnessPrime,
            deltaChromaPrime: deltaChromaPrime,
            deltaHuePrime: deltaHuePrime,
            weightedLightnessTerm: weightedLightnessTerm,
            weightedChromaTerm: weightedChromaTerm,
            weightedHueTerm: weightedHueTerm,
            rotationTerm: rotationTerm,
            lightnessScale: lightnessScale,
            chromaScale: chromaScale,
            hueScale: hueScale,
            factors: factors
        )
    }

    private func hueRadians(a: Double, b: Double) -> Double {
        guard a != 0 || b != 0 else { return 0 }
        let angle = atan2(b, a)
        return angle < 0 ? angle + (2 * .pi) : angle
    }
}

/// The CIEDE2000 terms as display equations.
enum ColorDifferenceMath {
    static let lightnessTermEquation = #"x_L=\frac{\Delta L'}{k_LS_L}"#
    static let chromaTermEquation = #"x_C=\frac{\Delta C'}{k_CS_C}"#
    static let hueTermEquation = #"x_H=\frac{\Delta H'}{k_HS_H}"#
    static let normalizedTermsEquation = #"x_L=\frac{\Delta L'}{k_LS_L},\qquad x_C=\frac{\Delta C'}{k_CS_C},\qquad x_H=\frac{\Delta H'}{k_HS_H}"#
    static let normalizedTermsReading = "The signed lightness, chroma, and hue differences are each divided by a parametric factor and a location-dependent scale."

    static let combinationEquation = #"\Delta E_{00}=\sqrt{x_L^2+x_C^2+x_H^2+R_Tx_Cx_H}"#
    static let combinationReading = "Delta E zero zero is the square root of the three squared weighted terms plus a rotation interaction between chroma and hue."
}
