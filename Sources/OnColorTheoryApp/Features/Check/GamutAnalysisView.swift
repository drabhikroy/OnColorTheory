import SwiftUI

/// The check for whether a Display P3 color survives conversion to sRGB.
struct GamutAnalysisView: View {
    @ObservedObject var model: AppModel
    let page: CheckWorkspacePage
    @Environment(\.appTextScale) private var textScale
    @State private var input: String
    @State private var inputError: String?
    @Environment(\.appSemanticPalette) private var semanticPalette

    private let analyzer = DisplayP3GamutAnalyzer()
    private let parser = DisplayP3Parser()

    init(model: AppModel, page: CheckWorkspacePage = .results) {
        self.model = model
        self.page = page
        _input = State(initialValue: model.checkDisplayP3Color.css(alpha: 1))
    }

    private var evaluation: GamutEvaluation {
        analyzer.evaluate(model.checkDisplayP3Color)
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
                        resultCard
                        channelCard
                    }
                }
            case .method:
                calculationCard
            }
        }
        .onChange(of: model.checkDisplayP3Color) { _, color in
            let representation = color.css(alpha: 1)
            if input != representation { input = representation }
            inputError = nil
        }
    }

    private var inputCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: AppMetrics.compact) {
                        inputHeading
                        Spacer()
                        presetMenu
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        inputHeading
                        presetMenu
                    }
                }

                HStack(alignment: .center, spacing: AppMetrics.compact) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(model.checkDisplayP3Color.swiftUIColor)
                        .frame(width: 72, height: 72)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(.separator, lineWidth: 1)
                        }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        HStack(spacing: AppMetrics.snug) {
                            TextField("color(display-p3 1 0.2 0.1)", text: $input)
                                .appFont(.value)
                                .monospacedDigit()
                                .textFieldStyle(.roundedBorder)
                                .onSubmit(applyInput)
                                .accessibilityLabel("Display P3 color value")
                                .accessibilityValue(inputError == nil ? "Valid value" : "Invalid value")
                                .accessibilityHint(
                                    inputError
                                        ?? "Enter three Display P3 components from zero to one, then press Return or Apply."
                                )

                            Button("Apply", action: applyInput)
                                .buttonStyle(.bordered)
                                .appFont(.body)
                        }

                        if let inputError {
                            Label(inputError, systemImage: "exclamationmark.triangle")
                                .appFont(.caption)
                                .foregroundStyle(semanticPalette.warning)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel("Input error")
                                .accessibilityValue(inputError)
                        } else {
                            Text("Use three values from 0 to 1, or percentages. This focused check uses opaque colors.")
                                .appFont(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    ForEach(RGBChannelID.allCases) { channel in
                        P3ComponentSlider(
                            channel: channel,
                            value: binding(for: channel)
                        )
                    }
                }
                .padding(AppMetrics.compact)
                .appSubtleSurface(cornerRadius: 10)

                TermHelpRow(conceptIDs: ["display-p3", "gamut"])
            }
        }
    }

    private var inputHeading: some View {
        PanelHeading(
            title: "Will this color fit in sRGB?",
            summary: "Choose a color encoded in Display P3, a wider RGB color space that shares sRGB's D65 white and transfer curve but uses different primaries."
        )
    }

    private var presetMenu: some View {
        Menu("Examples", systemImage: "square.grid.2x2") {
            ForEach(DisplayP3Preset.allCases) { preset in
                Button(preset.rawValue) {
                    model.checkDisplayP3Color = preset.color
                }
            }
        }
        .appFont(.body)
    }

    private var resultCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                HStack(alignment: .top, spacing: AppMetrics.compact) {
                    Image(systemName: evaluation.isInSRGBGamut ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(evaluation.isInSRGBGamut ? semanticPalette.positive : semanticPalette.warning)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppMetrics.tight) {
                        Text(evaluation.isInSRGBGamut ? "This color is inside sRGB" : "This color extends outside sRGB")
                            .appFont(.title2)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h2)
                        Text(resultExplanation)
                            .appFont(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_000 : 650,
                    leadingFraction: 0.5,
                    spacing: AppMetrics.compact
                ) {
                    GamutPreviewPanel(
                        title: "Display P3 source",
                        value: evaluation.source.css(alpha: 1),
                        color: evaluation.source.swiftUIColor,
                        copyDescription: "Display P3 CSS color"
                    )
                    GamutPreviewPanel(
                        title: evaluation.isInSRGBGamut ? "Equivalent sRGB" : "Simple clipped sRGB",
                        value: evaluation.clippedSRGB.hex,
                        color: evaluation.clippedSRGB.swiftUIColor,
                        copyDescription: "sRGB comparison color"
                    )
                }

                HStack(alignment: .top, spacing: AppMetrics.compact) {
                    Image(systemName: "display")
                        .foregroundStyle(semanticPalette.accent)
                        .accessibilityHidden(true)
                    Text("This is a color-managed preview. The visible difference depends on the display, system color management, and viewing conditions; the numeric result does not depend on whether this screen can show the source color fully.")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AppMetrics.compact) {
                        clippingBoundary
                        Spacer(minLength: 8)
                        openClippedButton
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        clippingBoundary
                        openClippedButton
                    }
                }
            }
        }
    }

    private var resultExplanation: String {
        if evaluation.isInSRGBGamut {
            return "All three converted sRGB channels remain between 0 and 1, so sRGB can represent this color without gamut adjustment."
        }
        let count = evaluation.clippedChannelCount
        return "\(count) converted sRGB \(count == 1 ? "channel falls" : "channels fall") outside the 0 to 1 range. Reproducing the color in sRGB therefore requires a gamut-mapping choice."
    }

    private var clippingBoundary: some View {
        Text(
            evaluation.isInSRGBGamut
                ? "The sRGB preview is the direct converted result; clipping does not change an in-range channel."
                : "The comparison limits each channel separately. It illustrates loss at the boundary, but it is not presented as the preferred mapping method."
        )
        .appFont(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var openClippedButton: some View {
        Button("Open sRGB result in Convert", systemImage: "arrow.right") {
            model.openInConvert(evaluation.clippedSRGB)
        }
        .buttonStyle(.bordered)
        .appFont(.body)
    }

    private var channelCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                PanelHeading(
                    title: "Where the converted channels land",
                    summary: "The shaded track is the sRGB reference range from 0 to 1. A boundary marker means the unadjusted value continues beyond that edge."
                )

                VStack(alignment: .leading, spacing: AppMetrics.regular) {
                    ForEach(evaluation.channels) { channel in
                        GamutChannelRow(channel: channel)
                    }
                }

                Divider()

                CoordinateRow(
                    label: "Converted sRGB",
                    value: "rgb(\(Format.decimal(evaluation.encodedSRGB.red, places: 5)) \(Format.decimal(evaluation.encodedSRGB.green, places: 5)) \(Format.decimal(evaluation.encodedSRGB.blue, places: 5)))"
                )
                CoordinateRow(
                    label: "Clipped comparison",
                    value: evaluation.clippedSRGB.hex
                )

                Text("Values outside 0 to 1 are useful intermediate coordinates: they show which destination boundary was crossed. They are not an error in the Display P3 source.")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var calculationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                PanelHeading(
                    title: "How the boundary check works",
                    summary: "The app decodes Display P3 to light-proportional channels, converts through XYZ with a D65 reference white, and then encodes the resulting sRGB channels."
                )

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_050 : 760,
                    leadingFraction: 0.5,
                    spacing: AppMetrics.compact
                ) {
                    GamutEquationPanel(
                        title: "Display P3 to XYZ",
                        latex: GamutMath.p3ToXYZEquation,
                        reading: GamutMath.p3ToXYZReading
                    )
                    GamutEquationPanel(
                        title: "XYZ to encoded sRGB",
                        latex: GamutMath.xyzToSRGBEquation,
                        reading: GamutMath.xyzToSRGBReading
                    )
                }

                GamutEquationPanel(
                    title: "Clipped comparison only",
                    latex: GamutMath.clippingEquation,
                    reading: GamutMath.clippingReading
                )

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    CoordinateRow(
                        label: "XYZ D65",
                        value: "\(Format.decimal(evaluation.xyzD65.x)), \(Format.decimal(evaluation.xyzD65.y)), \(Format.decimal(evaluation.xyzD65.z))"
                    )
                    CoordinateRow(
                        label: "Linear sRGB",
                        value: "\(Format.decimal(evaluation.linearSRGB.red)), \(Format.decimal(evaluation.linearSRGB.green)), \(Format.decimal(evaluation.linearSRGB.blue))"
                    )
                }

                TermHelpRow(conceptIDs: ["encoded-linear", "cie-xyz", "gamut-mapping"])
                sourceAndLimits
            }
        }
    }

    private var sourceAndLimits: some View {
        let records = ["w3c-css-color-4-gamut", "iec-srgb"]
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
            Text("The result tests the mathematical sRGB reference range, not the measured gamut of this Mac, another display, a printer, or a complete image. CSS Color 4 describes higher-quality gamut-mapping approaches; channel clipping is shown only because its effect is direct and easy to inspect.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func applyInput() {
        do {
            model.checkDisplayP3Color = try parser.parse(input)
            inputError = nil
        } catch {
            inputError = error.localizedDescription
            AccessibilityAnnouncer.announce(error.localizedDescription, priority: .high)
        }
    }

    private func binding(for channel: RGBChannelID) -> Binding<Double> {
        Binding(
            get: {
                switch channel {
                case .red: model.checkDisplayP3Color.red
                case .green: model.checkDisplayP3Color.green
                case .blue: model.checkDisplayP3Color.blue
                }
            },
            set: { value in
                let current = model.checkDisplayP3Color
                model.checkDisplayP3Color = DisplayP3Color(
                    red: channel == .red ? value : current.red,
                    green: channel == .green ? value : current.green,
                    blue: channel == .blue ? value : current.blue
                )
            }
        )
    }
}

