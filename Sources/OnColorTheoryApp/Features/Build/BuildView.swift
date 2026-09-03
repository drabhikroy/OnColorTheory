import SwiftUI

/// The palette studio.
///
/// Five pages carry one palette from design, through light and dark
/// appearances, an optional model suggestion, the app's own checks, and export.
/// The palette is held here rather than in the model because it is workspace
/// state rather than the working color every workspace shares.
struct BuildView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var ollama: OllamaController
    @Environment(\.appTextScale) private var textScale
    @Environment(\.openWindow) private var openWindow
    @State private var palette: InterfacePalette
    @State private var lightPalette: InterfacePalette
    @State private var darkPalette: InterfacePalette
    @State private var appearanceFocus: AppearancePaletteFocus = .both
    @State private var savedColorCount: Int?
    @State private var selectedPage: PaletteStudioPage = .design
    @State private var exportLanguage: CodeExportLanguage = .css
    @State private var recommendationPurpose: PaletteGenerationRequest.Purpose = .interface
    @State private var recommendationBrief = "A calm, legible interface palette for learning about color."
    @State private var recommendation: PaletteProposal?
    @State private var recommendedPalette: InterfacePalette?
    @State private var recommendationError: String?
    @State private var isGeneratingRecommendation = false
    @State private var showsRequestPreview = false
    @State private var recommendationTask: Task<Void, Never>?
    @State private var previewCopy: PalettePreviewCopy
    @State private var previewPaletteSource: PalettePreviewSource = .studio

    private let evaluator = InterfacePaletteEvaluator()

    init(
        model: AppModel,
        initialPalette: InterfacePalette? = nil,
        initialPage: PaletteStudioPage? = nil,
        initialRequestPreview: Bool = false,
        initialRecommendation: PaletteProposal? = nil,
        initialRecommendedPalette: InterfacePalette? = nil,
        initialPreviewCopy: PalettePreviewCopy? = nil
    ) {
        self.model = model
        _ollama = ObservedObject(wrappedValue: model.ollama)
        _palette = State(initialValue: initialPalette ?? model.workspaceSession.buildPalette)
        _lightPalette = State(
            initialValue: model.workspaceSession.buildLightPalette ?? InterfacePalettePreset.light.palette
        )
        _darkPalette = State(
            initialValue: model.workspaceSession.buildDarkPalette ?? InterfacePalettePreset.dark.palette
        )
        _selectedPage = State(
            initialValue: initialPage
                ?? PaletteStudioPage(rawValue: model.workspaceSession.buildPageRawValue)
                ?? .design
        )
        _exportLanguage = State(
            initialValue: CodeExportLanguage(
                rawValue: model.workspaceSession.buildExportLanguageRawValue
            ) ?? .css
        )
        _showsRequestPreview = State(initialValue: initialRequestPreview)
        _recommendation = State(initialValue: initialRecommendation)
        _recommendedPalette = State(initialValue: initialRecommendedPalette)
        _previewPaletteSource = State(
            initialValue: initialRecommendedPalette == nil ? .studio : .recommendation
        )
        _previewCopy = State(
            initialValue: initialPreviewCopy
                ?? model.workspaceSession.buildPreviewCopy
                ?? .sample
        )
    }

    private var results: [PaletteRelationshipResult] {
        evaluator.evaluate(palette)
    }

    private var passingCount: Int {
        results.filter(\.passes).count
    }

    var body: some View {
        WorkspaceCanvas(section: .build) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.section) {
                    header
                    studioWorkspace
                }
                .frame(maxWidth: 1_140, alignment: .leading)
                .padding(AppMetrics.page)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Build")
        .textSelection(.enabled)
        .onChange(of: palette) { _, value in
            model.updateWorkspaceSession { $0.buildPalette = value }
        }
        .onChange(of: lightPalette) { _, value in
            model.updateWorkspaceSession { $0.buildLightPalette = value }
        }
        .onChange(of: darkPalette) { _, value in
            model.updateWorkspaceSession { $0.buildDarkPalette = value }
        }
        .onChange(of: selectedPage) { _, page in
            model.updateWorkspaceSession { $0.buildPageRawValue = page.rawValue }
        }
        .onChange(of: exportLanguage) { _, language in
            model.updateWorkspaceSession { $0.buildExportLanguageRawValue = language.rawValue }
        }
        .onChange(of: previewCopy) { _, value in
            model.updateWorkspaceSession {
                $0.buildPreviewCopy = value == .sample ? nil : value
            }
        }
        .onChange(of: model.requestedBuildPage) { _, page in
            guard let page else { return }
            selectedPage = page
            model.requestedBuildPage = nil
        }
        .task(id: selectedPage) {
            if selectedPage == .recommend,
               ollama.isEnabled,
               ollama.connectionState == .idle {
                await ollama.refresh()
            }
        }
        .onDisappear {
            recommendationTask?.cancel()
        }
    }

    private var studioWorkspace: some View {
        AdaptivePairLayout(
            horizontalThreshold: textScale >= 1.3 ? 1_080 : 820,
            leadingFraction: 0.26,
            spacing: AppMetrics.roomy
        ) {
            studioNavigation

            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                Group {
                    switch selectedPage {
                    case .design:
                        designWorkspace
                    case .appearances:
                        appearanceWorkspace
                    case .recommend:
                        recommendationCard
                    case .check:
                        relationshipCard
                    case .export:
                        exportCard
                    }
                }
                persistentPreviewCard
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var studioNavigation: some View {
        AppCard(padding: AppMetrics.compact) {
            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                PanelHeading(
                    title: "Five connected stages",
                    summary: "Your palette and preview stay with you throughout."
                )

                ForEach(PaletteStudioPage.allCases) { page in
                    SectionRailButton(
                        title: page.title,
                        summary: page.explanation,
                        symbolName: page.symbolName,
                        motif: page.iconMotif,
                        isSelected: page == selectedPage
                    ) {
                        selectedPage = page
                    }
                }

                Divider()

                modelAssistRailCard

                Divider()

                Label(
                    "\(passingCount) of \(results.count) named checks currently pass",
                    systemImage: passingCount == results.count ? "checkmark.circle.fill" : "exclamationmark.triangle"
                )
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var designWorkspace: some View {
        editorCard
    }

    private var modelAssistRailCard: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Label("Model Assist", systemImage: "sparkles")
                .appFont(.headline)
            Text(modelAssistRailDetail)
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppMetrics.snug) { modelAssistRailActions }
                VStack(alignment: .leading, spacing: AppMetrics.snug) { modelAssistRailActions }
            }
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }

    private var modelAssistRailDetail: String {
        guard ollama.isEnabled else { return "Optional recommendations are off." }
        guard !ollama.selectedModel.isEmpty else { return "Choose or download a model to begin." }
        return "Ready with \(ollama.selectedModel)."
    }

    @ViewBuilder
    private var modelAssistRailActions: some View {
        Button(ollama.isEnabled && !ollama.selectedModel.isEmpty ? "Recommend" : "Set up") {
            if ollama.isEnabled && !ollama.selectedModel.isEmpty {
                selectedPage = .recommend
            } else {
                openWindow(id: AppWindowID.ollamaSetup)
            }
        }
        .buttonStyle(.borderedProminent)

        Button("Manage") {
            openWindow(id: AppWindowID.ollamaSetup)
        }
        .buttonStyle(.bordered)
    }

    private var appearanceWorkspace: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            AppCard {
                VStack(alignment: .leading, spacing: AppMetrics.regular) {
                    PanelHeading(
                        title: "Design for light and dark",
                        summary: "Keep a real palette for each appearance. Dark mode is not a simple inversion: surfaces, readable text, accents, and text on accents still need to work together."
                    )

                    Picker("Palette to work on", selection: $appearanceFocus) {
                        ForEach(AppearancePaletteFocus.allCases) { focus in
                            Label(focus.title, systemImage: focus.symbolName).tag(focus)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch appearanceFocus {
                    case .light:
                        appearanceEditor(for: .light)
                    case .dark:
                        appearanceEditor(for: .dark)
                    case .both:
                        appearanceComparison
                    }
                }
            }

            AppCard {
                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    Text("Helpful color tools")
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    Text("Use these alongside the checks above: one helps build adaptive themes, one tests specific pairs, and one explains why contrast matters.")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    appearanceResource(
                        title: "Leonardo adaptive color",
                        detail: "Create scales and themes that target contrast across light and dark surfaces.",
                        destination: AppExternalLinks.leonardo
                    )
                    appearanceResource(
                        title: "Adobe Color contrast analyzer",
                        detail: "Test a foreground and background pair and explore nearby alternatives.",
                        destination: AppExternalLinks.adobeContrastAnalyzer
                    )
                    appearanceResource(
                        title: "W3C contrast guidance",
                        detail: "Understand how contrast affects reading in different conditions and why it belongs in early palette decisions.",
                        destination: AppExternalLinks.wcagContrastPerspective
                    )

                    Label(
                        "External tools can broaden exploration. On Color Theory still calculates the three named relationships shown here; passing them alone does not establish whole-interface accessibility.",
                        systemImage: "info.circle"
                    )
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func appearanceEditor(for focus: AppearancePaletteFocus) -> some View {
        AdaptivePairLayout(
            horizontalThreshold: textScale >= 1.3 ? 1_020 : 760,
            leadingFraction: 0.48,
            spacing: AppMetrics.regular
        ) {
            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                HStack {
                    Text("\(focus.title) roles")
                        .appFont(.headline)
                    Spacer()
                    appearancePresetMenu(for: focus)
                }

                ForEach(InterfacePaletteRole.allCases) { role in
                    EditableColorInput(
                        title: role.title,
                        color: appearanceBinding(for: role, focus: focus),
                        swatchSize: 50,
                        supportingText: role.explanation
                    )
                }

                Button("Use Studio palette as \(focus.title)", systemImage: "arrow.down.left") {
                    setAppearancePalette(palette, for: focus)
                }
            }

            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                AppearancePalettePreview(
                    title: focus.title,
                    palette: appearancePalette(for: focus),
                    evaluator: evaluator
                )
                Button("Use \(focus.title) palette in Studio", systemImage: "paintpalette") {
                    palette = appearancePalette(for: focus)
                    selectedPage = .design
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var appearanceComparison: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            AdaptivePairLayout(
                horizontalThreshold: textScale >= 1.3 ? 1_020 : 720,
                leadingFraction: 0.5,
                spacing: AppMetrics.regular
            ) {
                AppearancePalettePreview(title: "Light", palette: lightPalette, evaluator: evaluator)
                AppearancePalettePreview(title: "Dark", palette: darkPalette, evaluator: evaluator)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppMetrics.snug) { appearanceComparisonActions }
                VStack(alignment: .leading, spacing: AppMetrics.snug) { appearanceComparisonActions }
            }

            ScrollView(.horizontal) {
                Text(ColorCodeExporter.adaptiveCSS(light: lightPalette, dark: darkPalette))
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(AppMetrics.compact)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .background(.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator, lineWidth: 1) }
            .accessibilityLabel("Adaptive light and dark CSS")
        }
    }

    @ViewBuilder
    private var appearanceComparisonActions: some View {
        Button("Edit Light", systemImage: "sun.max") { appearanceFocus = .light }
        Button("Edit Dark", systemImage: "moon.stars") { appearanceFocus = .dark }
        CopyValueButton(
            value: ColorCodeExporter.adaptiveCSS(light: lightPalette, dark: darkPalette),
            description: "adaptive light and dark CSS",
            label: "Copy CSS",
            isBordered: true
        )
    }

    // The destination is a parameter rather than a literal, so it is typed as a
    // URL and the compiler requires each call site to supply a real one. Taking
    // a string and forcing it here would move a malformed address from a build
    // error to a crash at the moment someone opens this panel.
    private func appearanceResource(title: String, detail: String, destination: URL) -> some View {
        Link(destination: destination) {
            HStack(alignment: .top, spacing: AppMetrics.compact) {
                Image(systemName: "arrow.up.right.square")
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text(title)
                        .appFont(.headline)
                    Text(detail)
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(AppMetrics.compact)
            .appSubtleSurface(cornerRadius: 10)
        }
        .buttonStyle(.plain)
    }

    private func appearancePresetMenu(for focus: AppearancePaletteFocus) -> some View {
        Menu("Starters", systemImage: "square.grid.2x2") {
            ForEach(focus == .dark ? InterfacePalettePreset.darkChoices : InterfacePalettePreset.lightChoices) { preset in
                Button(preset.rawValue) {
                    setAppearancePalette(preset.palette, for: focus)
                }
            }
        }
        .appFont(.body)
    }

    private func appearancePalette(for focus: AppearancePaletteFocus) -> InterfacePalette {
        focus == .dark ? darkPalette : lightPalette
    }

    private func setAppearancePalette(_ value: InterfacePalette, for focus: AppearancePaletteFocus) {
        if focus == .dark {
            darkPalette = value
        } else {
            lightPalette = value
        }
    }

    private func appearanceBinding(
        for role: InterfacePaletteRole,
        focus: AppearancePaletteFocus
    ) -> Binding<SRGBColor> {
        Binding(
            get: { appearancePalette(for: focus)[role] },
            set: { newValue in
                var updated = appearancePalette(for: focus)
                updated[role] = newValue
                setAppearancePalette(updated, for: focus)
            }
        )
    }

    private var header: some View {
        WorkspaceHeader(section: .build)
    }

    private var editorCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: AppMetrics.compact) {
                        editorHeading
                        Spacer()
                        presetMenu
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        editorHeading
                        presetMenu
                    }
                }

                ForEach(InterfacePaletteRole.allCases) { role in
                    EditableColorInput(
                        title: role.title,
                        color: binding(for: role),
                        swatchSize: 54,
                        supportingText: role.explanation
                    )
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppMetrics.snug) { editorActions }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) { editorActions }
                }
                .appFont(.callout)
            }
        }
    }

    private var editorHeading: some View {
        PanelHeading(
            title: "Choose color roles",
            summary: "Edit HEX or RGB values directly, or use the native color picker."
        )
    }

    private var presetMenu: some View {
        Menu("Starter palettes", systemImage: "square.grid.2x2") {
            ForEach(InterfacePalettePreset.allCases) { preset in
                Button(preset.rawValue) {
                    palette = preset.palette
                    savedColorCount = nil
                }
            }
        }
        .appFont(.body)
    }

    @ViewBuilder
    private var editorActions: some View {
        Button("Use Convert color as accent", systemImage: "arrow.down.left") {
            palette.accent = model.analysis.parsed.color.opaque
            savedColorCount = nil
        }

        Button("Choose higher-contrast text", systemImage: "circle.lefthalf.filled") {
            palette.accentText = evaluator.higherContrastText(on: palette.accent)
            savedColorCount = nil
        }
        .help("Choose black or white, whichever has the higher WCAG contrast against the accent. This does not change the accent color.")
    }

    private var persistentPreviewCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: AppMetrics.compact) {
                        previewHeading
                        Spacer(minLength: 12)
                        previewPalettePicker
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        previewHeading
                        previewPalettePicker
                    }
                }

                AdaptivePairLayout(
                    horizontalThreshold: textScale >= 1.3 ? 1_050 : 760,
                    leadingFraction: 0.45,
                    spacing: AppMetrics.regular
                ) {
                    PalettePreviewCopyEditor(copy: $previewCopy)
                    PaletteTextPreview(
                        palette: previewPalette,
                        title: previewCopy.title,
                        bodyText: previewCopy.bodyText,
                        cueTitle: previewCopy.cueTitle,
                        cueDetail: previewCopy.cueDetail,
                        actionTitle: previewCopy.actionTitle,
                        minimumHeight: 285,
                        sourceTitle: previewPaletteSource.title
                    )
                }

                Text("This visual sample helps you judge hierarchy and mood. The Check stage answers the narrower numerical questions.")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var previewHeading: some View {
        PanelHeading(
            title: "Persistent interface preview",
            summary: "Edit once and watch your text and colors evolve through all five stages."
        )
    }

    private var previewPalettePicker: some View {
        Picker("Preview palette", selection: $previewPaletteSource) {
            ForEach(PalettePreviewSource.allCases) { source in
                if source != .recommendation || recommendedPalette != nil {
                    Label(source.title, systemImage: source.symbolName).tag(source)
                }
            }
        }
        .pickerStyle(.menu)
    }

    private var previewPalette: InterfacePalette {
        switch previewPaletteSource {
        case .studio: palette
        case .light: lightPalette
        case .dark: darkPalette
        case .recommendation: recommendedPalette ?? palette
        }
    }

    private var recommendationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                PanelHeading(
                    title: "Ask for a starting point",
                    summary: "Model Assist can ask the selected Ollama model to propose four roles and explain every choice in plain language. The app then calculates the same named checks used everywhere else."
                )

                if !ollama.isEnabled {
                    modelSetupCallout(
                        title: "Model suggestions are off",
                        detail: "Turn on Ollama, choose a local or external connection, and select an installed model in Settings."
                    )
                } else if ollama.selectedModel.isEmpty {
                    modelSetupCallout(
                        title: "Choose an Ollama model",
                        detail: "Check the connection and select or download a model in Settings."
                    )
                } else {
                    Picker("Palette purpose", selection: $recommendationPurpose) {
                        ForEach(PaletteGenerationRequest.Purpose.buildChoices) { purpose in
                            Text(purpose.displayTitle).tag(purpose)
                        }
                    }

                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Design brief")
                                .appFont(.headline)
                            Spacer()
                            Text(briefCountLabel)
                                .appFont(.caption)
                                .foregroundStyle(isRecommendationBriefValid ? Color.secondary : Color.primary)
                        }
                        TextEditor(text: $recommendationBrief)
                            .appFont(.body)
                            .frame(minHeight: 86)
                            .padding(AppMetrics.snug)
                            .background(.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(.separator, lineWidth: 1)
                            }
                            .accessibilityLabel("Palette design brief")
                            .accessibilityValue(briefCountLabel)
                            .onChange(of: recommendationBrief) { _, value in
                                let hardLimit = OllamaPaletteModelProvider.maximumBriefLength + 500
                                if value.count > hardLimit {
                                    recommendationBrief = String(value.prefix(hardLimit))
                                }
                            }
                    }

                    requestPrivacyPreview

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AppMetrics.compact) { recommendationActions }
                        VStack(alignment: .leading, spacing: AppMetrics.snug) { recommendationActions }
                    }

                    Label(
                        ollama.connectionMode == .guidedLocal
                            ? "Using \(ollama.selectedModel) on this Mac"
                            : "Using \(ollama.selectedModel) at \(ollama.effectiveAddress)",
                        systemImage: ollama.connectionMode == .guidedLocal ? "desktopcomputer" : "network"
                    )
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                if let recommendationError {
                    Label(recommendationError, systemImage: "exclamationmark.triangle")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let recommendation, let recommendedPalette {
                    Divider()
                    recommendationResult(recommendation, palette: recommendedPalette)
                }

                Divider()

                Label(
                    "Suggestion boundary: the selected model supplies colors and explanations only. On Color Theory, not the model, calculates contrast ratios, conversions, gamut results, differences, and simulations.",
                    systemImage: "checkmark.shield"
                )
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var recommendationActions: some View {
        if isGeneratingRecommendation {
            Button("Cancel generation", systemImage: "xmark") {
                recommendationTask?.cancel()
            }
        } else {
            Button {
                recommendationTask?.cancel()
                recommendationTask = Task { await generateRecommendation() }
            } label: {
                Label(
                    ollama.connectionMode == .guidedLocal ? "Generate locally" : "Send and generate",
                    systemImage: "sparkles"
                )
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!isRecommendationBriefValid)
            .accessibilityHint(
                ollama.connectionMode == .guidedLocal
                    ? "Sends the reviewed request to Ollama on this Mac"
                    : "Sends the reviewed request to the configured external Ollama server"
            )
        }

        Button {
            openWindow(id: AppWindowID.ollamaSetup)
        } label: {
            Label("Model Assist setup", systemImage: "wand.and.stars")
        }
    }

    private var requestPrivacyPreview: some View {
        DisclosureGroup(isExpanded: $showsRequestPreview) {
            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                requestPreviewRow(
                    title: "Destination",
                    value: ollama.connectionMode == .guidedLocal
                        ? "Ollama on this Mac (127.0.0.1)"
                        : ollama.effectiveAddress
                )
                requestPreviewRow(title: "Purpose", value: recommendationPurpose.displayTitle)
                requestPreviewRow(
                    title: "Current roles",
                    value: InterfacePaletteRole.allCases
                        .map { "\($0.title) \(palette[$0].hex)" }
                        .joined(separator: " · ")
                )
                requestPreviewRow(
                    title: "Your brief",
                    value: recommendationBrief.trimmingCharacters(in: .whitespacesAndNewlines)
                )

                Label(
                    ollama.connectionMode == .guidedLocal
                        ? "No Color Tray history, files, account data, or scientific results are included."
                        : "The external server receives only the four items listed above. No Color Tray history, files, account data, or scientific results are included.",
                    systemImage: "lock.shield"
                )
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, AppMetrics.snug)
        } label: {
            Label("Review exactly what will be sent", systemImage: "doc.text.magnifyingglass")
                .appFont(.headline)
        }
        .padding(AppMetrics.compact)
        .appSubtleSurface(cornerRadius: 10)
    }

    private func requestPreviewRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.hairline) {
            Text(title)
                .appFont(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "Nothing entered" : value)
                .appFont(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var isRecommendationBriefValid: Bool {
        let trimmed = recommendationBrief.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && recommendationBrief.count <= OllamaPaletteModelProvider.maximumBriefLength
    }

    private var briefCountLabel: String {
        let count = recommendationBrief.count
        let limit = OllamaPaletteModelProvider.maximumBriefLength
        return count <= limit ? "\(count) of \(limit) characters" : "Too long · \(count) of \(limit)"
    }

    private func modelSetupCallout(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Label(title, systemImage: "cpu")
                .appFont(.headline)
            Text(detail)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                openWindow(id: AppWindowID.ollamaSetup)
            } label: {
                Label("Open Model Assist", systemImage: "wand.and.stars")
            }
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }

    private func recommendationResult(
        _ proposal: PaletteProposal,
        palette recommendedPalette: InterfacePalette
    ) -> some View {
        let evaluated = evaluator.evaluate(recommendedPalette)
        let passing = evaluated.filter(\.passes).count

        return VStack(alignment: .leading, spacing: AppMetrics.regular) {
            VStack(alignment: .leading, spacing: AppMetrics.tight) {
                Text("Why this palette")
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)
                Text("Overall approach")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                Text(proposal.summary)
                    .appFont(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text("From \(proposal.provider.name) · \(proposal.provider.runsLocally ? "local" : "external")")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(InterfacePaletteRole.allCases.enumerated()), id: \.element.id) { index, role in
                HStack(alignment: .top, spacing: AppMetrics.compact) {
                    ColorSwatchView(color: recommendedPalette[role], showsLabel: false)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                        HStack(spacing: AppMetrics.snug) {
                            Text(role.title)
                                .appFont(.headline)
                            Text(recommendedPalette[role].hex)
                                .appFont(.value)
                                .monospacedDigit()
                        }
                        Text("Why this color")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                        Text(proposal.colors[index].rationale)
                            .appFont(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Label(
                "On Color Theory check: \(passing) of \(evaluated.count) named relationships pass",
                systemImage: passing == evaluated.count ? "checkmark.circle.fill" : "exclamationmark.triangle"
            )
            .appFont(.headline)

            ForEach(evaluated) { result in
                HStack {
                    Text(result.title)
                        .appFont(.callout)
                    Spacer()
                    Text("\(Format.decimal(result.evaluation.ratio, places: 2)):1")
                        .appFont(.value)
                        .monospacedDigit()
                    Image(systemName: result.passes ? "checkmark.circle.fill" : "xmark.circle")
                        .accessibilityLabel(result.passes ? "Passes" : "Does not pass")
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppMetrics.snug) { proposedPaletteActions(recommendedPalette) }
                VStack(alignment: .leading, spacing: AppMetrics.snug) { proposedPaletteActions(recommendedPalette) }
            }
        }
    }

    @ViewBuilder
    private func proposedPaletteActions(_ recommendedPalette: InterfacePalette) -> some View {
        Button("Use this palette", systemImage: "paintpalette.fill") {
            palette = recommendedPalette
            previewPaletteSource = .studio
            savedColorCount = nil
            AccessibilityAnnouncer.announce("Applied the suggested palette")
        }
        .buttonStyle(.borderedProminent)

        Button("Use and review checks", systemImage: "checkmark.shield") {
            palette = recommendedPalette
            previewPaletteSource = .studio
            savedColorCount = nil
            selectedPage = .check
        }
    }

    private func generateRecommendation() async {
        isGeneratingRecommendation = true
        recommendationError = nil
        defer { isGeneratingRecommendation = false }

        do {
            let provider = try ollama.provider()
            let request = PaletteGenerationRequest(
                purpose: recommendationPurpose,
                description: recommendationBrief.trimmingCharacters(in: .whitespacesAndNewlines),
                desiredColorCount: 4,
                existingColors: InterfacePaletteRole.allCases.map { role in
                    ColorRecord(
                        label: role.title,
                        originalRepresentation: palette[role].hex,
                        originalColorSpace: .sRGB,
                        color: palette[role],
                        conversionHistory: [],
                        source: "Palette Studio"
                    )
                },
                lockedColorIDs: []
            )
            let proposed = try await provider.proposePalette(for: request)
            guard proposed.colors.count == 4 else {
                throw OllamaServiceError.invalidProposal("expected four colors")
            }
            recommendation = proposed
            recommendedPalette = InterfacePalette(
                background: proposed.colors[0].color,
                text: proposed.colors[1].color,
                accent: proposed.colors[2].color,
                accentText: proposed.colors[3].color
            )
            previewPaletteSource = .recommendation
            AccessibilityAnnouncer.announce("Ollama palette suggestion ready; deterministic checks calculated")
        } catch {
            recommendation = nil
            recommendedPalette = nil
            recommendationError = Task.isCancelled ? nil : error.localizedDescription
        }
    }

    private var relationshipCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: AppMetrics.compact) {
                        relationshipHeading
                        Spacer()
                        relationshipSummary
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        relationshipHeading
                        relationshipSummary
                    }
                }

                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    PaletteRelationshipRow(result: result) {
                        model.openInCheck(
                            foreground: result.evaluation.foreground,
                            background: result.evaluation.background
                        )
                    }
                    if index < results.count - 1 {
                        Divider()
                    }
                }

                Label(
                    "These checks cover only the three displayed relationships. Passing them does not establish that a whole interface is accessible.",
                    systemImage: "info.circle"
                )
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("Sources and boundaries")
                        .appFont(.headline)
                    ForEach(evidenceRecords) { record in
                        Link(destination: record.sourceURL) {
                            Label(record.title, systemImage: "arrow.up.right.square")
                        }
                        .appFont(.body)
                    }
                    Text("These standards define the named checks and export syntax. They do not choose a usable palette for a particular audience or interface.")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var relationshipHeading: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            HStack(spacing: AppMetrics.tight) {
                Text("Check the relationships")
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)
                TermHelpButton(conceptID: "wcag-contrast", showsTerm: false)
            }
            Text("Each result names what was tested and the threshold used.")
                .appFont(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var relationshipSummary: some View {
        Label(
            "\(passingCount) of \(results.count) meet their thresholds",
            systemImage: passingCount == results.count ? "checkmark.circle.fill" : "exclamationmark.triangle"
        )
        .appFont(.headline)
        .foregroundStyle(.primary)
        .accessibilityLabel("\(passingCount) of \(results.count) relationships meet their thresholds")
    }

    private var exportCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                PanelHeading(
                    title: "Use the palette",
                    summary: "Choose a language, copy the palette, or keep all four colors in the Color Tray."
                )

                CodeExportDisclosure(
                    title: "Palette code",
                    supportingText: "CSS, Swift, JavaScript, Python, R, and JSON use the same named roles.",
                    language: $exportLanguage,
                    initiallyExpanded: true
                ) { language in
                    ColorCodeExporter.paletteSnippet(palette, language: language)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppMetrics.snug) { exportActions }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) { exportActions }
                }
                .appFont(.callout)

                if let savedColorCount {
                    Label(
                        "\(savedColorCount) unique \(savedColorCount == 1 ? "color" : "colors") saved to the tray.",
                        systemImage: "checkmark.circle.fill"
                    )
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Save complete")
                    .accessibilityValue("\(savedColorCount) unique \(savedColorCount == 1 ? "color" : "colors") saved to the Color Tray")
                }
            }
        }
    }

    @ViewBuilder
    private var exportActions: some View {
        Button("Save all to Tray", systemImage: "tray.and.arrow.down") {
            savedColorCount = model.addPaletteToTray(palette)
            if model.tray.persistenceError == nil, let savedColorCount {
                AccessibilityAnnouncer.announce(
                    "Saved \(savedColorCount) unique \(savedColorCount == 1 ? "color" : "colors") to the Color Tray"
                )
            }
        }
        .appFont(.body)
    }

    private var evidenceRecords: [EvidenceRecord] {
        [
            "w3c-wcag-22-contrast",
            "w3c-wcag-22-non-text",
            "apple-hig-accessibility",
            "w3c-css-custom-properties"
        ]
        .compactMap(EvidenceRegistry.record(withID:))
    }

    private func binding(for role: InterfacePaletteRole) -> Binding<SRGBColor> {
        Binding(
            get: { palette[role] },
            set: { newValue in
                palette[role] = newValue
                savedColorCount = nil
            }
        )
    }
}

