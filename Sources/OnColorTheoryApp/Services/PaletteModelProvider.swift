import Foundation

/// A provider may propose palette candidates. It never supplies authoritative
/// contrast, conversion, gamut, difference, or vision-simulation results.
/// The model side of a palette suggestion, kept behind a protocol so the
/// suggestion path can be tested without a model.
protocol PaletteModelProvider: Sendable {
    var identity: PaletteModelIdentity { get }
    func proposePalette(for request: PaletteGenerationRequest) async throws -> PaletteProposal
}

/// Which model produced a suggestion, recorded so the result can be traced.
struct PaletteModelIdentity: Hashable, Sendable {
    let name: String
    let version: String
    let license: String
    let runsLocally: Bool
}

/// Exactly what gets sent to the model, and nothing else.
///
/// Keeping the request as one small type is what lets the review screen show
/// the person the whole payload before it leaves the machine.
struct PaletteGenerationRequest: Hashable, Sendable {
    enum Purpose: String, Hashable, Sendable {
        case interface
        case categoricalData
        case sequentialData
        case divergingData
        case textAndBackground
        case decorative
    }

    let purpose: Purpose
    let description: String
    let desiredColorCount: Int?
    let existingColors: [ColorRecord]
    let lockedColorIDs: Set<UUID>
}

/// One color a model suggested, with the reason it gave.
struct ProposedColor: Hashable, Sendable {
    let color: SRGBColor
    let rationale: String
}

/// A full suggestion, before any of the app's own checks have run on it.
struct PaletteProposal: Hashable, Sendable {
    let provider: PaletteModelIdentity
    let colors: [ProposedColor]
    let summary: String
}

