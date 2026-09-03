import Foundation

/// Everything restored when the app reopens.
///
/// Fields are stored by raw value rather than by case, so a session written by
/// an older build still decodes when a case is added.
struct WorkspaceSession: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 2

    var schemaVersion = Self.currentSchemaVersion
    var lastWorkspaceRawValue: String?
    var lastUpdatedAt: Date?

    var convertInput = "#C58F63"
    var convertRepresentationRawValue = "RGB"
    var convertStageIndex = 0
    var convertStagePageRawValue = "meaning"
    var convertCodeLanguageRawValue = "CSS"

    var learnLessonRawValue: String?
    var learnPartIndices: [String: Int] = [:]
    var learnRelationshipExampleRawValue = "Different hue, similar lightness"
    var learnSurroundLevel = 232.0 / 255.0

    var exploreExperimentRawValue: String?
    var mixingFirstColor = SRGBColor(red: 197.0 / 255, green: 143.0 / 255, blue: 99.0 / 255)
    var mixingSecondColor = SRGBColor(red: 0.10, green: 0.24, blue: 0.42)
    var mixingPosition = 0.5
    var mixingPredictionRawValue: String?
    var mixingHasRevealed = false
    var transparencySourceColor = SRGBColor(red: 197.0 / 255, green: 143.0 / 255, blue: 99.0 / 255)
    var transparencyOpacity = 0.55
    var transparencyBackdropRawValue = "Light and dark"
    var transparencyPredictionRawValue: String?
    var transparencyHasRevealed = false

    var buildPalette = InterfacePalettePreset.light.palette
    var buildLightPalette: InterfacePalette?
    var buildDarkPalette: InterfacePalette?
    var buildPageRawValue = "design"
    var buildExportLanguageRawValue = "CSS"
    var buildPreviewCopy: PalettePreviewCopy?

    var checkAnalysisRawValue = "contrast"
    var checkPageRawValue = "results"
    var checkForegroundColor = SRGBColor(red: 197.0 / 255, green: 143.0 / 255, blue: 99.0 / 255)
    var checkBackgroundColor = SRGBColor(red: 1, green: 1, blue: 1)
    var checkDisplayP3Color = DisplayP3Color(red: 1, green: 0.2, blue: 0.1)

    var referenceQuery = ""
    var referenceTopicRawValue: String?
    var referenceConceptID: String?

    var hasResumableWork: Bool {
        lastWorkspaceRawValue.flatMap(AppSection.init(rawValue:)) != nil
    }

    var resumeTitle: String {
        guard let section = lastWorkspaceRawValue.flatMap(AppSection.init(rawValue:)) else {
            return "Choose a workspace"
        }

        switch section {
        case .learn:
            return learnLessonRawValue
                .flatMap(LearningLessonID.init(rawValue:))?.title
                ?? "Browse the learning paths"
        case .explore:
            return exploreExperimentRawValue
                .flatMap(ExploreExperimentID.init(rawValue:))?.title
                ?? "Choose an experiment"
        case .convert:
            return "Continue with \(convertRepresentationRawValue)"
        case .build:
            return "Continue in \(buildPageRawValue.capitalized)"
        case .check:
            return CheckAnalysisID(rawValue: checkAnalysisRawValue)?.title
                ?? "Continue a color check"
        case .reference:
            if let conceptID = referenceConceptID,
               let concept = ReferenceCatalog.concepts.first(where: { $0.id == conceptID }) {
                return concept.term
            }
            if let topic = referenceTopicRawValue.flatMap(ReferenceTopicID.init(rawValue:)) {
                return topic.title
            }
            return referenceQuery.isEmpty ? "Browse the field guide" : "Continue searching"
        case .home:
            return "Choose a workspace"
        }
    }

    var resumeDetail: String {
        guard let section = lastWorkspaceRawValue.flatMap(AppSection.init(rawValue:)) else {
            return "Your working color and saved tray remain available."
        }

        switch section {
        case .learn:
            guard let lesson = learnLessonRawValue.flatMap(LearningLessonID.init(rawValue:)) else {
                return "The lesson library is ready."
            }
            let part = min(max(learnPartIndices[lesson.rawValue] ?? 0, 0), 2) + 1
            return "Part \(part) of 3 is ready to resume."
        case .explore:
            return exploreExperimentRawValue == nil
                ? "The experiment gallery is ready."
                : "Your inputs and observation state are preserved."
        case .convert:
            return "\(convertInput) · stage \(convertStageIndex + 1)"
        case .build:
            return "Your palette roles, preview copy, and export choice are preserved."
        case .check:
            return "Your selected diagnostic and working colors are preserved."
        case .reference:
            return referenceQuery.isEmpty
                ? "Return to the same topic or term."
                : "Search: “\(referenceQuery)”"
        case .home:
            return "Your working color and saved tray remain available."
        }
    }
}

/// What went wrong reading a saved session, in terms a person can act on.
enum WorkspaceSessionRecoveryIssue: Equatable, Sendable {
    case unreadableSavedState
    case newerSavedState(version: Int)
    case invalidWorkingColor

    var title: String {
        switch self {
        case .unreadableSavedState: "Saved workspace could not be read"
        case .newerSavedState: "Saved workspace came from a newer version"
        case .invalidWorkingColor: "Saved working color was invalid"
        }
    }

