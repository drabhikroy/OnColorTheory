import SwiftUI

/// The bounded experiments, keyed by slug.
enum ExploreExperimentID: String, CaseIterable, Identifiable, Sendable {
    case mixingLight = "mixing-light"
    case transparency = "transparency"

    var id: Self { self }

    var title: String {
        switch self {
        case .mixingLight: "Mixing colored light"
        case .transparency: "How a backdrop changes transparency"
        }
    }

    var summary: String {
        switch self {
        case .mixingLight:
            "Compare two ways of calculating the colors between the same endpoints."
        case .transparency:
            "Place one partly transparent source over two backdrops and inspect both visible results."
        }
    }

    var focus: String {
        switch self {
        case .mixingLight: "INTERPOLATION"
        case .transparency: "COMPOSITING"
        }
    }

    var actionTitle: String {
        switch self {
        case .mixingLight: "Compare mixing methods"
        case .transparency: "Try two backdrops"
        }
    }
}

/// The experiment library and the shell that presents one experiment.
struct ExploreView: View {
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var selectedExperimentID: ExploreExperimentID?
    private let initiallyShowsMixComparison: Bool

    init(
        model: AppModel,
        initialExperiment: ExploreExperimentID? = nil,
        showsComparison: Bool = false
    ) {
        self.model = model
        self.initiallyShowsMixComparison = showsComparison
        let restoredExperiment = model.workspaceSession.exploreExperimentRawValue
            .flatMap(ExploreExperimentID.init(rawValue:))
        _selectedExperimentID = State(
            initialValue: initialExperiment ?? (showsComparison ? .mixingLight : restoredExperiment)
        )
    }

    var body: some View {
        WorkspaceCanvas(section: .explore) {
            Group {
                switch selectedExperimentID {
                case .mixingLight:
                    MixingExperimentView(
                        model: model,
                        showsComparison: initiallyShowsMixComparison,
                        onClose: { selectedExperimentID = nil }
                    )
                case .transparency:
                    TransparencyExperimentView(
                        model: model,
                        onClose: { selectedExperimentID = nil }
                    )
                case nil:
                    experimentLibrary
                }
            }
        }
        .navigationTitle("Explore")
        .textSelection(.enabled)
        .onChange(of: selectedExperimentID) { _, experiment in
            model.updateWorkspaceSession { $0.exploreExperimentRawValue = experiment?.rawValue }
        }
    }

    private var experimentLibrary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                WorkspaceHeader(section: .explore)

                PanelHeading(
                    title: "Choose an experiment",
                    summary: "Each card names the relationship you will manipulate."
                )

                LazyVGrid(columns: columns, alignment: .leading, spacing: AppMetrics.regular) {
                    ForEach(ExploreExperimentID.allCases) { experiment in
                        ExploreExperimentCard(experiment: experiment) {
                            selectedExperimentID = experiment
                        }
                    }
                }
            }
            .frame(maxWidth: 1_020, alignment: .leading)
            .padding(AppMetrics.page)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var columns: [GridItem] {
        if textScale >= 1.3 {
            return [GridItem(.flexible(), spacing: AppMetrics.regular, alignment: .top)]
        }
        return [GridItem(.adaptive(minimum: 320, maximum: 500), spacing: AppMetrics.regular, alignment: .top)]
    }
}

/// One experiment as a card, naming the question it answers.
private struct ExploreExperimentCard: View {
    let experiment: ExploreExperimentID
    let action: () -> Void
    @Environment(\.appSemanticPalette) private var semanticPalette

    var body: some View {
        let accent = semanticPalette.accent
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            // Only the experiment's own focus appears here. A caption that
            // reads the same on all four cards distinguishes nothing and
            // costs a line on each of them.
            HStack(alignment: .center, spacing: AppMetrics.compact) {
                ExploreExperimentIcon(experiment: experiment)
                    .frame(width: 56, height: 56)

                Text(experiment.focus)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                Text(experiment.title)
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h3)
                Text(experiment.summary)
                    .appFont(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppMetrics.tight)

            Button(experiment.actionTitle, systemImage: "arrow.right", action: action)
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .appFont(.body)
        }
        .padding(AppMetrics.roomy)
        .frame(maxWidth: .infinity, minHeight: 250, alignment: .leading)
        .background(
            Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: AppMetrics.radiusLarge, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.30), lineWidth: 1)
        }
    }
}

/// An experiment's icon, sized to whatever space it is given.
struct ExploreExperimentIcon: View {
    let experiment: ExploreExperimentID
    @Environment(\.appSemanticPalette) private var semanticPalette

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let accent = semanticPalette.accent
            let secondary = semanticPalette.secondaryCue

            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.18), secondary.opacity(0.13)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                ExploreExperimentArtwork(
                    experiment: experiment,
                    accent: accent,
                    secondary: secondary,
                    size: size
                )
            }
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .strokeBorder(accent.opacity(0.20), lineWidth: 1)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The shape behind an experiment icon, redundant with the label by design so
/// it never carries meaning on its own.
private struct ExploreExperimentArtwork: View {
    let experiment: ExploreExperimentID
    let accent: Color
    let secondary: Color
    let size: CGFloat

    var body: some View {
        switch experiment {
        case .mixingLight:
            HStack(spacing: -size * 0.14) {
                Circle()
                    .fill(accent.opacity(0.82))
                    .frame(width: circleSize, height: circleSize)
                Circle()
                    .fill(secondary.opacity(0.82))
                    .frame(width: circleSize, height: circleSize)
            }
            .overlay {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: centerBadgeSize, height: centerBadgeSize)
                    .background(.background.opacity(0.86), in: Circle())
            }
        case .transparency:
            ZStack {
                RoundedRectangle(cornerRadius: layerCornerRadius)
                    .fill(secondary.opacity(0.68))
                    .frame(width: layerWidth, height: layerHeight)
                    .offset(x: layerOffset, y: layerOffset / 2)
                RoundedRectangle(cornerRadius: layerCornerRadius)
                    .fill(accent.opacity(0.72))
                    .frame(width: layerWidth, height: layerHeight)
                    .offset(x: -layerOffset, y: -layerOffset / 2)
                Image(systemName: "square.3.layers.3d")
                    .font(.system(size: size * 0.20, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var circleSize: CGFloat { size * 0.48 }
    private var centerBadgeSize: CGFloat { size * 0.30 }
    private var layerWidth: CGFloat { size * 0.68 }
    private var layerHeight: CGFloat { size * 0.42 }
    private var layerOffset: CGFloat { size * 0.12 }
    private var layerCornerRadius: CGFloat { size * 0.08 }
}
