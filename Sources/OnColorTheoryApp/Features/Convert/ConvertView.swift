import AppKit
import SwiftUI

/// The output a conversion is asked for, as the reader chooses it.
enum OutputRepresentation: String, CaseIterable, Identifiable, Sendable {
    case rgb = "RGB"
    case hex = "HEX"
    case hsl = "HSL"
    case okLCh = "OkLCh"
    case lab = "CIELAB"
    case lch = "CIE LCh"
    case okLab = "Oklab"
    case displayP3 = "Display P3"
    case linearSRGB = "Linear sRGB"
    case xyzD65 = "XYZ · D65"
    case xyzD50 = "XYZ · D50"

    var id: Self { self }

    static let everyday: [Self] = [.rgb, .hex, .hsl]
    static let perceptual: [Self] = [.okLCh, .lab, .lch, .okLab]
    static let technical: [Self] = [.displayP3, .linearSRGB, .xyzD65, .xyzD50]

    var conversionTarget: ConversionTargetID {
        switch self {
        case .rgb: .rgb
        case .hex: .hexadecimal
        case .hsl: .hsl
        case .okLCh: .okLCh
        case .lab: .labD50
        case .lch: .lchD50
        case .okLab: .okLab
        case .displayP3: .displayP3
        case .linearSRGB: .linearSRGB
        case .xyzD65: .xyzD65
        case .xyzD50: .xyzD50
        }
    }

    var definitionIDs: [String] {
        switch self {
        case .rgb: ["rgb-model", "srgb"]
        case .hex: ["hex-notation", "srgb"]
        case .hsl: ["hsl"]
        case .okLCh, .okLab: ["oklab", "reference-white"]
        case .lab: ["cielab", "reference-white"]
        case .lch: ["cie-lch", "reference-white"]
        case .displayP3: ["display-p3", "gamut"]
        case .linearSRGB: ["encoded-linear"]
        case .xyzD65, .xyzD50: ["cie-xyz", "reference-white"]
        }
    }

    var explanation: String {
        switch self {
        case .rgb:
            "Red, green, and blue are encoded as values from 0 to 255. Together they reproduce this sRGB color."
        case .hex:
            "Each hexadecimal pair stores one sRGB channel. 00 is the minimum and FF is the maximum."
        case .hsl:
            "Hue, saturation, and lightness reorganize encoded sRGB for convenient editing. HSL lightness is not perceptual lightness."
        case .okLCh:
            "OkLCh rearranges Oklab into lightness, chroma, and hue coordinates. These values retain a D65 reference."
        case .lab:
            "L* describes lightness while a* and b* locate the color on two signed axes. These coordinates are relative to D50."
        case .lch:
            "CIE LCh rearranges D50 Lab into lightness, chroma, and hue angle."
        case .okLab:
            "Oklab uses lightness and two signed color axes, calculated here from D65 XYZ."
        case .displayP3:
            "The same intended color is expressed using Display P3 primaries and a D65 reference. Its component numbers differ from sRGB because the primaries differ."
        case .linearSRGB:
            "Linear-light components are proportional to light. They are used for calculation rather than ordinary color entry."
        case .xyzD65:
            "CIE XYZ provides a colorimetric connection space. These coordinates retain the D65 reference used by sRGB."
        case .xyzD50:
            "These XYZ coordinates have been adapted from D65 to D50 before the Lab conversion."
        }
    }

