import SwiftUI

/// The fixed color the color-space-limits lesson is built around.
///
/// A single example runs through all three parts so the reader is comparing
/// stages rather than colors. It is a vivid red because vivid reds are the
/// clearest case of components that are valid in Display P3 and impossible in
/// sRGB.
enum GamutLessonExample {
    static let source = DisplayP3Color(red: 1, green: 0.2, blue: 0.1)
    static let sameComponentsInSRGB = SRGBColor(red: 1, green: 0.2, blue: 0.1)

    static var evaluation: GamutEvaluation {
        DisplayP3GamutAnalyzer().evaluate(source)
    }
}

/// The three parts of the color-space-limits lesson, in order.
private enum GamutLessonPart: Int, CaseIterable, Identifiable {
    case sourceSpace
    case destinationBoundary
    case mappingChoice

    var id: Self { self }

    var shortTitle: String {
        switch self {
        case .sourceSpace: "Source coordinates"
        case .destinationBoundary: "Destination boundary"
        case .mappingChoice: "Mapping choice"
        }
    }

    var title: String {
        switch self {
        case .sourceSpace:
            "Attach the color space before interpreting the numbers"
        case .destinationBoundary:
            "Convert the color before asking whether it fits"
        case .mappingChoice:
            "A crossed boundary creates a mapping decision"
        }
    }

    var symbolName: String {
        switch self {
        case .sourceSpace: "number"
        case .destinationBoundary: "triangle"
        case .mappingChoice: "arrow.triangle.branch"
        }
    }

    var explanation: String {
        switch self {
        case .sourceSpace:
            "The component triple 1, 0.2, 0.1 is not a complete color description. Display P3 and sRGB use different primaries, so interpreting the same three numbers in each space names two different colors."
        case .destinationBoundary:
            "To ask whether the intended Display P3 color fits in sRGB, the app first converts it through XYZ under their shared D65 reference white. The converted sRGB channels, not the original P3 numbers, are then compared with the destination range from 0 to 1."
        case .mappingChoice:
            "An out-of-range result establishes that the source cannot remain unchanged in sRGB. It does not identify one universally correct replacement. Mapping methods choose an in-range color by making stated tradeoffs among lightness, chroma, and hue."
        }
    }

    var keyPoint: String {
        switch self {
        case .sourceSpace:
            "RGB numbers only have colorimetric meaning when their RGB color space is known."
        case .destinationBoundary:
            "Gamut membership is a relationship between a color and a stated destination, not a property of an unlabelled number triple."
        case .mappingChoice:
            "Boundary detection is a calculation; selecting a mapping method is a separate reproduction decision."
        }
    }

    var definitionIDs: [String] {
        switch self {
        case .sourceSpace: ["display-p3", "srgb", "rgb-model"]
        case .destinationBoundary: ["cie-xyz", "gamut", "encoded-linear"]
        case .mappingChoice: ["gamut-mapping", "chroma", "oklab"]
        }
    }

    var evidenceIDs: [String] {
        switch self {
        case .sourceSpace: ["w3c-css-color-4"]
        case .destinationBoundary, .mappingChoice: ["w3c-css-color-4-gamut"]
        }
    }
}

/// The color-space-limits lesson.
///
/// Part one shows that the same three numbers name different colors in
/// different spaces, part two shows which channels leave the destination range,
/// and part three shows that what to do about it is a choice rather than a
/// calculation.
struct GamutLessonView: View {
    @Environment(\.appSemanticPalette) private var palette
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var selectedPartIndex: Int
    let onClose: () -> Void

    init(
        model: AppModel,
        initialPartIndex: Int = 0,
        onClose: @escaping () -> Void = {}
    ) {
        self.model = model
        self.onClose = onClose
        _selectedPartIndex = State(
            initialValue: min(max(initialPartIndex, 0), GamutLessonPart.allCases.count - 1)
        )
    }

    private var selectedPart: GamutLessonPart {
        GamutLessonPart.allCases[selectedPartIndex]
    }