/// The words shown in the palette preview.
///
/// These are editable because judging a palette on placeholder text is
/// different from judging it on the text it will actually carry.
struct PalettePreviewCopy: Codable, Equatable, Sendable {
    var title: String
    var bodyText: String
    var cueTitle: String
    var cueDetail: String
    var actionTitle: String

    static let sample = PalettePreviewCopy(
        title: "Bring your ideas into focus",
        bodyText: "Use this sample to see how a heading, reading text, a meaningful cue, and an action work together in the recommended scheme.",
        cueTitle: "A useful point to notice",
        cueDetail: "The accent is shown as a labeled shape as well as a color.",
        actionTitle: "Continue reading"
    )
}

/// Lets the reader replace the preview wording with their own.
struct PalettePreviewCopyEditor: View {
    @Binding var copy: PalettePreviewCopy

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: AppMetrics.compact) { editorHeading }
                VStack(alignment: .leading, spacing: AppMetrics.snug) { editorHeading }
            }

            previewField(
                "Heading",
                text: limitedBinding(\.title, maximum: 120),
                prompt: "Preview heading",
                lineLimit: 2
            )
            previewField(
                "Body text",
                text: limitedBinding(\.bodyText, maximum: 500),
                prompt: "Preview paragraph",
                lineLimit: 4
            )
            previewField(
                "Cue heading",
                text: limitedBinding(\.cueTitle, maximum: 120),
                prompt: "Accent cue heading",
                lineLimit: 2
            )
            previewField(
                "Cue detail",
                text: limitedBinding(\.cueDetail, maximum: 300),
                prompt: "Accent cue detail",
                lineLimit: 3
            )
            previewField(
                "Button label",
                text: limitedBinding(\.actionTitle, maximum: 80),
                prompt: "Action label",
                lineLimit: 2
            )
        }
        .padding(AppMetrics.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }

    @ViewBuilder
    private var editorHeading: some View {
        VStack(alignment: .leading, spacing: AppMetrics.hairline) {
            Text("Use your own preview text")
                .appFont(.headline)
            Text("Edit every visible text role below. The sample stays with this Build workspace.")
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
        Button("Restore sample", systemImage: "arrow.counterclockwise") {
            copy = .sample
        }
        .appFont(.callout)
    }

    private func previewField(
        _ label: String,
        text: Binding<String>,
        prompt: String,
        lineLimit: Int
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.compact) {
                Text(label)
                    .appFont(.callout)
                    .frame(width: 96, alignment: .leading)
                previewTextField(text: text, prompt: prompt, lineLimit: lineLimit)
            }

            VStack(alignment: .leading, spacing: AppMetrics.tight) {
                Text(label)
                    .appFont(.callout)
                previewTextField(text: text, prompt: prompt, lineLimit: lineLimit)
            }
        }
    }

    private func previewTextField(
        text: Binding<String>,
        prompt: String,
        lineLimit: Int
    ) -> some View {
        TextField(prompt, text: text, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(1...lineLimit)
            .appFont(.body)
    }

    private func limitedBinding(
        _ keyPath: WritableKeyPath<PalettePreviewCopy, String>,
        maximum: Int
    ) -> Binding<String> {
        Binding(
            get: { copy[keyPath: keyPath] },
            set: { value in
                copy[keyPath: keyPath] = String(value.prefix(maximum))
            }
        )
    }
}

