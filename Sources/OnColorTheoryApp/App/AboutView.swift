import SwiftUI

/// The About window, naming the app, its author, and the terms it is offered
/// under.
///
/// The PolyForm terms call the author line a Required Notice and oblige it to
/// travel with any copy of the software, so it is stated here rather than left
/// to the Finder's package inspector.
///
/// Release notes are a link rather than bundled text. Notes written into the
/// app can only describe the build they shipped in, which means the copy a
/// reader has is always the one version behind whatever they are about to
/// install.
struct AboutView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.roomy) {
            HStack(alignment: .top, spacing: AppMetrics.regular) {
                AppBrandIcon(size: 72)

                VStack(alignment: .leading, spacing: AppMetrics.tight) {
                    Text("On Color Theory")
                        .appFont(.title)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                    Text(AppVersionInfo.display)
                        .appFont(.body)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Text("A workbench for learning how color numbers behave, and for checking the ones you are about to use.")
                .appFont(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: AppMetrics.tight) {
                Text("Coming in a later release")
                    .appFont(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)
                Text("A Brief History of Color, and a Color Theory section.")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                Text(AppVersionInfo.attribution)
                    .appFont(.callout)

                Link(destination: AppVersionInfo.licenseURL) {
                    Label(AppVersionInfo.license, systemImage: "arrow.up.right")
                }
                .appFont(.callout)

                Link(destination: AppVersionInfo.releasesURL) {
                    Label("Releases and version history", systemImage: "arrow.up.right")
                }
                .appFont(.callout)

                Link(destination: AppVersionInfo.repositoryURL) {
                    Label("Source code", systemImage: "arrow.up.right")
                }
                .appFont(.callout)
            }

            Spacer(minLength: 0)

            HStack(spacing: AppMetrics.snug) {
                Button("Walkthrough") {
                    openWindow(id: AppWindowID.walkthrough)
                }
                Button("Help") {
                    openWindow(id: AppWindowID.help)
                }
                Spacer()
            }
            .appFont(.body)
        }
        .padding(AppMetrics.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .textSelection(.enabled)
    }
}