    func serializedValue(for analysis: ColorAnalysis) -> String {
        let alpha = analysis.parsed.color.alpha
        let alphaSuffix = alpha >= 1 ? "" : " / \(Format.decimal(alpha, places: 3))"
        let cieHue = analysis.lchD50.hue.map { Format.decimal($0, places: 2) } ?? "none"
        let okHue = analysis.okLCh.hue.map { Format.decimal($0, places: 2) } ?? "none"

        switch self {
        case .rgb:
            return analysis.parsed.color.cssRGB
        case .hex:
            return analysis.parsed.color.hex
        case .hsl:
            return "hsl(\(Format.decimal(analysis.hsl.hue, places: 1)) \(Format.percent(analysis.hsl.saturation)) \(Format.percent(analysis.hsl.lightness))\(alphaSuffix))"
        case .okLCh:
            return "oklch(\(Format.decimal(analysis.okLCh.lightness, places: 5)) \(Format.decimal(analysis.okLCh.chroma, places: 5)) \(okHue)\(alphaSuffix))"
        case .lab:
            return "lab(\(Format.decimal(analysis.labD50.lightness, places: 2))% \(Format.signed(analysis.labD50.a)) \(Format.signed(analysis.labD50.b))\(alphaSuffix))"
        case .lch:
            return "lch(\(Format.decimal(analysis.lchD50.lightness, places: 2))% \(Format.decimal(analysis.lchD50.chroma, places: 2)) \(cieHue)\(alphaSuffix))"
        case .okLab:
            return "oklab(\(Format.decimal(analysis.okLab.lightness, places: 5)) \(Format.signed(analysis.okLab.a, places: 5)) \(Format.signed(analysis.okLab.b, places: 5))\(alphaSuffix))"
        case .displayP3:
            return analysis.displayP3.css(alpha: alpha)
        case .linearSRGB:
            return "color(srgb-linear \(Format.decimal(analysis.linear.red)) \(Format.decimal(analysis.linear.green)) \(Format.decimal(analysis.linear.blue))\(alphaSuffix))"
        case .xyzD65:
            return "color(xyz-d65 \(Format.decimal(analysis.xyzD65.x)) \(Format.decimal(analysis.xyzD65.y)) \(Format.decimal(analysis.xyzD65.z))\(alphaSuffix))"
        case .xyzD50:
            return "color(xyz-d50 \(Format.decimal(analysis.xyzD50.x)) \(Format.decimal(analysis.xyzD50.y)) \(Format.decimal(analysis.xyzD50.z))\(alphaSuffix))"
        }
    }

    fileprivate func components(for analysis: ColorAnalysis) -> [VisualComponent] {
        let color = analysis.parsed.color
        let components: [VisualComponent]

        switch self {
        case .rgb:
            components = [
                VisualComponent("Red", "\(color.red8)", color.red, "0", "255", role: .red),
                VisualComponent("Green", "\(color.green8)", color.green, "0", "255", role: .green),
                VisualComponent("Blue", "\(color.blue8)", color.blue, "0", "255", role: .blue)
            ]
        case .hex:
            components = [
                VisualComponent("Red", String(format: "%02X", color.red8), color.red, "00", "FF", role: .red),
                VisualComponent("Green", String(format: "%02X", color.green8), color.green, "00", "FF", role: .green),
                VisualComponent("Blue", String(format: "%02X", color.blue8), color.blue, "00", "FF", role: .blue)
            ]
        case .hsl:
            components = [
                VisualComponent("Hue", "\(Format.decimal(analysis.hsl.hue, places: 1))°", analysis.hsl.hue / 360, "0°", "360°", role: .sample),
                VisualComponent("Saturation", Format.percent(analysis.hsl.saturation), analysis.hsl.saturation, "0%", "100%", role: .sample),
                VisualComponent("Lightness", Format.percent(analysis.hsl.lightness), analysis.hsl.lightness, "0%", "100%")
            ]
        case .okLCh:
            components = [
                VisualComponent("Lightness", Format.decimal(analysis.okLCh.lightness, places: 3), analysis.okLCh.lightness, "0", "1"),
                VisualComponent("Chroma", Format.decimal(analysis.okLCh.chroma, places: 3), analysis.okLCh.chroma / 0.4, "0", "0.4", role: .sample),
                hueComponent(analysis.okLCh.hue)
            ]
        case .lab:
            components = [
                VisualComponent("L*", Format.decimal(analysis.labD50.lightness, places: 1), analysis.labD50.lightness / 100, "0", "100"),
                signedComponent("a*", analysis.labD50.a, limit: 125),
                signedComponent("b*", analysis.labD50.b, limit: 125)
            ]
        case .lch:
            components = [
                VisualComponent("L*", Format.decimal(analysis.lchD50.lightness, places: 1), analysis.lchD50.lightness / 100, "0", "100"),
                VisualComponent("C*", Format.decimal(analysis.lchD50.chroma, places: 1), analysis.lchD50.chroma / 150, "0", "150", role: .sample),
                hueComponent(analysis.lchD50.hue)
            ]
        case .okLab:
            components = [
                VisualComponent("L", Format.decimal(analysis.okLab.lightness, places: 3), analysis.okLab.lightness, "0", "1"),
                signedComponent("a", analysis.okLab.a, limit: 0.4),
                signedComponent("b", analysis.okLab.b, limit: 0.4)
            ]
        case .displayP3:
            components = [
                VisualComponent("Red", Format.decimal(analysis.displayP3.red, places: 3), analysis.displayP3.red, "0", "1", role: .red),
                VisualComponent("Green", Format.decimal(analysis.displayP3.green, places: 3), analysis.displayP3.green, "0", "1", role: .green),
                VisualComponent("Blue", Format.decimal(analysis.displayP3.blue, places: 3), analysis.displayP3.blue, "0", "1", role: .blue)
            ]
        case .linearSRGB:
            components = [
                VisualComponent("Red", Format.decimal(analysis.linear.red, places: 3), analysis.linear.red, "0", "1", role: .red),
                VisualComponent("Green", Format.decimal(analysis.linear.green, places: 3), analysis.linear.green, "0", "1", role: .green),
                VisualComponent("Blue", Format.decimal(analysis.linear.blue, places: 3), analysis.linear.blue, "0", "1", role: .blue)
            ]
        case .xyzD65:
            components = xyzComponents(analysis.xyzD65, white: XYZColor(x: 0.95047, y: 1, z: 1.08883))
        case .xyzD50:
            components = xyzComponents(analysis.xyzD50, white: XYZColor(x: 0.96430, y: 1, z: 0.82510))
        }

        guard color.alpha < 1 else { return components }
        return components + [
            VisualComponent("Alpha", Format.percent(color.alpha), color.alpha, "0%", "100%")
        ]
    }

