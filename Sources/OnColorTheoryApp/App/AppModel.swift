import AppKit
import Combine
import SwiftUI

@MainActor
/// The state every workspace shares.
///
/// The working color, the selected section, and the two panel toggles live here
/// rather than in each view, so moving between workspaces carries the color
/// along. Changes write through to the saved session as they happen, which is
/// why the published properties have observers rather than a save call at the
/// end.
final class AppModel: ObservableObject {
    @Published var selectedSection: AppSection? = .home {
        didSet {
            guard let section = selectedSection, section != .home else { return }
            updateWorkspaceSession { session in
                session.lastWorkspaceRawValue = section.rawValue
            }
        }
    }
    @Published var colorInput: String
    @Published var inputNotation: ColorNotationID
    @Published private(set) var analysis: ColorAnalysis
    @Published private(set) var inputError: String?
    @Published var isInspectorPresented = false
    @Published var isTrayPresented = false
    @Published var selectedTrayColorID: UUID?
    @Published var requestedBuildPage: PaletteStudioPage?
    @Published private(set) var workspaceRecoveryIssue: WorkspaceSessionRecoveryIssue?
    @Published var checkForegroundColor: SRGBColor {
        didSet {
            updateWorkspaceSession { $0.checkForegroundColor = checkForegroundColor }
        }
    }
    @Published var checkBackgroundColor: SRGBColor {
        didSet {
            updateWorkspaceSession { $0.checkBackgroundColor = checkBackgroundColor }
        }
    }
    @Published var checkDisplayP3Color: DisplayP3Color {
        didSet {
            updateWorkspaceSession { $0.checkDisplayP3Color = checkDisplayP3Color }
        }
    }
    @Published var selectedCheckAnalysis: CheckAnalysisID {
        didSet {
            updateWorkspaceSession { $0.checkAnalysisRawValue = selectedCheckAnalysis.rawValue }
        }
    }
    /// The saved session.
    ///
    /// This is deliberately not `@Published`. A session write is a side effect
    /// of almost every interaction, and many of those writes originate inside a
    /// SwiftUI update: a `List` selection binding, an `onChange` handler, or a
    /// `didSet` on another published property. Publishing from inside an update
    /// is what produces "Publishing changes from within view updates is not
    /// allowed", and the behavior it warns about is undefined rather than
    /// merely noisy.
    ///
    /// The value itself changes synchronously, so a read straight after a write
    /// sees the new session and two writes in one turn cannot clobber each
    /// other. Only the notification is deferred, and it is coalesced, so a burst
    /// of writes in one turn wakes the views once.
    private(set) var workspaceSession: WorkspaceSession {
        didSet {
            sessionStore.save(workspaceSession)
            scheduleSessionChangeNotification()
        }
    }

    private var hasPendingSessionNotification = false

    let tray: ColorTrayStore
    let ollama: OllamaController
    private let colorCore: ColorCore
    private let sessionStore: WorkspaceSessionStore
    private let defaults: UserDefaults

    init(
        colorCore: ColorCore = ColorCore(),
        tray: ColorTrayStore? = nil,
        sessionStore: WorkspaceSessionStore? = nil,
        ollama: OllamaController? = nil,
        defaults: UserDefaults = .standard,
        initialRepresentation: String = "#C58F63"
    ) {
        let resolvedSessionStore = sessionStore ?? (tray == nil ? .live : .ephemeral())
        let loadResult = resolvedSessionStore.loadResult()
        var restoredSession = loadResult.session
        var recoveryIssue = loadResult.recoveryIssue
        let restoredInput = restoredSession.convertInput
        let initialAnalysis: ColorAnalysis
        if let restoredAnalysis = try? colorCore.analyze(restoredInput) {
            initialAnalysis = restoredAnalysis
        } else if let fallbackAnalysis = try? colorCore.analyze(initialRepresentation) {
            initialAnalysis = fallbackAnalysis
            restoredSession.convertInput = fallbackAnalysis.parsed.originalRepresentation
            recoveryIssue = .invalidWorkingColor
        } else {
            initialAnalysis = colorCore.analyze(
                SRGBColor(red: 197.0 / 255, green: 143.0 / 255, blue: 99.0 / 255),
                as: .hexadecimal
            )
            restoredSession.convertInput = initialAnalysis.parsed.originalRepresentation
            recoveryIssue = .invalidWorkingColor
        }
        self.colorCore = colorCore
        self.sessionStore = resolvedSessionStore
        self.defaults = defaults
        self.workspaceSession = restoredSession
        self.tray = tray ?? ColorTrayStore()
        self.ollama = ollama ?? OllamaController()
        self.colorInput = initialAnalysis.parsed.originalRepresentation
        self.inputNotation = initialAnalysis.parsed.notationID
        self.analysis = initialAnalysis
        self.checkForegroundColor = restoredSession.checkForegroundColor
        self.checkBackgroundColor = restoredSession.checkBackgroundColor
        self.checkDisplayP3Color = restoredSession.checkDisplayP3Color
        self.selectedCheckAnalysis = CheckAnalysisID(rawValue: restoredSession.checkAnalysisRawValue) ?? .contrast
        self.workspaceRecoveryIssue = recoveryIssue
    }