/// A palette shown as a heading, reading text, a cue, and an action together,
/// which is how the colors will be seen, rather than as isolated swatches.
struct PaletteTextPreview: View {
    let palette: InterfacePalette
    let title: String
    let bodyText: String
    let cueTitle: String
    let cueDetail: String
    let actionTitle: String
    let minimumHeight: CGFloat
    var sourceTitle: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            if let sourceTitle {
                HStack(spacing: AppMetrics.snug) {
                    Circle()
                        .fill(palette.accent.swiftUIColor)
                        .frame(width: 9, height: 9)
                    Text(sourceTitle)
                        .appFont(.caption)
                    Spacer(minLength: 0)
                    HStack(spacing: AppMetrics.tight) {
                        ForEach(InterfacePaletteRole.allCases) { role in
                            Circle()
                                .fill(palette[role].swiftUIColor)
                                .frame(width: 12, height: 12)
                                .overlay { Circle().strokeBorder(.separator, lineWidth: 0.5) }
                        }
                    }
                    .accessibilityHidden(true)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppMetrics.compact)
                .padding(.vertical, AppMetrics.snug)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()
            }

            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text(title)
                        .appFont(.title2)
                    Text(bodyText)
                        .appFont(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .center, spacing: AppMetrics.compact) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(palette.accent.swiftUIColor)
                        .frame(width: 8, height: 54)
                    VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                        Text(cueTitle)
                            .appFont(.headline)
                        Text(cueDetail)
                            .appFont(.callout)
                            .opacity(0.82)
                    }
                }

                Text(actionTitle)
                    .appFont(.headline)
                    .foregroundStyle(palette.accentText.swiftUIColor)
                    .padding(.horizontal, AppMetrics.regular)
                    .padding(.vertical, AppMetrics.compact)
                    .background(palette.accent.swiftUIColor, in: RoundedRectangle(cornerRadius: 10))
            }
            .foregroundStyle(palette.text.swiftUIColor)
            .padding(AppMetrics.roomy)
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .topLeading)
            .background(palette.background.swiftUIColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Palette example with text")
        .accessibilityValue(
            "Canvas \(palette.background.hex), body text \(palette.text.hex), accent \(palette.accent.hex), and accent text \(palette.accentText.hex). Heading: \(title). Body: \(bodyText). Cue: \(cueTitle). \(cueDetail). Button: \(actionTitle)."
        )
    }
}

