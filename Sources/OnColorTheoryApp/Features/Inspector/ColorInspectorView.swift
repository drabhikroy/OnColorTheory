import SwiftUI

/// The inspector window, holding values, measurements, and context for the
/// working color, plus the screen sampler.
struct ColorInspectorView: View {
    @ObservedObject var model: AppModel
    @StateObject private var screenSampler = ScreenColorSampler()
    @State private var selectedPage: InspectorPage

    init(model: AppModel, initialPage: InspectorPage = .values) {
        self.model = model
        _selectedPage = State(initialValue: initialPage)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                inspectorHeader
                samplePanel
                informationPanel
                actions
            }
            .padding(AppMetrics.regular)
        }
        .accessibilityLabel("Color Inspector")
        .textSelection(.enabled)
    }

    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Label("Color Inspector", systemImage: "eyedropper")
                .appFont(.title2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)
            Text("Inspect one working color without leaving your current workspace.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var samplePanel: some View {
        AppCard(padding: AppMetrics.compact) {
            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                ColorSwatchView(color: model.analysis.parsed.color, showsLabel: false)
                    .frame(height: 112)

                Button {
                    selectedPage = .values
                    screenSampler.sample { color in
                        model.setWorkingColor(color)
                        AccessibilityAnnouncer.announce("Sampled \(color.hex) from the screen")
                    }
                } label: {
                    Label(
                        screenSampler.isSampling ? "Choose a pixel…" : "Sample Anywhere on Screen",
                        systemImage: "eyedropper.halffull"
                    )
                    .frame(maxWidth: .infinity)
                }
                .appFont(.body)
                .buttonStyle(.borderedProminent)
                .disabled(screenSampler.isSampling)
                .accessibilityHint("Choose a color from this app, another app, or another display.")

                Text(
                    screenSampler.isSampling
                        ? "Select a pixel anywhere on your displays, or press Escape to cancel."
                        : "Pick a pixel inside or outside On Color Theory. Its Hex, RGB, and Alpha values update below."
                )
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var informationPanel: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Picker("Inspector information", selection: $selectedPage) {
                ForEach(InspectorPage.allCases) { page in
                    Label(page.title, systemImage: page.symbolName).tag(page)
                }
            }
            .pickerStyle(.segmented)
            .appFont(.body)

            AppCard(padding: AppMetrics.compact) {
                switch selectedPage {
                case .values:
                    InspectorValueGrid(color: model.analysis.parsed.color)
                case .measurements:
                    AlignedValueGrid(
                        rows: [
                            AlignedValueRowData(
                            label: "Relative luminance",
                            value: Format.decimal(model.analysis.relativeLuminance),
                            definitionID: "relative-luminance"
                            ),
                            AlignedValueRowData(
                            label: "CIELAB (D50)",
                            value: "\(Format.decimal(model.analysis.labD50.lightness, places: 1)), \(Format.signed(model.analysis.labD50.a, places: 1)), \(Format.signed(model.analysis.labD50.b, places: 1))",
                            definitionID: "cielab"
                            ),
                            AlignedValueRowData(
                            label: "OkLCh (D65)",
                            value: "\(Format.decimal(model.analysis.okLCh.lightness, places: 3)), \(Format.decimal(model.analysis.okLCh.chroma, places: 3)), \(Format.hue(model.analysis.okLCh.hue, places: 1))",
                            definitionID: "oklab"
                            )
                        ],
                        labelWidth: 126
                    )
                case .context:
                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        AlignedValueGrid(
                            rows: [
                                AlignedValueRowData(label: "Notation", value: model.analysis.parsed.notation),
                                AlignedValueRowData(label: "Color space", value: model.analysis.parsed.colorSpace.rawValue),
                                AlignedValueRowData(label: "Source white", value: "D65"),
                                AlignedValueRowData(label: "Lab adaptation", value: "Bradford D65 → D50")
                            ],
                            labelWidth: 96
                        )

                        Text("These labels keep the numbers attached to the assumptions that give them meaning.")
                            .appFont(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, AppMetrics.tight)

                        TermHelpRow(conceptIDs: ["reference-white", "chromatic-adaptation"])
                    }
                }
            }
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Button {
                model.addCurrentColorToTray()
            } label: {
                Label("Save to Color Tray", systemImage: "tray.and.arrow.down")
            }
            .appFont(.body)
            .buttonStyle(.bordered)

            SettingsLink {
                Label("Appearance & color-vision options", systemImage: "accessibility")
            }
            .appFont(.callout)
            .help("Choose Light, Dark, text size, and color-vision-aware interface cues")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The working color in every notation, aligned in one column so the values
/// can be read down rather than hunted for.
private struct InspectorValueGrid: View {
    let color: SRGBColor

    var body: some View {
        AlignedValueGrid(
            rows: [
                AlignedValueRowData(label: "Hex", value: color.hex, definitionID: "hex-notation"),
                AlignedValueRowData(
                    label: "RGB",
                    value: "\(color.red8), \(color.green8), \(color.blue8)",
                    definitionID: "rgb-model"
                ),
                AlignedValueRowData(
                    label: "Alpha",
                    value: "\(Format.percent(color.alpha)) (\(color.alpha8))",
                    definitionID: "alpha"
                )
            ],
            labelWidth: 50
        )
    }
}

/// The three inspector pages.
enum InspectorPage: String, CaseIterable, Identifiable {
    case values
    case measurements
    case context

    var id: Self { self }

    var title: String {
        switch self {
        case .values: "Values"
        case .measurements: "Measures"
        case .context: "Context"
        }
    }

    var symbolName: String {
        switch self {
        case .values: "number"
        case .measurements: "ruler"
        case .context: "info.circle"
        }
    }
}
