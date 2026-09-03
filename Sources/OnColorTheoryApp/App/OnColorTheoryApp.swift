import AppKit
import SwiftUI

/// Window identifiers, named here so opening and dismissing a window cannot
/// drift apart over a typo.
enum AppWindowID {
    static let main = "main"
    static let inspector = "color-inspector"
    static let tray = "color-tray"
    static let ollamaSetup = "ollama-setup"
    static let help = "help"
    static let walkthrough = "walkthrough"
    static let definition = "definition"
    static let about = "about"

    static let singleInstanceIDs = [
        main, inspector, tray, ollamaSetup, help, walkthrough, definition, about
    ]
}

@main
/// The application entry point.
///
/// Appearance is applied and fonts are registered in the initializer rather
/// than on first appearance, so the first frame is already correct.
struct OnColorTheoryApp: App {
    @StateObject private var model: AppModel
    @StateObject private var definitionSelection: DefinitionWindowSelection

    init() {
        ApplicationDefaults.register()
        let savedAppearance = UserDefaults.standard.string(forKey: AppPreferenceKeys.appearance)
            .flatMap(AppAppearanceMode.init(rawValue:)) ?? .dark
        savedAppearance.applyToApplication()
        FontRegistrar.registerBundledFonts()
        _model = StateObject(wrappedValue: AppModel())
        _definitionSelection = StateObject(wrappedValue: DefinitionWindowSelection.shared)
    }

    var body: some Scene {
        Window("On Color Theory", id: AppWindowID.main) {
            AppShellView(model: model)
                .frame(minWidth: 920, minHeight: 650)
                .restoreWindowGeometry("main")
        }
        .defaultSize(width: 1160, height: 760)
        .commands {
            AppTextEditingCommands()
            ColorCommands(model: model)
        }

        Window("Color Inspector", id: AppWindowID.inspector) {
            AppEnvironmentHost {
                ColorInspectorView(model: model)
                    .frame(minWidth: 320, minHeight: 480)
                    .restoreWindowGeometry(AppWindowID.inspector)
                    .onDisappear { model.isInspectorPresented = false }
            }
        }
        .defaultSize(width: 390, height: 720)
        .windowResizability(.contentMinSize)
        .commands { AppTextEditingCommands() }

        Window("On Color Theory Walkthrough", id: AppWindowID.walkthrough) {
            AppEnvironmentHost {
                WalkthroughView(model: model)
                    .frame(minWidth: 650, minHeight: 540)
                    .restoreWindowGeometry(AppWindowID.walkthrough)
            }
        }
        .defaultSize(width: 780, height: 680)
        .windowResizability(.contentMinSize)
        .commands { AppTextEditingCommands() }

        Window("Color Tray", id: AppWindowID.tray) {
            AppEnvironmentHost {
                ColorTrayView(model: model, store: model.tray)
                    .frame(minWidth: 330, minHeight: 330)
                    .restoreWindowGeometry(AppWindowID.tray)
                    .onDisappear { model.isTrayPresented = false }
            }
        }
        .defaultSize(width: 420, height: 520)
        .windowResizability(.contentMinSize)
        .commands { AppTextEditingCommands() }

        Window("Model Assist Setup", id: AppWindowID.ollamaSetup) {
            AppEnvironmentHost {
                OllamaSetupView(model: model, controller: model.ollama)
                    .frame(minWidth: 660, minHeight: 520)
                    .restoreWindowGeometry(AppWindowID.ollamaSetup)
            }
        }
        .defaultSize(width: 820, height: 680)
        .windowResizability(.contentMinSize)
        .commands { AppTextEditingCommands() }

        Window("On Color Theory Help", id: AppWindowID.help) {
            AppEnvironmentHost {
                HelpView(model: model)
                    .frame(minWidth: 680, minHeight: 520)
                    .restoreWindowGeometry(AppWindowID.help)
            }
        }
        .defaultSize(width: 940, height: 720)
        .windowResizability(.contentMinSize)
        .commands { AppTextEditingCommands() }

        Window("Definition", id: AppWindowID.definition) {
            AppEnvironmentHost {
                TermDefinitionWindow(conceptID: definitionSelection.conceptID)
                    .frame(minWidth: 340, minHeight: 240)
                    .restoreWindowGeometry(AppWindowID.definition)
            }
        }
        .defaultSize(width: 430, height: 360)
        .windowResizability(.contentMinSize)
        .commands { AppTextEditingCommands() }

        Window("About On Color Theory", id: AppWindowID.about) {
            AppEnvironmentHost {
                AboutView()
                    .frame(minWidth: 420, minHeight: 400)
                    .restoreWindowGeometry(AppWindowID.about)
            }
        }
        .defaultSize(width: 480, height: 460)
        .windowResizability(.contentMinSize)
        .commands { AppTextEditingCommands() }

        Settings {
            TypographySettingsView(model: model)
                .frame(minWidth: 520, minHeight: 500)
                .restoreWindowGeometry("settings")
        }
        .defaultSize(width: 600, height: 720)
        .windowResizability(.contentMinSize)
        .commands { AppTextEditingCommands() }
    }
}

/// Cut, copy, and paste, supplied explicitly because several windows host
/// text fields outside the responder chain that would otherwise carry them.
struct AppTextEditingCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .pasteboard) {
            Button("Cut") { AppTextEditingAction.cut.send() }
                .keyboardShortcut("x", modifiers: .command)
            Button("Copy") { AppTextEditingAction.copy.send() }
                .keyboardShortcut("c", modifiers: .command)
            Button("Paste") { AppTextEditingAction.paste.send() }
                .keyboardShortcut("v", modifiers: .command)
            Button("Paste and Match Style") { AppTextEditingAction.pasteAsPlainText.send() }
                .keyboardShortcut("v", modifiers: [.command, .option, .shift])

