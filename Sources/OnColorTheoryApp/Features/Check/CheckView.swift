import SwiftUI

/// The Check workspace, holding the four analyses and the results and method
/// pages that each of them shares.
struct CheckView: View {
    @ObservedObject private var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var selectedPage: CheckWorkspacePage

    init(model: AppModel, initialPage: CheckWorkspacePage? = nil) {
        self.model = model
        _selectedPage = State(
            initialValue: initialPage
                ?? CheckWorkspacePage(rawValue: model.workspaceSession.checkPageRawValue)
                ?? .results
        )
    }

    var body: some View {
        WorkspaceCanvas(section: .check) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: AppMetrics.section) {
                        header
                        checkWorkspace
                    }
                    .id("check-top")
                    .frame(maxWidth: 1_140, alignment: .leading)
                    .padding(AppMetrics.page)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .defaultScrollAnchor(.top)
                .onAppear {
                    proxy.scrollTo("check-top", anchor: .top)
                }
                .onChange(of: model.selectedCheckAnalysis) {
                    selectedPage = .results
                    proxy.scrollTo("check-top", anchor: .top)
                }
            }
        }
        .navigationTitle("Check")
        .textSelection(.enabled)
        .onChange(of: selectedPage) { _, page in
            model.updateWorkspaceSession { $0.checkPageRawValue = page.rawValue }
        }
    }

    private var header: some View {
        WorkspaceHeader(section: .check)
    }

    private var checkWorkspace: some View {
        AdaptivePairLayout(
            horizontalThreshold: textScale >= 1.3 ? 1_080 : 820,
            leadingFraction: 0.25,
            spacing: AppMetrics.roomy
        ) {
            analysisNavigation

            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                informationLevelNavigation

                Group {
                    switch model.selectedCheckAnalysis {
                    case .contrast:
                        ContrastAnalysisView(model: model, page: selectedPage)
                    case .difference:
                        DifferenceAnalysisView(model: model, page: selectedPage)
                    case .gamut:
                        GamutAnalysisView(model: model, page: selectedPage)
                    case .colorReliance:
                        ColorRelianceAnalysisView(model: model, page: selectedPage)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var analysisNavigation: some View {
        AppCard(padding: AppMetrics.compact) {
            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                PanelHeading(title: "What do you need to know?")

                ForEach(CheckAnalysisID.allCases) { analysis in
                    SectionRailButton(
                        title: analysis.compactTitle,
                        summary: analysis.summary,
                        symbolName: analysis.symbolName,
                        motif: analysis.iconMotif,
                        isSelected: model.selectedCheckAnalysis == analysis
                    ) {
                        model.selectedCheckAnalysis = analysis
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color diagnostic choices")
    }

    // The rail on the left already carries each diagnostic's summary, so this
    // strip names the current one and offers the level of detail, and nothing
    // more. Wrapping it in a surface of its own would put a third box on a page
    // that already has a rail and a result card.
    private var informationLevelNavigation: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            Text(model.selectedCheckAnalysis.title)
                .appFont(.title2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            Picker("Information level", selection: $selectedPage) {
                ForEach(CheckWorkspacePage.allCases) { page in
                    Label(page.title, systemImage: page.symbolName).tag(page)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .appFont(.body)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selected diagnostic and information level")
    }
}

/// Whether the reader is looking at the result or at how it was calculated.
///
/// Splitting the two is what keeps an equation off the first screen without
/// hiding it behind an advanced mode.
enum CheckWorkspacePage: String, CaseIterable, Identifiable, Sendable {
    case results
    case method

    var id: Self { self }

    var title: String {
        switch self {
        case .results: "Work and results"
        case .method: "Method and sources"
        }
    }

    var symbolName: String {
        switch self {
        case .results: "rectangle.and.pencil.and.ellipsis"
        case .method: "function"
        }
    }
}

/// The WCAG contrast check for a foreground and background pair.
private struct ContrastAnalysisView: View {
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    let page: CheckWorkspacePage

    private let checker = WCAGContrastChecker()

    var body: some View {
        Group {
            switch page {
            case .results:
                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_050 : 820,
                    leadingFraction: 0.48,
                    spacing: AppMetrics.regular
                ) {
                    inputCard
                    resultCard
                }
            case .method:
                calculationCard
            }
        }
    }

    private var inputCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                PanelHeading(
                    title: "Foreground and background",
                    summary: "Use opaque sRGB colors so the displayed pair has one unambiguous backdrop."
                )

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_000 : 650,
                    leadingFraction: 0.5,
                    spacing: AppMetrics.compact
                ) {
                    EditableColorInput(
                        title: "Foreground",
                        color: $model.checkForegroundColor,
                        swatchSize: 56
                    )
                    EditableColorInput(
                        title: "Background",
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

    @ViewBuilder
    private var inputActions: some View {
        Button("Swap", systemImage: "arrow.left.arrow.right") {
            let foreground = model.checkForegroundColor
            model.checkForegroundColor = model.checkBackgroundColor
            model.checkBackgroundColor = foreground
        }

        Button("Use Convert color", systemImage: "arrow.down.left") {
            model.checkForegroundColor = model.analysis.parsed.color.opaque
        }
    }

    private var resultCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                Text("Contrast result")
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)

                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    Text("Color should support the message.")
                        .appFont(.title2)
                    Text("Use the actual size and weight you plan to design with.")
                        .appFont(.body)
                }
                .foregroundStyle(evaluation.foreground.swiftUIColor)
                .padding(AppMetrics.section)
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
                .background(evaluation.background.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.separator, lineWidth: 1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Contrast preview")
                .accessibilityValue(
                    "Foreground \(evaluation.foreground.hex) on background \(evaluation.background.hex). The sample says color should support the message."
                )

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AppMetrics.section) {
                        ratio
                        verdict
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        ratio
                        verdict
                    }
                }

                ContrastThresholdScale(ratio: evaluation.ratio)
                TermHelpRow(conceptIDs: ["wcag-contrast", "relative-luminance"])
            }
        }
    }

    private var ratio: some View {
        VStack(alignment: .leading, spacing: AppMetrics.hairline) {
            Text("Contrast")
                .appFont(.body)
                .foregroundStyle(.secondary)
            Text("\(Format.decimal(evaluation.ratio, places: 2)):1")
                .appFont(.largeTitle)
                .monospacedDigit()
                .textSelection(.enabled)
        }
        .frame(minWidth: 150, alignment: .leading)
    }

    private var verdict: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Text(verdictTitle)
                .appFont(.headline)
            Text(verdictDetail)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var verdictTitle: String {
        if evaluation.ratio >= 7 { return "Enhanced contrast" }
        if evaluation.ratio >= 4.5 { return "Suitable for normal text" }
        if evaluation.ratio >= 3 { return "Minimum for large text or required cues" }
        return "Not enough contrast for these WCAG relationships"
    }

    private var verdictDetail: String {
        if evaluation.ratio >= 7 {
            return "Meets the enhanced WCAG threshold for normal text."
        }
        if evaluation.ratio >= 4.5 {
            return "Meets the minimum for normal text and the enhanced threshold for large text."
        }
        if evaluation.ratio >= 3 {
            return "Meets the minimum for large text and required non-text cues, but not for normal text."
        }
        return "Below the 3:1 threshold used for large text and required non-text cues. Increase the light and dark difference."
    }

    private var calculationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                PanelHeading(
                    title: "How contrast is calculated",
                    summary: "Encoded sRGB channels are converted to values proportional to light before the luminances are compared."
                )

                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    ContrastEquationPanel(
                        title: "Relative luminance",
                        latex: ContrastMath.relativeLuminanceEquation,
                        reading: ContrastMath.relativeLuminanceReading
                    )
                    ContrastEquationPanel(
                        title: "Contrast ratio",
                        latex: ContrastMath.ratioEquation,
                        reading: ContrastMath.ratioReading
                    )
                }

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    CoordinateRow(
                        label: "Foreground luminance",
                        value: Format.decimal(evaluation.foregroundLuminance)
                    )
                    CoordinateRow(
                        label: "Background luminance",
                        value: Format.decimal(evaluation.backgroundLuminance)
                    )
                }

                if let record = EvidenceRegistry.record(withID: "w3c-wcag-22-contrast") {
                    Link(destination: record.sourceURL) {
                        Label(record.title, systemImage: "arrow.up.right.square")
                    }
                    .appFont(.body)

                    Text(record.limitation)
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                DisclosureGroup("View all five WCAG criteria") {
                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        Text("Large text means at least 18 pt regular or 14 pt bold in WCAG's definition. Threshold decisions use the unrounded ratio.")
                            .appFont(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(Array(WCAGContrastCriterion.allCases.enumerated()), id: \.element.id) { index, criterion in
                            ContrastCriterionRow(
                                criterion: criterion,
                                passes: evaluation.passes(criterion)
                            )
                            if index < WCAGContrastCriterion.allCases.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding(.top, AppMetrics.compact)
                }
                .appFont(.body)
            }
        }
    }

    private var evaluation: ContrastEvaluation {
        checker.evaluateOverOpaqueBackground(
            foreground: model.checkForegroundColor.opaque,
            background: model.checkBackgroundColor.opaque
        )
    }
}

