import SwiftUI

/// The abstract shape drawn behind a section symbol.
///
/// Motifs are geometric rather than pictorial so they survive being redrawn at
/// any size and carry no meaning that a label does not already state.
enum DesignedIconMotif: Hashable, Sendable {
    case grid
    case stack
    case orbit
    case split
    case swatches
    case compare
    case books
    case overlap
    case layers
    case steps
    case type
    case measure
    case path
    case spectrum
}

/// A section icon, presented either as a plain symbol or over its motif.
///
/// Two presentations exist because the same icon has to work at two very
/// different sizes. At sidebar size the motif is smaller than a few points and
/// resolves into noise, so only the symbol is drawn. At card size the motif has
/// room to read and gives each section something to be recognized by besides
/// its label. The cutoff sits at 40 points, below which the motif is dropped.
struct DesignedSymbolIcon: View {
    let symbolName: String
    let motif: DesignedIconMotif
    var size: CGFloat = 52

    @Environment(\.appSemanticPalette) private var palette

    /// Motif artwork is only legible once the icon has room for it.
    private var showsMotif: Bool { size >= 40 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.accent.opacity(0.16), palette.secondaryCue.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if showsMotif {
                DesignedMotifArtwork(
                    motif: motif,
                    accent: palette.accent,
                    secondary: palette.secondaryCue,
                    supporting: palette.positive
                )
                .padding(size * 0.13)

                // A disc behind the symbol so it stays readable over the motif.
                // Without the motif there is nothing to separate it from, and
                // the disc only eats space that the symbol could use.
                Circle()
                    .fill(.background.opacity(0.86))
                    .frame(width: size * 0.46, height: size * 0.46)
            }

            Image(systemName: symbolName)
                .font(.system(size: size * (showsMotif ? 0.27 : 0.52), weight: .semibold))
                .foregroundStyle(showsMotif ? Color.primary : palette.accent)
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .strokeBorder(palette.accent.opacity(0.22), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

/// The icon for one workspace, at whatever size the caller needs.
struct AppSectionIcon: View {
    let section: AppSection
    var size: CGFloat = 52

    var body: some View {
        DesignedSymbolIcon(
            symbolName: section.symbolName,
            motif: section.designedIconMotif,
            size: size
        )
    }
}

extension AppSection {
    var designedIconMotif: DesignedIconMotif {
        switch self {
        case .home: .grid
        case .learn: .stack
        case .explore: .orbit
        case .convert: .split
        case .build: .swatches
        case .check: .compare
        case .reference: .books
        }
    }
}

/// Draws one motif from primitives, so nothing here depends on a bundled image.
private struct DesignedMotifArtwork: View {
    let motif: DesignedIconMotif
    let accent: Color
    let secondary: Color
    let supporting: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                switch motif {
                case .grid:
                    grid(width: width, height: height)
                case .stack:
                    stack(width: width, height: height)
                case .orbit:
                    orbit(width: width, height: height)
                case .split:
                    split(width: width, height: height)
                case .swatches:
                    swatches(width: width, height: height)
                case .compare:
                    compare(width: width, height: height)
                case .books:
                    books(width: width, height: height)
                case .overlap:
                    overlap(width: width, height: height)
                case .layers:
                    layers(width: width, height: height)
                case .steps:
                    steps(width: width, height: height)
                case .type:
                    typeBlocks(width: width, height: height)
                case .measure:
                    measure(width: width, height: height)
                case .path:
                    path(width: width, height: height)
                case .spectrum:
                    spectrum(width: width, height: height)
                }
            }
            .frame(width: width, height: height)
        }
    }

    private func grid(width: CGFloat, height: CGFloat) -> some View {
        let side = min(width, height) * 0.37
        return ZStack {
            RoundedRectangle(cornerRadius: side * 0.28).fill(accent.opacity(0.82))
                .frame(width: side, height: side).offset(x: -side * 0.48, y: -side * 0.48)
            RoundedRectangle(cornerRadius: side * 0.28).fill(secondary.opacity(0.78))
                .frame(width: side, height: side).offset(x: side * 0.48, y: -side * 0.48)
            RoundedRectangle(cornerRadius: side * 0.28).fill(supporting.opacity(0.74))
                .frame(width: side, height: side).offset(x: -side * 0.48, y: side * 0.48)
            RoundedRectangle(cornerRadius: side * 0.28).fill(accent.opacity(0.52))
                .frame(width: side, height: side).offset(x: side * 0.48, y: side * 0.48)
        }
    }

