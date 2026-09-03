import Combine
import Foundation

@MainActor
/// The colors a person has set aside, in the order they added them.
final class ColorTrayStore: ObservableObject {
    private static let maximumStoredBytes: UInt64 = 5 * 1_024 * 1_024
    @Published private(set) var colors: [ColorRecord]
    @Published private(set) var persistenceError: String?

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
        self.colors = []
        self.persistenceError = nil
        load()
    }

    @discardableResult
    func add(_ record: ColorRecord) -> ColorRecord {
        if let existing = colors.first(where: {
            $0.color == record.color && $0.originalColorSpace == record.originalColorSpace
        }) {
            return existing
        }
        colors.insert(record, at: 0)
        persist()
        return record
    }

    func remove(id: UUID) {
        colors.removeAll { $0.id == id }
        persist()
    }

    @discardableResult
    func removeAll() -> Bool {
        colors.removeAll()
        persist()
        return persistenceError == nil
    }

    func toggleLock(id: UUID) {
        guard let index = colors.firstIndex(where: { $0.id == id }) else { return }
        colors[index].isLocked.toggle()
        persist()
    }

    func dismissPersistenceError() {
        persistenceError = nil
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let storedBytes = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
            guard storedBytes <= Self.maximumStoredBytes else {
                throw CocoaError(.fileReadTooLarge)
            }
            let data = try Data(contentsOf: fileURL)
            colors = try decoder.decode([ColorRecord].self, from: data)
        } catch {
            // Preserve the unreadable file for recovery; begin with an empty in-memory tray.
            colors = []
            persistenceError = "The saved Color Tray could not be read. Its file was left unchanged."
        }
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(colors)
            try data.write(to: fileURL, options: .atomic)
            persistenceError = nil
        } catch {
            persistenceError = "Changes could not be saved. The current colors remain available until the app closes."
            AccessibilityAnnouncer.announce(persistenceError!, priority: .high)
        }
    }

    private static func defaultFileURL() -> URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return applicationSupport
            .appendingPathComponent("On Color Theory", isDirectory: true)
            .appendingPathComponent("color-tray.json", isDirectory: false)
    }
}