            Divider()

            Button("Delete") { AppTextEditingAction.delete.send() }
            Button("Select All") { AppTextEditingAction.selectAll.send() }
                .keyboardShortcut("a", modifiers: .command)
        }
    }
}

/// The app's own menu commands, including the workspace shortcuts and the
/// panel toggles.
struct ColorCommands: Commands {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some Commands {
        CommandMenu("Navigate") {
            Button("Home") { navigate(to: .home) }
                .keyboardShortcut("1", modifiers: .command)
            Button("Learn") { navigate(to: .learn) }
                .keyboardShortcut("2", modifiers: .command)
            Button("Explore") { navigate(to: .explore) }
                .keyboardShortcut("3", modifiers: .command)
            Button("Convert") { navigate(to: .convert) }
                .keyboardShortcut("4", modifiers: .command)
            Button("Build") { navigate(to: .build) }
                .keyboardShortcut("5", modifiers: .command)
            Button("Check") { navigate(to: .check) }
                .keyboardShortcut("6", modifiers: .command)
            Button("Reference") { navigate(to: .reference) }
                .keyboardShortcut("7", modifiers: .command)

            Divider()

            Button("Continue Saved Workspace") {
                navigate(to: model.resumableSection ?? .home)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(model.resumableSection == nil)
        }

        CommandMenu("Color") {
            Button("Add Current Color to Tray") {
                model.addCurrentColorToTray()
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])

            Button(model.isTrayPresented ? "Hide Color Tray" : "Show Color Tray") {
                if model.isTrayPresented {
                    dismissWindow(id: AppWindowID.tray)
                    model.isTrayPresented = false
                } else {
                    model.isTrayPresented = true
                    openWindow(id: AppWindowID.tray)
                }
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Button(model.isInspectorPresented ? "Hide Color Inspector" : "Show Color Inspector") {
                if model.isInspectorPresented {
                    dismissWindow(id: AppWindowID.inspector)
                    model.isInspectorPresented = false
                } else {
                    model.isInspectorPresented = true
                    openWindow(id: AppWindowID.inspector)
                }
            }
            .keyboardShortcut("i", modifiers: [.command, .option])

            Button("Open Model Assist") {
                openWindow(id: AppWindowID.ollamaSetup)
            }
            .keyboardShortcut("o", modifiers: [.command, .option])
        }

        CommandGroup(replacing: .appInfo) {
            Button("About On Color Theory") {
                openWindow(id: AppWindowID.about)
            }
        }

        CommandGroup(replacing: .help) {
            Button("On Color Theory Help") {
                openWindow(id: AppWindowID.help)
            }
            .keyboardShortcut("/", modifiers: [.command, .shift])

            Button("App Walkthrough") {
                openWindow(id: AppWindowID.walkthrough)
            }

            Divider()

            Link("Releases and Version History", destination: AppVersionInfo.releasesURL)
            Link("Source Code on GitHub", destination: AppVersionInfo.repositoryURL)
            Link("License", destination: AppVersionInfo.licenseURL)
        }
    }

    private func navigate(to section: AppSection) {
        model.selectedSection = section
        openWindow(id: AppWindowID.main)
    }
}

/// The editing selectors, sent to the first responder by name.
enum AppTextEditingAction: String, CaseIterable {
    case cut = "cut:"
    case copy = "copy:"
    case paste = "paste:"
    case pasteAsPlainText = "pasteAsPlainText:"
    case delete = "delete:"
    case selectAll = "selectAll:"

    var selector: Selector {
        NSSelectorFromString(rawValue)
    }

    @MainActor
    func send() {
        NSApp.sendAction(selector, to: nil, from: nil)
    }
}

/// Supplies the appearance, palette, typography, and accessibility
/// environment to a secondary window.
///
/// Auxiliary windows do not inherit it from the main scene, so without this
/// they would render in a different palette from the app that opened them.
private struct AppEnvironmentHost<Content: View>: View {
    @AppStorage(AppPreferenceKeys.textScale) private var textScale = 1.0
    @AppStorage(AppPreferenceKeys.useSystemFont) private var useSystemFont = false
    @AppStorage(AppPreferenceKeys.appearance) private var appearanceRawValue = AppAppearanceMode.dark.rawValue
    @AppStorage(AppPreferenceKeys.colorVisionPalette) private var paletteRawValue = AppColorVisionPalette.system.rawValue
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environment(\.appTextScale, textScale)
            .environment(\.useSystemFont, useSystemFont)
            .environment(\.appAccessibilityPreferences, accessibilityPreferences)
            .controlSize(.large)
            .appInterfaceTheme(colorVisionPalette)
            .syncApplicationAppearance(appearanceMode)
            .textSelection(.enabled)
    }

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceRawValue) ?? .dark
    }

    private var colorVisionPalette: AppColorVisionPalette {
        AppColorVisionPalette(rawValue: paletteRawValue) ?? .system
    }

    private var accessibilityPreferences: AppAccessibilityPreferences {
        AppAccessibilityPreferences(
            increasedContrast: colorSchemeContrast == .increased,
            differentiateWithoutColor: differentiateWithoutColor,
            reduceMotion: reduceMotion,
            reduceTransparency: reduceTransparency
        )
    }
}