    private func stack(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            roundedBlock(width, height, color: secondary.opacity(0.70)).offset(x: width * 0.13, y: height * 0.13)
            roundedBlock(width, height, color: supporting.opacity(0.66))
            roundedBlock(width, height, color: accent.opacity(0.76)).offset(x: -width * 0.13, y: -height * 0.13)
        }
    }

    private func orbit(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .stroke(accent.opacity(0.72), lineWidth: max(width * 0.09, 2))
                .frame(width: width * 0.82, height: height * 0.54)
                .rotationEffect(.degrees(-22))
            Circle().fill(secondary.opacity(0.86)).frame(width: width * 0.28).offset(x: width * 0.28, y: -height * 0.18)
            Circle().fill(supporting.opacity(0.82)).frame(width: width * 0.22).offset(x: -width * 0.29, y: height * 0.16)
        }
    }

    private func split(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: -width * 0.08) {
            Capsule().fill(accent.opacity(0.78)).frame(width: width * 0.55, height: height * 0.42)
            Capsule().fill(secondary.opacity(0.76)).frame(width: width * 0.55, height: height * 0.42)
        }
        .rotationEffect(.degrees(-10))
    }

    private func swatches(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.11).fill(supporting.opacity(0.72))
                .frame(width: width * 0.56, height: height * 0.70).rotationEffect(.degrees(-24)).offset(x: -width * 0.12)
            RoundedRectangle(cornerRadius: width * 0.11).fill(secondary.opacity(0.72))
                .frame(width: width * 0.56, height: height * 0.70).rotationEffect(.degrees(20)).offset(x: width * 0.12)
            RoundedRectangle(cornerRadius: width * 0.11).fill(accent.opacity(0.76))
                .frame(width: width * 0.56, height: height * 0.70)
        }
    }

    private func compare(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: -width * 0.16) {
            Circle().fill(accent.opacity(0.76)).frame(width: width * 0.62)
            Circle().fill(secondary.opacity(0.72)).frame(width: width * 0.62)
        }
    }

    private func books(width: CGFloat, height: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: width * 0.07) {
            RoundedRectangle(cornerRadius: width * 0.08).fill(accent.opacity(0.80))
                .frame(width: width * 0.24, height: height * 0.68)
            RoundedRectangle(cornerRadius: width * 0.08).fill(secondary.opacity(0.76))
                .frame(width: width * 0.24, height: height * 0.86)
            RoundedRectangle(cornerRadius: width * 0.08).fill(supporting.opacity(0.72))
                .frame(width: width * 0.24, height: height * 0.56)
        }
    }

    private func overlap(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: -width * 0.20) {
            Circle().fill(accent.opacity(0.80)).frame(width: width * 0.62)
            Circle().fill(secondary.opacity(0.78)).frame(width: width * 0.62)
        }
    }

    private func layers(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            roundedBlock(width, height, color: secondary.opacity(0.72)).offset(x: width * 0.15, y: height * 0.12)
            roundedBlock(width, height, color: accent.opacity(0.76)).offset(x: -width * 0.15, y: -height * 0.12)
        }
    }

    private func steps(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Capsule().fill(accent.opacity(0.82)).frame(width: width * 0.58, height: height * 0.22).offset(x: -width * 0.16, y: height * 0.23)
            Capsule().fill(secondary.opacity(0.78)).frame(width: width * 0.58, height: height * 0.22)
            Capsule().fill(supporting.opacity(0.76)).frame(width: width * 0.58, height: height * 0.22).offset(x: width * 0.16, y: -height * 0.23)
        }
    }

    private func typeBlocks(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.12).fill(accent.opacity(0.78))
                .frame(width: width * 0.72, height: height * 0.50).offset(x: -width * 0.10, y: -height * 0.12)
            RoundedRectangle(cornerRadius: width * 0.12).fill(secondary.opacity(0.74))
                .frame(width: width * 0.72, height: height * 0.50).offset(x: width * 0.10, y: height * 0.12)
        }
    }

    private func measure(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Circle().stroke(accent.opacity(0.82), lineWidth: max(width * 0.13, 2)).frame(width: width * 0.76)
            Capsule().fill(secondary.opacity(0.82)).frame(width: width * 0.78, height: height * 0.18).rotationEffect(.degrees(-38))
            Circle().fill(supporting.opacity(0.86)).frame(width: width * 0.24).offset(x: width * 0.24, y: -height * 0.22)
        }
    }

    private func path(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Capsule().fill(accent.opacity(0.74)).frame(width: width * 0.86, height: height * 0.14).rotationEffect(.degrees(-26))
            Circle().fill(accent).frame(width: width * 0.26).offset(x: -width * 0.30, y: height * 0.16)
            Circle().fill(secondary).frame(width: width * 0.26)
            Circle().fill(supporting).frame(width: width * 0.26).offset(x: width * 0.30, y: -height * 0.16)
        }
    }

    private func spectrum(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: -width * 0.12) {
            Circle().fill(accent.opacity(0.82)).frame(width: width * 0.48)
            Circle().fill(supporting.opacity(0.78)).frame(width: width * 0.48)
            Circle().fill(secondary.opacity(0.80)).frame(width: width * 0.48)
        }
    }

    private func roundedBlock(_ width: CGFloat, _ height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: width * 0.10)
            .fill(color)
            .frame(width: width * 0.70, height: height * 0.52)
    }
}
