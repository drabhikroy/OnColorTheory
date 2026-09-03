import SwiftUI

/// The four lessons, keyed by slug.
///
/// Raw values are slugs rather than titles because they are written into the
/// saved session, so a title can be reworded without stranding a session.
enum LearningLessonID: String, CaseIterable, Identifiable, Sendable {
    case colorCoordinates = "color-coordinates"
    case contrastAndDifference = "contrast-and-difference"
    case surroundingsAndAppearance = "surroundings-and-appearance"
    case colorSpaceLimits = "color-space-limits"

    var id: Self { self }

    var title: String {
        switch self {
        case .colorCoordinates:
            "From a color code to color coordinates"
        case .contrastAndDifference:
            "Contrast and color difference answer different questions"
        case .surroundingsAndAppearance:
            "The same color can look different in different surroundings"
        case .colorSpaceLimits:
            "Some colors fit one color space but not another"
        }
    }

    var summary: String {
        switch self {
        case .colorCoordinates:
            "Follow one sRGB color through stored channels, light-proportional values, and reference-white assumptions."
        case .contrastAndDifference:
            "Use the same pair to see why a readability relationship and a modeled color difference are not interchangeable."
        case .surroundingsAndAppearance:
            "Keep one center color fixed while the surrounding lightness changes, then separate numeric identity from perceived appearance."
        case .colorSpaceLimits:
            "Follow one Display P3 color into sRGB, see where its converted channels cross the boundary, and identify the mapping choice that follows."
        }
    }

    var symbolName: String {
        switch self {
        case .colorCoordinates: "point.3.connected.trianglepath.dotted"
        case .contrastAndDifference: "arrow.triangle.branch"
        case .surroundingsAndAppearance: "square.on.square"
        case .colorSpaceLimits: "triangle"
        }
    }

    var iconMotif: DesignedIconMotif {
        switch self {
        case .colorCoordinates: .path
        case .contrastAndDifference: .compare
        case .surroundingsAndAppearance: .layers
        case .colorSpaceLimits: .spectrum
        }
    }

    var category: String {
        switch self {
        case .colorCoordinates: "FOUNDATION"
        case .contrastAndDifference: "PRACTICAL"
        case .surroundingsAndAppearance: "PERCEPTION"
        case .colorSpaceLimits: "REPRODUCTION"
        }
    }

    var actionTitle: String {
        switch self {
        case .colorCoordinates: "Start foundation lesson"
        case .contrastAndDifference: "Compare the two measures"
        case .surroundingsAndAppearance: "Compare the surroundings"
        case .colorSpaceLimits: "Follow a color to the boundary"
        }
    }
}

/// The lesson library and the shell that presents one lesson at a time.
struct LearnView: View {
    @ObservedObject var model: AppModel
    @State private var selectedLessonID: LearningLessonID?
    @State private var focusedLessonID: LearningLessonID
    private let initialPartIndex: Int?
    @Environment(\.appTextScale) private var textScale

    init(
        model: AppModel,
        initialLesson: LearningLessonID? = nil,
        initialPartIndex: Int? = nil
    ) {
        self.model = model
        self.initialPartIndex = initialPartIndex
        let restoredLesson = initialLesson
            ?? model.workspaceSession.learnLessonRawValue.flatMap(LearningLessonID.init(rawValue:))
        _selectedLessonID = State(initialValue: restoredLesson)
        _focusedLessonID = State(initialValue: restoredLesson ?? .colorCoordinates)
    }

    var body: some View {
        WorkspaceCanvas(section: .learn) {
            Group {
                switch selectedLessonID {
                case .colorCoordinates:
                    ColorCoordinatesLessonView(
                        model: model,
                        initialPartIndex: partIndex(for: .colorCoordinates),
                        onClose: { selectedLessonID = nil }
                    )
                case .contrastAndDifference:
                    ContrastAndDifferenceLessonView(
                        model: model,
                        initialPartIndex: partIndex(for: .contrastAndDifference),
                        onClose: { selectedLessonID = nil }
                    )
                case .surroundingsAndAppearance:
                    SurroundingsLessonView(
                        model: model,
                        initialPartIndex: partIndex(for: .surroundingsAndAppearance),
                        onClose: { selectedLessonID = nil }
                    )
                case .colorSpaceLimits:
                    GamutLessonView(
                        model: model,
                        initialPartIndex: partIndex(for: .colorSpaceLimits),
                        onClose: { selectedLessonID = nil }
                    )
                case nil:
                    lessonLibrary
                }
            }
        }
        .navigationTitle("Learn")
        .textSelection(.enabled)
        .onChange(of: selectedLessonID) { _, lesson in
            model.updateWorkspaceSession { $0.learnLessonRawValue = lesson?.rawValue }
        }
    }

