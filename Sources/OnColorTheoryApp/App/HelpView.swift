import SwiftUI

/// Help topics, named by the task rather than by the feature.
enum HelpTopic: String, CaseIterable, Identifiable {
    case start = "Start here"
    case inspect = "Sample and inspect colors"
    case appearances = "Design for Light & Dark"
    case ollama = "Model Assist and Ollama"
    case results = "Understand results"
    case shortcuts = "Shortcuts and troubleshooting"
    case reset = "Reset On Color Theory"

    var id: Self { self }

    var symbolName: String {
        switch self {
        case .start: "sparkles"
        case .inspect: "eyedropper"
        case .appearances: "circle.lefthalf.filled"
        case .ollama: "cpu"
        case .results: "checkmark.shield"
        case .shortcuts: "keyboard"
        case .reset: "arrow.counterclockwise"
        }
    }

    var iconMotif: DesignedIconMotif {
        switch self {
        case .start: .orbit
        case .inspect: .measure
        case .appearances: .split
        case .ollama: .spectrum
        case .results: .compare
        case .shortcuts: .steps
        case .reset: .orbit
        }
    }

    var summary: String {
        switch self {
        case .start:
            "Take or repeat the guided walkthrough, then open the workspace you need."
        case .inspect:
            "Pick a screen color, read its values and measures, then save it with context."
        case .appearances:
            "Create and test coordinated palettes for light mode, dark mode, or both."
        case .ollama:
            "Decide whether local model suggestions are useful, then install and apply them safely."
        case .results:
            "Know what On Color Theory calculates, illustrates, proposes, and cannot determine."
        case .shortcuts:
            "Move quickly, restore windows, and solve common connection or saved-work problems."
        case .reset:
            "Clear saved work and preferences, with separate choices for local Ollama and its downloaded models."
        }
    }

    var searchTerms: String {
        switch self {
        case .start: "home learn explore convert build check reference working color navigation beginner walkthrough tour"
        case .inspect: "inspector sampler sample anywhere screen hex rgb alpha measures context tray"
        case .appearances: "light dark both adaptive palette theme display contrast css"
        case .ollama: "model ai local external install download qwen privacy optional recommendations preview custom text heading paragraph cue button"
        case .results: "calculated illustrated proposed contrast wcag difference gamut simulation limitations"
        case .shortcuts: "keyboard command window missing offscreen recovery corrupt timeout connection help"
        case .reset: "reset restore default clear erase remove uninstall ollama models walkthrough start over"
        }
    }

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return true }
        return rawValue.lowercased().contains(needle)
            || summary.lowercased().contains(needle)
            || searchTerms.contains(needle)
    }
}

/// The Help window, one topic at a time.
struct HelpView: View {
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @Environment(\.appSemanticPalette) private var semanticPalette
    @Environment(\.openWindow) private var openWindow
    @State private var selectedTopic: HelpTopic
    @State private var query = ""
    @State private var resetRemovesOllama = false
    @State private var resetRemovesModels = false
    @State private var showsResetConfirmation = false
    @State private var isResetting = false
    @State private var resetMessage: String?
    @State private var resetHasIssue = false

    init(model: AppModel, initialTopic: HelpTopic = .start) {
        self.model = model
        _selectedTopic = State(initialValue: initialTopic)
    }

