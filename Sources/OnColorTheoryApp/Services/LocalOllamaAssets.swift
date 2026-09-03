import AppKit
import Foundation

/// Where the managed runtime and its downloads live on disk.
enum LocalOllamaAssets {
    static func applicationURL(fileManager: FileManager = .default) -> URL? {
        applicationCandidates.first { fileManager.fileExists(atPath: $0.path) }
    }

    static func modelDirectoryURL(fileManager: FileManager = .default) -> URL? {
        let url = modelDirectoryCandidate(homeDirectory: fileManager.homeDirectoryForCurrentUser)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    static func modelDirectoryCandidate(homeDirectory: URL) -> URL {
        homeDirectory
            .appendingPathComponent(".ollama", isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)
    }

    @MainActor
    static func moveToTrash(_ url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.recycle([url]) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    static var applicationCandidates: [URL] {
        [
            URL(fileURLWithPath: "/Applications/Ollama.app", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
                .appendingPathComponent("Ollama.app", isDirectory: true)
        ]
    }
}