    private func hueComponent(_ hue: Double?) -> VisualComponent {
        guard let hue else {
            return VisualComponent("Hue", "Undefined", nil, "0°", "360°", role: .sample)
        }
        return VisualComponent("Hue", "\(Format.decimal(hue, places: 1))°", hue / 360, "0°", "360°", role: .sample)
    }

    private func signedComponent(_ label: String, _ value: Double, limit: Double) -> VisualComponent {
        VisualComponent(
            label,
            Format.signed(value, places: limit > 1 ? 1 : 3),
            (value + limit) / (2 * limit),
            Format.signed(-limit, places: limit > 1 ? 0 : 1),
            Format.signed(limit, places: limit > 1 ? 0 : 1),
            centered: true,
            role: .sample
        )
    }

    private func xyzComponents(_ xyz: XYZColor, white: XYZColor) -> [VisualComponent] {
        [
            VisualComponent("X", Format.decimal(xyz.x, places: 4), xyz.x / white.x, "0", "white"),
            VisualComponent("Y", Format.decimal(xyz.y, places: 4), xyz.y / white.y, "0", "white"),
            VisualComponent("Z", Format.decimal(xyz.z, places: 4), xyz.z / white.z, "0", "white")
        ]
    }
}

/// What a component bar is tinted by, so a red channel reads as red and a
/// neutral coordinate does not pick up a misleading hue.
private enum ComponentColorRole {
    case red
    case green
    case blue
    case neutral
    case sample
}

/// One coordinate ready to be drawn on a track.
///
/// `centered` exists because Lab's a and b axes run through zero, so their
/// track has to be marked from the middle rather than from the left.
private struct VisualComponent: Identifiable {
    let label: String
    let displayValue: String
    let normalizedPosition: Double?
    let minimumLabel: String
    let maximumLabel: String
    let centered: Bool
    let role: ComponentColorRole

    var id: String { label }

    init(
        _ label: String,
        _ displayValue: String,
        _ normalizedPosition: Double?,
        _ minimumLabel: String,
        _ maximumLabel: String,
        centered: Bool = false,
        role: ComponentColorRole = .neutral
    ) {
        self.label = label
        self.displayValue = displayValue
        self.normalizedPosition = normalizedPosition
        self.minimumLabel = minimumLabel
        self.maximumLabel = maximumLabel
        self.centered = centered
        self.role = role
    }
}

/// The Convert workspace, holding the input, the output, and the route
/// between them.
struct ConvertView: View {
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var representation: OutputRepresentation = .rgb
    @State private var selectedStageIndex = 0
    @State private var codeLanguage: CodeExportLanguage = .css
    @Environment(\.appSemanticPalette) private var semanticPalette

