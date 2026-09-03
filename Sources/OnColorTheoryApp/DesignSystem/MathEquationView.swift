import AppKit
import SwiftMath
import SwiftUI

/// Checks that a LaTeX string will typeset before it is shown.
///
/// An equation that fails to parse renders as nothing at all, which would leave
/// a blank panel with no indication that anything was missing.
enum MathEquationValidator {
    static func errorDescription(in latex: String) -> String? {
        var error: NSError?
        _ = MTMathListBuilder.build(fromString: latex, error: &error)
        return error?.localizedDescription
    }
}

/// A native LaTeX math surface with an explicit spoken equivalent.
struct MathEquationView: NSViewRepresentable {
    @Environment(\.appTextScale) private var textScale

    let latex: String
    let accessibilityLabel: String
    var baseFontSize: CGFloat = 22
    var labelMode: MTMathUILabelMode = .display
    var textAlignment: MTTextAlignment = .center

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyDown
        view.imageAlignment = .alignCenter
        view.imageFrameStyle = .none
        view.contentTintColor = .labelColor
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.staticText)
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        let fontSize = baseFontSize * textScale
        var renderer = SwiftMath.MathImage(
            latex: latex,
            fontSize: fontSize,
            textColor: .black,
            labelMode: labelMode,
            textAlignment: textAlignment
        )
        renderer.font = .latinModernFont
        renderer.contentInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        let (_, image, _) = renderer.asImage()
        image?.isTemplate = true
        view.image = image
        view.setAccessibilityLabel(accessibilityLabel)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: NSImageView,
        context: Context
    ) -> CGSize? {
        let naturalSize = nsView.image?.size ?? CGSize(
            width: proposal.width ?? 1,
            height: baseFontSize * textScale * 1.45
        )
        let availableWidth = proposal.width ?? naturalSize.width
        let scale = min(availableWidth / max(naturalSize.width, 1), 1)
        return CGSize(
            width: availableWidth,
            height: max(naturalSize.height * scale, baseFontSize * textScale * 1.45)
        )
    }
}
