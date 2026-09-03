import SwiftUI

/// What the reader expects before the result is revealed.
///
/// Recording a prediction first is the point of the experiment. The third case
/// exists so declining to guess is a real option rather than a wrong one.
private enum MixPrediction: String, CaseIterable, Identifiable {
    case same = "The same"
    case different = "Different"
    case observeFirst = "I want to observe first"

    var id: Self { self }

    var accessibilityLabel: String {
        switch self {
        case .same: "I predict the methods produce the same midpoint"
        case .different: "I predict the methods produce different midpoints"
        case .observeFirst: "I am not making a prediction"
        }
    }
}

/// Starting pairs for the mixing experiment, chosen so the two spaces give
/// visibly different midpoints.
private enum MixPreset: String, CaseIterable, Identifiable {
    case blackWhite = "Black and white"
    case redGreen = "Red and green"
    case blueYellow = "Blue and yellow"

    var id: Self { self }

    var colors: (SRGBColor, SRGBColor) {
        switch self {
        case .blackWhite:
            (SRGBColor(red: 0, green: 0, blue: 0), SRGBColor(red: 1, green: 1, blue: 1))
        case .redGreen:
            (SRGBColor(red: 1, green: 0, blue: 0), SRGBColor(red: 0, green: 1, blue: 0))
        case .blueYellow:
            (SRGBColor(red: 0, green: 0.25, blue: 0.85), SRGBColor(red: 1, green: 0.85, blue: 0))
        }
    }
}

/// The experiment on mixing in encoded sRGB against mixing in linear light.
struct MixingExperimentView: View {
    @Environment(\.appSemanticPalette) private var palette
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var firstColor: SRGBColor
    @State private var secondColor: SRGBColor
    @State private var position = 0.5
    @State private var prediction: MixPrediction?
    @State private var hasRevealed = false
    let onClose: () -> Void

    private let mixer = ColorMixer()

    init(
        model: AppModel,
        showsComparison: Bool = false,
        onClose: @escaping () -> Void = {}
    ) {
        self.model = model
        self.onClose = onClose
        let session = model.workspaceSession
        _firstColor = State(initialValue: showsComparison ? model.analysis.parsed.color.opaque : session.mixingFirstColor)
        _secondColor = State(initialValue: session.mixingSecondColor)
        _position = State(initialValue: showsComparison ? 0.5 : session.mixingPosition)
        _prediction = State(
            initialValue: showsComparison
                ? .different
                : session.mixingPredictionRawValue.flatMap(MixPrediction.init(rawValue:))
        )
        _hasRevealed = State(initialValue: showsComparison || session.mixingHasRevealed)
    }

    private var comparison: ColorMixComparison {
        mixer.compare(firstColor, secondColor, position: position)
    }

