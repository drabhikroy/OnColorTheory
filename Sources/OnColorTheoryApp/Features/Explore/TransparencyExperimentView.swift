import SwiftUI

/// What the reader expects before the composite is revealed.
private enum TransparencyPrediction: String, CaseIterable, Identifiable {
    case same = "The same"
    case different = "Different"
    case observeFirst = "I want to observe first"

    var id: Self { self }

    var accessibilityLabel: String {
        switch self {
        case .same: "I predict the two visible colors will be the same"
        case .different: "I predict the two visible colors will be different"
        case .observeFirst: "I am not making a prediction"
        }
    }
}

/// Backdrop pairs for the transparency experiment, chosen so the same source
/// color lands somewhere different over each one.
private enum BackdropPreset: String, CaseIterable, Identifiable {
    case lightAndDark = "Light and dark"
    case warmAndCool = "Warm and cool"
    case mutedPair = "Muted pair"

    var id: Self { self }

    var colors: (SRGBColor, SRGBColor) {
        switch self {
        case .lightAndDark:
            (Self.color(250, 250, 248), Self.color(24, 36, 51))
        case .warmAndCool:
            (Self.color(244, 229, 211), Self.color(31, 74, 90))
        case .mutedPair:
            (Self.color(215, 210, 200), Self.color(96, 113, 122))
        }
    }