/// The CIEDE2000 difference between two colors, broken into its terms.
private struct DifferenceAnalysisView: View {
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    let page: CheckWorkspacePage

    private let converter = DefaultColorSpaceConverter()
    private let calculator = CIEDE2000DifferenceCalculator()

    var body: some View {
        Group {
            switch page {
            case .results:
                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_050 : 820,
                    leadingFraction: 0.48,
                    spacing: AppMetrics.regular
                ) {
                    inputCard
                    resultCard
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
            title: "Two colors to compare",
            summary: "Both colors use the same sRGB-to-CIELAB conversion and D50 reference white."
        )
    }

    private var examplesMenu: some View {
        Menu("Examples", systemImage: "square.grid.2x2") {
            ForEach(DifferencePreset.allCases) { preset in
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

    private var resultCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                Text("Modeled difference")
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)

                DifferencePairPreview(
                    first: model.checkForegroundColor,
                    second: model.checkBackgroundColor
                )

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AppMetrics.section) {
                        differenceValue
                        differenceExplanation
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        differenceValue
                        differenceExplanation
                    }
                }

                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    VStack(alignment: .leading, spacing: AppMetrics.tight) {
                        Text("Weighted terms before combination")
                            .appFont(.headline)
                        Text("Bar lengths compare the light and dark, chroma, and hue-direction term sizes within this pair. Chroma describes distance from neutral in the calculation. Signed values remain visible because the final formula also includes a hue to chroma interaction.")
                            .appFont(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(differenceComponents) { component in
                        DifferenceComponentBar(
                            component: component,
                            maximumMagnitude: maximumComponentMagnitude
                        )
                    }
                }

                TermHelpRow(conceptIDs: ["cielab", "chroma"])
            }
        }
    }

    private var differenceValue: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            HStack(spacing: AppMetrics.tight) {
                Text("CIEDE2000 difference")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                TermHelpButton(conceptID: "ciede2000", showsTerm: false)
            }
            Text(Format.decimal(difference.deltaE00, places: 3))
                .appFont(.largeTitle)
                .monospacedDigit()
                .textSelection(.enabled)
            Text("ΔE00")
                .appFont(.value)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 180, alignment: .leading)
    }

    private var differenceExplanation: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Text(difference.deltaE00 == 0 ? "The coordinates are identical in this model" : "A relative difference, not a pass or fail")
                .appFont(.headline)
            Text("Zero means the same CIELAB coordinates. Larger values mean a larger modeled difference, but what a person notices or accepts depends on the viewing conditions, task, display, surroundings, and observer.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var calculationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                PanelHeading(
                    title: "How the difference is calculated",
                    summary: "The app converts both colors to CIELAB on the same D50 basis, then applies CIEDE2000 with unit parametric factors: kL = kC = kH = 1."
                )

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_000 : 640,
                    leadingFraction: 0.5,
                    spacing: AppMetrics.compact
                ) {
                    DifferenceLabPanel(title: "First color", color: model.checkForegroundColor, lab: firstLab)
                    DifferenceLabPanel(title: "Second color", color: model.checkBackgroundColor, lab: secondLab)
                }

                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Normalize three signed differences")
                            .appFont(.headline)
                        Spacer()
                        CopyValueButton(
                            value: ColorDifferenceMath.normalizedTermsEquation,
                            description: "CIEDE2000 normalized terms as LaTeX",
                            label: "Copy LaTeX"
                        )
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: AppMetrics.snug) {
                            DifferenceTermEquation(title: "Light and dark", latex: ColorDifferenceMath.lightnessTermEquation)
                            DifferenceTermEquation(title: "Chroma", latex: ColorDifferenceMath.chromaTermEquation)
                            DifferenceTermEquation(title: "Hue direction", latex: ColorDifferenceMath.hueTermEquation)
                        }
                        VStack(alignment: .leading, spacing: AppMetrics.snug) {
                            DifferenceTermEquation(title: "Light and dark", latex: ColorDifferenceMath.lightnessTermEquation)
                            DifferenceTermEquation(title: "Chroma", latex: ColorDifferenceMath.chromaTermEquation)
                            DifferenceTermEquation(title: "Hue direction", latex: ColorDifferenceMath.hueTermEquation)
                        }
                    }

                    Text(ColorDifferenceMath.normalizedTermsReading)
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Combine the weighted terms")
                            .appFont(.headline)
                        Spacer()
                        CopyValueButton(
                            value: ColorDifferenceMath.combinationEquation,
                            description: "CIEDE2000 combination equation as LaTeX",
                            label: "Copy LaTeX"
                        )
                    }

                    MathEquationView(
                        latex: ColorDifferenceMath.combinationEquation,
                        accessibilityLabel: ColorDifferenceMath.combinationReading,
                        baseFontSize: 24
                    )

                    Text(ColorDifferenceMath.combinationReading)
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    CoordinateRow(
                        label: "Hue and chroma interaction (Rₜ)",
                        value: Format.signed(difference.rotationTerm, places: 4)
                    )
                }

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    ForEach(differenceEvidence) { record in
                        Link(destination: record.sourceURL) {
                            Label(record.title, systemImage: "arrow.up.right.square")
                        }
                        .appFont(.body)
                    }

                    Text("The implementation is tested against all 34 supplemental reference pairs published by Sharma, Wu, and Dalal. Their paper validates computation and explicitly does not define a universal perceptual threshold.")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var firstLab: LabColor {
        analysis(for: model.checkForegroundColor).labD50
    }

    private var secondLab: LabColor {
        analysis(for: model.checkBackgroundColor).labD50
    }

    private var difference: ColorDifferenceEvaluation {
        calculator.evaluate(reference: firstLab, sample: secondLab)
    }

    private var differenceComponents: [DifferenceComponent] {
        [
            DifferenceComponent(
                id: "lightness",
                title: "Light and dark",
                symbol: "xL",
                value: difference.weightedLightnessTerm
            ),
            DifferenceComponent(
                id: "chroma",
                title: "Chroma",
                symbol: "xC",
                value: difference.weightedChromaTerm
            ),
            DifferenceComponent(
                id: "hue",
                title: "Hue direction",
                symbol: "xH",
                value: difference.weightedHueTerm
            )
        ]
    }

    private var maximumComponentMagnitude: Double {
        max(differenceComponents.map { abs($0.value) }.max() ?? 0, 0.000_001)
    }

    private var differenceEvidence: [EvidenceRecord] {
        ["iso-cie-11664-6-2022", "sharma-ciede2000-2005"]
            .compactMap(EvidenceRegistry.record(withID:))
    }

    private func analysis(for color: SRGBColor) -> ColorAnalysis {
        converter.analyze(
            ParsedColor(
                originalRepresentation: color.hex,
                notation: "CSS hexadecimal",
                notationID: .hexadecimal,
                colorSpace: .sRGB,
                color: color.opaque
            )
        )
    }
}