    func updateRepresentation(_ value: String) {
        colorInput = value
        do {
            analysis = try colorCore.analyze(value)
            inputNotation = analysis.parsed.notationID
            inputError = nil
            selectedTrayColorID = nil
            updateWorkspaceSession { session in
                session.convertInput = analysis.parsed.originalRepresentation
            }
        } catch {
            inputError = error.localizedDescription
        }
    }

    func selectInputNotation(_ notation: ColorNotationID) {
        guard notation != inputNotation else { return }
        inputNotation = notation
        let representation: String
        switch notation {
        case .hexadecimal:
            representation = analysis.parsed.color.hex
        case .rgb:
            representation = analysis.parsed.color.cssRGB
        }
        updateRepresentation(representation)
    }

    func updateFromColorPicker(_ color: Color) {
        guard let converted = NSColor(color).usingColorSpace(.sRGB) else { return }
        let value = SRGBColor(
            red: Double(converted.redComponent),
            green: Double(converted.greenComponent),
            blue: Double(converted.blueComponent),
            alpha: Double(converted.alphaComponent)
        )
        let representation = inputNotation == .hexadecimal ? value.hex : value.cssRGB
        updateRepresentation(representation)
    }

    func setWorkingColor(_ color: SRGBColor) {
        let updated = colorCore.analyze(color, as: inputNotation)
        colorInput = updated.parsed.originalRepresentation
        analysis = updated
        inputError = nil
        selectedTrayColorID = nil
        updateWorkspaceSession { session in
            session.convertInput = updated.parsed.originalRepresentation
        }
    }

    func addCurrentColorToTray(conversionTarget: ConversionTargetID = .rgb) {
        let record = ColorRecord(
            label: "Color \(tray.colors.count + 1)",
            originalRepresentation: analysis.parsed.originalRepresentation,
            originalColorSpace: analysis.parsed.colorSpace,
            color: analysis.parsed.color,
            conversionHistory: analysis.stages(for: conversionTarget).map(\.id),
            source: "Convert"
        )
        let stored = tray.add(record)
        selectedTrayColorID = stored.id
        if tray.persistenceError == nil {
            AccessibilityAnnouncer.announce("Saved \(stored.color.hex) to the Color Tray")
        }
    }

    @discardableResult
    func addColorToTray(_ color: SRGBColor, label: String, source: String) -> ColorRecord {
        let record = ColorRecord(
            label: label,
            originalRepresentation: color.opaque.hex,
            originalColorSpace: .sRGB,
            color: color.opaque,
            conversionHistory: [],
            source: source
        )
        let stored = tray.add(record)
        selectedTrayColorID = stored.id
        return stored
    }

    @discardableResult
    func addPaletteToTray(_ palette: InterfacePalette) -> Int {
        let records = InterfacePaletteRole.allCases.map { role in
            addColorToTray(
                palette[role],
                label: role.title,
                source: "Palette Studio"
            )
        }
        return Set(records.map(\.id)).count
    }

