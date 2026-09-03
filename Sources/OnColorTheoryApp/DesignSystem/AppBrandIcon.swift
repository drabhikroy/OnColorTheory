import AppKit
import SwiftUI

/// The app mark, loaded from the bundled brand image, falling back to shapes
/// rendered in code if that image is missing.
struct AppBrandIcon: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = Self.image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                DesignedSymbolIcon(symbolName: "scope", motif: .spectrum, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .accessibilityHidden(true)
    }

    private static let image: NSImage? = {
        let extensions = ["png", "svg"]
        for fileExtension in extensions {
            let direct = Bundle.module.url(
                forResource: "OnColorTheoryAppIcon",
                withExtension: fileExtension
            )
            let nested = Bundle.module.url(
                forResource: "OnColorTheoryAppIcon",
                withExtension: fileExtension,
                subdirectory: "Brand"
            )
            if let url = direct ?? nested,
               let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
    }()
}