    var labels: (String, String) {
        switch self {
        case .lightAndDark: ("Light backdrop", "Dark backdrop")
        case .warmAndCool: ("Warm backdrop", "Cool backdrop")
        case .mutedPair: ("Pale backdrop", "Deep backdrop")
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

/// The experiment on one translucent color over two backdrops.
///
/// Scope is stated on screen rather than assumed. This is simple source over
/// on encoded sRGB over opaque backdrops, not blend modes, group opacity, or
/// high dynamic range rendering.
struct TransparencyExperimentView: View {
    @Environment(\.appSemanticPalette) private var palette
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var sourceColor: SRGBColor
    @State private var sourceOpacity = 0.55
    @State private var selectedPreset: BackdropPreset = .lightAndDark
    @State private var prediction: TransparencyPrediction?
    @State private var hasRevealed = false
    let onClose: () -> Void

    private let compositor = SourceOverCompositor()

    init(
        model: AppModel,
        showsObservation: Bool = false,
        onClose: @escaping () -> Void = {}
    ) {
        self.model = model
        self.onClose = onClose
        let session = model.workspaceSession
        _sourceColor = State(
            initialValue: showsObservation ? model.analysis.parsed.color.opaque : session.transparencySourceColor
        )
        _sourceOpacity = State(initialValue: session.transparencyOpacity)
        _selectedPreset = State(
            initialValue: BackdropPreset(rawValue: session.transparencyBackdropRawValue) ?? .lightAndDark
        )
        _prediction = State(
            initialValue: showsObservation
                ? .different
                : session.transparencyPredictionRawValue.flatMap(TransparencyPrediction.init(rawValue:))
        )
        _hasRevealed = State(initialValue: showsObservation || session.transparencyHasRevealed)
    }

    private var source: SRGBColor {
        SRGBColor(
            red: sourceColor.red,
            green: sourceColor.green,
            blue: sourceColor.blue,
            alpha: sourceOpacity
        )
    }

    private var backdropColors: (SRGBColor, SRGBColor) {
        selectedPreset.colors
    }

    private var results: (SourceOverComposite, SourceOverComposite) {
        (
            compositor.compositeOverOpaqueBackdrop(source: source, backdrop: backdropColors.0),
            compositor.compositeOverOpaqueBackdrop(source: source, backdrop: backdropColors.1)
        )
    }

    private var visibleResultsDiffer: Bool {
        let first = results.0.result
        let second = results.1.result
        let largestDifference = max(
            abs(first.red - second.red),
            abs(first.green - second.green),
            abs(first.blue - second.blue)
        )
        return largestDifference > (0.5 / 255)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                header
                setupCard

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
        .onChange(of: sourceColor) { _, _ in resetExperiment() }
        .onChange(of: sourceOpacity) { _, _ in resetExperiment() }
        .onChange(of: selectedPreset) { _, _ in resetExperiment() }
        .onChange(of: sourceColor) { _, color in
            model.updateWorkspaceSession { $0.transparencySourceColor = color.opaque }
        }
        .onChange(of: sourceOpacity) { _, value in
            model.updateWorkspaceSession { $0.transparencyOpacity = value }
        }
        .onChange(of: selectedPreset) { _, preset in
            model.updateWorkspaceSession { $0.transparencyBackdropRawValue = preset.rawValue }
        }
        .onChange(of: prediction) { _, value in
            model.updateWorkspaceSession { $0.transparencyPredictionRawValue = value?.rawValue }
        }
        .onChange(of: hasRevealed) { _, value in
            model.updateWorkspaceSession { $0.transparencyHasRevealed = value }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            Button("All experiments", systemImage: "chevron.left", action: onClose)
                .appFont(.callout)

            DestinationHeader(
                context: "Experiment, compositing",
                title: "How a backdrop changes transparency",
                summary: "One source color over two opaque backdrops, compared side by side."
            )
        }
    }

    private var setupCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: AppMetrics.regular) {
                        setupHeading
                        Spacer()
                        setupActions
                    }

                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        setupHeading
                        setupActions
                    }
                }

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_200 : 680,
                    leadingFraction: 0.54,
                    spacing: AppMetrics.regular
                ) {
                    EditableColorInput(
                        title: "Source color",
                        color: $sourceColor,
                        swatchSize: 76,
                        supportingText: "This color stays the same over both backdrops."
                    )
                    opacityControl
                }
            }
        }
    }

    private var setupHeading: some View {
        PanelHeading(
            title: "Set the source layer",
            summary: "Only the backdrop will differ between the two observations."
        )
    }

    private var setupActions: some View {
        HStack(spacing: AppMetrics.snug) {
            Button("Use Convert color", systemImage: "arrow.down.left") {
                sourceColor = model.analysis.parsed.color.opaque
            }

            Menu("Backdrops", systemImage: "square.split.2x1") {
                ForEach(BackdropPreset.allCases) { preset in
                    Button(preset.rawValue) {
                        selectedPreset = preset
                    }
                }
            }
        }
        .appFont(.callout)
    }

    private var opacityControl: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.snug) {
                Text("How much the source contributes")
                    .appFont(.headline)
                Spacer()
                Text(Format.percent(sourceOpacity, places: 0))
                    .appFont(.value)
                    .monospacedDigit()
            }

            Slider(value: $sourceOpacity, in: 0...1, step: 0.05)
                .accessibilityLabel("Source contribution")
                .accessibilityValue(Format.percent(sourceOpacity, places: 0))

            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.tight) {
                Text("The alpha value controls the source contribution; the backdrop supplies the remainder.")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                TermHelpButton(conceptID: "alpha", showsTerm: false)
            }
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }

    private var predictionCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                Label("PREDICT", systemImage: "questionmark.bubble")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("Will the visible color be the same on both backdrops?")
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    Text("The source color and its contribution stay fixed. Only the opaque backdrop changes.")
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
                    Button("Reveal results", systemImage: "eye") {
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
        ForEach(TransparencyPrediction.allCases) { choice in
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
                        predictAgainButton
                    }

                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        observationHeading
                        predictAgainButton
                    }
                }

                predictionFeedback

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_200 : 720,
                    leadingFraction: 0.5,
                    spacing: AppMetrics.regular
                ) {
                    CompositeResultPanel(
                        title: selectedPreset.labels.0,
                        composite: results.0,
                        openInConvert: { model.openInConvert(results.0.result) }
                    )
                    CompositeResultPanel(
                        title: selectedPreset.labels.1,
                        composite: results.1,
                        openInConvert: { model.openInConvert(results.1.result) }
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
            Text("Compare the visible results")
                .appFont(.title2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
        }
    }

    private var predictAgainButton: some View {
        Button("Predict again", systemImage: "arrow.counterclockwise") {
            prediction = nil
            hasRevealed = false
        }
    }

    private var predictionFeedback: some View {
        let expected: TransparencyPrediction = visibleResultsDiffer ? .different : .same
        let message: String

        if prediction == .observeFirst {
            message = visibleResultsDiffer
                ? "The two backdrops produce different visible sRGB colors."
                : "The two backdrops produce the same visible sRGB color at this source contribution."
        } else if prediction == expected {
            message = "Your prediction matches this setup. " + (visibleResultsDiffer
                ? "The backdrop changes the visible result."
                : "The opaque source fully replaces both backdrops.")
        } else {
            message = visibleResultsDiffer
                ? "For this setup, the backdrops produce different visible colors."
                : "For this setup, both backdrops produce the same visible color."
        }

        return Label(message, systemImage: visibleResultsDiffer ? "square.split.2x1" : "equal.circle")
            .appFont(.body)
            .padding(AppMetrics.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var explanationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                Label("EXPLAIN", systemImage: "text.bubble")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("Transparency describes a relationship between layers")
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    Text("The source contributes \(Format.percent(sourceOpacity, places: 0)) of each encoded sRGB component. The backdrop contributes the remaining \(Format.percent(1 - sourceOpacity, places: 0)). Changing the backdrop therefore changes the visible color unless the source is fully opaque.")
                        .appFont(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TermHelpRow(conceptIDs: ["alpha", "srgb"])

                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Source-over rule for an opaque backdrop")
                            .appFont(.headline)
                        Spacer()
                        CopyValueButton(
                            value: AlphaCompositingMath.opaqueBackdropEquation,
                            description: "source-over equation as LaTeX",
                            label: "Copy LaTeX"
                        )
                    }

                    MathEquationView(
                        latex: AlphaCompositingMath.opaqueBackdropEquation,
                        accessibilityLabel: AlphaCompositingMath.opaqueBackdropReading,
                        baseFontSize: 24
                    )

                    Text(AlphaCompositingMath.opaqueBackdropReading)
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                }
                .padding(AppMetrics.regular)
                .appSubtleSurface(cornerRadius: 10)

                Label(
                    "Scope: simple source-over on encoded sRGB components over opaque backdrops. This experiment does not cover blend modes, high-dynamic-range rendering, group opacity, or translucent backdrops.",
                    systemImage: "info.circle"
                )
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("Primary specifications")
                        .appFont(.headline)
                    ForEach(["w3c-compositing-1", "w3c-css-color-4"], id: \.self) { evidenceID in
                        if let record = EvidenceRegistry.record(withID: evidenceID) {
                            Link(destination: record.sourceURL) {
                                Label(record.title, systemImage: "arrow.up.right")
                            }
                            .appFont(.callout)
                        }
                    }
                }
            }
        }
    }

    private func resetExperiment() {
        prediction = nil
        hasRevealed = false
    }
}