/// Starting colors for the gamut check.
///
/// Three fall outside sRGB and one inside, so the reader sees both outcomes
/// without having to hunt for a color that fits.
private enum DisplayP3Preset: String, CaseIterable, Identifiable {
    case vividRed = "Vivid red: outside sRGB"
    case vividGreen = "Vivid green: outside sRGB"
    case warmAccent = "Warm accent: outside sRGB"
    case neutral = "Neutral gray: inside sRGB"

    var id: Self { self }

    var color: DisplayP3Color {
        switch self {
        case .vividRed: DisplayP3Color(red: 1, green: 0, blue: 0)
        case .vividGreen: DisplayP3Color(red: 0, green: 1, blue: 0)
        case .warmAccent: DisplayP3Color(red: 1, green: 0.2, blue: 0.1)
        case .neutral: DisplayP3Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }
}

/// One Display P3 channel as a labeled slider with its numeric value.
private struct P3ComponentSlider: View {
    let channel: RGBChannelID
    @Binding var value: Double
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        HStack(spacing: AppMetrics.compact) {
            Text(channel.title)
                .appFont(.headline)
                .frame(width: textScale >= 1.3 ? 96 : 54, alignment: .leading)

            Slider(value: $value, in: 0...1)
                .accessibilityLabel("Display P3 \(channel.rawValue) component")
                .accessibilityValue(Format.decimal(value, places: 3))

            Text(Format.decimal(value, places: 3))
                .appFont(.value)
                .monospacedDigit()
                .frame(width: textScale >= 1.3 ? 88 : 58, alignment: .trailing)
        }
    }
}