/// Which palette the preview is showing.
private enum PalettePreviewSource: String, CaseIterable, Identifiable {
    case studio
    case light
    case dark
    case recommendation

    var id: Self { self }

    var title: String {
        switch self {
        case .studio: "Studio palette"
        case .light: "Light palette"
        case .dark: "Dark palette"
        case .recommendation: "Model suggestion"
        }
    }

    var symbolName: String {
        switch self {
        case .studio: "paintpalette"
        case .light: "sun.max"
        case .dark: "moon.stars"
        case .recommendation: "sparkles"
        }
    }
}

/// The five stages of the palette studio.
enum PaletteStudioPage: String, CaseIterable, Identifiable, Sendable {
    case design
    case appearances
    case recommend
    case check
    case export

    var id: Self { self }

    var title: String {
        switch self {
        case .design: "Design"
        case .appearances: "Light & Dark"
        case .recommend: "Recommend"
        case .check: "Check"
        case .export: "Export"
        }
    }

    var symbolName: String {
        switch self {
        case .design: "paintpalette"
        case .appearances: "circle.lefthalf.filled"
        case .recommend: "sparkles"
        case .check: "checkmark.shield"
        case .export: "chevron.left.forwardslash.chevron.right"
        }
    }

    var iconMotif: DesignedIconMotif {
        switch self {
        case .design: .swatches
        case .appearances: .split
        case .recommend: .spectrum
        case .check: .compare
        case .export: .path
        }
    }