    private var midpointComparison: ColorMixComparison {
        mixer.compare(firstColor, secondColor, position: 0.5)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                header
                colorInputs

                if hasRevealed {
                    observationCard
                    explanationCard
                } else {
                    predictionCard
                }
            }
            .frame(maxWidth: 1_020, alignment: .leading)
            .padding(AppMetrics.page)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle("Explore")
        .textSelection(.enabled)
        .onChange(of: firstColor) { _, _ in resetExperiment() }
        .onChange(of: secondColor) { _, _ in resetExperiment() }
        .onChange(of: firstColor) { _, color in
            model.updateWorkspaceSession { $0.mixingFirstColor = color.opaque }
        }
        .onChange(of: secondColor) { _, color in
            model.updateWorkspaceSession { $0.mixingSecondColor = color.opaque }
        }
        .onChange(of: position) { _, value in
            model.updateWorkspaceSession { $0.mixingPosition = value }
        }
        .onChange(of: prediction) { _, value in
            model.updateWorkspaceSession { $0.mixingPredictionRawValue = value?.rawValue }
        }
        .onChange(of: hasRevealed) { _, value in
            model.updateWorkspaceSession { $0.mixingHasRevealed = value }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            Button("All experiments", systemImage: "chevron.left", action: onClose)
                .appFont(.callout)

            DestinationHeader(
                context: "Experiment, interpolation",
                title: "Mixing colored light",
                summary: "Move one mixing position and compare two calculations for the same pair."
            )
        }
    }

    private var colorInputs: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: AppMetrics.regular) {
                        inputHeading
                        Spacer()
                        inputActions
                    }

                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        inputHeading
                        inputActions
                    }
                }

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_200 : 640,
                    leadingFraction: 0.5,
                    spacing: AppMetrics.regular
                ) {
                    EditableColorInput(title: "First light", color: $firstColor, swatchSize: 74)
                    EditableColorInput(title: "Second light", color: $secondColor, swatchSize: 74)
                }
            }
        }
    }

    private var inputHeading: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Text("Choose two colors")
                .appFont(.title2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.tight) {
                Text("The experiment uses opaque sRGB colors so only the mixing calculation changes.")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                TermHelpButton(conceptID: "srgb", showsTerm: false)
            }
        }
    }

    private var inputActions: some View {
        HStack(spacing: AppMetrics.snug) {
            Button("Use Convert color", systemImage: "arrow.down.left") {
                firstColor = model.analysis.parsed.color.opaque
            }

            Menu("Examples", systemImage: "square.grid.2x2") {
                ForEach(MixPreset.allCases) { preset in
                    Button(preset.rawValue) {
                        let colors = preset.colors
                        firstColor = colors.0
                        secondColor = colors.1
                    }
                }
            }
        }
        .appFont(.callout)
    }

    private var predictionCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                Label("PREDICT", systemImage: "questionmark.bubble")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("Will the two methods produce the same midpoint?")
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    Text("One method averages the stored sRGB numbers. The other first converts them to values proportional to light.")
                        .appFont(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppMetrics.snug) { predictionChoices }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) { predictionChoices }
                }

                HStack {
                    Spacer()
                    Button("Reveal comparison", systemImage: "eye") {
                        position = 0.5
                        hasRevealed = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(prediction == nil)
                }
            }
        }
    }

    @ViewBuilder
    private var predictionChoices: some View {
        ForEach(MixPrediction.allCases) { choice in
            Button {
                prediction = choice
            } label: {
                Label(
                    choice.rawValue,
                    systemImage: prediction == choice ? "checkmark.circle.fill" : "circle"
                )
            }
            .buttonStyle(.bordered)
            .tint(prediction == choice ? palette.accent : Color.secondary)
            .accessibilityLabel(choice.accessibilityLabel)
            .accessibilityValue(prediction == choice ? "Selected" : "Not selected")
        }
    }

    private var observationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: AppMetrics.regular) {
                        observationHeading
                        Spacer()
                        Button("Predict again", systemImage: "arrow.counterclockwise") {
                            prediction = nil
                            hasRevealed = false
                            position = 0.5
                        }
                    }

                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        observationHeading
                        Button("Predict again", systemImage: "arrow.counterclockwise") {
                            prediction = nil
                            hasRevealed = false
                            position = 0.5
                        }
                    }
                }

                predictionFeedback
                mixPositionControl

                VStack(spacing: AppMetrics.regular) {
                    MixGradientBand(
                        title: "Average stored numbers",
                        first: firstColor,
                        second: secondColor,
                        position: position,
                        space: .encodedSRGB
                    )
                    MixGradientBand(
                        title: "Average light",
                        first: firstColor,
                        second: secondColor,
                        position: position,
                        space: .linearSRGB
                    )
                }

                Divider()

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_200 : 700,
                    leadingFraction: 0.5,
                    spacing: AppMetrics.regular
                ) {
                    MixResultPanel(
                        title: "Stored-number result",
                        explanation: "The encoded sRGB components are averaged directly.",
                        color: comparison.encodedSRGB,
                        openInConvert: { model.openInConvert(comparison.encodedSRGB) }
                    )
                    MixResultPanel(
                        title: "Light-average result",
                        explanation: "The components are decoded, averaged as light, then encoded again.",
                        color: comparison.linearSRGB,
                        openInConvert: { model.openInConvert(comparison.linearSRGB) }
                    )
                }
            }
        }
    }

    private var observationHeading: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Label("OBSERVE", systemImage: "eye")
                .appFont(.caption)
                .foregroundStyle(.secondary)
            Text("Compare the two paths")
                .appFont(.title2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
        }
    }

    private var predictionFeedback: some View {
        let differs = colorsDiffer(
            midpointComparison.encodedSRGB,
            midpointComparison.linearSRGB
        )
        let expected: MixPrediction = differs ? .different : .same
        let message: String

        if prediction == .observeFirst {
            message = differs
                ? "At the midpoint, these methods produce different encoded sRGB colors."
                : "At the midpoint, these methods produce the same encoded sRGB color for this pair."
        } else if prediction == expected {
            message = "Your midpoint prediction matches this pair. " + (differs
                ? "The two calculations produce different colors."
                : "The two calculations meet at the same color.")
        } else {
            message = "For this pair, the midpoint is " + (differs
                ? "different between the two calculations."
                : "the same in both calculations.")
        }

        return Label(message, systemImage: differs ? "arrow.triangle.branch" : "equal.circle")
            .appFont(.body)
            .padding(AppMetrics.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var mixPositionControl: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack(alignment: .firstTextBaseline) {
                Text("Mix position")
                    .appFont(.headline)
                Spacer()
                Text(Format.percent(position, places: 0))
                    .appFont(.value)
                    .monospacedDigit()
                Button("Center") { position = 0.5 }
                    .disabled(abs(position - 0.5) < 0.000_1)
            }

            Slider(value: $position, in: 0...1)
                .accessibilityLabel("Mix position")
                .accessibilityValue(Format.percent(position, places: 0))

            HStack {
                Text("First light")
                Spacer()
                Text("Second light")
            }
            .appFont(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var explanationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                Label("EXPLAIN", systemImage: "text.bubble")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("The color space changes the result")
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    Text("sRGB stores components with a nonlinear encoding. Averaging those stored numbers treats the encoding as though it were proportional to light. The second path decodes each component first, averages the light-proportional values, and then re-encodes the result for display.")
                        .appFont(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TermHelpRow(conceptIDs: ["color-interpolation", "encoded-linear", "srgb"])

                Label(
                    "Linear-light mixing models the numeric combination of emitted light. It is not a claim that the resulting steps will look perceptually even.",
                    systemImage: "info.circle"
                )
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                Divider()

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: AppMetrics.regular) { formulaPanels }
                    VStack(alignment: .leading, spacing: AppMetrics.regular) { formulaPanels }
                }

                if let record = EvidenceRegistry.record(withID: "w3c-css-color-4") {
                    Link(destination: record.sourceURL) {
                        Label(record.title, systemImage: "arrow.up.right")
                    }
                    .appFont(.callout)
                }
            }
        }
    }

    @ViewBuilder
    private var formulaPanels: some View {
        MixFormulaPanel(
            title: "Average stored numbers",
            latex: ColorMixingMath.encodedEquation,
            spoken: ColorMixingMath.encodedReading
        )
        MixFormulaPanel(
            title: "Average light",
            latex: ColorMixingMath.linearEquation,
            spoken: ColorMixingMath.linearReading
        )
    }

    private func resetExperiment() {
        prediction = nil
        hasRevealed = false
        position = 0.5
    }

    private func colorsDiffer(_ first: SRGBColor, _ second: SRGBColor) -> Bool {
        let difference = max(
            abs(first.red - second.red),
            abs(first.green - second.green),
            abs(first.blue - second.blue)
        )
        return difference > (0.5 / 255)
    }
}