/// Starting pairs for the difference check, spread so the terms differ.
private enum DifferencePreset: String, CaseIterable, Identifiable {
    case nearbyBlues = "Nearby blues"
    case neutralShift = "Nearby neutrals"
    case warmAndCool = "Warm and cool"

    var id: Self { self }

    var colors: (SRGBColor, SRGBColor) {
        switch self {
        case .nearbyBlues:
            (color(47, 111, 237), color(47, 115, 232))
        case .neutralShift:
            (color(118, 118, 118), color(126, 126, 126))
        case .warmAndCool:
            (color(201, 92, 66), color(59, 111, 161))
        }
    }

    private func color(_ red: Int, _ green: Int, _ blue: Int) -> SRGBColor {
        SRGBColor(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}

/// The two colors being compared, shown together.
private struct DifferencePairPreview: View {
    let first: SRGBColor
    let second: SRGBColor

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack {
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text("First")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                    Text(first.hex)
                        .appFont(.value)
                        .monospacedDigit()
                        .textSelection(.enabled)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: AppMetrics.hairline) {
                    Text("Second")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                    Text(second.hex)
                        .appFont(.value)
                        .monospacedDigit()
                        .textSelection(.enabled)
                }
            }

            HStack(spacing: 0) {
                Rectangle().fill(first.swiftUIColor)
                Rectangle().fill(second.swiftUIColor)
            }
            .frame(height: 150)
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Side-by-side color comparison")
            .accessibilityValue("First \(first.accessibleDescription). Second \(second.accessibleDescription).")
        }
    }
}