    var detail: String {
        switch self {
        case .unreadableSavedState:
            "On Color Theory opened a fresh workspace instead of repeatedly failing. A copy of the unreadable saved data was retained locally for diagnosis."
        case let .newerSavedState(version):
            "The saved workspace uses schema \(version), which this build does not understand. A local recovery copy was retained and a fresh workspace was opened."
        case .invalidWorkingColor:
            "The rest of the saved workspace was kept, but its working color could not be analyzed. On Color Theory restored the default working color instead."
        }
    }
}

/// A loaded session together with any problem found while reading it.
struct WorkspaceSessionLoadResult: Equatable, Sendable {
    let session: WorkspaceSession
    let recoveryIssue: WorkspaceSessionRecoveryIssue?
    let migratedFromVersion: Int?
}

/// Reads and writes the saved session.
///
/// A session that cannot be read is replaced with defaults and reported rather
/// than thrown, because losing the previous state is a smaller cost than
/// refusing to open.
final class WorkspaceSessionStore: @unchecked Sendable {
    static let live = WorkspaceSessionStore()
    private static let maximumStoredBytes = 2 * 1_024 * 1_024

    private let defaults: UserDefaults?
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let inMemoryLock = NSLock()
    private var inMemorySession: WorkspaceSession?

    init(
        defaults: UserDefaults = .standard,
        key: String = "onColorTheory.workspaceSession.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    private init(inMemorySession: WorkspaceSession) {
        self.defaults = nil
        self.key = ""
        self.inMemorySession = inMemorySession
    }

    static func ephemeral(
        initialSession: WorkspaceSession = WorkspaceSession()
    ) -> WorkspaceSessionStore {
        WorkspaceSessionStore(inMemorySession: initialSession)
    }

    func load() -> WorkspaceSession {
        loadResult().session
    }

    func loadResult() -> WorkspaceSessionLoadResult {
        guard let defaults else {
            inMemoryLock.lock()
            defer { inMemoryLock.unlock() }
            let stored = inMemorySession ?? WorkspaceSession()
            let result = migrate(stored)
            inMemorySession = result.session
            return result
        }

        guard let data = defaults.data(forKey: key) else {
            return WorkspaceSessionLoadResult(
                session: WorkspaceSession(),
                recoveryIssue: nil,
                migratedFromVersion: nil
            )
        }
        guard data.count <= Self.maximumStoredBytes else {
            let result = WorkspaceSessionLoadResult(
                session: WorkspaceSession(),
                recoveryIssue: .unreadableSavedState,
                migratedFromVersion: nil
            )
            save(result.session)
            return result
        }
        guard let session = try? decoder.decode(WorkspaceSession.self, from: data) else {
            preserveRecoveryCopy(data, defaults: defaults)
            let result = WorkspaceSessionLoadResult(
                session: WorkspaceSession(),
                recoveryIssue: .unreadableSavedState,
                migratedFromVersion: nil
            )
            save(result.session)
            return result
        }

        let result = migrate(session)
        if result.recoveryIssue != nil {
            preserveRecoveryCopy(data, defaults: defaults)
            save(result.session)
        } else if result.migratedFromVersion != nil {
            save(result.session)
        }
        return result
    }

    func save(_ session: WorkspaceSession) {
        guard let defaults else {
            inMemoryLock.lock()
            defer { inMemoryLock.unlock() }
            inMemorySession = session
            return
        }
        guard let data = try? encoder.encode(session) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        if let defaults {
            defaults.removeObject(forKey: key)
            defaults.removeObject(forKey: recoveryKey)
        } else {
            inMemoryLock.lock()
            defer { inMemoryLock.unlock() }
            inMemorySession = nil
        }
    }

    var hasRecoveryCopy: Bool {
        defaults?.data(forKey: recoveryKey) != nil
    }

    private var recoveryKey: String { key + ".recovery" }

    private func migrate(_ stored: WorkspaceSession) -> WorkspaceSessionLoadResult {
        if stored.schemaVersion == WorkspaceSession.currentSchemaVersion {
            return WorkspaceSessionLoadResult(
                session: stored,
                recoveryIssue: nil,
                migratedFromVersion: nil
            )
        }
        if stored.schemaVersion > WorkspaceSession.currentSchemaVersion {
            return WorkspaceSessionLoadResult(
                session: WorkspaceSession(),
                recoveryIssue: .newerSavedState(version: stored.schemaVersion),
                migratedFromVersion: nil
            )
        }
        guard stored.schemaVersion == 1 else {
            return WorkspaceSessionLoadResult(
                session: WorkspaceSession(),
                recoveryIssue: .unreadableSavedState,
                migratedFromVersion: nil
            )
        }

        var migrated = stored
        migrated.schemaVersion = WorkspaceSession.currentSchemaVersion
        migrated.buildLightPalette = migrated.buildLightPalette ?? InterfacePalettePreset.light.palette
        migrated.buildDarkPalette = migrated.buildDarkPalette ?? InterfacePalettePreset.dark.palette
        return WorkspaceSessionLoadResult(
            session: migrated,
            recoveryIssue: nil,
            migratedFromVersion: stored.schemaVersion
        )
    }

    private func preserveRecoveryCopy(_ data: Data, defaults: UserDefaults) {
        defaults.set(data, forKey: recoveryKey)
    }
}