    var explanation: String {
        switch self {
        case .design: "Assign colors to four jobs and judge them together in a live interface sample."
        case .appearances: "Choose, compare, and test a coordinated palette for each appearance."
        case .recommend: "Ask a selected Ollama model for a starting point, then calculate its named checks."
        case .check: "Review the three specific color relationships this studio can calculate."
        case .export: "Reuse the named roles in code or save the colors for another workspace."
        }
    }
}

/// Whether the appearances page shows light, dark, or both at once.
private enum AppearancePaletteFocus: String, CaseIterable, Identifiable {
    case light
    case dark
    case both

    var id: Self { self }

    var title: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .both: "Compare both"
        }
    }

    var symbolName: String {
        switch self {
        case .light: "sun.max"
        case .dark: "moon.stars"
        case .both: "rectangle.split.2x1"
        }
    }
}

/// One appearance's palette with its relationship results, so light and dark
/// can be judged against each other rather than one after the other.
private struct AppearancePalettePreview: View {
    let title: String
    let palette: InterfacePalette
    let evaluator: InterfacePaletteEvaluator

    private var results: [PaletteRelationshipResult] { evaluator.evaluate(palette) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            HStack {
                Label(title, systemImage: title == "Dark" ? "moon.stars" : "sun.max")
                    .appFont(.headline)
                Spacer()
                Text("\(results.filter(\.passes).count)/\(results.count) checks")
                    .appFont(.value)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                Text("Readable in \(title.lowercased()) mode")
                    .appFont(.title2)
                Text("Body text, repeated cues, and actions are shown together, not as isolated swatches.")
                    .appFont(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Continue")
                    .appFont(.headline)
                    .foregroundStyle(palette.accentText.swiftUIColor)
                    .padding(.horizontal, AppMetrics.regular)
                    .padding(.vertical, AppMetrics.snug)
                    .background(palette.accent.swiftUIColor, in: RoundedRectangle(cornerRadius: 6))
            }
            .foregroundStyle(palette.text.swiftUIColor)
            .padding(AppMetrics.regular)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            .background(palette.background.swiftUIColor, in: RoundedRectangle(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator, lineWidth: 1) }

            ForEach(results) { result in
                HStack(spacing: AppMetrics.snug) {
                    Image(systemName: result.passes ? "checkmark.circle.fill" : "xmark.circle")
                    Text(result.title)
                        .appFont(.callout)
                    Spacer()
                    Text("\(Format.decimal(result.evaluation.ratio, places: 2)):1")
                        .appFont(.value)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(AppMetrics.compact)
        .appSubtleSurface(cornerRadius: 10)
    }
}

private extension InterfacePalettePreset {
    static let lightChoices: [Self] = [.light, .warm, .ocean]
    static let darkChoices: [Self] = [.dark, .midnight, .plum]
}

private extension PaletteGenerationRequest.Purpose {
    static let buildChoices: [Self] = [.interface, .textAndBackground, .decorative]
}

/// One checked relationship with its result and a route into Check.
private struct PaletteRelationshipRow: View {
    let result: PaletteRelationshipResult
    let openInCheck: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppMetrics.regular) {
                colorPair
                description
                Spacer(minLength: 12)
                measurement
                Button("Check details", systemImage: "arrow.right", action: openInCheck)
                    .buttonStyle(.bordered)
                    .appFont(.body)
            }

            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                HStack(alignment: .top, spacing: AppMetrics.compact) {
                    colorPair
                    description
                }
                HStack(spacing: AppMetrics.compact) {
                    measurement
                    Spacer()
                    Button("Check details", systemImage: "arrow.right", action: openInCheck)
                        .buttonStyle(.bordered)
                        .appFont(.body)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var colorPair: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(result.evaluation.background.swiftUIColor)
                .frame(width: 58, height: 58)
            Circle()
                .fill(result.evaluation.foreground.swiftUIColor)
                .frame(width: 28, height: 28)
                .overlay { Circle().stroke(.separator, lineWidth: 1) }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.separator, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Text(result.title)
                .appFont(.headline)
            Text(result.explanation)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 480, alignment: .leading)
        }
    }

    private var measurement: some View {
        VStack(alignment: .trailing, spacing: AppMetrics.tight) {
            Text("\(Format.decimal(result.evaluation.ratio, places: 2)):1")
                .appFont(.title2)
                .monospacedDigit()
                .textSelection(.enabled)
            Label(
                result.passes ? "Meets \(Format.decimal(result.criterion.threshold, places: 1)):1" : "Below \(Format.decimal(result.criterion.threshold, places: 1)):1",
                systemImage: result.passes ? "checkmark.circle.fill" : "xmark.circle"
            )
            .appFont(.callout)
            .foregroundStyle(.primary)
        }
        .frame(minWidth: 116, alignment: .trailing)
        .accessibilityElement(children: .combine)
    }
}
