import AppKit
import SwiftUI

/// The entry screen, offering the workspaces plus anything left unfinished
/// from the previous session.
struct HomeView: View {
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @Environment(\.appSemanticPalette) private var semanticPalette
    @Environment(\.openWindow) private var openWindow

    private var columns: [GridItem] {
        let minimum: CGFloat = textScale >= 1.3 ? 380 : 288
        return [GridItem(.adaptive(minimum: minimum, maximum: 520), spacing: AppMetrics.regular, alignment: .top)]
    }

    var body: some View {
        WorkspaceCanvas(section: .home) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.page) {
                    homeHero
                    if let issue = model.workspaceRecoveryIssue {
                        workspaceRecoveryCard(issue)
                    }
                    if let section = model.resumableSection {
                        resumeWorkspace(section: section)
                    }
                    workspaceChooser
                }
                .frame(maxWidth: 1_120, alignment: .leading)
                .padding(AppMetrics.page)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Home")
        .textSelection(.enabled)
    }

    private func workspaceRecoveryCard(_ issue: WorkspaceSessionRecoveryIssue) -> some View {
        AppCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: AppMetrics.compact) {
                    recoveryMessage(issue)
                    Spacer(minLength: 18)
                    recoveryDismissButton
                }
                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    recoveryMessage(issue)
                    recoveryDismissButton
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func recoveryMessage(_ issue: WorkspaceSessionRecoveryIssue) -> some View {
        HStack(alignment: .top, spacing: AppMetrics.compact) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(semanticPalette.warning)
                .frame(width: 34)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppMetrics.tight) {
                Text("Workspace recovery")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                Text(issue.title)
                    .appFont(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)
                Text(issue.detail)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recoveryDismissButton: some View {
        Button("Dismiss", systemImage: "xmark") {
            model.dismissWorkspaceRecoveryIssue()
        }
        .buttonStyle(.bordered)
        .appFont(.body)
    }

    private func resumeWorkspace(section: AppSection) -> some View {
        let identity = AppSectionIdentity(section: section, palette: semanticPalette)
        let session = model.workspaceSession

        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppMetrics.regular) {
                resumeIdentity(section: section)
                resumeCopy(session: session)
                Spacer(minLength: 18)
                resumeAction(section: section, identity: identity)
            }

            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                HStack(alignment: .top, spacing: AppMetrics.compact) {
                    resumeIdentity(section: section)
                    resumeCopy(session: session)
                }
                resumeAction(section: section, identity: identity)
            }
        }
        .padding(AppMetrics.roomy)
        .background(
            Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: AppMetrics.radiusLarge, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.30), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func resumeIdentity(section: AppSection) -> some View {
        AppSectionIcon(section: section, size: 44)
    }

    private func resumeCopy(session: WorkspaceSession) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Text("Continue where you left off")
                .appFont(.callout)
                .foregroundStyle(.secondary)
            Text(session.resumeTitle)
                .appFont(.title2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
            Text(session.resumeDetail)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 620, alignment: .leading)
    }

    private func resumeAction(
        section: AppSection,
        identity: AppSectionIdentity
    ) -> some View {
        Button("Resume \(section.rawValue)", systemImage: "arrow.right") {
            model.selectedSection = section
        }
        .buttonStyle(.borderedProminent)
        .tint(identity.primary)
        .appFont(.body)
    }

    private var homeHero: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: AppMetrics.section) {
                homeIntroduction
                Spacer(minLength: AppMetrics.roomy)
                currentColorPanel
            }

            VStack(alignment: .leading, spacing: AppMetrics.section) {
                homeIntroduction
                currentColorPanel
            }
        }
    }

    /// The landing block: the app's name, what it is, and how it works.
    ///
    /// The first screen names the app rather than opening on a slogan. Someone
    /// who has just installed something wants confirmation of what they opened
    /// and a sentence saying what it is for, and the version answers the
    /// question a person asks first when reporting a problem.
    private var homeIntroduction: some View {
        HStack(alignment: .top, spacing: AppMetrics.regular) {
            AppBrandIcon(size: 84)
            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text("On Color Theory")
                        .appFont(.largeTitle)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                    Text(AppVersionInfo.display)
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Text("A workbench for learning how color numbers behave, and for checking the ones you are about to use. Convert a color between notations, test whether people can actually read it, build a palette that holds up, and find out why any of it works the way it does.")
                    .appFont(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 600, alignment: .leading)

                Text("One color travels with you. Pick it once, and every workspace picks it up from there.")
                    .appFont(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 600, alignment: .leading)

                HStack(spacing: AppMetrics.snug) {
                    Button("Take the walkthrough") {
                        openWindow(id: AppWindowID.walkthrough)
                    }
                    Button("Help") {
                        openWindow(id: AppWindowID.help)
                    }
                }
                .appFont(.body)
                .padding(.top, AppMetrics.tight)
            }
        }
    }

    private var currentColorPanel: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            HStack(spacing: AppMetrics.compact) {
                ColorSwatchView(color: model.analysis.parsed.color, showsLabel: false)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text("Working color, shown in the sidebar wherever you go")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(model.analysis.parsed.color.hex)
                        .appFont(.title2)
                        .monospacedDigit()
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppMetrics.snug) { currentColorActions }
                VStack(alignment: .leading, spacing: AppMetrics.snug) { currentColorActions }
            }
        }
        .padding(AppMetrics.regular)
        .frame(minWidth: 300, alignment: .leading)
        .background(
            Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: AppMetrics.radiusLarge, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge, style: .continuous)
                .strokeBorder(.separator.opacity(0.30), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var currentColorActions: some View {
        Button("Open Convert", systemImage: AppSection.convert.symbolName) {
            model.selectedSection = .convert
        }
        .buttonStyle(.borderedProminent)
        .appFont(.body)

        Button("Inspect", systemImage: "sidebar.right") {
            model.isInspectorPresented = true
            openWindow(id: AppWindowID.inspector)
        }
        .appFont(.body)
    }

    // Cards are led by the question rather than by the workspace name. A name
    // on its own carries almost no signal about what is behind it, and a
    // reader holding a question has no reason to guess which of six abstract
    // nouns owns it. Leading with the question puts the words they are
    // actually searching for on the card.
    private var workspaceChooser: some View {
        VStack(alignment: .leading, spacing: AppMetrics.section) {
            ForEach(AppSection.Group.allCases) { group in
                VStack(alignment: .leading, spacing: AppMetrics.regular) {
                    PanelHeading(title: group.rawValue)

                    LazyVGrid(columns: columns, alignment: .leading, spacing: AppMetrics.regular) {
                        ForEach(AppSection.allCases.filter { $0.group == group }) { section in
                            WorkspaceCard(section: section) {
                                model.selectedSection = section
                            }
                        }
                    }
                }
            }
        }
    }
}

/// One workspace as a task card, led by the question it answers.
///
/// The whole card is the control. A card that shows a button in one corner
/// gives a small target for something the reader already understands to be
/// clickable, and it reads to VoiceOver as a container plus a button rather
/// than as one choice among six.
private struct WorkspaceCard: View {
    let section: AppSection
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppCard {
                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    HStack(spacing: AppMetrics.compact) {
                        AppSectionIcon(section: section, size: 34)
                        Text(section.rawValue)
                            .appFont(.callout)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }

                    Text(section.question)
                        .appFont(.title2)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(section.summary)
                        .appFont(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: AppMetrics.tight)

                    Label(section.firstStep, systemImage: "arrow.right")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(minHeight: 186, alignment: .topLeading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(section.rawValue). \(section.question)")
        .accessibilityHint("\(section.summary) \(section.firstStep)")
        .accessibilityAddTraits(.isButton)
    }
}
