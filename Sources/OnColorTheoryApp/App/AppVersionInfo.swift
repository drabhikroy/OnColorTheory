import Foundation

/// Reads the version and build from the bundle for display, and holds the
/// author and license lines that go with them.
///
/// The three strings sit together because they are always shown together, and
/// because a license notice that lives in one view is a license notice that
/// gets missed when a second view needs one.
enum AppVersionInfo {
    static let fallbackShortVersion = "1.0.0"
    static let fallbackBuild = "1"

    /// The author line. The PolyForm terms call this a Required Notice, and it
    /// has to travel with any copy of the software.
    static let attribution = "Copyright 2026 Abhik Roy"

    static let license = "Licensed under the PolyForm Noncommercial License 1.0.0"

    static let licenseURL = URL(string: "https://polyformproject.org/licenses/noncommercial/1.0.0")!

    /// Where releases are published. The About window links here rather than
    /// carrying its own change log, so the notes have one home.
    static let releasesURL = URL(string: "https://github.com/drabhikroy/OnColorTheory/releases")!

    static let repositoryURL = URL(string: "https://github.com/drabhikroy/OnColorTheory")!

    static var display: String {
        display(bundle: .main)
    }

    static func display(bundle: Bundle) -> String {
        let shortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? fallbackShortVersion
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? fallbackBuild
        return formatted(shortVersion: shortVersion, build: build)
    }

    static func formatted(shortVersion: String, build: String) -> String {
        "Version \(shortVersion) (\(build))"
    }
}