/// One weighted term of a CIEDE2000 result, ready to be drawn as a bar.
private struct DifferenceComponent: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let value: Double
}

/// One term drawn against the largest term in the same result, so the bars
/// compare within a pair rather than against an absolute scale.
private struct DifferenceComponentBar: View {
    let component: DifferenceComponent
    let maximumMagnitude: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack(alignment: .firstTextBaseline) {
                Text(component.title)
                    .appFont(.body)
                Text(component.symbol)
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Format.signed(component.value, places: 3))
                    .appFont(.value)
                    .monospacedDigit()
                    .textSelection(.enabled)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                    Capsule()
                        .fill(.tint)
                        .frame(
                            width: geometry.size.width * min(abs(component.value) / maximumMagnitude, 1)
                        )
                }
            }
            .frame(height: 9)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(component.title)
        .accessibilityValue("Signed weighted term \(Format.signed(component.value, places: 3))")
    }
}

/// One color's Lab coordinates, labeled with which color they belong to.
private struct DifferenceLabPanel: View {
    let title: String
    let color: SRGBColor
    let lab: LabColor

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack(spacing: AppMetrics.snug) {
                ColorSwatchView(color: color, showsLabel: false)
                    .frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text(title)
                        .appFont(.headline)
                    Text("CIELAB · D50")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            CoordinateRow(label: "L* · lightness", value: Format.decimal(lab.lightness, places: 3))
            CoordinateRow(label: "a* · green to red", value: Format.signed(lab.a, places: 3))
            CoordinateRow(label: "b* · blue to yellow", value: Format.signed(lab.b, places: 3))
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }
}

