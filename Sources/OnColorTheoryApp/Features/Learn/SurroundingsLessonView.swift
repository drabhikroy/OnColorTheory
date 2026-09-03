import SwiftUI

/// The fixed target and the surrounds it is shown against.
///
/// The target never changes value. That is the whole point of the lesson, so it
/// is held here as a constant rather than passed in.
enum SurroundingsLessonExample {
    static let target = gray(128)
    static let darkSurround = gray(32)
    static let lightSurround = gray(232)

    static func adjustableSurround(encodedLevel: Double) -> SRGBColor {
        let clamped = min(max(encodedLevel, 0), 1)
        return SRGBColor(red: clamped, green: clamped, blue: clamped)
    }

    private static func gray(_ component: Int) -> SRGBColor {
        let value = Double(component) / 255
        return SRGBColor(red: value, green: value, blue: value)
    }
}

/// The three parts of the surroundings lesson.
private enum SurroundingsLessonPart: Int, CaseIterable, Identifiable {
    case fixedTarget
    case changingSurround
    case measurementBoundary

    var id: Self { self }

    var shortTitle: String {
        switch self {
        case .fixedTarget: "Fixed target"
        case .changingSurround: "Changing context"
        case .measurementBoundary: "What is measured"
        }
    }

    var title: String {
        switch self {
        case .fixedTarget:
            "Hold the center color constant"
        case .changingSurround:
            "Change the surround, not the target"
        case .measurementBoundary:
            "Coordinates describe the target, not the whole scene"
        }
    }

    var symbolName: String {
        switch self {
        case .fixedTarget: "equal.square"
        case .changingSurround: "slider.horizontal.3"
        case .measurementBoundary: "eye"
        }
    }

    var explanation: String {
        switch self {
        case .fixedTarget:
            "Both center patches below use the same opaque sRGB value. Only their surrounding fields differ. If the centers do not look identical, that difference is part of the visual experience, not a difference in the stored target values."
        case .changingSurround:
            "Move the control to change only the second surround. The two center patches remain #808080 throughout. This isolates one contextual variable while keeping the target's encoded channels unchanged."
        case .measurementBoundary:
            "The app can verify that the target coordinates match and that the surrounds differ. Perceived appearance also depends on viewing conditions and the observer, so this lesson does not assign one universal number to the effect."
        }
    }

    var keyPoint: String {
        switch self {
        case .fixedTarget:
            "Matching color values do not produce matching appearance when the visual context changes."
        case .changingSurround:
            "A controlled comparison changes one stated variable and keeps the rest visible."
        case .measurementBoundary:
            "Color coordinates are measurements within a model; they are not a complete prediction of individual perception."
        }
    }

    var definitionIDs: [String] {
        switch self {
        case .fixedTarget: ["srgb", "simultaneous-contrast"]
        case .changingSurround: ["encoded-linear", "simultaneous-contrast"]
        case .measurementBoundary: ["color-appearance", "cielab", "reference-white"]
        }
    }

    var evidenceIDs: [String] {
        switch self {
        case .fixedTarget: ["iec-srgb", "kingdom-lightness-2011"]
        case .changingSurround: ["kingdom-lightness-2011"]
        case .measurementBoundary: ["cie-248-2022-ciecam16", "cie-015-2018"]
        }
    }
}

/// The lesson on context changing appearance without changing the color.
///
/// Part three is a boundary rather than a payoff. An on-screen demonstration
/// shows that context matters; it does not measure how much, and a color
/// appearance model predicts correlates for stated viewing conditions rather
/// than reading one person's experience.
struct SurroundingsLessonView: View {
    @Environment(\.appSemanticPalette) private var palette
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var selectedPartIndex = 0
    @State private var adjustableSurroundLevel = 232.0 / 255.0
    let onClose: () -> Void