    private func partIndex(for lesson: LearningLessonID) -> Int {
        max(initialPartIndex ?? model.workspaceSession.learnPartIndices[lesson.rawValue] ?? 0, 0)
    }

    private var lessonLibrary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                WorkspaceHeader(section: .learn)

                PanelHeading(
                    title: "Four connected paths",
                    summary: "Start anywhere. The numbered order is a useful route, not a prerequisite."
                )

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_040 : 760,
                    leadingFraction: 0.36,
                    spacing: AppMetrics.regular
                ) {
                    AppCard(padding: AppMetrics.compact) {
                        VStack(spacing: AppMetrics.snug) {
                            ForEach(Array(LearningLessonID.allCases.enumerated()), id: \.element.id) { index, lesson in
                                LearningLessonSelectorRow(
                                    lesson: lesson,
                                    index: index + 1,
                                    isSelected: lesson == focusedLessonID
                                ) {
                                    focusedLessonID = lesson
                                }
                            }
                        }
                    }

                    LearningLessonPreview(
                        lesson: focusedLessonID,
                        index: (LearningLessonID.allCases.firstIndex(of: focusedLessonID) ?? 0) + 1
                    ) {
                        selectedLessonID = focusedLessonID
                    }
                }
            }
            .frame(maxWidth: 1_020, alignment: .leading)
            .padding(AppMetrics.page)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

}

/// One lesson in the selector list, numbered and showing selection state.
private struct LearningLessonSelectorRow: View {
    let lesson: LearningLessonID
    let index: Int
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.appSectionIdentity) private var identity

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: AppMetrics.compact) {
                Text("\(index)")
                    .appFont(.headline)
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? identity.primary : Color.secondary)
                    .frame(width: 34, height: 34)
                    .background(
                        (isSelected ? identity.primary : Color.secondary).opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text(lesson.category.capitalized)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                    Text(lesson.title)
                        .appFont(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(isSelected ? identity.primary : Color.secondary)
                    .accessibilityHidden(true)
            }
            .padding(AppMetrics.snug)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(
                isSelected ? identity.primary.opacity(0.085) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected ? identity.primary.opacity(0.38) : Color.clear,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A lesson as a card in the library grid, before one is opened.
private struct LearningLessonPreview: View {
    let lesson: LearningLessonID
    let index: Int
    let action: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                HStack(alignment: .center, spacing: AppMetrics.compact) {
                    lessonMark

                    VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                        Text("PATH \(index) · \(lesson.category)")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                        Label("3 short parts", systemImage: "rectangle.stack")
                            .appFont(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text(lesson.title)
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    Text(lesson.summary)
                        .appFont(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppMetrics.regular) { lessonParts }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) { lessonParts }
                }

                Spacer(minLength: 2)

                Button(lesson.actionTitle, systemImage: "arrow.right", action: action)
                    .buttonStyle(.borderedProminent)
                    .appFont(.body)
                    .fixedSize()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(minHeight: 314, alignment: .topLeading)
        }
    }

    private var lessonMark: some View {
        DesignedSymbolIcon(symbolName: lesson.symbolName, motif: lesson.iconMotif, size: 50)
    }

    @ViewBuilder
    private var lessonParts: some View {
        Label("Plain meaning", systemImage: "text.alignleft")
            .appFont(.callout)
            .foregroundStyle(.secondary)
        Label("Visual example", systemImage: "eye")
            .appFont(.callout)
            .foregroundStyle(.secondary)
        Label("Technical detail", systemImage: "function")
            .appFont(.callout)
            .foregroundStyle(.secondary)
    }
}