/// One space's gradient between the two colors, with the current position
/// marked.
private struct MixGradientBand: View {
    let title: String
    let first: SRGBColor
    let second: SRGBColor
    let position: Double
    let space: ColorMixingSpace

    private let mixer = ColorMixer()

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack {
                Text(title)
                    .appFont(.headline)
                Spacer()
                Text(mixer.mix(first, second, position: position, in: space).hex)
                    .appFont(.value)
                    .monospacedDigit()
                    .textSelection(.enabled)
            }

            Canvas { context, size in
                let samples = max(Int(size.width.rounded(.up)), 2)
                let sampleWidth = size.width / CGFloat(samples)
                for sample in 0..<samples {
                    let t = Double(sample) / Double(samples - 1)
                    let color = mixer.mix(first, second, position: t, in: space)
                    let rectangle = CGRect(
                        x: CGFloat(sample) * sampleWidth,
                        y: 0,
                        width: sampleWidth + 1,
                        height: size.height
                    )
                    context.fill(Path(rectangle), with: .color(color.swiftUIColor))
                }
            }
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                GeometryReader { geometry in
                    let x = geometry.size.width * position
                    ZStack {
                        Rectangle().fill(.black.opacity(0.75)).frame(width: 4, height: 62)
                        Rectangle().fill(.white).frame(width: 2, height: 62)
                    }
                    .position(x: x, y: geometry.size.height / 2)
                    .accessibilityHidden(true)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.separator, lineWidth: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(
            "A gradient from \(first.hex) to \(second.hex). At \(Format.percent(position, places: 0)), the color is \(mixer.mix(first, second, position: position, in: space).hex)."
        )
    }
}

/// One space's result at the current position, with a route into Convert.
private struct MixResultPanel: View {
    let title: String
    let explanation: String
    let color: SRGBColor
    let openInConvert: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            Text(title)
                .appFont(.headline)
            ColorSwatchView(color: color)
                .frame(maxWidth: .infinity, minHeight: 126)
            Text(explanation)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: AppMetrics.compact) {
                CopyValueButton(
                    value: color.hex,
                    description: "\(title) HEX value",
                    isBordered: true
                )
                Button("Open in Convert", systemImage: "arrow.right", action: openInConvert)
            }
            .appFont(.callout)
        }
        .padding(AppMetrics.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }
}

/// The interpolation equation with a reading of it in words.
private struct MixFormulaPanel: View {
    let title: String
    let latex: String
    let spoken: String

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
                accessibilityLabel: spoken,
                baseFontSize: 23
            )
            Text(spoken)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }
}