/// One CIEDE2000 term with its equation.
private struct DifferenceTermEquation: View {
    let title: String
    let latex: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Text(title)
                .appFont(.caption)
                .foregroundStyle(.secondary)
            MathEquationView(
                latex: latex,
                accessibilityLabel: "\(title) weighted CIEDE2000 term",
                baseFontSize: 20
            )
        }
        .padding(AppMetrics.snug)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }
}

/// The contrast equation with a reading of it in words.
private struct ContrastEquationPanel: View {
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

/// Places the calculated ratio on a scale marked at 3, 4.5, and 7 to 1, so
/// the reader sees how much margin the pair has rather than only a verdict.
private struct ContrastThresholdScale: View {
    let ratio: Double
    private let thresholds = [3.0, 4.5, 7.0]

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text("WCAG threshold scale")
                .appFont(.headline)

            GeometryReader { geometry in
                let width = max(geometry.size.width - 16, 1)
                let markerX = 8 + (width * position(for: ratio))

                ZStack(alignment: .topLeading) {
                    Capsule()
                        .fill(.quaternary)
                        .frame(width: width, height: 8)
                        .offset(x: 8, y: 8)

                    ForEach(thresholds, id: \.self) { threshold in
                        let x = 8 + (width * position(for: threshold))
                        Rectangle()
                            .fill(.secondary)
                            .frame(width: 1, height: 18)
                            .offset(x: x, y: 3)
                        Text(threshold == 4.5 ? "4.5:1" : "\(Int(threshold)):1")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                            .offset(x: min(max(x - 18, 0), geometry.size.width - 38), y: 26)
                    }

                    Circle()
                        .fill(.tint)
                        .frame(width: 14, height: 14)
                        .overlay { Circle().stroke(.background, lineWidth: 2) }
                        .offset(x: markerX - 7, y: 5)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 50)

            Text("3:1 large text or required UI cue · 4.5:1 normal text · 7:1 enhanced text")
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("WCAG threshold scale")
        .accessibilityValue("Current contrast \(Format.decimal(ratio, places: 2)) to 1. Thresholds are 3 to 1 for large text and required user interface cues, 4.5 to 1 for normal text, and 7 to 1 for enhanced normal text.")
    }