/// The three parts of the contrast and difference lesson.
private enum RelationshipLessonPart: Int, CaseIterable, Identifiable {
    case twoQuestions
    case contrast
    case difference

    var id: Self { self }

    var shortTitle: String {
        switch self {
        case .twoQuestions: "Two questions"
        case .contrast: "Contrast"
        case .difference: "Difference"
        }
    }

    var title: String {
        switch self {
        case .twoQuestions:
            "Begin with the question, not the number"
        case .contrast:
            "Contrast asks about a foreground and its background"
        case .difference:
            "Color difference asks how far apart two coordinates are"
        }
    }

    var symbolName: String {
        switch self {
        case .twoQuestions: "questionmark.bubble"
        case .contrast: "circle.lefthalf.filled"
        case .difference: "circle.grid.cross"
        }
    }

    var explanation: String {
        switch self {
        case .twoQuestions:
            "The same two colors can be evaluated in more than one way. A WCAG contrast ratio asks whether a foreground and background have enough light and dark contrast for a named use. CIEDE2000 estimates the relative magnitude of their color difference. Neither number substitutes for the other."
        case .contrast:
            "WCAG contrast compares the relative luminance of the lighter color with the darker color. It is directional in use: one color is the content and the other is its background, even though swapping the two leaves the numeric ratio unchanged."
        case .difference:
            "CIEDE2000 begins with two CIELAB coordinates and adjusts lightness, chroma, and hue contributions. A larger value means a larger difference within this model, but it does not supply one universal value for what every person will notice or accept."
        }
    }

    var keyPoint: String {
        switch self {
        case .twoQuestions:
            "Name the design question before choosing a measurement."
        case .contrast:
            "A large hue change can still have too little light and dark contrast for text."
        case .difference:
            "A modeled color difference describes separation, not readability or accessibility by itself."
        }
    }

    var definitionIDs: [String] {
        switch self {
        case .twoQuestions: ["wcag-contrast", "ciede2000"]
        case .contrast: ["relative-luminance", "wcag-contrast"]
        case .difference: ["ciede2000", "cielab", "chroma"]
        }
    }

    var evidenceIDs: [String] {
        switch self {
        case .twoQuestions: ["w3c-wcag-22-contrast", "iso-cie-11664-6-2022"]
        case .contrast: ["w3c-wcag-22-contrast"]
        case .difference: ["iso-cie-11664-6-2022", "sharma-ciede2000-2005"]
        }
    }
}

/// The color pairs this lesson offers.
///
/// The three cases are chosen to pull contrast and difference apart. A large
/// hue change with similar lightness scores high on difference and low on
/// contrast, and nearby neutrals do the reverse.
enum LearningRelationshipExample: String, CaseIterable, Identifiable {
    case differentHueSimilarLightness = "Different hue, similar lightness"
    case nearbyNeutrals = "Nearby neutrals"
    case blackAndWhite = "Black and white"

    var id: Self { self }

