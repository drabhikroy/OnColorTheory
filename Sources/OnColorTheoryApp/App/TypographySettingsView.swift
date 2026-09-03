import SwiftUI

/// The Settings window, holding appearance, text size, the font choice, the
/// color vision palette, and the model connection.
struct TypographySettingsView: View {
    @ObservedObject private var ollama: OllamaController
    @AppStorage(AppPreferenceKeys.textScale) private var textScale = 1.0
    @AppStorage(AppPreferenceKeys.useSystemFont) private var useSystemFont = false
    @AppStorage(AppPreferenceKeys.appearance) private var appearanceRawValue = AppAppearanceMode.dark.rawValue
    @AppStorage(AppPreferenceKeys.colorVisionPalette) private var paletteRawValue = AppColorVisionPalette.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    init(model: AppModel) {
        _ollama = ObservedObject(wrappedValue: model.ollama)
    }

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("App appearance", selection: $appearanceRawValue) {
                    ForEach(AppAppearanceMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.symbolName)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Text("Follow Mac updates with the system. Light and Dark keep this app in the selected appearance.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Reading") {
                Toggle("Use macOS system font", isOn: $useSystemFont)
                LabeledContent("Text size") {
                    HStack {
                        Slider(value: $textScale, in: 1.0...1.6, step: 0.1)
                            .frame(width: 210)
                        Text("\(Int((textScale * 100).rounded()))%")
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                Text("Atkinson Hyperlegible Next is the default. The system-font option respects readers who find another typeface more comfortable.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("Preview")
                        .appFont(.headline)
                    Text("Color is more than what we see.")
                        .appFont(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("O 0   I l 1   B 8   p q")
                        .appFont(.value)
                        .monospacedDigit()
                }
                .padding(.vertical, AppMetrics.tight)
            }

            Section("Color-vision accessibility") {
                Picker("Interface cue palette", selection: $paletteRawValue) {
                    ForEach(AppColorVisionPalette.allCases) { palette in
                        Text(palette.title).tag(palette.rawValue)
                    }
                }

                AppPalettePreview(palette: selectedPalette.resolved(for: colorScheme))

                Text(selectedPalette.explanation)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(
                    "These presets change the app’s structural and status cues only. They do not alter analyzed colors, simulate one person’s vision, or by themselves establish accessibility.",
                    systemImage: "info.circle"
                )
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            OllamaSettingsSection(controller: ollama)

            Section("About") {
                LabeledContent("On Color Theory", value: AppVersionInfo.display)
                LabeledContent("Author", value: AppVersionInfo.attribution)
                Link(destination: AppVersionInfo.licenseURL) {
                    LabeledContent("License", value: AppVersionInfo.license)
                }
                Text("Build numbers make installed releases and support screenshots easy to identify.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

        }
        .formStyle(.grouped)
        .padding()
        .controlSize(.large)
        .environment(\.appTextScale, textScale)
        .environment(\.useSystemFont, useSystemFont)
        .appInterfaceTheme(selectedPalette)
        .syncApplicationAppearance(selectedAppearance)
        .textSelection(.enabled)
        .task {
            if ollama.isEnabled, ollama.connectionState == .idle {
                await ollama.refresh()
            }
        }
    }

    private var selectedAppearance: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceRawValue) ?? .dark
    }

    private var selectedPalette: AppColorVisionPalette {
        AppColorVisionPalette(rawValue: paletteRawValue) ?? .system
    }
}

/// The model connection settings, with a route into the full setup.
private struct OllamaSettingsSection: View {
    @ObservedObject var controller: OllamaController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Section("Model-assisted recommendations") {
            Toggle("Turn on Ollama suggestions", isOn: $controller.isEnabled)
                .onChange(of: controller.isEnabled) { _, enabled in
                    guard enabled else { return }
                    Task { await controller.refresh() }
                }

            Text("Ollama can suggest palette roles and explain each choice in plain language. On Color Theory still calculates every contrast result and scientific measurement itself.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if controller.isEnabled, !controller.selectedModel.isEmpty {
                Label(
                    "Ready to use \(controller.selectedModel) in Build → Recommend",
                    systemImage: "checkmark.circle.fill"
                )
            } else {
                Label("Optional setup is incomplete", systemImage: "circle.dotted")
                    .foregroundStyle(.secondary)
            }

            Button {
                openWindow(id: AppWindowID.ollamaSetup)
            } label: {
                Label("Open step-by-step setup", systemImage: "wand.and.stars")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

/// The four semantic cues of the selected palette, each shown as a labeled
/// symbol as well as a color, so the preview demonstrates the redundancy it is
/// describing.
private struct AppPalettePreview: View {
    let palette: AppSemanticPalette

    var body: some View {
        HStack(spacing: AppMetrics.compact) {
            cue("Accent", color: palette.accent, symbol: "arrow.right.circle.fill")
            cue("Positive", color: palette.positive, symbol: "checkmark.circle.fill")
            cue("Caution", color: palette.warning, symbol: "exclamationmark.triangle.fill")
            cue("Critical", color: palette.critical, symbol: "xmark.octagon.fill")
        }
        .padding(.vertical, AppMetrics.tight)
        .accessibilityElement(children: .contain)
    }

    private func cue(_ title: String, color: Color, symbol: String) -> some View {
        VStack(spacing: AppMetrics.tight) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .appFont(.caption)
        }
        .frame(maxWidth: .infinity)
    }
}
