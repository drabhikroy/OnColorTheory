import SwiftUI

/// The three parts of the coordinates lesson.
private enum IntroLessonPart: Int, CaseIterable, Identifiable {
    case encodedChannels
    case linearLight
    case referenceWhite

    var id: Self { self }

    var title: String {
        switch self {
        case .encodedChannels: "A color code stores three channel instructions"
        case .linearLight: "Recover values proportional to light"
        case .referenceWhite: "Keep the viewing reference attached"
        }
    }

    var shortTitle: String {
        switch self {
        case .encodedChannels: "Stored channels"
        case .linearLight: "Proportional light"
        case .referenceWhite: "Viewing reference"
        }
    }

    var symbolName: String {
        switch self {
        case .encodedChannels: "number"
        case .linearLight: "sun.max"
        case .referenceWhite: "sun.haze"
        }
    }

    var explanation: String {
        switch self {
        case .encodedChannels:
            "An sRGB value does not describe a measured spectrum. It stores three encoded channel instructions and, when present, an alpha value. The sRGB definition gives those numbers their colorimetric meaning."
        case .linearLight:
            "sRGB stores its channel values on a nonlinear scale. Before a matrix calculation, the app decodes each channel onto a scale proportional to light. The numbers change, but the intended color does not."
        case .referenceWhite:
            "XYZ and Lab coordinates are interpreted relative to stated reference conditions. sRGB begins from D65. This workflow adapts XYZ to D50 before calculating CSS Lab, so the white-point assumption remains explicit."
        }
    }

    var keyPoint: String {
        switch self {
        case .encodedChannels:
            "A tuple of numbers is incomplete without its color space, encoding, and channel ranges."
        case .linearLight:
            "Equal changes in encoded sRGB do not correspond to equal changes in light."
        case .referenceWhite:
            "Two coordinate sets should not be compared as equivalent when their reference whites differ."
        }
    }

    var definitionIDs: [String] {
        switch self {
        case .encodedChannels: ["srgb", "alpha"]
        case .linearLight: ["encoded-linear"]
        case .referenceWhite: ["reference-white", "chromatic-adaptation"]
        }
    }

    var evidenceIDs: [String] {
        switch self {
        case .encodedChannels, .linearLight:
            ["iec-srgb", "w3c-css-color-4"]
        case .referenceWhite:
            ["cie-015-2018", "w3c-css-color-4"]
        }
    }
}

/// The lesson on what a color coordinate actually names.
///
/// It moves from encoded channels, to the linear light those encode, to the
/// reference white the whole thing is measured against, because each step is
/// meaningless without the one before it.
struct ColorCoordinatesLessonView: View {
    @Environment(\.appSemanticPalette) private var palette
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var selectedPartIndex = 0
    let onClose: () -> Void

    init(
        model: AppModel,
        initialPartIndex: Int = 0,
        onClose: @escaping () -> Void = {}
    ) {
        self.model = model
        self.onClose = onClose
        _selectedPartIndex = State(
            initialValue: min(max(initialPartIndex, 0), IntroLessonPart.allCases.count - 1)
        )
    }

    private var selectedPart: IntroLessonPart {
        IntroLessonPart.allCases[selectedPartIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                header
                lessonIntroduction
                lessonMap
                navigation
                lessonPart
                sourceLinks
            }
            .frame(maxWidth: 800, alignment: .leading)
            .padding(AppMetrics.page)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle("Learn")
        .textSelection(.enabled)
        .onChange(of: selectedPartIndex) { _, index in
            model.updateWorkspaceSession {
                $0.learnPartIndices[LearningLessonID.colorCoordinates.rawValue] = index
            }
        }
    }

    private var header: some View {
        Button("All lessons", systemImage: "chevron.left", action: onClose)
            .buttonStyle(.plain)
            .appFont(.body)
            .foregroundStyle(palette.accent)
    }