    var colors: (SRGBColor, SRGBColor) {
        switch self {
        case .differentHueSimilarLightness:
            (Self.color(199, 70, 105), Self.color(43, 140, 130))
        case .nearbyNeutrals:
            (Self.color(119, 119, 119), Self.color(133, 133, 133))
        case .blackAndWhite:
            (Self.color(0, 0, 0), Self.color(255, 255, 255))
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

/// The lesson on why contrast and color difference answer different
/// questions about the same pair of colors.
private struct ContrastAndDifferenceLessonView: View {
    @Environment(\.appSemanticPalette) private var palette
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var selectedPartIndex = 0
    @State private var selectedExample: LearningRelationshipExample = .differentHueSimilarLightness
    let onClose: () -> Void

    private let contrastChecker = WCAGContrastChecker()
    private let converter = DefaultColorSpaceConverter()
    private let differenceCalculator = CIEDE2000DifferenceCalculator()

    init(
        model: AppModel,
        initialPartIndex: Int = 0,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.onClose = onClose
        _selectedPartIndex = State(
            initialValue: min(max(initialPartIndex, 0), RelationshipLessonPart.allCases.count - 1)
        )
        _selectedExample = State(
            initialValue: LearningRelationshipExample(
                rawValue: model.workspaceSession.learnRelationshipExampleRawValue
            ) ?? .differentHueSimilarLightness
        )
    }

    private var selectedPart: RelationshipLessonPart {
        RelationshipLessonPart.allCases[selectedPartIndex]
    }

    private var colors: (SRGBColor, SRGBColor) {
        selectedExample.colors
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                Button("All lessons", systemImage: "chevron.left", action: onClose)
                    .buttonStyle(.plain)
                    .appFont(.body)
                    .foregroundStyle(palette.accent)

                introduction
                lessonMap
                navigation
                lessonCard
                sourceLinks
            }
            .frame(maxWidth: 860, alignment: .leading)
            .padding(AppMetrics.page)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .onChange(of: selectedPartIndex) { _, index in
            model.updateWorkspaceSession {
                $0.learnPartIndices[LearningLessonID.contrastAndDifference.rawValue] = index
            }
        }
        .onChange(of: selectedExample) { _, example in
            model.updateWorkspaceSession { $0.learnRelationshipExampleRawValue = example.rawValue }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            DestinationHeader(
                context: "Practical, 3 short parts",
                title: LearningLessonID.contrastAndDifference.title,
                summary: "Keep one pair visible while the question and measurement change."
            )

            Menu("Example: \(selectedExample.rawValue)", systemImage: "square.grid.2x2") {
                ForEach(LearningRelationshipExample.allCases) { example in
                    Button(example.rawValue) {
                        selectedExample = example
                    }
                }
            }
            .appFont(.callout)
            .padding(.top, AppMetrics.tight)
        }
    }

    private var lessonMap: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text("Lesson map")
                .appFont(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppMetrics.snug) {
                    ForEach(RelationshipLessonPart.allCases) { part in
                        let index = part.rawValue
                        Button {
                            selectedPartIndex = index
                        } label: {
                            HStack(spacing: AppMetrics.compact) {
                                IndexedSelectionBadge(
                                    index: index + 1,
                                    isSelected: index == selectedPartIndex
                                )

                                VStack(alignment: .leading, spacing: AppMetrics.tight) {
                                    Image(systemName: part.symbolName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(index == selectedPartIndex ? palette.accent : Color.secondary)
                                        .accessibilityHidden(true)
                                    Text(part.shortTitle)
                                        .appFont(.callout)
                                        .foregroundStyle(.primary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(AppMetrics.compact)
                            .frame(
                                width: textScale >= 1.3 ? 340 : 230,
                                height: textScale >= 1.3 ? 92 : 72,
                                alignment: .leading
                            )
                            .background {
                                SelectableCardChrome(isSelected: index == selectedPartIndex)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Part \(index + 1), \(part.title)")
                        .accessibilityValue(index == selectedPartIndex ? "Selected" : "Not selected")
                    }
                }
                .padding(AppMetrics.hairline)
            }
        }
    }

    private var navigation: some View {
        HStack(spacing: AppMetrics.regular) {
            Button("Previous", systemImage: "chevron.left") {
                selectedPartIndex = max(selectedPartIndex - 1, 0)
            }
            .disabled(selectedPartIndex == 0)
            .frame(minWidth: 120, alignment: .leading)

            Spacer()

            Text("Part \(selectedPartIndex + 1) of \(RelationshipLessonPart.allCases.count)")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer()

            if selectedPartIndex < RelationshipLessonPart.allCases.count - 1 {
                Button("Next", systemImage: "chevron.right") {
                    selectedPartIndex += 1
                }
                .buttonStyle(.borderedProminent)
                .frame(minWidth: 140, alignment: .trailing)
            } else {
                Button("Compare in Check", systemImage: "arrow.right") {
                    model.openInCheck(
                        foreground: colors.0,
                        background: colors.1,
                        analysis: .difference
                    )
                }
                .buttonStyle(.borderedProminent)
                .frame(minWidth: 140, alignment: .trailing)
            }
        }
        .appFont(.body)
        .frame(minHeight: 34)
    }

    private var lessonCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                Text(selectedPart.title)
                    .appFont(.title)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)

                Text(selectedPart.explanation)
                    .appFont(.body)
                    .fixedSize(horizontal: false, vertical: true)

                TermHelpRow(conceptIDs: selectedPart.definitionIDs)

                partVisualization

                VStack(alignment: .leading, spacing: AppMetrics.tight) {
                    Text("Keep in view")
                        .appFont(.headline)
                    Text(selectedPart.keyPoint)
                        .appFont(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var partVisualization: some View {
        switch selectedPart {
        case .twoQuestions:
            TwoQuestionsGraphic(
                first: colors.0,
                second: colors.1,
                contrast: contrast,
                difference: difference
            )
        case .contrast:
            ContrastRelationshipGraphic(
                foreground: colors.0,
                background: colors.1,
                evaluation: contrast,
                openInCheck: {
                    model.openInCheck(
                        foreground: colors.0,
                        background: colors.1,
                        analysis: .contrast
                    )
                }
            )
        case .difference:
            DifferenceRelationshipGraphic(
                first: colors.0,
                second: colors.1,
                evaluation: difference,
                openInCheck: {
                    model.openInCheck(
                        foreground: colors.0,
                        background: colors.1,
                        analysis: .difference
                    )
                }
            )
        }
    }

    private var sourceLinks: some View {
        let evidence = selectedPart.evidenceIDs.compactMap(EvidenceRegistry.record(withID:))
        return VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text("Sources for this part")
                .appFont(.caption)
                .foregroundStyle(.secondary)
            ForEach(evidence) { record in
                Link(destination: record.sourceURL) {
                    Label(record.title, systemImage: "arrow.up.right")
                }
                .appFont(.callout)
            }
        }
        .padding(.horizontal, AppMetrics.tight)
    }

    private var contrast: ContrastEvaluation {
        contrastChecker.evaluateOverOpaqueBackground(foreground: colors.0, background: colors.1)
    }

    private var difference: ColorDifferenceEvaluation {
        differenceCalculator.evaluate(
            reference: lab(for: colors.0),
            sample: lab(for: colors.1)
        )
    }

    private func lab(for color: SRGBColor) -> LabColor {
        converter.analyze(
            ParsedColor(
                originalRepresentation: color.hex,
                notation: "CSS hexadecimal",
                notationID: .hexadecimal,
                colorSpace: .sRGB,
                color: color
            )
        ).labD50
    }
}

/// The two colors under discussion, shown together with their labels.
private struct RelationshipPairPreview: View {
    let first: SRGBColor
    let second: SRGBColor
    var firstLabel = "First"
    var secondLabel = "Second"

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack {
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text(firstLabel).appFont(.caption).foregroundStyle(.secondary)
                    Text(first.hex).appFont(.value).monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: AppMetrics.hairline) {
                    Text(secondLabel).appFont(.caption).foregroundStyle(.secondary)
                    Text(second.hex).appFont(.value).monospacedDigit()
                }
            }

            HStack(spacing: 0) {
                Rectangle().fill(first.swiftUIColor)
                Rectangle().fill(second.swiftUIColor)
            }
            .frame(height: 118)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Two-color example")
        .accessibilityValue("\(firstLabel) \(first.accessibleDescription). \(secondLabel) \(second.accessibleDescription).")
    }
}

/// Puts the contrast ratio and the difference value beside each other so the
/// reader sees one pair producing two unrelated answers.
private struct TwoQuestionsGraphic: View {
    let first: SRGBColor
    let second: SRGBColor
    let contrast: ContrastEvaluation
    let difference: ColorDifferenceEvaluation
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            RelationshipPairPreview(first: first, second: second)

            AdaptivePairLayout(
                horizontalThreshold: textScale >= 1.3 ? 900 : 620,
                leadingFraction: 0.5,
                spacing: AppMetrics.compact
            ) {
                metricPanel(
                    title: "Foreground/background contrast",
                    value: "\(Format.decimal(contrast.ratio, places: 2)):1",
                    question: "Does this relationship meet the threshold for its intended use?",
                    symbol: "circle.lefthalf.filled"
                )
                metricPanel(
                    title: "Modeled color difference",
                    value: Format.decimal(difference.deltaE00, places: 3),
                    question: "How large is the relative difference in CIEDE2000?",
                    symbol: "circle.grid.cross"
                )
            }
        }
    }

    private func metricPanel(title: String, value: String, question: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Label(title, systemImage: symbol)
                .appFont(.headline)
            Text(value)
                .appFont(.largeTitle)
                .monospacedDigit()
            Text(question)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.regular)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    }
}

