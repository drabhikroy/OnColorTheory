import AppKit
import Combine

@MainActor
/// Reads the color of a pixel the person points at.
///
/// What comes back is the composited screen pixel, not the source asset. Its
/// original color space, any color management applied on the way to the
/// display, and anything layered above it are all already folded in.
final class ScreenColorSampler: ObservableObject {
    @Published private(set) var isSampling = false

    private var activeSampler: NSColorSampler?

    func sample(_ completion: @escaping @MainActor @Sendable (SRGBColor) -> Void) {
        guard !isSampling else { return }

        let sampler = NSColorSampler()
        activeSampler = sampler
        isSampling = true

        sampler.show { [weak self] selectedColor in
            let color = selectedColor.flatMap(Self.sRGBColor(from:))
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isSampling = false
                self.activeSampler = nil
                if let color { completion(color) }
            }
        }
    }

    nonisolated static func sRGBColor(from color: NSColor) -> SRGBColor? {
        guard let converted = color.usingColorSpace(.sRGB) else { return nil }
        return SRGBColor(
            red: Double(converted.redComponent),
            green: Double(converted.greenComponent),
            blue: Double(converted.blueComponent),
            alpha: Double(converted.alphaComponent)
        )
    }
}
