import SwiftUI

/// The main window, holding the sidebar, the selected workspace, and the
/// toolbar.
///
/// Every appearance and accessibility preference is applied here and passed
/// down through the environment, so a workspace never reads a preference
/// directly and cannot disagree with its neighbors.
struct AppShellView: View {
    @ObservedObject var model: AppModel
    @AppStorage(AppPreferenceKeys.textScale) private var textScale = 1.0
    @AppStorage(AppPreferenceKeys.useSystemFont) private var useSystemFont = false
    @AppStorage(AppPreferenceKeys.appearance) private var appearanceRawValue = AppAppearanceMode.dark.rawValue
    @AppStorage(AppPreferenceKeys.colorVisionPalette) private var paletteRawValue = AppColorVisionPalette.system.rawValue
    @AppStorage(AppPreferenceKeys.completedInitialWalkthrough) private var completedInitialWalkthrough = false
    @State private var hasPresentedWalkthroughThisLaunch = false
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        NavigationSplitView {
            // Two named groups rather than one list of six. The breadth over
            // depth literature is consistent that a broad, shallow structure
            // beats a narrow, deep one, and that holds for screen reader users
            // as well, so the answer is not fewer destinations. It is a first
            // decision between two obviously different intents, and headings a
            // rotor can jump between.
            List(selection: $model.selectedSection) {
                SidebarSectionRow(
                    section: .home,
                    isSelected: model.selectedSection == .home
                )
                    .tag(AppSection.home)

                ForEach(AppSection.Group.allCases) { group in
                    Section(group.rawValue) {
                        ForEach(AppSection.allCases.filter { $0.group == group }) { section in
                            SidebarSectionRow(
                                section: section,
                                isSelected: model.selectedSection == section
                            )
                                .tag(section)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                sidebarColorSummary
            }
            .navigationTitle("On Color Theory")
            .navigationSplitViewColumnWidth(min: 210, ideal: 236, max: 270)
            .accessibilityLabel("Main sections")
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .textSelection(.enabled)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            if #available(macOS 26.0, *) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        openWindow(id: AppWindowID.ollamaSetup)
                    } label: {
                        Label("Model Assist", systemImage: "cpu")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .appFont(.body)
                    .help("Open optional model setup (⌥⌘O)")
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarSpacer(.fixed, placement: .primaryAction)
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        openWindow(id: AppWindowID.ollamaSetup)
                    } label: {
                        Label("Model Assist", systemImage: "cpu")
                            .labelStyle(.titleAndIcon)
                    }
                    .appFont(.body)
                    .help("Open optional model setup (⌥⌘O)")
                }
            }

            // The two panels people toggle while working keep their own buttons.
            // Settings and Help are opened once in a while, so they sit behind
            // one menu rather than taking permanent width in every window.
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    toggleWindow(id: AppWindowID.tray, isPresented: $model.isTrayPresented)
                } label: {
                    Label("Color Tray", systemImage: "tray.full")
                        .labelStyle(.titleAndIcon)
                }
                .appFont(.body)
                .help("Show the persistent Color Tray (⇧⌘T)")

                Button {
                    toggleWindow(id: AppWindowID.inspector, isPresented: $model.isInspectorPresented)
                } label: {
                    Label("Inspector", systemImage: "sidebar.right")
                        .labelStyle(.titleAndIcon)
                }
                .appFont(.body)
                .help("Show or hide the Color Inspector (⌥⌘I)")