/// The contrast side of the lesson, with a route into the Check workspace for
/// the same pair.
private struct ContrastRelationshipGraphic: View {
    let foreground: SRGBColor
    let background: SRGBColor
    let evaluation: ContrastEvaluation
    let openInCheck: () -> Void

    private var passesNormalText: Bool { evaluation.ratio >= 4.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            Text("Sample foreground text")
                .appFont(.title2)
            .foregroundStyle(foreground.swiftUIColor)
            .padding(AppMetrics.roomy)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .background(background.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).strokeBorder(.separator, lineWidth: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Foreground and background contrast sample")
            .accessibilityValue("Foreground \(foreground.hex) on background \(background.hex).")

            Text("The block above deliberately uses the actual pair. The numeric result and wording below remain readable independently of that appearance.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AppMetrics.section) { resultContent }
                VStack(alignment: .leading, spacing: AppMetrics.snug) { resultContent }
            }

            Button("Open this contrast in Check", systemImage: "arrow.right", action: openInCheck)
                .buttonStyle(.bordered)
                .appFont(.callout)
        }
    }

    @ViewBuilder
    private var resultContent: some View {
        VStack(alignment: .leading, spacing: AppMetrics.hairline) {
            Text("Contrast ratio")
                .appFont(.callout)
                .foregroundStyle(.secondary)
            Text("\(Format.decimal(evaluation.ratio, places: 2)):1")
                .appFont(.largeTitle)
                .monospacedDigit()
        }
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Label(
                passesNormalText ? "Meets 4.5:1 for normal text" : "Below 4.5:1 for normal text",
                systemImage: passesNormalText ? "checkmark.circle" : "xmark.circle"
            )
            .appFont(.headline)
            Text("Other uses have their own named criteria. Open Check to inspect them separately.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The difference side of the lesson, with the same route into Check.
private struct DifferenceRelationshipGraphic: View {
    @Environment(\.appSemanticPalette) private var palette
    let first: SRGBColor
    let second: SRGBColor
    let evaluation: ColorDifferenceEvaluation
    let openInCheck: () -> Void

    private var components: [(String, Double)] {
        [
            ("Light and dark", evaluation.weightedLightnessTerm),
            ("Chroma", evaluation.weightedChromaTerm),
            ("Hue direction", evaluation.weightedHueTerm)
        ]
    }

    private var maximumMagnitude: Double {
        max(components.map { abs($0.1) }.max() ?? 0, 0.000_001)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            RelationshipPairPreview(first: first, second: second)

            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.compact) {
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text("CIEDE2000 difference")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                    Text(Format.decimal(evaluation.deltaE00, places: 3))
                        .appFont(.largeTitle)
                        .monospacedDigit()
                    Text("ΔE00")
                        .appFont(.value)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("A relative value, not a universal pass or fail")
                    .appFont(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                Text("Weighted terms for this pair")
                    .appFont(.headline)
                ForEach(Array(components.enumerated()), id: \.offset) { _, component in
                    lessonBar(title: component.0, value: component.1)
                }
            }

            Button("Open this difference in Check", systemImage: "arrow.right", action: openInCheck)
                .buttonStyle(.bordered)
                .appFont(.callout)
        }
    }

    private func lessonBar(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            HStack {
                Text(title).appFont(.callout)
                Spacer()
                Text(Format.signed(value, places: 3))
                    .appFont(.value)
                    .monospacedDigit()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.14))
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: max(4, geometry.size.width * abs(value) / maximumMagnitude))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Format.signed(value, places: 3))
    }
}