    init(
        model: AppModel,
        initialRepresentation: OutputRepresentation? = nil,
        initialStageIndex: Int? = nil
    ) {
        self.model = model
        let restoredRepresentation = OutputRepresentation(
            rawValue: model.workspaceSession.convertRepresentationRawValue
        ) ?? .rgb
        _representation = State(initialValue: initialRepresentation ?? restoredRepresentation)
        _selectedStageIndex = State(
            initialValue: max(initialStageIndex ?? model.workspaceSession.convertStageIndex, 0)
        )
        _codeLanguage = State(
            initialValue: CodeExportLanguage(
                rawValue: model.workspaceSession.convertCodeLanguageRawValue
            ) ?? .css
        )
    }

    var body: some View {
        WorkspaceCanvas(section: .convert) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.section) {
                    header
                    colorWorkspace
                    calculationRouteSection
                }
                .frame(maxWidth: 1_120, alignment: .leading)
                .padding(AppMetrics.page)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Convert")
        .textSelection(.enabled)
        .onChange(of: representation) { _, _ in
            selectedStageIndex = 0
            model.updateWorkspaceSession { session in
                session.convertRepresentationRawValue = representation.rawValue
                session.convertStageIndex = 0
            }
        }
        .onChange(of: selectedStageIndex) { _, index in
            model.updateWorkspaceSession { $0.convertStageIndex = max(index, 0) }
        }
        .onChange(of: codeLanguage) { _, language in
            model.updateWorkspaceSession { $0.convertCodeLanguageRawValue = language.rawValue }
        }
    }

    private var header: some View {
        WorkspaceHeader(section: .convert)
    }

    private var colorWorkspace: some View {
        AdaptivePairLayout(
            horizontalThreshold: textScale >= 1.3 ? 1_000 : 780,
            leadingFraction: 0.40
        ) {
            sourceEditor
            representationResult
        }
    }

    private var sourceEditor: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                HStack(alignment: .firstTextBaseline) {
                    PanelHeading(title: "Choose a color")

                    Spacer()

                    Button {
                        model.addCurrentColorToTray(conversionTarget: representation.conversionTarget)
                    } label: {
                        Label("Save to Tray", systemImage: "tray.and.arrow.down")
                    }
                    .appFont(.body)
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AppMetrics.regular) {
                        sourceSwatch
                        sourceControls
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        sourceSwatch
                        sourceControls
                    }
                }
            }
        }
    }

    private var sourceSwatch: some View {
        ColorSwatchView(color: model.analysis.parsed.color, showsLabel: false)
            .frame(width: 96, height: 96)
    }

    private var sourceControls: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text("Color value")
                .appFont(.headline)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppMetrics.snug) {
                    sourceTextField
                    sourceColorPicker
                }

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    sourceTextField
                    sourceColorPicker
                }
            }

            inputStatus
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sourceTextField: some View {
                TextField(
                    "HEX or RGB",
                    text: Binding(
                        get: { model.colorInput },
                        set: { model.updateRepresentation($0) }
                    )
                )
                .appFont(.value)
                .monospacedDigit()
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("HEX or RGB color value")
                .accessibilityValue(model.inputError == nil ? "Valid value" : "Invalid value")
                .accessibilityHint(
                    model.inputError
                        ?? "Enter a HEX or RGB color. The representation updates as the value becomes valid."
                )
    }

    private var sourceColorPicker: some View {
        ColorPicker(
            "Choose color",
            selection: Binding(
                get: { model.analysis.parsed.color.swiftUIColor },
                set: { model.updateFromColorPicker($0) }
            ),
            supportsOpacity: true
        )
        .appFont(.body)
    }

    @ViewBuilder
    private var inputStatus: some View {
        if let error = model.inputError {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .appFont(.callout)
                .foregroundStyle(semanticPalette.warning)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Input error")
                .accessibilityValue(error)
        } else {
            HStack(spacing: AppMetrics.tight) {
                Text("Recognized as \(model.analysis.parsed.notationID.rawValue), sRGB")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                TermHelpButton(conceptID: "srgb", showsTerm: false)
            }
        }
    }

    private var representationResult: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                HStack(alignment: .firstTextBaseline) {
                    PanelHeading(title: "Representation")

                    Spacer()

                    Picker("Representation", selection: $representation) {
                        Section("Everyday") {
                            ForEach(OutputRepresentation.everyday) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        Section("Perceptual") {
                            ForEach(OutputRepresentation.perceptual) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        Section("Technical") {
                            ForEach(OutputRepresentation.technical) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .appFont(.body)
                }

                HStack(alignment: .top, spacing: AppMetrics.compact) {
                    Text(representation.serializedValue(for: model.analysis))
                        .appFont(.title2)
                        .monospacedDigit()
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    CopyValueButton(
                        value: representation.serializedValue(for: model.analysis),
                        description: representation.rawValue
                    )
                }

                Text(representation.explanation)
                    .appFont(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                TermHelpRow(conceptIDs: representation.definitionIDs)

                ComponentPositionGraphic(
                    components: representation.components(for: model.analysis),
                    sampleColor: model.analysis.parsed.color
                )

                CodeExportDisclosure(
                    title: "Use this color in code",
                    supportingText: "CSS keeps the selected \(representation.rawValue) value. Other languages use explicit sRGB components.",
                    language: $codeLanguage
                ) { language in
                    ColorCodeExporter.colorSnippet(
                        color: model.analysis.parsed.color,
                        cssValue: representation.serializedValue(for: model.analysis),
                        language: language
                    )
                }
            }
        }
    }

    private var calculationRouteSection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            PanelHeading(
                title: "Understand the conversion",
                summary: "Select a stage to see its meaning, its calculation, and its sources."
            )

            conversionRoute
        }
    }

    private var conversionRoute: some View {
        let stages = model.analysis.stages(for: representation.conversionTarget)
        let safeIndex = min(selectedStageIndex, max(stages.count - 1, 0))

        return AppCard(padding: AppMetrics.regular) {
            AdaptivePairLayout(
                horizontalThreshold: textScale >= 1.3 ? 1_120 : 860,
                leadingFraction: 0.28,
                spacing: AppMetrics.roomy
            ) {
                ConversionMapView(
                    stages: stages,
                    selectedStageIndex: Binding(
                        get: { safeIndex },
                        set: { selectedStageIndex = $0 }
                    )
                )

                VStack(alignment: .leading, spacing: AppMetrics.regular) {
                    ConversionStageView(
                        stage: stages[safeIndex],
                        initialPage: ConversionStagePage(
                            rawValue: model.workspaceSession.convertStagePageRawValue
                        ) ?? .meaning,
                        onPageChange: { page in
                            model.updateWorkspaceSession {
                                $0.convertStagePageRawValue = page.rawValue
                            }
                        }
                    )
                        .id(stages[safeIndex].id)

                    Divider()

                    StepNavigationBar(
                        currentIndex: safeIndex,
                        total: stages.count,
                        previous: { selectedStageIndex = max(safeIndex - 1, 0) },
                        next: {
                            selectedStageIndex = safeIndex == stages.count - 1 ? 0 : safeIndex + 1
                        }
                    )
                }
            }
        }
    }
}

