import Foundation

/// Why a compositing result could not be calculated.
enum AlphaCompositingError: LocalizedError, Equatable {
    case backdropMustBeOpaque

    var errorDescription: String? {
        switch self {
        case .backdropMustBeOpaque:
            "This calculation needs an opaque backdrop. A translucent backdrop requires another layer beneath it."
        }
    }
}

/// The result of placing one translucent color over an opaque backdrop.
struct SourceOverComposite: Hashable, Sendable {
    let source: SRGBColor
    let backdrop: SRGBColor
    let result: SRGBColor
    let sourceContribution: Double
    let backdropContribution: Double
}

/// Simple source-over compositing of encoded sRGB components onto an opaque backdrop.
/// Simple alpha compositing, source over, on encoded sRGB components.
///
/// Scope is deliberately narrow. Blend modes, group opacity, translucent
/// backdrops, and high dynamic range rendering are all out, and the interface
/// says so rather than letting the result be read as general.
struct SourceOverCompositor: Sendable {
    func composite(
        source: SRGBColor,
        overOpaque backdrop: SRGBColor
    ) throws -> SourceOverComposite {
        guard backdrop.alpha >= 1 else {
            throw AlphaCompositingError.backdropMustBeOpaque
        }
        return compositeOverOpaqueBackdrop(source: source, backdrop: backdrop)
    }

    func compositeOverOpaqueBackdrop(
        source: SRGBColor,
        backdrop: SRGBColor
    ) -> SourceOverComposite {
        let opaqueBackdrop = backdrop.opaque

        let sourceAlpha = min(max(source.alpha, 0), 1)
        let backdropWeight = 1 - sourceAlpha
        let result = SRGBColor(
            red: (source.red * sourceAlpha) + (opaqueBackdrop.red * backdropWeight),
            green: (source.green * sourceAlpha) + (opaqueBackdrop.green * backdropWeight),
            blue: (source.blue * sourceAlpha) + (opaqueBackdrop.blue * backdropWeight),
            alpha: 1
        )

        return SourceOverComposite(
            source: source,
            backdrop: opaqueBackdrop,
            result: result,
            sourceContribution: sourceAlpha,
            backdropContribution: backdropWeight
        )
    }
}

/// The source over equation, kept for display.
enum AlphaCompositingMath {
    static let opaqueBackdropEquation = #"C_o = \alpha_s\,C_s + (1 - \alpha_s)\,C_b"#
    static let opaqueBackdropReading = "Each output encoded sRGB component equals source alpha times the source component, plus one minus source alpha times the backdrop component."
}