/// One labeled swatch with a copyable value.
private struct GamutPreviewPanel: View {
    let title: String
    let value: String
    let color: Color
    let copyDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.snug) {
                Text(title)
                    .appFont(.headline)
                Spacer()
                CopyValueButton(value: value, description: copyDescription)
            }

            Rectangle()
                .fill(color)
                .frame(height: 138)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.separator, lineWidth: 1)
                }
                .accessibilityLabel("\(title) color preview")
                .accessibilityValue(value)

            Text(value)
                .appFont(.value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.compact)
        .appSubtleSurface(cornerRadius: 10)
    }
}

/// One converted channel against the sRGB range, marked when it runs past
/// the boundary.
private struct GamutChannelRow: View {
    let channel: GamutChannelEvaluation
    @Environment(\.appTextScale) private var textScale
    @Environment(\.appSemanticPalette) private var semanticPalette

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.snug) {
                Text(channel.id.title)
                    .appFont(.headline)
                Spacer()
                Label(channel.position.rawValue, systemImage: statusSymbol)
                    .appFont(.caption)
                    .foregroundStyle(channel.position == .inside ? Color.secondary : semanticPalette.warning)
                Text(Format.decimal(channel.encodedValue, places: 5))
                    .appFont(.value)
                    .monospacedDigit()
                    .frame(width: textScale >= 1.3 ? 118 : 84, alignment: .trailing)
            }

            GeometryReader { geometry in
                let markerX = geometry.size.width * min(max(channel.encodedValue, 0), 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 9)
                    Capsule()
                        .fill(channelColor.opacity(0.78))
                        .frame(width: max(markerX, 4), height: 9)
                    Circle()
                        .fill(Color(nsColor: .labelColor))
                        .frame(width: 13, height: 13)
                        .offset(x: min(max(markerX - 6.5, 0), max(geometry.size.width - 13, 0)))
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 15)

            HStack {
                Text("0")
                Spacer()
                Text("1")
            }
            .appFont(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Converted sRGB \(channel.id.rawValue) channel")
        .accessibilityValue("\(Format.decimal(channel.encodedValue, places: 5)), \(channel.position.rawValue.lowercased())")
    }

    private var statusSymbol: String {
        switch channel.position {
        case .below: "arrow.left"
        case .inside: "checkmark"
        case .above: "arrow.right"
        }
    }

    private var channelColor: Color {
        switch channel.id {
        case .red: .red
        case .green: .green
        case .blue: .blue
        }
    }
}

/// The conversion equation with a reading of it in words.
private struct GamutEquationPanel: View {
    let title: String
    let latex: String
    let reading: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.snug) {
                Text(title)
                    .appFont(.headline)
                Spacer()
                CopyValueButton(
                    value: latex,
                    description: "\(title.lowercased()) equation as LaTeX",
                    label: "Copy LaTeX"
                )
            }

            MathEquationView(
                latex: latex,
                accessibilityLabel: reading,
                baseFontSize: 21
            )
            .frame(maxWidth: .infinity, minHeight: 76)

            Text(reading)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.regular)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .appSubtleSurface(cornerRadius: 10)
    }
}