    private var lessonIntroduction: some View {
        DestinationHeader(
            context: "Foundation, 3 short parts",
            title: LearningLessonID.colorCoordinates.title,
            summary: "Follow the current Convert color through the assumptions behind its numbers."
        )
    }

    private var lessonMap: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text("Lesson map")
                .appFont(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppMetrics.snug) {
                    ForEach(IntroLessonPart.allCases) { part in
                        let index = part.rawValue
                        Button {
                            selectedPartIndex = index
                        } label: {
                            HStack(spacing: AppMetrics.compact) {
                                IndexedSelectionBadge(
                                    index: index + 1,
                                    isSelected: index == selectedPartIndex
                                )

                                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
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

    private var lessonPart: some View {
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

                if selectedPart == .linearLight {
                    Button("Try the mixing experiment", systemImage: "slider.horizontal.3") {
                        model.selectedSection = .explore
                    }
                    .buttonStyle(.borderedProminent)
                    .appFont(.body)
                }

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
        case .encodedChannels:
            EncodedChannelGraphic(color: model.analysis.parsed.color)
        case .linearLight:
            TransferCurveGraphic(analysis: model.analysis)
        case .referenceWhite:
            CoordinateRouteGraphic()
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

    private var navigation: some View {
        HStack(spacing: AppMetrics.regular) {
            Button("Previous", systemImage: "chevron.left") {
                selectedPartIndex = max(selectedPartIndex - 1, 0)
            }
            .disabled(selectedPartIndex == 0)
            .frame(minWidth: 120, alignment: .leading)

            Spacer()

            Text("Part \(selectedPartIndex + 1) of \(IntroLessonPart.allCases.count)")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer()

            if selectedPartIndex < IntroLessonPart.allCases.count - 1 {
                Button("Next", systemImage: "chevron.right") {
                    selectedPartIndex += 1
                }
                .buttonStyle(.borderedProminent)
                .frame(minWidth: 140, alignment: .trailing)
            } else {
                Button("Open Convert", systemImage: "arrow.right") {
                    model.selectedSection = .convert
                }
                .buttonStyle(.borderedProminent)
                .frame(minWidth: 140, alignment: .trailing)
            }
        }
        .appFont(.body)
        .frame(minHeight: 34)
    }
}

/// The three encoded channels of the working color, as values and bars.
private struct EncodedChannelGraphic: View {
    let color: SRGBColor
    @Environment(\.appTextScale) private var textScale

    private var channels: [(String, Int, Double, Color)] {
        [
            ("Red", color.red8, color.red, .red),
            ("Green", color.green8, color.green, .green),
            ("Blue", color.blue8, color.blue, .blue)
        ]
    }

    var body: some View {
        VStack(spacing: AppMetrics.compact) {
            ForEach(channels, id: \.0) { channel in
                Group {
                    if textScale >= 1.3 {
                        VStack(alignment: .leading, spacing: AppMetrics.snug) {
                            HStack {
                                Text(channel.0)
                                    .appFont(.headline)
                                Spacer()
                                Text("\(channel.1) / 255")
                                    .appFont(.value)
                                    .monospacedDigit()
                            }
                            channelBar(channel)
                        }
                    } else {
                        HStack(spacing: AppMetrics.compact) {
                            Text(channel.0)
                                .appFont(.headline)
                                .frame(width: 64, alignment: .leading)
                            channelBar(channel)
                            Text("\(channel.1) / 255")
                                .appFont(.value)
                                .monospacedDigit()
                                .frame(width: 92, alignment: .trailing)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(channel.0)
                .accessibilityValue("\(channel.1) out of 255")
            }
        }
        .padding(.vertical, AppMetrics.tight)
    }

    private func channelBar(_ channel: (String, Int, Double, Color)) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.14))
                Capsule()
                    .fill(channel.3.opacity(0.78))
                    .frame(width: max(4, geometry.size.width * channel.2))
            }
        }
        .frame(height: 12)
    }
}

/// Plots each channel on the sRGB transfer curve, showing that the encoded
/// value and the light it stands for are not proportional.
private struct TransferCurveGraphic: View {
    let analysis: ColorAnalysis

    private var points: [(String, Double, Double, Color)] {
        [
            ("R", analysis.parsed.color.red, analysis.linear.red, .red),
            ("G", analysis.parsed.color.green, analysis.linear.green, .green),
            ("B", analysis.parsed.color.blue, analysis.linear.blue, .blue)
        ]
    }

    var body: some View {
        VStack(spacing: AppMetrics.tight) {
            HStack(spacing: AppMetrics.snug) {
                Text("Linear light")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: 18)

                Canvas { context, size in
                    let plot = CGRect(x: 14, y: 12, width: max(1, size.width - 26), height: max(1, size.height - 24))

                    var axes = Path()
                    axes.move(to: CGPoint(x: plot.minX, y: plot.minY))
                    axes.addLine(to: CGPoint(x: plot.minX, y: plot.maxY))
                    axes.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
                    context.stroke(axes, with: .color(.secondary.opacity(0.5)), lineWidth: 1)

                    var curve = Path()
                    for sample in 0...100 {
                        let encoded = Double(sample) / 100
                        let linear = TransferFunctions.sRGBToLinear(encoded)
                        let point = CGPoint(
                            x: plot.minX + (plot.width * encoded),
                            y: plot.maxY - (plot.height * linear)
                        )
                        if sample == 0 { curve.move(to: point) } else { curve.addLine(to: point) }
                    }
                    context.stroke(curve, with: .color(.primary), lineWidth: 2)

                    for point in points {
                        let center = CGPoint(
                            x: plot.minX + (plot.width * point.1),
                            y: plot.maxY - (plot.height * point.2)
                        )
                        let marker = CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)
                        context.fill(Path(ellipseIn: marker), with: .color(point.3))
                        context.stroke(Path(ellipseIn: marker), with: .color(.primary), lineWidth: 1)
                        context.draw(
                            Text(point.0).font(.system(size: 12, weight: .bold)),
                            at: CGPoint(x: center.x + 12, y: center.y - 10)
                        )
                    }
                }
                .frame(minHeight: 220)
            }

            Text("Encoded sRGB")
                .appFont(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("sRGB decoding curve")
        .accessibilityValue(
            "The curve maps encoded values on the horizontal axis to linear-light values on the vertical axis. The current red, green, and blue channels are labeled on the curve."
        )
    }
}

/// The conversion route as a row of labeled nodes, stacking when the width
/// or the text size will not hold one line.
private struct CoordinateRouteGraphic: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppMetrics.compact) {
                routeNode("sRGB", detail: "encoded · D65", symbol: "number")
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                routeNode("Linear sRGB", detail: "light", symbol: "sun.max")
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                routeNode("XYZ", detail: "D65 → D50", symbol: "move.3d")
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                routeNode("Lab", detail: "D50", symbol: "axis.3d")
            }

            VStack(spacing: AppMetrics.snug) {
                routeNode("sRGB", detail: "encoded · D65", symbol: "number")
                Image(systemName: "arrow.down").foregroundStyle(.secondary)
                routeNode("Linear sRGB", detail: "light", symbol: "sun.max")
                Image(systemName: "arrow.down").foregroundStyle(.secondary)
                routeNode("XYZ", detail: "D65 → D50", symbol: "move.3d")
                Image(systemName: "arrow.down").foregroundStyle(.secondary)
                routeNode("Lab", detail: "D50", symbol: "axis.3d")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppMetrics.snug)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Coordinate route")
        .accessibilityValue("Encoded sRGB under D65 becomes linear sRGB, then XYZ adapted from D65 to D50, then Lab under D50.")
    }

    private func routeNode(_ title: String, detail: String, symbol: String) -> some View {
        VStack(spacing: AppMetrics.tight) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .frame(height: 28)
            Text(title)
                .appFont(.headline)
            Text(detail)
                .appFont(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