/// One composite result, with a route into Convert.
private struct CompositeResultPanel: View {
    let title: String
    let composite: SourceOverComposite
    let openInConvert: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            VStack(alignment: .leading, spacing: AppMetrics.tight) {
                Text(title)
                    .appFont(.headline)
                Text(composite.backdrop.hex)
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            ColorSwatchView(color: composite.result)
                .frame(maxWidth: .infinity, minHeight: 140)

            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                Text("Component contributions")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                ContributionBar(composite: composite)
                HStack {
                    Text("Source \(Format.percent(composite.sourceContribution, places: 0))")
                    Spacer()
                    Text("Backdrop \(Format.percent(composite.backdropContribution, places: 0))")
                }
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                Text("Visible result")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                Text(composite.result.cssRGB)
                    .appFont(.value)
                    .monospacedDigit()
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: AppMetrics.compact) {
                CopyValueButton(
                    value: composite.result.hex,
                    description: "\(title) result HEX value",
                    isBordered: true
                )
                Button("Open in Convert", systemImage: "arrow.right", action: openInConvert)
            }
            .appFont(.callout)
        }
        .padding(AppMetrics.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
        .accessibilityElement(children: .contain)
    }
}

/// How much of the result came from the source and how much from the
/// backdrop, drawn to scale.
private struct ContributionBar: View {
    let composite: SourceOverComposite

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(composite.source.opaque.swiftUIColor)
                    .frame(width: geometry.size.width * composite.sourceContribution)
                Rectangle()
                    .fill(composite.backdrop.swiftUIColor)
            }
        }
        .frame(height: 16)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.separator, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}