    private var evaluation: GamutEvaluation {
        GamutLessonExample.evaluation
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.section) {
                    Color.clear
                        .frame(height: 0)
                        .id("gamut-lesson-top")

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
            .defaultScrollAnchor(.top)
            .onAppear {
                proxy.scrollTo("gamut-lesson-top", anchor: .top)
            }
            .onChange(of: selectedPartIndex) {
                proxy.scrollTo("gamut-lesson-top", anchor: .top)
            }
        }
        .navigationTitle("Learn")
        .textSelection(.enabled)
        .onChange(of: selectedPartIndex) { _, index in
            model.updateWorkspaceSession {
                $0.learnPartIndices[LearningLessonID.colorSpaceLimits.rawValue] = index
            }
        }
    }

    private var introduction: some View {
        DestinationHeader(
            context: "Reproduction, 3 short parts",
            title: LearningLessonID.colorSpaceLimits.title,
            summary: "One wide-gamut source, with interpretation and reproduction kept apart."
        )
    }

    private var lessonMap: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text("Lesson map")
                .appFont(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppMetrics.snug) {
                    ForEach(GamutLessonPart.allCases) { part in
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
            .accessibilityLabel("Lesson parts")
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

            Text("Part \(selectedPartIndex + 1) of \(GamutLessonPart.allCases.count)")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer()

            if selectedPartIndex < GamutLessonPart.allCases.count - 1 {
                Button("Next", systemImage: "chevron.right") {
                    selectedPartIndex += 1
                }
                .buttonStyle(.borderedProminent)
                .frame(minWidth: 140, alignment: .trailing)
            } else {
                Button("Open example in Check", systemImage: "arrow.right") {
                    model.openInGamutCheck(GamutLessonExample.source)
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
        case .sourceSpace:
            SameCoordinatesGraphic(
                displayP3: GamutLessonExample.source,
                sRGB: GamutLessonExample.sameComponentsInSRGB
            )
        case .destinationBoundary:
            DestinationBoundaryGraphic(evaluation: evaluation)
        case .mappingChoice:
            MappingChoiceGraphic(evaluation: evaluation)
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

/// Shows one set of components rendered as Display P3 and as sRGB side by
/// side, which is the lesson's opening point.
private struct SameCoordinatesGraphic: View {
    let displayP3: DisplayP3Color
    let sRGB: SRGBColor
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            AdaptivePairLayout(
                horizontalThreshold: textScale >= 1.3 ? 1_050 : 620,
                leadingFraction: 0.5,
                spacing: AppMetrics.compact
            ) {
                LessonColorSpacePanel(
                    title: "Interpreted as Display P3",
                    value: displayP3.css(alpha: 1),
                    color: displayP3.swiftUIColor,
                    accessibilityValue: displayP3.accessibleDescription
                )
                LessonColorSpacePanel(
                    title: "Interpreted as sRGB",
                    value: sRGB.hex,
                    color: sRGB.swiftUIColor,
                    accessibilityValue: sRGB.accessibleDescription
                )
            }

            Label(
                "Same component numbers; different primary definitions; different intended colors.",
                systemImage: "arrow.triangle.branch"
            )
            .appFont(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// One labeled swatch with its numeric value, used in pairs for comparison.
private struct LessonColorSpacePanel: View {
    let title: String
    let value: String
    let color: Color
    let accessibilityValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text(title)
                .appFont(.headline)

            Rectangle()
                .fill(color)
                .frame(height: 148)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.separator, lineWidth: 1)
                }
                .accessibilityLabel(title)
                .accessibilityValue(accessibilityValue)

            Text(value)
                .appFont(.value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.compact)
        .appSubtleSurface(cornerRadius: 10)
    }
}

/// Shows each converted channel against the sRGB range so the reader can see
/// which one crossed the boundary and by how much.
private struct DestinationBoundaryGraphic: View {
    @Environment(\.appSemanticPalette) private var palette
    let evaluation: GamutEvaluation
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppMetrics.compact) { routeNodes(horizontal: true) }
                VStack(spacing: AppMetrics.snug) { routeNodes(horizontal: false) }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                ForEach(evaluation.channels) { channel in
                    LessonBoundaryChannelRow(channel: channel)
                }
            }
            .padding(AppMetrics.compact)
            .appSubtleSurface(cornerRadius: 10)

            Label(
                "All three converted channels cross an sRGB boundary in this example.",
                systemImage: "exclamationmark.triangle"
            )
            .appFont(.callout)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func routeNodes(horizontal: Bool) -> some View {
        routeNode("Display P3", detail: "Decode source", symbol: "1.circle")
        Image(systemName: horizontal ? "arrow.right" : "arrow.down")
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        routeNode("XYZ D65", detail: "Shared connection", symbol: "2.circle")
        Image(systemName: horizontal ? "arrow.right" : "arrow.down")
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        routeNode("sRGB", detail: "Inspect range", symbol: "3.circle")
    }

    private func routeNode(_ title: String, detail: String, symbol: String) -> some View {
        VStack(spacing: AppMetrics.tight) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(palette.accent)
            Text(title)
                .appFont(.headline)
            Text(detail)
                .appFont(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: textScale >= 1.3 ? 104 : 88)
        .padding(.horizontal, AppMetrics.snug)
        .appSubtleSurface(cornerRadius: 10)
    }
}

/// One channel's converted value on a track marked with the sRGB range.
private struct LessonBoundaryChannelRow: View {
    @Environment(\.appSemanticPalette) private var palette
    let channel: GamutChannelEvaluation
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: AppMetrics.snug) { labels }
                VStack(alignment: .leading, spacing: AppMetrics.tight) { labels }
            }

            GeometryReader { geometry in
                let markerX = geometry.size.width * min(max(channel.encodedValue, 0), 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 9)
                    Capsule()
                        .fill(palette.accent.opacity(0.72))
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

    @ViewBuilder
    private var labels: some View {
        Text(channel.id.title)
            .appFont(.headline)
        if textScale < 1.3 { Spacer(minLength: 8) }
        Label(channel.position.rawValue, systemImage: statusSymbol)
            .appFont(.caption)
            .foregroundStyle(channel.position == .inside ? Color.secondary : Color.orange)
        Text(Format.decimal(channel.encodedValue, places: 5))
            .appFont(.value)
            .monospacedDigit()
    }

    private var statusSymbol: String {
        switch channel.position {
        case .below: "arrow.left"
        case .inside: "checkmark"
        case .above: "arrow.right"
        }
    }
}