    init(
        model: AppModel,
        initialPartIndex: Int = 0,
        onClose: @escaping () -> Void = {}
    ) {
        self.model = model
        self.onClose = onClose
        _selectedPartIndex = State(
            initialValue: min(max(initialPartIndex, 0), SurroundingsLessonPart.allCases.count - 1)
        )
        _adjustableSurroundLevel = State(initialValue: model.workspaceSession.learnSurroundLevel)
    }

    private var selectedPart: SurroundingsLessonPart {
        SurroundingsLessonPart.allCases[selectedPartIndex]
    }

    private var adjustableSurround: SRGBColor {
        SurroundingsLessonExample.adjustableSurround(encodedLevel: adjustableSurroundLevel)
    }

    var body: some View {
        ScrollViewReader { proxy in
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
                .id("surroundings-lesson-top")
                .frame(maxWidth: 860, alignment: .leading)
                .padding(AppMetrics.page)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .defaultScrollAnchor(.top)
            .onAppear {
                proxy.scrollTo("surroundings-lesson-top", anchor: .top)
            }
            .onChange(of: selectedPartIndex) {
                proxy.scrollTo("surroundings-lesson-top", anchor: .top)
            }
        }
        .navigationTitle("Learn")
        .textSelection(.enabled)
        .onChange(of: selectedPartIndex) { _, index in
            model.updateWorkspaceSession {
                $0.learnPartIndices[LearningLessonID.surroundingsAndAppearance.rawValue] = index
            }
        }
        .onChange(of: adjustableSurroundLevel) { _, level in
            model.updateWorkspaceSession { $0.learnSurroundLevel = level }
        }
    }

    private var introduction: some View {
        DestinationHeader(
            context: "Perception, 3 short parts",
            title: LearningLessonID.surroundingsAndAppearance.title,
            summary: "One fixed center color in two surroundings."
        )
    }

    private var lessonMap: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text("Lesson map")
                .appFont(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppMetrics.snug) {
                    ForEach(SurroundingsLessonPart.allCases) { part in
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
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
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

            Text("Part \(selectedPartIndex + 1) of \(SurroundingsLessonPart.allCases.count)")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer()

            if selectedPartIndex < SurroundingsLessonPart.allCases.count - 1 {
                Button("Next", systemImage: "chevron.right") {
                    selectedPartIndex += 1
                }
                .buttonStyle(.borderedProminent)
                .frame(minWidth: 140, alignment: .trailing)
            } else {
                Button("Open target in Convert", systemImage: "arrow.right") {
                    model.openInConvert(SurroundingsLessonExample.target)
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
        case .fixedTarget:
            ContextPatchPairGraphic(
                target: SurroundingsLessonExample.target,
                firstSurround: SurroundingsLessonExample.darkSurround,
                secondSurround: SurroundingsLessonExample.lightSurround,
                firstLabel: "Dark surround",
                secondLabel: "Light surround"
            )
        case .changingSurround:
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Second surround")
                            .appFont(.headline)
                        Spacer()
                        Text(adjustableSurround.hex)
                            .appFont(.value)
                            .monospacedDigit()
                    }

                    Slider(
                        value: $adjustableSurroundLevel,
                        in: 0.08...0.92,
                        step: 1.0 / 255.0
                    )
                    .accessibilityLabel("Second surround encoded sRGB level")
                    .accessibilityValue("\(adjustableSurround.hex), \(Format.percent(adjustableSurroundLevel))")

                    HStack {
                        Text("Darker")
                        Spacer()
                        Text("Lighter")
                    }
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                }

                ContextPatchPairGraphic(
                    target: SurroundingsLessonExample.target,
                    firstSurround: SurroundingsLessonExample.darkSurround,
                    secondSurround: adjustableSurround,
                    firstLabel: "Fixed comparison",
                    secondLabel: "Adjustable surround"
                )
            }
        case .measurementBoundary:
            AppearanceBoundaryGraphic(
                target: SurroundingsLessonExample.target,
                firstSurround: SurroundingsLessonExample.darkSurround,
                secondSurround: SurroundingsLessonExample.lightSurround
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
}

/// The same target shown on two surrounds at once, side by side.
private struct ContextPatchPairGraphic: View {
    let target: SRGBColor
    let firstSurround: SRGBColor
    let secondSurround: SRGBColor
    let firstLabel: String
    let secondLabel: String
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        AdaptivePairLayout(
            horizontalThreshold: textScale >= 1.3 ? 1_100 : 620,
            leadingFraction: 0.5,
            spacing: AppMetrics.regular
        ) {
            ContextPatchGraphic(target: target, surround: firstSurround, label: firstLabel)
            ContextPatchGraphic(target: target, surround: secondSurround, label: secondLabel)
        }
    }
}

/// One target patch on one surround.
private struct ContextPatchGraphic: View {
    let target: SRGBColor
    let surround: SRGBColor
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Rectangle()
                .fill(surround.swiftUIColor)
                .frame(maxWidth: .infinity, minHeight: 200)
                .overlay {
                    Rectangle()
                        .fill(target.swiftUIColor)
                        .frame(width: 96, height: 96)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                Text(label)
                    .appFont(.headline)
                Text("Target \(target.hex) · Surround \(surround.hex)")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("Target \(target.accessibleDescription). Surround \(surround.accessibleDescription).")
    }
}

/// States what the demonstration does and does not establish, with the
/// calculated values that stay identical across both surrounds.
private struct AppearanceBoundaryGraphic: View {
    let target: SRGBColor
    let firstSurround: SRGBColor
    let secondSurround: SRGBColor
    @Environment(\.appTextScale) private var textScale