    var body: some View {
        Group {
            if textScale >= 1.3 {
                compactLayout
            } else {
                regularLayout
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("On Color Theory Help")
        .textSelection(.enabled)
        .onChange(of: query) { _, _ in
            guard let first = filteredTopics.first,
                  !filteredTopics.contains(selectedTopic) else { return }
            selectedTopic = first
        }
        .alert("Reset On Color Theory?", isPresented: $showsResetConfirmation) {
            Button("Reset", role: .destructive) {
                Task { await performReset() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(resetConfirmationMessage)
        }
    }

    private var regularLayout: some View {
        HStack(spacing: 0) {
            helpRail
                .frame(width: 270)
            Divider()
            topicReader
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                compactHeader
                searchField
                if filteredTopics.isEmpty {
                    noSearchResults
                } else {
                    Picker("Help topic", selection: $selectedTopic) {
                        ForEach(filteredTopics) { topic in
                            Label(topic.rawValue, systemImage: topic.symbolName).tag(topic)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppMetrics.regular)
            Divider()
            topicReader
        }
    }

    private var helpRail: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            VStack(alignment: .leading, spacing: AppMetrics.tight) {
                DesignedSymbolIcon(symbolName: "questionmark", motif: .orbit, size: 46)
                Text("On Color Theory Help")
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h1)
                Text("Find an answer, then go directly to the right tool.")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            searchField

            if filteredTopics.isEmpty {
                noSearchResults
            } else {
                ScrollView {
                    VStack(spacing: AppMetrics.snug) {
                        ForEach(filteredTopics) { topic in
                            topicButton(topic)
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                Label("Help never changes your colors or saved work.", systemImage: "lock.shield")
                Divider()
                Text(AppVersionInfo.display)
                Text(AppVersionInfo.attribution)
                Text(AppVersionInfo.license)
            }
            .appFont(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.regular)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.52))
    }

    private var compactHeader: some View {
        HStack(spacing: AppMetrics.snug) {
            DesignedSymbolIcon(symbolName: "questionmark", motif: .orbit, size: 38)
            Text("On Color Theory Help")
                .appFont(.title2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)
        }
    }

    private var searchField: some View {
        TextField("Search help", text: $query)
            .textFieldStyle(.roundedBorder)
            .appFont(.body)
            .accessibilityHint("Filters help topics by task or term")
    }

    private var noSearchResults: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Text("No matching help topic")
                .appFont(.headline)
            Text("Try a task such as sample, dark mode, model, contrast, or keyboard.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Clear search") { query = "" }
                .appFont(.body)
        }
        .padding(.vertical, AppMetrics.snug)
    }

    private func topicButton(_ topic: HelpTopic) -> some View {
        let isSelected = selectedTopic == topic
        return Button {
            selectedTopic = topic
        } label: {
            HStack(alignment: .top, spacing: AppMetrics.compact) {
                DesignedSymbolIcon(symbolName: topic.symbolName, motif: topic.iconMotif, size: 34)
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text(topic.rawValue)
                        .appFont(.headline)
                        .foregroundStyle(.primary)
                    Text(topic.summary)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(AppMetrics.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? semanticPalette.accent.opacity(0.09) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? semanticPalette.accent.opacity(0.38) : Color.clear)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var filteredTopics: [HelpTopic] {
        HelpTopic.allCases.filter { $0.matches(query) }
    }

    private var topicReader: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                topicHeader
                topicContent
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(AppMetrics.section)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var topicHeader: some View {
        DestinationHeader(
            title: selectedTopic.rawValue,
            summary: selectedTopic.summary
        )
    }

    @ViewBuilder
    private var topicContent: some View {
        switch selectedTopic {
        case .start:
            startContent
        case .inspect:
            inspectContent
        case .appearances:
            appearanceContent
        case .ollama:
            ollamaContent
        case .results:
            resultsContent
        case .shortcuts:
            shortcutsContent
        case .reset:
            resetContent
        }
    }

    private var startContent: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            helpCard(title: "Guided app walkthrough", symbol: "rectangle.stack") {
                Text("Open a seven-step slideshow that introduces one part of On Color Theory at a time. It includes clear progress, Previous and Next controls, and a short explanation of what each workspace is for.")
                    .appFont(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HelpActionPanel(title: "Learn the app", symbol: "rectangle.stack") {
                helpAction("Open walkthrough", symbol: "play.rectangle") {
                    openWindow(id: AppWindowID.walkthrough)
                }
            }

            HelpActionPanel(title: "Open a workspace", symbol: "arrow.up.forward.app") {
                actionButton("Open Home", symbol: "house", section: .home)
                actionButton("Start with Learn", symbol: "book.pages", section: .learn)
                helpAction("Open Inspector", symbol: "sidebar.right") {
                    model.isInspectorPresented = true
                    openWindow(id: AppWindowID.inspector)
                }
                actionButton("Design a palette", symbol: "swatchpalette", section: .build, buildPage: .design)
                actionButton("Open recommendations", symbol: "sparkles", section: .build, buildPage: .recommend)
            }
            helpNote("Every app-owned window has one stable identity. Repeating an action brings that window forward instead of creating another copy.", symbol: "macwindow.on.rectangle")
        }
    }

    private var inspectContent: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            helpCard(title: "Sample a color anywhere on screen", symbol: "eyedropper") {
                HelpSteps(items: [
                    "Open Inspector and choose Sample Anywhere on Screen.",
                    "Move the system sampler over this app, another app, or another display, then select a pixel.",
                    "Read Values, Measures, and Context. Save useful results to the Color Tray with their source information."
                ])
            }
            HelpActionPanel {
                helpAction("Open Inspector", symbol: "sidebar.right") {
                    model.isInspectorPresented = true
                    openWindow(id: AppWindowID.inspector)
                }
            }
            helpNote("A sampled pixel is the displayed result in sRGB, not the original asset, its source profile, or recoverable transparency.", symbol: "info.circle")
        }
    }

    private var appearanceContent: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            helpCard(title: "Use two related palettes, not one inverted palette", symbol: "circle.lefthalf.filled") {
                HelpSteps(items: [
                    "Open Build, then choose Light & Dark in the studio rail.",
                    "Choose a coordinated starter or edit Canvas, Body text, Accent, and Accent text separately for each appearance.",
                    "Review the live previews and all three named relationship checks for both modes.",
                    "Export adaptive CSS when the palette is ready."
                ])
            }
            HelpActionPanel {
                actionButton("Open Light & Dark", symbol: "swatchpalette", section: .build, buildPage: .appearances)
                SettingsLink {
                    Label("Display Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .appFont(.body)
            }
            helpNote("Display Settings changes how On Color Theory itself looks. Build → Light & Dark designs the palette you are evaluating or exporting.", symbol: "lightbulb")
        }
    }

    private var ollamaContent: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            helpCard(title: "Ollama is optional", symbol: "cpu") {
                Text("On Color Theory performs every lesson, conversion, comparison, check, and export without a model. Ollama only adds palette starting-point suggestions in Build → Recommend.")
                    .appFont(.body)
                    .fixedSize(horizontal: false, vertical: true)
                HelpSteps(items: [
                    "Choose whether Ollama runs on this Mac or on a server you already manage.",
                    "Follow the install guidance, check the connection, and choose a model sized for the system.",
                    "Review exactly what will be sent before generating.",
                    "After a proposal appears, edit the heading, body text, cue heading, cue detail, and button label to test your real copy in the recommended colors.",
                    "Inspect On Color Theory's independent checks before applying a suggestion."
                ])
            }
            helpCard(title: "Current status", symbol: model.ollama.isEnabled ? "checkmark.circle.fill" : "pause.circle") {
                LabeledContent("Suggestions", value: model.ollama.isEnabled ? "On" : "Off")
                LabeledContent("Selected model", value: model.ollama.selectedModel.isEmpty ? "None" : model.ollama.selectedModel)
                LabeledContent("Connection", value: model.ollama.connectionMode.title)
            }
            HelpActionPanel {
                helpAction("Open Model Assist", symbol: "cpu") {
                    openWindow(id: AppWindowID.ollamaSetup)
                }
                actionButton("Open Recommendations", symbol: "sparkles", section: .build, buildPage: .recommend)
            }
            helpNote("A model can propose four colors and explain each choice in plain language. It cannot author On Color Theory's contrast, conversion, gamut, difference, or simulation results.", symbol: "checkmark.shield")
        }
    }

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            helpCard(title: "Read the authority label first", symbol: "checkmark.shield") {
                HelpDefinitionRow(term: "Calculated", meaning: "A deterministic result from the app's documented color mathematics.")
                HelpDefinitionRow(term: "Illustrated", meaning: "A visual aid for inspection or learning, not a device measurement or universal perception prediction.")
                HelpDefinitionRow(term: "Proposed", meaning: "An optional model-written starting point that still requires review.")
                HelpDefinitionRow(term: "Needs context", meaning: "A result whose meaning depends on the design task, viewing conditions, or complete interface.")
            }
            helpCard(title: "Keep unlike questions separate", symbol: "arrow.triangle.branch") {
                Text("Contrast, color difference, gamut, alpha compositing, and reliance on color answer different questions. On Color Theory does not convert one result into another or claim that a single number proves an entire design works.")
                    .appFont(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HelpActionPanel {
                actionButton("Open Check", symbol: "checkmark.shield", section: .check)
                actionButton("Open Reference", symbol: "books.vertical", section: .reference)
            }
        }
    }

    private var shortcutsContent: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            helpCard(title: "Keyboard routes", symbol: "keyboard") {
                HelpShortcutRow(keys: "⌘1 to ⌘7", action: "Open Home through Reference")
                HelpShortcutRow(keys: "⇧⌘R", action: "Continue saved workspace")
                HelpShortcutRow(keys: "⇧⌘T", action: "Show or hide Color Tray")
                HelpShortcutRow(keys: "⌥⌘I", action: "Show or hide Inspector")
                HelpShortcutRow(keys: "⌥⌘O", action: "Open Model Assist")
                HelpShortcutRow(keys: "⇧⌘/", action: "Open On Color Theory Help")
            }
            helpCard(title: "If something does not look right", symbol: "wrench.and.screwdriver") {
                HelpDefinitionRow(term: "A window is missing", meaning: "Open it again from the top toolbar. Saved geometry that is no longer on a connected display is recentered automatically. Repeating the action brings the same window forward rather than creating another copy.")
                HelpDefinitionRow(term: "Saved work could not load", meaning: "Home explains the recovery and keeps an untouched recovery copy while opening a valid fresh workspace.")
                HelpDefinitionRow(term: "Ollama will not connect", meaning: "Confirm Ollama is running, check the server address, and use HTTPS for an external server when available.")
                HelpDefinitionRow(term: "A screen sample was canceled", meaning: "No color changes. Open Inspector and start the sampler again when ready.")
            }
        }
    }

    private var resetContent: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            helpCard(title: "Choose what returns to default", symbol: "arrow.counterclockwise") {
                HelpDefinitionRow(
                    term: "Always reset",
                    meaning: "Workspace progress, the Color Tray, reading and appearance settings, window positions, and Model Assist preferences return to their defaults. The app starts in Dark appearance."
                )
                HelpDefinitionRow(
                    term: "Kept unless selected",
                    meaning: "The local Ollama app and models downloaded through the standard local Ollama store remain on this Mac. Nothing on an external Ollama server is removed."
                )
            }

            AppCard {
                VStack(alignment: .leading, spacing: AppMetrics.regular) {
                    PanelHeading(
                        title: "Remove Ollama files from this Mac",
                        summary: "Items move to the Trash and stay recoverable until the Trash is emptied."
                    )

                    Toggle(isOn: $resetRemovesModels) {
                        VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                            Text("Remove all locally downloaded models")
                                .appFont(.headline)
                            Text("Moves the standard local model folder to the Trash. Models on an external server are never touched.")
                                .appFont(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Divider()

                    Toggle(isOn: $resetRemovesOllama) {
                        VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                            Text("Remove the local Ollama app")
                                .appFont(.headline)
                            Text("Moves Ollama.app from Applications to the Trash when it is installed there.")
                                .appFont(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if resetRemovesModels && resetRemovesOllama {
                        Label(
                            "With both choices selected, Reset returns to the complete first-run state and reopens the initial walkthrough.",
                            systemImage: "sparkles"
                        )
                        .appFont(.callout)
                        .foregroundStyle(semanticPalette.accent)
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Label(
                            "The initial walkthrough stays completed unless both cleanup choices are selected.",
                            systemImage: "checkmark.circle"
                        )
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .disabled(isResetting)

            if let resetMessage {
                Label(resetMessage, systemImage: resetHasIssue ? "exclamationmark.triangle" : "checkmark.circle.fill")
                    .appFont(.callout)
                    .foregroundStyle(resetHasIssue ? semanticPalette.critical : semanticPalette.positive)
                    .padding(AppMetrics.regular)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        (resetHasIssue ? semanticPalette.critical : semanticPalette.positive).opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            }

            HelpActionPanel(title: "Reset actions", symbol: "arrow.counterclockwise") {
                Button(role: .destructive) {
                    showsResetConfirmation = true
                } label: {
                    HStack(spacing: AppMetrics.snug) {
                        if isResetting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        Text(isResetting ? "Resetting…" : "Reset On Color Theory…")
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .tint(semanticPalette.critical)
                .appFont(.body)
                .disabled(isResetting)
            }
        }
    }

    private var resetConfirmationMessage: String {
        if resetRemovesModels && resetRemovesOllama {
            return "This clears On Color Theory and moves the standard local model store and Ollama app to the Trash. The initial walkthrough will reopen."
        }
        if resetRemovesModels || resetRemovesOllama {
            return "This clears On Color Theory and moves the selected local Ollama item to the Trash. The initial walkthrough will remain completed."
        }
        return "This clears saved work, the Color Tray, settings, window positions, and Model Assist preferences. Ollama and downloaded models remain installed."
    }

    @MainActor
    private func performReset() async {
        isResetting = true
        resetMessage = nil
        resetHasIssue = false

        var issues: [String] = []

        if resetRemovesModels,
           let modelDirectory = LocalOllamaAssets.modelDirectoryURL() {
            do {
                try await LocalOllamaAssets.moveToTrash(modelDirectory)
            } catch {
                issues.append("Downloaded models could not be moved to the Trash: \(error.localizedDescription)")
            }
        }

        if resetRemovesOllama,
           let applicationURL = LocalOllamaAssets.applicationURL() {
            do {
                try await LocalOllamaAssets.moveToTrash(applicationURL)
            } catch {
                issues.append("Ollama.app could not be moved to the Trash: \(error.localizedDescription)")
            }
        }

        let requestedCompleteFirstRunReset = resetRemovesModels && resetRemovesOllama && issues.isEmpty
        let trayWasCleared = model.resetToDefaults(
            showInitialWalkthrough: requestedCompleteFirstRunReset
        )
        if !trayWasCleared {
            issues.append("The saved Color Tray could not be replaced with an empty tray.")
        }
        let isCompleteFirstRunReset = requestedCompleteFirstRunReset && trayWasCleared
        isResetting = false

        if isCompleteFirstRunReset {
            resetRemovesModels = false
            resetRemovesOllama = false
            selectedTopic = .start
            return
        }

        if issues.isEmpty {
            resetMessage = "On Color Theory returned to its defaults. The initial walkthrough remains completed."
        } else {
            resetHasIssue = true
            resetMessage = "On Color Theory was reset, but local cleanup needs attention. " + issues.joined(separator: " ")
        }
    }

    private func helpCard<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                Label(title, systemImage: symbol)
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)
                content()
            }
        }
    }

    private func helpNote(_ text: String, symbol: String) -> some View {
        Label {
            Text(text)
                .appFont(.callout)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(semanticPalette.accent)
        }
        .padding(AppMetrics.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(semanticPalette.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    private func actionButton(
        _ title: String,
        symbol: String,
        section: AppSection,
        buildPage: PaletteStudioPage? = nil
    ) -> some View {
        helpAction(title, symbol: symbol) {
            if let buildPage {
                model.updateWorkspaceSession { $0.buildPageRawValue = buildPage.rawValue }
                model.requestedBuildPage = buildPage
            }
            model.selectedSection = section
            openWindow(id: AppWindowID.main)
        }
    }

    private func helpAction(
        _ title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
        }
        .buttonStyle(.borderedProminent)
        .appFont(.body)
    }
}

/// A numbered sequence of steps.
private struct HelpSteps: View {
    @Environment(\.appSemanticPalette) private var palette
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: AppMetrics.compact) {
                    Text("\(index + 1)")
                        .appFont(.headline)
                        .frame(width: 28, height: 28)
                        .background(palette.accent.opacity(0.11), in: Circle())
                        .accessibilityHidden(true)
                    Text(item)
                        .appFont(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(index + 1). \(item)")
            }
        }
    }
}

/// A panel that offers a control alongside the instruction describing it.
private struct HelpActionPanel<Content: View>: View {
    let title: String
    let symbol: String
    let content: Content

    init(
        title: String = "Open in On Color Theory",
        symbol: String = "arrow.up.forward.app",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            Label(title, systemImage: symbol)
                .appFont(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 210, maximum: 340), spacing: AppMetrics.snug)],
                alignment: .leading,
                spacing: AppMetrics.snug
            ) {
                content
            }
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.45))
        }
    }
}

/// One term and its plain meaning.
private struct HelpDefinitionRow: View {
    let term: String
    let meaning: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.hairline) {
            Text(term)
                .appFont(.headline)
            Text(meaning)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// One keyboard shortcut and what it does.
private struct HelpShortcutRow: View {
    let keys: String
    let action: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppMetrics.compact) {
            Text(keys)
                .appFont(.value)
                .monospaced()
                .frame(width: 82, alignment: .leading)
            Text(action)
                .appFont(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