                Menu {
                    SettingsLink {
                        Label("Display and text", systemImage: "circle.lefthalf.filled")
                    }
                    Button {
                        openWindow(id: AppWindowID.help)
                    } label: {
                        Label("On Color Theory Help", systemImage: "questionmark.circle")
                    }
                    Divider()
                    Button {
                        openWindow(id: AppWindowID.walkthrough)
                    } label: {
                        Label("Walkthrough", systemImage: "sparkles")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                        .labelStyle(.titleAndIcon)
                }
                .appFont(.body)
                .menuIndicator(.hidden)
                .help("Settings, Help, and the walkthrough")
            }
        }
        .environment(\.appTextScale, textScale)
        .environment(\.useSystemFont, useSystemFont)
        .environment(\.appAccessibilityPreferences, accessibilityPreferences)
        .controlSize(.large)
        .appInterfaceTheme(colorVisionPalette)
        .syncApplicationAppearance(appearanceMode)
        .onChange(of: model.selectedSection) { _, section in
            guard let section else { return }
            AccessibilityAnnouncer.announce("\(section.rawValue) workspace opened")
        }
        .onAppear { presentInitialWalkthroughIfNeeded() }
        .onChange(of: completedInitialWalkthrough) { _, completed in
            guard !completed else { return }
            hasPresentedWalkthroughThisLaunch = false
            presentInitialWalkthroughIfNeeded()
        }
    }

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceRawValue) ?? .dark
    }

    private var colorVisionPalette: AppColorVisionPalette {
        AppColorVisionPalette(rawValue: paletteRawValue) ?? .system
    }

    /// Opens the walkthrough on a first run, and never again on its own.
    ///
    /// Two guards, because they cover different failures. The stored flag stops
    /// it returning on later launches. The launch scoped flag stops it opening
    /// twice within one launch, since `onAppear` runs again whenever the shell
    /// is reinserted, such as after the main window is closed and reopened from
    /// the Window menu.
    ///
    /// The flag is written here, at the moment of presenting, rather than by
    /// the walkthrough view when it draws. Writing it there conflates having
    /// been shown with having been rendered, and it also fires when someone
    /// opens the walkthrough deliberately from Home, Help, or About, which is
    /// not a first run at all.
    private func presentInitialWalkthroughIfNeeded() {
        guard !completedInitialWalkthrough else { return }
        guard !hasPresentedWalkthroughThisLaunch else { return }
        hasPresentedWalkthroughThisLaunch = true
        completedInitialWalkthrough = true
        openWindow(id: AppWindowID.walkthrough)
    }

    private var accessibilityPreferences: AppAccessibilityPreferences {
        AppAccessibilityPreferences(
            increasedContrast: colorSchemeContrast == .increased,
            differentiateWithoutColor: differentiateWithoutColor,
            reduceMotion: reduceMotion,
            reduceTransparency: reduceTransparency
        )
    }

    private func toggleWindow(id: String, isPresented: Binding<Bool>) {
        if isPresented.wrappedValue {
            dismissWindow(id: id)
            isPresented.wrappedValue = false
        } else {
            isPresented.wrappedValue = true
            openWindow(id: id)
        }
    }

    private var sidebarColorSummary: some View {
        Button {
            model.selectedSection = .convert
        } label: {
            HStack(spacing: AppMetrics.compact) {
                ColorSwatchView(color: model.analysis.parsed.color, showsLabel: false)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text("Working color")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                    Text(model.analysis.parsed.color.hex)
                        .appFont(.value)
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }

                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(AppMetrics.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .background.opacity(0.58),
                in: RoundedRectangle(cornerRadius: AppMetrics.radiusMedium, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .padding(AppMetrics.snug)
        // The working color follows the reader between workspaces, which is
        // the app's central idea and the one thing nothing on screen said.
        // It stays where it already lives rather than gaining a bar of its
        // own, and gains the sentence that explains it instead.
        .help("This color follows you between workspaces. Click to open it in Convert.")
        .accessibilityLabel("Working color \(model.analysis.parsed.color.hex)")
        .accessibilityHint("Follows you between workspaces. Opens in Convert.")
    }

    @ViewBuilder
    private var detail: some View {
        switch model.selectedSection ?? .home {
        case .home:
            HomeView(model: model)
        case .learn:
            LearnView(model: model)
        case .explore:
            ExploreView(model: model)
        case .convert:
            ConvertView(model: model)
        case .build:
            BuildView(model: model)
        case .check:
            CheckView(model: model)
        case .reference:
            ReferenceView(model: model)
        }
    }
}

/// One workspace in the sidebar, combined into a single accessibility element
/// so a screen reader announces the row rather than the icon and label
/// separately.
private struct SidebarSectionRow: View {
    let section: AppSection
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppMetrics.compact) {
            AppSectionIcon(section: section, size: 30)

            Text(section.rawValue)
                .appFont(.body)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppMetrics.hairline)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