/// Previous and next controls for stepping through the route.
private struct StepNavigationBar: View {
    let currentIndex: Int
    let total: Int
    let previous: () -> Void
    let next: () -> Void

    var body: some View {
        HStack(spacing: AppMetrics.regular) {
            Button("Previous", systemImage: "chevron.left", action: previous)
                .disabled(currentIndex == 0)
                .frame(minWidth: 120, alignment: .leading)
                .appFont(.body)

            Spacer()

            Text("Stage \(currentIndex + 1) of \(total)")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel("Stage \(currentIndex + 1) of \(total)")

            Spacer()

            Button(
                currentIndex == total - 1 ? "Start over" : "Next",
                systemImage: currentIndex == total - 1 ? "arrow.counterclockwise" : "chevron.right",
                action: next
            )
            .buttonStyle(.borderedProminent)
            .frame(minWidth: 120, alignment: .trailing)
            .appFont(.body)
        }
        .frame(minHeight: 42)
    }
}

/// The route as a list of stages, all of them directly reachable.
///
/// One stage is expanded at a time, but none is behind the others, so nothing
/// requires stepping through material the reader does not want.
private struct ConversionMapView: View {
    let stages: [ConversionStage]
    @Binding var selectedStageIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            VStack(alignment: .leading, spacing: AppMetrics.tight) {
                Text("Path map")
                    .appFont(.headline)
                Text("Choose any stage")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: AppMetrics.snug) {
                ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                    ConversionMapButton(
                        stage: stage,
                        index: index,
                        isSelected: index == selectedStageIndex
                    ) {
                        selectedStageIndex = index
                    }
                }
            }
            .accessibilityLabel("Conversion stages")
        }
        .padding(AppMetrics.compact)
        .appSubtleSurface(cornerRadius: 14)
    }

}