    private var analysis: ColorAnalysis {
        ColorCore().analyze(target, as: .hexadecimal)
    }

    var body: some View {
        Group {
            if textScale >= 1.3 {
                VStack(spacing: AppMetrics.compact) {
                    fixedTargetNode
                    Image(systemName: "plus").foregroundStyle(.secondary).accessibilityHidden(true)
                    contextNode
                    Image(systemName: "arrow.down").foregroundStyle(.secondary).accessibilityHidden(true)
                    appearanceNode
                }
            } else {
                HStack(spacing: AppMetrics.compact) {
                    fixedTargetNode
                    Image(systemName: "plus").foregroundStyle(.secondary).accessibilityHidden(true)
                    contextNode
                    Image(systemName: "arrow.right").foregroundStyle(.secondary).accessibilityHidden(true)
                    appearanceNode
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var fixedTargetNode: some View {
        boundaryNode(title: "Fixed target", symbol: "equal.square") {
            HStack(spacing: AppMetrics.snug) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(target.swiftUIColor)
                    .frame(width: 44, height: 44)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6).strokeBorder(.separator, lineWidth: 1)
                    }
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text(target.hex)
                        .appFont(.value)
                        .monospacedDigit()
                    Text(labText)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }

    private var contextNode: some View {
        boundaryNode(title: "Different context", symbol: "square.on.square") {
            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                labeledSwatch("First surround", color: firstSurround)
                labeledSwatch("Second surround", color: secondSurround)
            }
        }
    }

    private var appearanceNode: some View {
        boundaryNode(title: "Perceived appearance", symbol: "eye") {
            Text("Context-dependent; this lesson does not assign one universal value.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var labText: String {
        let lab = analysis.labD50
        return "Lab \(Format.decimal(lab.lightness, places: 2))  \(Format.decimal(lab.a, places: 2))  \(Format.decimal(lab.b, places: 2))"
    }

    private func labeledSwatch(_ label: String, color: SRGBColor) -> some View {
        HStack(spacing: AppMetrics.snug) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.swiftUIColor)
                .frame(width: 28, height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(.separator, lineWidth: 1)
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).appFont(.caption).foregroundStyle(.secondary)
                Text(color.hex).appFont(.value).monospacedDigit()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(color.accessibleDescription)
    }

    private func boundaryNode<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            Label(title, systemImage: symbol)
                .appFont(.headline)
            content()
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        .appSubtleSurface(cornerRadius: 10)
    }
}