    private func position(for value: Double) -> Double {
        min(max((value - 1) / 6, 0), 1)
    }
}

/// One success criterion and whether this pair meets it.
private struct ContrastCriterionRow: View {
    let criterion: WCAGContrastCriterion
    let passes: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppMetrics.regular) {
                criterionDescription
                Spacer(minLength: 12)
                threshold
                ResultLabel(passes: passes)
            }
            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                criterionDescription
                HStack(spacing: AppMetrics.compact) {
                    threshold
                    ResultLabel(passes: passes)
                }
            }
        }
    }

    private var criterionDescription: some View {
        VStack(alignment: .leading, spacing: AppMetrics.hairline) {
            Text("\(criterion.level) · \(criterion.title)")
                .appFont(.headline)
            Text(criterion.scope)
                .appFont(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var threshold: some View {
        Text("\(Format.decimal(criterion.threshold, places: 1)):1")
            .appFont(.value)
            .monospacedDigit()
    }
}

/// A pass or fail label carrying a symbol and text as well as color, so the
/// verdict does not depend on hue alone.
private struct ResultLabel: View {
    let passes: Bool
    @Environment(\.appSemanticPalette) private var semanticPalette

    var body: some View {
        Label(
            passes ? "Pass" : "Does not pass",
            systemImage: passes ? "checkmark.circle.fill" : "xmark.circle"
        )
        .appFont(.callout)
        .foregroundStyle(passes ? semanticPalette.positive : semanticPalette.critical)
        .accessibilityLabel(passes ? "Passes" : "Does not pass")
    }
}
