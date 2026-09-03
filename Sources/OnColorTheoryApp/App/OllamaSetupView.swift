import AppKit
import SwiftUI

/// The optional model setup, walked one step at a time.
struct OllamaSetupView: View {
    @Environment(\.appSemanticPalette) private var palette
    @ObservedObject var model: AppModel
    @ObservedObject var controller: OllamaController
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.appTextScale) private var textScale
    @State private var step: OllamaSetupStep
    @State private var modelToDownload = OllamaSetupModel.recommended.name
    @State private var downloadTask: Task<Void, Never>?
    @State private var modelPendingDeletion: OllamaModelInfo?
    @State private var showsOllamaRemovalConfirmation = false
    @State private var ollamaRemovalMessage: String?
    @FocusState private var focusedField: OllamaSetupField?

    init(
        model: AppModel,
        controller: OllamaController,
        initialStep: OllamaSetupStep = .welcome
    ) {
        self.model = model
        self.controller = controller
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        VStack(spacing: 0) {
            if textScale >= 1.3 {
                compactStepNavigation
                Divider()
                stepScroller
            } else {
                HStack(alignment: .top, spacing: 0) {
                    stepRail
                    Divider()
                    stepScroller
                }
            }

            Divider()
            navigationBar
        }
        .navigationTitle("Model Assist Setup")
        .onDisappear {
            downloadTask?.cancel()
        }
        .onChange(of: step) { _, updatedStep in
            Task { @MainActor in
                await Task.yield()
                switch updatedStep {
                case .connection where controller.connectionMode == .external:
                    focusedField = .serverAddress
                case .model:
                    focusedField = .modelName
                default:
                    focusedField = nil
                }
            }
        }
        .alert("Delete this model?", isPresented: modelDeleteConfirmation, presenting: modelPendingDeletion) { item in
            Button("Delete \(item.name)", role: .destructive) {
                modelPendingDeletion = nil
                Task { await controller.delete(model: item.name) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("This removes \(item.name) from the connected Ollama server and frees its model storage. This cannot be undone from On Color Theory.")
        }
        .alert("Move Ollama to Trash?", isPresented: $showsOllamaRemovalConfirmation) {
            Button("Move to Trash", role: .destructive) { moveOllamaToTrash() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The Ollama app will move to the Trash. Downloaded models and Ollama support files remain until you remove them separately.")
        }
    }

    private var compactStepNavigation: some View {
        HStack(spacing: AppMetrics.compact) {
            VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                Text("Optional model assist")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                Text("Step \(step.index) of \(OllamaSetupStep.allCases.count)")
                    .appFont(.headline)
            }
            Spacer(minLength: 8)
            Picker("Setup step", selection: $step) {
                ForEach(OllamaSetupStep.allCases) { item in
                    Label("\(item.index). \(item.title)", systemImage: item.symbolName)
                        .tag(item)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .padding(.horizontal, AppMetrics.regular)
        .padding(.vertical, AppMetrics.compact)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var stepScroller: some View {
        ScrollView {
            stepContent
                .frame(maxWidth: 660, alignment: .topLeading)
                .padding(textScale >= 1.3 ? 22 : 28)
                .frame(maxWidth: .infinity, alignment: .top)
        }
        .defaultScrollAnchor(.top)
    }

    private var stepRail: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text("Model assist")
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppMetrics.snug)
                .padding(.bottom, AppMetrics.tight)

            ForEach(OllamaSetupStep.allCases) { item in
                Button {
                    step = item
                } label: {
                    HStack(spacing: AppMetrics.snug) {
                        Image(systemName: item.symbolName)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                            Text("Step \(item.index)")
                                .appFont(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.title)
                                .appFont(.body)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(AppMetrics.snug)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        step == item ? palette.accent.opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(step == item ? .isSelected : [])
            }

            Spacer(minLength: 12)
            Label("Entirely optional", systemImage: "info.circle")
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .padding(AppMetrics.snug)
        }
        .padding(AppMetrics.compact)
        .frame(width: 194)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            welcomeStep
        case .connection:
            connectionStep
        case .install:
            installStep
        case .model:
            modelStep
        case .finish:
            finishStep
        }
    }

    private var welcomeStep: some View {
        setupPage(
            stepLabel: "Step 1 of 5",
            title: "Decide whether Ollama is useful to you",
            summary: "Ollama is optional. On Color Theory can design, convert, check, compare, and export colors without it. Turning it on only adds model-written palette starting points in Build → Recommend."
        ) {
            Toggle("Use optional Ollama suggestions", isOn: $controller.isEnabled)
                .appFont(.headline)
                .onChange(of: controller.isEnabled) { _, enabled in
                    guard enabled else { return }
                    Task { await controller.refresh() }
                }

            setupCallout(
                symbol: "checkmark.shield",
                title: "What the model does and does not do",
                detail: "It proposes four colors and explains each choice in accessible, natural language. On Color Theory independently calculates contrast, color conversions, gamut, differences, and simulations. Model output is never treated as a measurement."
            )

            setupCallout(
                symbol: "internaldrive",
                title: "Storage and privacy",
                detail: "Local models can occupy several gigabytes. With the on-this-Mac option, prompts stay on this Mac; an external server receives the design brief and current palette values."
            )
        }
    }

    private var connectionStep: some View {
        setupPage(
            stepLabel: "Step 2 of 5",
            title: "Choose where Ollama runs",
            summary: "Most people should start on this Mac. The external option is for an Ollama server you already operate."
        ) {
            Picker("Ollama connection", selection: $controller.connectionMode) {
                ForEach(OllamaConnectionMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if controller.connectionMode == .guidedLocal {
                setupCallout(
                    symbol: "desktopcomputer",
                    title: "On this Mac",
                    detail: "On Color Theory connects only to 127.0.0.1:11434. Install and launch the official Ollama app, then return here to check the connection."
                )
            } else {
                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("Ollama server address")
                        .appFont(.headline)
                    TextField("https://server.example", text: $controller.externalAddress)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .serverAddress)
                        .onSubmit { Task { await controller.refresh() } }
                    Label(
                        "Prompts, current palette values, and model output are sent to this address. Prefer HTTPS outside a trusted local network.",
                        systemImage: "network"
                    )
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    Label(
                        controller.externalConnectionUsesTLS
                            ? "The configured address uses HTTPS. The server still controls storage, access, and model behavior."
                            : "HTTP works only with localhost or a private local-network address. Use a verified HTTPS endpoint for every remote server.",
                        systemImage: controller.externalConnectionUsesTLS ? "lock.fill" : "lock.open.trianglebadge.exclamationmark"
                    )
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            connectionStatus
        }
    }

    private var installStep: some View {
        setupPage(
            stepLabel: "Step 3 of 5",
            title: controller.connectionMode == .guidedLocal ? "Install and start Ollama" : "Connect to your server",
            summary: controller.connectionMode == .guidedLocal
                ? "The official macOS app is the simplest install path. Ollama requires macOS 14 or newer."
                : "On Color Theory does not change or administer an external Ollama server. Enter its address, then verify that its API is reachable."
        ) {
            if controller.connectionMode == .guidedLocal {
                systemSummary

                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    numberedInstruction(1, "Open the official Ollama download page and download the macOS disk image.")
                    numberedInstruction(2, "Open the disk image, drag Ollama to Applications, then launch Ollama.")
                    numberedInstruction(3, "Allow Ollama to add its command-line link if you want terminal access. On Color Theory itself uses the local API.")
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppMetrics.snug) { installActions }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) { installActions }
                }

                Label(
                    localOllamaURL == nil
                        ? "Ollama.app is not currently visible in Applications. You can still check the connection if it is installed elsewhere."
                        : "Ollama.app was found in Applications.",
                    systemImage: localOllamaURL == nil ? "app.dashed" : "checkmark.circle.fill"
                )
                .appFont(.callout)
                .foregroundStyle(.secondary)

                if let ollamaRemovalMessage {
                    Label(ollamaRemovalMessage, systemImage: "info.circle")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            connectionStatus
        }
    }

    @ViewBuilder
    private var installActions: some View {
        Link(destination: URL(string: "https://ollama.com/download/mac")!) {
            Label("Download Ollama", systemImage: "arrow.down.circle")
        }
        .buttonStyle(.borderedProminent)

        Button("Launch Ollama", systemImage: "play.fill") {
            guard let localOllamaURL else { return }
            NSWorkspace.shared.open(localOllamaURL)
        }
        .disabled(localOllamaURL == nil)

        Button("Move Ollama to Trash", systemImage: "trash", role: .destructive) {
            showsOllamaRemovalConfirmation = true
        }
        .disabled(localOllamaURL == nil)

        Link("Official macOS instructions", destination: URL(string: "https://docs.ollama.com/macos")!)
    }

    private var modelStep: some View {
        setupPage(
            stepLabel: "Step 4 of 5",
            title: "Choose a model that fits this Mac",
            summary: "Start smaller when unsure. The recommendation below is a conservative memory-based starting point, not a promise about speed; model downloads and working memory both matter."
        ) {
            if controller.connectionMode == .guidedLocal {
                systemSummary

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("Suggested starting points")
                        .appFont(.headline)

                    ForEach(OllamaSetupModel.catalog) { item in
                        Button {
                            modelToDownload = item.name
                        } label: {
                            HStack(alignment: .top, spacing: AppMetrics.compact) {
                                Image(systemName: modelToDownload == item.name ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(modelToDownload == item.name ? palette.accent : Color.secondary)
                                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                                    HStack(spacing: AppMetrics.snug) {
                                        Text(item.title)
                                            .appFont(.headline)
                                        if item.name == OllamaSetupModel.recommended.name {
                                            Text("Recommended here")
                                                .appFont(.caption)
                                                .padding(.horizontal, AppMetrics.tight)
                                                .padding(.vertical, AppMetrics.hairline)
                                                .background(palette.accent.opacity(0.12), in: Capsule())
                                        }
                                    }
                                    Text("\(item.name) · about \(item.downloadSize) · \(item.detail)")
                                        .appFont(.callout)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(AppMetrics.compact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                modelToDownload == item.name ? palette.accent.opacity(0.08) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator, lineWidth: 1) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                setupCallout(
                    symbol: "server.rack",
                    title: "Choose for the server, not this Mac",
                    detail: "On Color Theory cannot inspect the external server’s memory or processor. Ask its administrator which model size fits, then select an installed model below or enter an approved model name."
                )
            }

            if !controller.installedModels.isEmpty {
                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Text("Installed models")
                        .appFont(.headline)
                    ForEach(controller.installedModels) { item in
                        installedModelRow(item)
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                Text("Model name")
                    .appFont(.headline)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppMetrics.snug) { modelDownloadControls }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) { modelDownloadControls }
                }
                Text("Downloads may be several gigabytes and can take several minutes. Leave Ollama running until the download completes.")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            connectionStatus
            Link("Browse the Ollama model library", destination: URL(string: "https://ollama.com/search")!)
        }
    }

    @ViewBuilder
    private var modelDownloadControls: some View {
        TextField("qwen3:4b", text: $modelToDownload)
            .textFieldStyle(.roundedBorder)
            .frame(minWidth: 220)
            .focused($focusedField, equals: .modelName)
            .onSubmit { startModelDownload() }
        if controller.connectionState.isPulling {
            Button("Cancel download", systemImage: "xmark") {
                downloadTask?.cancel()
            }
        } else {
            Button("Download model") {
                startModelDownload()
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                controller.connectionState.isBusy
                    || modelToDownload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }

    private var finishStep: some View {
        setupPage(
            stepLabel: "Step 5 of 5",
            title: "Use the model in Build",
            summary: "Setup is complete once Ollama is reachable, a model is installed and selected, and optional suggestions are on."
        ) {
            setupCallout(
                symbol: controller.isEnabled ? "checkmark.circle.fill" : "pause.circle",
                title: controller.isEnabled ? "Ollama suggestions are on" : "Ollama suggestions remain off",
                detail: controller.isEnabled
                    ? "Selected model: \(controller.selectedModel.isEmpty ? "none yet" : controller.selectedModel). Connection: \(controller.connectionMode.title.lowercased())."
                    : "Nothing else in On Color Theory is disabled. Return to Step 1 whenever you want to opt in."
            )

            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                Text("How to apply a model suggestion")
                    .appFont(.title2)
                numberedInstruction(1, "Open Build and choose Recommend.")
                numberedInstruction(2, "Describe the interface and choose a palette purpose, then generate a suggestion.")
                numberedInstruction(3, "Edit the heading, body text, cue heading, cue detail, and button label above the preview to test your own copy.")
                numberedInstruction(4, "Review the model’s explanation and On Color Theory’s independently calculated checks.")
                numberedInstruction(5, "Choose Use this palette, adjust it in Design or Light & Dark, then export it.")
            }

            Button {
                model.openBuildRecommendations()
                openWindow(id: AppWindowID.main)
                dismissWindow(id: AppWindowID.ollamaSetup)
            } label: {
                Label("Open Build recommendations", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!controller.isEnabled || controller.selectedModel.isEmpty)

            Label(
                "You can turn model suggestions off at any time. Return to the Model step to select or delete installed models.",
                systemImage: "info.circle"
            )
            .appFont(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var connectionStatus: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack(spacing: AppMetrics.snug) {
                if controller.connectionState.isBusy {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: statusSymbol)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text(controller.statusTitle)
                        .appFont(.headline)
                    if let progress = controller.pullProgress {
                        if let fraction = progress.fraction {
                            ProgressView(value: fraction)
                                .frame(maxWidth: 240)
                            Text("\(progress.status) · \(Int((fraction * 100).rounded()))%")
                                .appFont(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(progress.status)
                                .appFont(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let detail = controller.statusDetail {
                        Text(detail)
                            .appFont(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                Button("Check connection") {
                    controller.isEnabled = true
                    Task { await controller.refresh() }
                }
                .disabled(controller.connectionState.isBusy)
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        .padding(AppMetrics.compact)
        .appSubtleSurface(cornerRadius: 10)
    }

    private var systemSummary: some View {
        let profile = OllamaSystemProfile.current
        return HStack(alignment: .top, spacing: AppMetrics.compact) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                Text("This Mac: \(profile.architecture) · \(profile.memoryGB) GB memory")
                    .appFont(.headline)
                Text(profile.note)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppMetrics.compact)
        .appSubtleSurface(cornerRadius: 10)
    }

    private var navigationBar: some View {
        HStack(spacing: AppMetrics.snug) {
            Button("Close") {
                dismissWindow(id: AppWindowID.ollamaSetup)
            }
            .keyboardShortcut(.cancelAction)
            Spacer()
            Button("Back") {
                step = step.previous
            }
            .disabled(step == .welcome)
            .keyboardShortcut("[", modifiers: .command)
            Button(step == .finish ? "Done" : "Continue") {
                if step == .finish {
                    dismissWindow(id: AppWindowID.ollamaSetup)
                } else {
                    step = step.next
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, AppMetrics.regular)
        .padding(.vertical, AppMetrics.compact)
    }

    private func setupPage<Content: View>(
        stepLabel: String,
        title: String,
        summary: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.roomy) {
            DestinationHeader(
                context: stepLabel,
                title: title,
                summary: summary
            )
            content()
        }
    }

    private func setupCallout(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppMetrics.compact) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: AppMetrics.tight) {
                Text(title)
                    .appFont(.headline)
                Text(detail)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }

    private func numberedInstruction(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: AppMetrics.compact) {
            Text("\(number)")
                .appFont(.headline)
                .frame(width: 28, height: 28)
                .background(palette.accent.opacity(0.12), in: Circle())
            Text(text)
                .appFont(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppMetrics.hairline)
        }
    }

    private var localOllamaURL: URL? {
        LocalOllamaAssets.applicationURL()
    }

    private var statusSymbol: String {
        switch controller.connectionState {
        case .ready: "checkmark.circle.fill"
        case .unavailable: "exclamationmark.triangle"
        default: "circle.dotted"
        }
    }

    private func startModelDownload() {
        guard !controller.connectionState.isBusy else { return }
        controller.isEnabled = true
        downloadTask?.cancel()
        downloadTask = Task { await controller.pull(model: modelToDownload) }
    }

    private func installedModelRow(_ item: OllamaModelInfo) -> some View {
        HStack(alignment: .center, spacing: AppMetrics.compact) {
            Button {
                controller.selectedModel = item.name
            } label: {
                HStack(alignment: .top, spacing: AppMetrics.snug) {
                    Image(systemName: controller.selectedModel == item.name ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(controller.selectedModel == item.name ? palette.accent : Color.secondary)
                    VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                        Text(item.name)
                            .appFont(.headline)
                        Text(modelDetail(item))
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button("Delete \(item.name)", systemImage: "trash", role: .destructive) {
                modelPendingDeletion = item
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .disabled(controller.connectionState.isBusy)
            .help("Delete \(item.name) from Ollama")
        }
        .padding(AppMetrics.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSubtleSurface(cornerRadius: 10)
    }

    private func modelDetail(_ item: OllamaModelInfo) -> String {
        var parts: [String] = []
        if let detail = item.detail { parts.append(detail) }
        if let size = item.size {
            parts.append(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
        }
        return parts.isEmpty ? "Installed" : parts.joined(separator: " · ")
    }

    private var modelDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { modelPendingDeletion != nil },
            set: { if !$0 { modelPendingDeletion = nil } }
        )
    }

    private func moveOllamaToTrash() {
        guard let localOllamaURL else { return }
        Task {
            do {
                try await LocalOllamaAssets.moveToTrash(localOllamaURL)
                controller.isEnabled = false
                ollamaRemovalMessage = "Ollama was moved to the Trash. Its models and support files were left in place."
            } catch {
                ollamaRemovalMessage = "Ollama could not be moved to the Trash: \(error.localizedDescription)"
            }
        }
    }
}

/// The setup steps, in order.
enum OllamaSetupStep: String, CaseIterable, Identifiable {
    case welcome
    case connection
    case install
    case model
    case finish

    var id: Self { self }
    var index: Int { Self.allCases.firstIndex(of: self)! + 1 }
    var next: Self { Self.allCases[min(index, Self.allCases.count - 1)] }
    var previous: Self { Self.allCases[max(index - 2, 0)] }

    var title: String {
        switch self {
        case .welcome: "Optional feature"
        case .connection: "Connection"
        case .install: "Install"
        case .model: "Choose model"
        case .finish: "Use it"
        }
    }

    var symbolName: String {
        switch self {
        case .welcome: "sparkles"
        case .connection: "network"
        case .install: "arrow.down.app"
        case .model: "cpu"
        case .finish: "checkmark.circle"
        }
    }
}

/// Focusable fields in the setup, so focus can be moved between steps.
private enum OllamaSetupField: Hashable {
    case serverAddress
    case modelName
}

/// One offered model with its size and what it is suited to.
private struct OllamaSetupModel: Identifiable {
    let name: String
    let title: String
    let downloadSize: String
    let detail: String
    var id: String { name }

    static let catalog = [
        OllamaSetupModel(name: "qwen3:4b", title: "Qwen 3 · 4B", downloadSize: "2.5 GB", detail: "smallest, best first try"),
        OllamaSetupModel(name: "qwen3:8b", title: "Qwen 3 · 8B", downloadSize: "5.2 GB", detail: "balanced on a Mac with more memory"),
        OllamaSetupModel(name: "qwen3:14b", title: "Qwen 3 · 14B", downloadSize: "9.3 GB", detail: "larger and slower, with more memory demand")
    ]

    static var recommended: Self {
        let memoryGB = OllamaSystemProfile.current.memoryGB
        if memoryGB >= 28 { return catalog[2] }
        if memoryGB >= 16 { return catalog[1] }
        return catalog[0]
    }
}

/// This Mac's architecture and memory, read so the recommended model is
/// sized to the machine.
///
/// The recommendation is a conservative starting point based on memory. It is
/// not a promise about speed, and the interface says so.
private struct OllamaSystemProfile {
    let architecture: String
    let memoryGB: Int

    static var current: Self {
        #if arch(arm64)
        let architecture = "Apple silicon"
        #else
        let architecture = "Intel"
        #endif
        let bytes = ProcessInfo.processInfo.physicalMemory
        let gigabytes = max(1, Int((Double(bytes) / 1_073_741_824).rounded()))
        return Self(architecture: architecture, memoryGB: gigabytes)
    }

    var note: String {
        if architecture == "Intel" {
            return "Ollama runs models on the CPU on Intel Macs, so begin with the 4B option and expect lower speed."
        }
        if memoryGB >= 28 {
            return "The 14B option is a reasonable starting point; use 8B if you prefer a smaller, faster download."
        }
        if memoryGB >= 16 {
            return "The 8B option is a balanced starting point; use 4B if you prefer lower memory use."
        }
        return "Begin with the 4B option to limit memory and storage demands."
    }
}