/// Presents the gamut mapping options without recommending one.
///
/// Which mapping is right depends on what the color is for, which the app
/// cannot know, so this part names the trade-offs rather than picking.
private struct MappingChoiceGraphic: View {
    @Environment(\.appSemanticPalette) private var palette
    let evaluation: GamutEvaluation
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            AdaptivePairLayout(
                horizontalThreshold: textScale >= 1.3 ? 1_050 : 620,
                leadingFraction: 0.5,
                spacing: AppMetrics.compact
            ) {
                LessonColorSpacePanel(
                    title: "Display P3 source",
                    value: evaluation.source.css(alpha: 1),
                    color: evaluation.source.swiftUIColor,
                    accessibilityValue: evaluation.source.accessibleDescription
                )
                LessonColorSpacePanel(
                    title: "Simple clipped comparison",
                    value: evaluation.clippedSRGB.hex,
                    color: evaluation.clippedSRGB.swiftUIColor,
                    accessibilityValue: evaluation.clippedSRGB.accessibleDescription
                )
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppMetrics.snug) { decisionNodes(horizontal: true) }
                VStack(spacing: AppMetrics.snug) { decisionNodes(horizontal: false) }
            }

            Text("Clipping is easy to inspect because it limits each channel independently. It can change the balance of the primaries and shift hue, so current CSS color processing defines higher-quality alternatives for mapping individual SDR colors.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func decisionNodes(horizontal: Bool) -> some View {
        decisionNode("Outside range", detail: "Detected", symbol: "exclamationmark.triangle")
        Image(systemName: horizontal ? "arrow.right" : "arrow.down")
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        decisionNode("Choose a method", detail: "Tradeoffs", symbol: "arrow.triangle.branch")
        Image(systemName: horizontal ? "arrow.right" : "arrow.down")
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        decisionNode("Inside range", detail: "Destination", symbol: "checkmark.circle")
    }

    private func decisionNode(_ title: String, detail: String, symbol: String) -> some View {
        HStack(spacing: AppMetrics.snug) {
            Image(systemName: symbol)
                .foregroundStyle(palette.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                Text(title).appFont(.headline)
                Text(detail).appFont(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }
}
