import SwiftUI

/// The check for meaning that depends on hue alone.
///
/// Colors are shown normally and again as neutrals of the same calculated
/// luminance. Whatever stops being distinguishable in the second view is
/// carried by hue and needs another channel as well.
struct ColorRelianceAnalysisView: View {
    @Environment(\.appSemanticPalette) private var palette
    @ObservedObject var model: AppModel
    let page: CheckWorkspacePage
    @Environment(\.appTextScale) private var textScale

    private let previewer = ColorReliancePreviewer()

    private var evaluation: ColorRelianceEvaluation {
        previewer.evaluate(
            first: model.checkForegroundColor,
            second: model.checkBackgroundColor
        )
    }

    var body: some View {
        Group {
            switch page {
            case .results:
                VStack(alignment: .leading, spacing: AppMetrics.regular) {
                    inputCard
                    AdaptivePairLayout(
                        horizontalThreshold: textScale >= 1.3 ? 1_050 : 820,
                        leadingFraction: 0.52,
                        spacing: AppMetrics.regular
                    ) {
                        previewCard
                        reviewCard
                    }
                }
            case .method:
                calculationCard
            }
        }
    }

    private var inputCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: AppMetrics.compact) {
                        inputHeading
                        Spacer()
                        examplesMenu
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        inputHeading
                        examplesMenu
                    }
                }

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_000 : 650,
                    leadingFraction: 0.5,
                    spacing: AppMetrics.compact
                ) {
                    EditableColorInput(
                        title: "First color",
                        color: $model.checkForegroundColor,
                        swatchSize: 56
                    )
                    EditableColorInput(
                        title: "Second color",
                        color: $model.checkBackgroundColor,
                        swatchSize: 56
                    )
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppMetrics.snug) { inputActions }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) { inputActions }
                }
                .appFont(.body)
            }
        }
    }

    private var inputHeading: some View {
        PanelHeading(
            title: "Two colors used to convey meaning",
            summary: "Use the pair from a state, category, link, chart, or other relationship in the design you are reviewing."
        )
    }

    private var examplesMenu: some View {
        Menu("Examples", systemImage: "square.grid.2x2") {
            ForEach(ColorReliancePreset.allCases) { preset in
                Button(preset.rawValue) {
                    model.checkForegroundColor = preset.colors.0
                    model.checkBackgroundColor = preset.colors.1
                }
            }
        }
        .appFont(.body)
    }

    @ViewBuilder
    private var inputActions: some View {
        Button("Swap", systemImage: "arrow.left.arrow.right") {
            let first = model.checkForegroundColor
            model.checkForegroundColor = model.checkBackgroundColor
            model.checkBackgroundColor = first
        }

        Button("Use Convert color first", systemImage: "arrow.down.left") {
            model.checkForegroundColor = model.analysis.parsed.color.opaque
        }
    }

    private var previewCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                PanelHeading(
                    title: "Original and light and dark preview",
                    summary: "The second view removes hue while preserving each color's calculated relative luminance."
                )

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_000 : 650,
                    leadingFraction: 0.5,
                    spacing: AppMetrics.compact
                ) {
                    ColorReliancePairPanel(
                        title: "Original colors",
                        first: evaluation.first,
                        second: evaluation.second,
                        symbolName: "paintpalette"
                    )
                    ColorReliancePairPanel(
                        title: "Neutral preview",
                        first: evaluation.firstNeutral,
                        second: evaluation.secondNeutral,
                        symbolName: "circle.bottomhalf.filled"
                    )
                }

                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Calculated light and dark values")
                            .appFont(.headline)
                        Spacer()
                        Text("Separation \(Format.decimal(evaluation.luminanceSeparation, places: 4))")
                            .appFont(.value)
                            .monospacedDigit()
                    }

                    LuminanceValueBar(
                        title: "First",
                        value: evaluation.firstRelativeLuminance
                    )
                    LuminanceValueBar(
                        title: "Second",
                        value: evaluation.secondRelativeLuminance
                    )

                    Text("These values describe this defined calculation. This tool does not assign a pass or fail to the pair.")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TermHelpRow(conceptIDs: ["neutral-preview", "relative-luminance"])
            }
        }
    }

    private var reviewCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                VStack(alignment: .leading, spacing: AppMetrics.tight) {
                    Text("Review the meaning, not only the pair")
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    Text("A pair of values cannot tell the app what the colors mean in the finished interface. Inspect the complete design using these three prompts.")
                        .appFont(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LazyVGrid(columns: reviewColumns, alignment: .leading, spacing: AppMetrics.compact) {
                    ReviewPrompt(
                        title: "Name it",
                        detail: "Does visible text identify the state, category, action, or result?",
                        symbolName: "textformat"
                    )
                    ReviewPrompt(
                        title: "Show it another way",
                        detail: "Does a symbol, shape, pattern, position, or underline reinforce the difference?",
                        symbolName: "square.on.circle"
                    )
                    ReviewPrompt(
                        title: "Check every state",
                        detail: "Do focus, hover, selected, success, and error states retain a non-color cue?",
                        symbolName: "cursorarrow.motionlines"
                    )
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AppMetrics.compact) {
                        reviewBoundaryText
                        Spacer(minLength: 8)
                        contrastButton
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        reviewBoundaryText
                        contrastButton
                    }
                }

                TermHelpRow(conceptIDs: ["color-reliance"])
            }
        }
    }

    private var reviewBoundaryText: some View {
        HStack(alignment: .top, spacing: AppMetrics.compact) {
            Image(systemName: "info.circle")
                .foregroundStyle(palette.accent)
                .accessibilityHidden(true)
            Text("WCAG requires another visible means when color carries information. A neutral preview supports review but does not replace checking the actual design and task.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var contrastButton: some View {
        Button("Check this pair's contrast", systemImage: "arrow.right") {
            model.selectedCheckAnalysis = .contrast
        }
        .buttonStyle(.bordered)
        .appFont(.body)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var calculationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                PanelHeading(
                    title: "How the neutral preview is built",
                    summary: "The app decodes sRGB, calculates relative luminance, then encodes that value into three equal neutral channels."
                )

                RelianceEquationPanel(
                    title: "Calculate relative luminance",
                    latex: ContrastMath.relativeLuminanceEquation,
                    reading: ContrastMath.relativeLuminanceReading
                )
                RelianceEquationPanel(
                    title: "Create an equal-channel neutral",
                    latex: ColorRelianceMath.neutralEquation,
                    reading: ColorRelianceMath.neutralReading
                )

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    CoordinateRow(
                        label: "First neutral",
                        value: "\(evaluation.firstNeutral.hex) · Y \(Format.decimal(evaluation.firstRelativeLuminance))"
                    )
                    CoordinateRow(
                        label: "Second neutral",
                        value: "\(evaluation.secondNeutral.hex) · Y \(Format.decimal(evaluation.secondRelativeLuminance))"
                    )
                }

                sourceLinks
            }
        }
    }

    private var reviewColumns: [GridItem] {
        if textScale >= 1.3 {
            return [GridItem(.flexible(), spacing: AppMetrics.compact, alignment: .top)]
        }
        return [GridItem(.adaptive(minimum: 220, maximum: 360), spacing: AppMetrics.compact, alignment: .top)]
    }

    private var sourceLinks: some View {
        let records = ["w3c-wcag-22-use-of-color", "iec-srgb"]
            .compactMap(EvidenceRegistry.record(withID:))
        return VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text("Sources and limits")
                .appFont(.headline)
            ForEach(records) { record in
                Link(destination: record.sourceURL) {
                    Label(record.title, systemImage: "arrow.up.right.square")
                }
                .appFont(.body)
            }
            if let useOfColor = records.first {
                Text(useOfColor.limitation)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Starting sets for the reliance check, including a status color set, since
/// status colors are where hue-only meaning usually appears.
private enum ColorReliancePreset: String, CaseIterable, Identifiable {
    case similarLightness = "Different hues, similar lightness"
    case differentLightness = "Different hues and lightness"
    case statusColors = "Status colors"

    var id: Self { self }

    var colors: (SRGBColor, SRGBColor) {
        switch self {
        case .similarLightness:
            (Self.color(199, 70, 105), Self.color(43, 140, 130))
        case .differentLightness:
            (Self.color(242, 193, 78), Self.color(24, 59, 86))
        case .statusColors:
            (Self.color(209, 73, 91), Self.color(42, 157, 143))
        }
    }

    private static func color(_ red: Int, _ green: Int, _ blue: Int) -> SRGBColor {
        SRGBColor(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}

/// One pair shown in both the original and the neutral view.
private struct ColorReliancePairPanel: View {
    let title: String
    let first: SRGBColor
    let second: SRGBColor
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Label(title, systemImage: symbolName)
                .appFont(.headline)

            HStack {
                Text("First \(first.hex)")
                Spacer()
                Text("Second \(second.hex)")
            }
            .appFont(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()

            HStack(spacing: 0) {
                Rectangle().fill(first.swiftUIColor)
                Rectangle().fill(second.swiftUIColor)
            }
            .frame(height: 138)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.separator, lineWidth: 1)
            }
            .overlay {
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 1)
                    .accessibilityHidden(true)
            }
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("First \(first.accessibleDescription). Second \(second.accessibleDescription).")
    }
}

/// One color's calculated relative luminance as a labeled bar.
private struct LuminanceValueBar: View {
    @Environment(\.appSemanticPalette) private var palette
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            HStack {
                Text(title)
                    .appFont(.body)
                Spacer()
                Text(Format.decimal(value, places: 5))
                    .appFont(.value)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.14))
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: max(4, geometry.size.width * min(max(value, 0), 1)))
                }
            }
            .frame(height: 10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) relative luminance")
        .accessibilityValue(Format.decimal(value, places: 5))
    }
}

/// A question put to the reader about what they can still tell apart. The app
/// cannot answer this one, so it asks rather than reporting.
private struct ReviewPrompt: View {
    @Environment(\.appSemanticPalette) private var palette
    let title: String
    let detail: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 34, height: 34)
                .background(palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)
            Text(title)
                .appFont(.headline)
            Text(detail)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .appSubtleSurface(cornerRadius: 10)
    }
}

/// The luminance to neutral equation with a reading of it in words.
private struct RelianceEquationPanel: View {
    let title: String
    let latex: String
    let reading: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .appFont(.headline)
                Spacer()
                CopyValueButton(
                    value: latex,
                    description: "\(title) equation as LaTeX",
                    label: "Copy LaTeX"
                )
            }

            MathEquationView(
                latex: latex,
                accessibilityLabel: reading,
                baseFontSize: 21
            )

            Text(reading)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }
}
