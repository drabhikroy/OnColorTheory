import SwiftUI

/// The color a workspace uses to identify itself in headings and accents.
///
/// Every section resolves to the palette accent rather than a per-section hue.
/// Seven separate section hues would have to stay distinct from each other and
/// from the five semantic roles at the same time, which no palette survives
/// under a dichromat simulation. Sections are told apart by their name, their
/// icon motif, and their position instead.
struct AppSectionIdentity {
    let primary: Color

    /// Fallback used before a palette reaches the environment.
    static let neutral = AppSectionIdentity(primary: .secondary)

    init(section _: AppSection, palette: AppSemanticPalette) {
        primary = palette.accent
    }

    private init(primary: Color) {
        self.primary = primary
    }
}

/// Carries the current workspace's identity color down the view tree.
private struct AppSectionIdentityKey: EnvironmentKey {
    static let defaultValue = AppSectionIdentity.neutral
}

extension EnvironmentValues {
    var appSectionIdentity: AppSectionIdentity {
        get { self[AppSectionIdentityKey.self] }
        set { self[AppSectionIdentityKey.self] = newValue }
    }
}

/// The surface every workspace sits on, supplying the section identity to
/// everything inside it.
struct WorkspaceCanvas<Content: View>: View {
    let section: AppSection
    private let content: Content

    @Environment(\.appSemanticPalette) private var semanticPalette
    init(section: AppSection, @ViewBuilder content: () -> Content) {
        self.section = section
        self.content = content()
    }

    var body: some View {
        let identity = AppSectionIdentity(section: section, palette: semanticPalette)

        ZStack {
            Color(nsColor: .windowBackgroundColor)
            content
        }
        .environment(\.appSectionIdentity, identity)
        .tint(identity.primary)
    }
}

/// A workspace's heading, naming what the workspace is for.
///
/// The heading is a title and one supporting line, set directly on the page
/// with no surface of its own. The sidebar already names the workspace and
/// shows its icon, so repeating either one here would spend the top of every
/// screen restating the row the reader just clicked.
struct WorkspaceHeader: View {
    let section: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            // The heading is the same question the sidebar and the Home card
            // used. One name for one thing, all the way through: a reader who
            // clicked "Can people actually read this?" should land on a page
            // that says so, rather than on a differently worded title they now
            // have to match up.
            DestinationHeader(title: section.question, summary: section.summary)

            // Every workspace names its first move. A screen that opens with a
            // title and a wall of panels leaves the reader to work out where
            // to begin, and that inference is the point at which someone
            // decides an app is hard to follow.
            Label(section.firstStep, systemImage: "1.circle.fill")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("First step. \(section.firstStep)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The heading for a screen opened from a workspace, such as one lesson or
/// one experiment.
///
/// `context` carries information the title cannot, such as which step of a
/// sequence this is or how many parts a lesson has. It is spoken rather than
/// hidden, because a reader who cannot see the page needs the position in the
/// sequence as much as anyone else. Pass nothing when there is no such fact to
/// give, rather than restating the title in different words.
struct DestinationHeader: View {
    let context: String?
    let title: String
    let summary: String

    init(context: String? = nil, title: String, summary: String) {
        self.context = context
        self.title = title
        self.summary = summary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            if let context {
                Text(context)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .appFont(.title)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)
            Text(summary)
                .appFont(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 640, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // The gap below the title belongs to the header rather than to each
        // page, so every workspace opens with the same rhythm.
        .padding(.bottom, AppMetrics.snug)
        .accessibilityElement(children: .contain)
    }
}

/// A workspace as a button in a rail, carrying its icon and summary.
struct SectionRailButton: View {
    let title: String
    let summary: String
    let symbolName: String
    let motif: DesignedIconMotif
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.appSectionIdentity) private var identity

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AppMetrics.compact) {
                DesignedSymbolIcon(symbolName: symbolName, motif: motif, size: 36)

                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text(title)
                        .appFont(.headline)
                        .foregroundStyle(.primary)
                    Text(summary)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(identity.primary)
                        .accessibilityHidden(true)
                }
            }
            .padding(AppMetrics.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? identity.primary.opacity(0.12) : Color.clear,
                in: RoundedRectangle(cornerRadius: AppMetrics.radiusMedium, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium, style: .continuous)
                    .strokeBorder(
                        isSelected ? identity.primary.opacity(0.45) : Color.clear,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A heading inside a panel, with an optional supporting line.
///
/// There is deliberately no slot for a small uppercased label above the title.
/// Such a label almost always restates the name of the card it sits inside, and
/// a screen full of panels turns that into a second shouted title above every
/// real one. A fact the title cannot carry belongs in `summary`, where it is
/// both readable and audible.
struct PanelHeading: View {
    let title: String
    let summary: String?

    init(title: String, summary: String? = nil) {
        self.title = title
        self.summary = summary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Text(title)
                .appFont(.title2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
            if let summary {
                Text(summary)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// External addresses the app links to.
///
/// Each one is built once here, so a malformed address is a compile error in a
/// single place rather than a crash the first time somebody opens the panel
/// that links to it.
enum AppExternalLinks {
    static let leonardo = URL(string: "https://leonardocolor.io/")!
    static let adobeContrastAnalyzer = URL(string: "https://color.adobe.com/create/color-contrast-analyzer")!
    static let wcagContrastPerspective = URL(string: "https://www.w3.org/WAI/perspectives/contrast.html")!
}