    func selectTrayColor(_ record: ColorRecord) {
        selectedTrayColorID = record.id
        if let restored = try? colorCore.analyze(record.originalRepresentation) {
            inputNotation = restored.parsed.notationID
            colorInput = record.originalRepresentation
            analysis = restored
            inputError = nil
        } else {
            let representation = inputNotation == .hexadecimal ? record.color.hex : record.color.cssRGB
            updateRepresentation(representation)
        }
        selectedTrayColorID = record.id
        selectedSection = .convert
        isTrayPresented = false
    }

    func openInConvert(_ color: SRGBColor) {
        inputNotation = .hexadecimal
        updateRepresentation(color.hex)
        selectedSection = .convert
    }

    func openInCheck(
        foreground: SRGBColor,
        background: SRGBColor,
        analysis: CheckAnalysisID = .contrast
    ) {
        checkForegroundColor = foreground.opaque
        checkBackgroundColor = background.opaque
        selectedCheckAnalysis = analysis
        selectedSection = .check
    }

    func openInGamutCheck(_ color: DisplayP3Color) {
        checkDisplayP3Color = color
        selectedCheckAnalysis = .gamut
        selectedSection = .check
    }

    func openBuildRecommendations() {
        updateWorkspaceSession { $0.buildPageRawValue = PaletteStudioPage.recommend.rawValue }
        requestedBuildPage = .recommend
        selectedSection = .build
    }

    var resumableSection: AppSection? {
        guard workspaceSession.hasResumableWork else { return nil }
        return workspaceSession.lastWorkspaceRawValue.flatMap(AppSection.init(rawValue:))
    }

    func updateWorkspaceSession(_ update: (inout WorkspaceSession) -> Void) {
        var next = workspaceSession
        update(&next)
        next.lastUpdatedAt = Date()
        guard next != workspaceSession else { return }
        workspaceSession = next
    }

    /// Wakes observers on the next main-actor turn rather than during the
    /// update that caused the write.
    private func scheduleSessionChangeNotification() {
        guard !hasPendingSessionNotification else { return }
        hasPendingSessionNotification = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.hasPendingSessionNotification = false
            self.objectWillChange.send()
        }
    }

    func clearWorkspaceSession() {
        let currentColor = analysis.parsed.color.opaque
        var fresh = WorkspaceSession()
        fresh.convertInput = currentColor.hex
        fresh.mixingFirstColor = currentColor
        fresh.transparencySourceColor = currentColor
        fresh.checkForegroundColor = checkForegroundColor
        fresh.checkBackgroundColor = checkBackgroundColor
        fresh.checkDisplayP3Color = checkDisplayP3Color
        workspaceSession = fresh
        sessionStore.clear()
        sessionStore.save(fresh)
        AccessibilityAnnouncer.announce("Saved workspace progress cleared")
    }

    @discardableResult
    func resetToDefaults(showInitialWalkthrough: Bool) -> Bool {
        let fresh = WorkspaceSession()
        let defaultAnalysis = colorCore.analyze(
            SRGBColor(red: 197.0 / 255, green: 143.0 / 255, blue: 99.0 / 255),
            as: .hexadecimal
        )

        sessionStore.clear()
        workspaceSession = fresh
        selectedSection = .home
        colorInput = defaultAnalysis.parsed.originalRepresentation
        inputNotation = defaultAnalysis.parsed.notationID
        analysis = defaultAnalysis
        inputError = nil
        selectedTrayColorID = nil
        requestedBuildPage = nil
        workspaceRecoveryIssue = nil
        checkForegroundColor = fresh.checkForegroundColor
        checkBackgroundColor = fresh.checkBackgroundColor
        checkDisplayP3Color = fresh.checkDisplayP3Color
        selectedCheckAnalysis = .contrast
        let trayWasCleared = tray.removeAll()
        ollama.resetPreferences()
        ApplicationDefaults.reset(
            in: defaults,
            showInitialWalkthrough: showInitialWalkthrough && trayWasCleared
        )
        AccessibilityAnnouncer.announce("On Color Theory reset to its defaults")
        return trayWasCleared
    }

    func dismissWorkspaceRecoveryIssue() {
        workspaceRecoveryIssue = nil
        AccessibilityAnnouncer.announce("Workspace recovery notice dismissed")
    }
}