/// One stage in the route map, numbered and showing selection state.
private struct ConversionMapButton: View {
    @Environment(\.appSemanticPalette) private var palette
    let stage: ConversionStage
    let index: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppMetrics.snug) {
                IndexedSelectionBadge(index: index + 1, isSelected: isSelected)
                Text(stage.navigationTitle)
                    .appFont(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Image(systemName: stage.symbolName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? palette.accent : Color.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, AppMetrics.compact)
            .padding(.vertical, AppMetrics.snug)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 54, alignment: .leading)
            .background(SelectableCardChrome(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .help(stage.title)
        .accessibilityLabel("Step \(index + 1), \(stage.title)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

/// Every coordinate of the current stage drawn on its own track.
private struct ComponentPositionGraphic: View {
    let components: [VisualComponent]
    let sampleColor: SRGBColor

    var body: some View {
        VStack(spacing: AppMetrics.compact) {
            ForEach(components) { component in
                ComponentPositionRow(
                    component: component,
                    tint: tint(for: component.role)
                )
            }
        }
        .padding(.top, AppMetrics.hairline)
    }

    private func tint(for role: ComponentColorRole) -> Color {
        switch role {
        case .red: .red
        case .green: .green
        case .blue: .blue
        case .neutral: .primary
        case .sample: sampleColor.swiftUIColor
        }
    }
}

/// One coordinate on a track, labeled with its range at both ends.
private struct ComponentPositionRow: View {
    let component: VisualComponent
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: AppMetrics.compact) {
            Text(component.label)
                .appFont(.headline)
                .frame(width: 78, alignment: .leading)

            VStack(spacing: AppMetrics.hairline) {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let position = width * min(max(component.normalizedPosition ?? 0, 0), 1)

                    ZStack(alignment: .leading) {
                        Capsule().fill(.quaternary)

                        if let normalizedPosition = component.normalizedPosition {
                            if component.centered {
                                let center = width / 2
                                Capsule()
                                    .fill(tint.opacity(0.78))
                                    .frame(width: max(3, abs(position - center)))
                                    .offset(x: min(position, center))
                                Rectangle()
                                    .fill(.secondary)
                                    .frame(width: 1, height: 14)
                                    .offset(x: center)
                            } else {
                                Capsule()
                                    .fill(tint.opacity(0.78))
                                    .frame(width: max(3, width * min(max(normalizedPosition, 0), 1)))
                            }
                        }
                    }
                }
                .frame(height: 9)

                HStack {
                    Text(component.minimumLabel)
                    Spacer()
                    Text(component.maximumLabel)
                }
                .appFont(.caption)
                .foregroundStyle(.secondary)
            }

            Text(component.displayValue)
                .appFont(.value)
                .monospacedDigit()
                .frame(width: 92, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(component.label)
        .accessibilityValue("\(component.displayValue), range \(component.minimumLabel) to \(component.maximumLabel)")
    }
}

/// One stage of a conversion, with its meaning, its calculation, and its
/// sources.
struct ConversionStageView: View {
    let stage: ConversionStage
    @Environment(\.appTextScale) private var textScale
    @State private var selectedPage: ConversionStagePage
    private let onPageChange: (ConversionStagePage) -> Void

    init(
        stage: ConversionStage,
        initialPage: ConversionStagePage = .meaning,
        onPageChange: @escaping (ConversionStagePage) -> Void = { _ in }
    ) {
        self.stage = stage
        self.onPageChange = onPageChange
        _selectedPage = State(initialValue: initialPage)
    }

    private var evidence: [EvidenceRecord] {
        stage.evidenceIDs.compactMap(EvidenceRegistry.record(withID:))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                Label("Selected stage", systemImage: stage.symbolName)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)

                Text(stage.title)
                    .appFont(.title)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)

                HStack(alignment: .top, spacing: AppMetrics.compact) {
                    Text("Result")
                        .appFont(.headline)
                    Text(stage.value)
                        .appFont(.value)
                        .monospacedDigit()
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppMetrics.compact)
                .appSubtleSurface(cornerRadius: 10)
            }

            pagePicker

            Group {
                switch selectedPage {
                case .meaning:
                    meaningPage
                case .calculation:
                    calculationPage
                case .sources:
                    sourcesPage
                }
            }
        }
        .onChange(of: selectedPage) { _, page in
            onPageChange(page)
        }
    }

    private var pagePicker: some View {
        ViewThatFits(in: .horizontal) {
            Picker("Stage information", selection: $selectedPage) {
                ForEach(ConversionStagePage.allCases) { page in
                    Label(page.title, systemImage: page.symbolName).tag(page)
                }
            }
            .pickerStyle(.segmented)

            Picker("Stage information", selection: $selectedPage) {
                ForEach(ConversionStagePage.allCases) { page in
                    Label(page.title, systemImage: page.symbolName).tag(page)
                }
            }
            .pickerStyle(.menu)
        }
        .appFont(.body)
    }

    private var meaningPage: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            AdaptivePairLayout(
                horizontalThreshold: textScale >= 1.3 ? 1_000 : 720,
                leadingFraction: 0.5,
                spacing: AppMetrics.compact
            ) {
                explanationPanel(
                    title: "What changes",
                    text: stage.whatChanges,
                    symbol: "arrow.triangle.2.circlepath"
                )
                explanationPanel(
                    title: "Why this step exists",
                    text: stage.whyItMatters,
                    symbol: "questionmark.circle"
                )
            }
            TermHelpRow(conceptIDs: stage.definitionIDs)
        }
    }

    @ViewBuilder
    private var calculationPage: some View {
        if let equation = stage.equationLaTeX,
           let equationLabel = stage.equationAccessibilityLabel {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                HStack(alignment: .firstTextBaseline) {
                    Text("General rule")
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    Spacer()
                    CopyValueButton(
                        value: equation,
                        description: "general equation as LaTeX",
                        label: "Copy LaTeX"
                    )
                }

                MathEquationView(
                    latex: equation,
                    accessibilityLabel: equationLabel,
                    baseFontSize: 23,
                    textAlignment: .center
                )

                VStack(alignment: .leading, spacing: AppMetrics.tight) {
                    Text("In words")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                    Text(equationLabel)
                        .appFont(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let substitution = stage.substitutionLaTeX,
                   let substitutionLabel = stage.substitutionAccessibilityLabel {
                    Divider()
                    HStack(alignment: .firstTextBaseline) {
                        Text("For this color")
                            .appFont(.headline)
                        Spacer()
                        CopyValueButton(
                            value: substitution,
                            description: "applied equation as LaTeX",
                            label: "Copy LaTeX"
                        )
                    }
                    MathEquationView(
                        latex: substitution,
                        accessibilityLabel: substitutionLabel,
                        baseFontSize: 20,
                        labelMode: .text,
                        textAlignment: .center
                    )
                    Text(substitutionLabel)
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppMetrics.regular)
            .appSubtleSurface(cornerRadius: 10)
        } else {
            Label(
                "This stage interprets or organizes the value without adding a separate numerical equation.",
                systemImage: "text.alignleft"
            )
            .appFont(.body)
            .padding(AppMetrics.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSubtleSurface(cornerRadius: 10)
        }
    }

    private var sourcesPage: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            if evidence.isEmpty {
                Label(
                    "No separate source is attached to this organizational stage.",
                    systemImage: "info.circle"
                )
                .appFont(.body)
            } else {
                ForEach(evidence) { record in
                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        evidenceLink(record)
                            .appFont(.body)
                        Text("\(record.category.rawValue) · \(record.version)")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                        Text(record.limitation)
                            .appFont(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppMetrics.compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appSubtleSurface(cornerRadius: 10)
                }
            }
        }
    }

    private func evidenceLink(_ record: EvidenceRecord) -> some View {
        Link(destination: record.sourceURL) {
            Label(record.title, systemImage: "arrow.up.right")
                .labelStyle(.titleAndIcon)
        }
        .appFont(.body)
    }

    private func explanationPanel(title: String, text: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Label(title, systemImage: symbol)
                .appFont(.headline)
            Text(text)
                .appFont(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.regular)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .appSubtleSurface(cornerRadius: 10)
    }
}

/// The three views of a single conversion stage.
enum ConversionStagePage: String, CaseIterable, Identifiable, Sendable {
    case meaning
    case calculation
    case sources

    var id: Self { self }

    var title: String {
        switch self {
        case .meaning: "Meaning"
        case .calculation: "Calculation"
        case .sources: "Sources"
        }
    }

    var symbolName: String {
        switch self {
        case .meaning: "lightbulb"
        case .calculation: "function"
        case .sources: "books.vertical"
        }
    }
}
