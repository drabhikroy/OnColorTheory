import SwiftUI

/// One slide of the first-run walkthrough.
struct WalkthroughStep: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let symbolName: String
    let motif: DesignedIconMotif
    let points: [String]

    static let all: [WalkthroughStep] = [
        WalkthroughStep(
            id: "welcome",
            title: "See color more clearly",
            summary: "On Color Theory helps you learn an idea, test a relationship, and carry useful colors into practical work.",
            symbolName: "scope",
            motif: .spectrum,
            points: [
                "The app begins on Home, where every workspace is visible without opening several menus.",
                "This walkthrough has seven short steps and takes about two minutes.",
                "You can skip it now or open it again from Help at any time."
            ]
        ),
        WalkthroughStep(
            id: "working-color",
            title: "Keep one working color with you",
            summary: "The same color can move between learning, conversion, design, and checking tasks.",
            symbolName: "eyedropper",
            motif: .path,
            points: [
                "Open Inspector to enter a color or sample a pixel inside or outside On Color Theory.",
                "Review its Hex, RGB, Alpha, Measures, and Context information.",
                "Save useful colors to the Color Tray, or use the working-color control in the sidebar to continue in Convert."
            ]
        ),
        WalkthroughStep(
            id: "learn-explore",
            title: "Learn and Explore one idea at a time",
            summary: "Use a guided explanation when you want a path, or an experiment when you want to test a prediction.",
            symbolName: "book.pages",
            motif: .stack,
            points: [
                "Learn breaks each color-science question into three short parts.",
                "Explore lets you predict, observe, and explain a focused visual relationship.",
                "Handoff buttons keep the example connected when you move to Convert or Check."
            ]
        ),
        WalkthroughStep(
            id: "convert",
            title: "Convert without losing the meaning",
            summary: "Enter a color once, then open only the representation and calculation detail you need.",
            symbolName: "arrow.left.arrow.right",
            motif: .split,
            points: [
                "Convert recognizes common Hex and RGB input and reports invalid values instead of silently changing them.",
                "Choose a result such as RGB, Display P3, Lab, or Oklab.",
                "Meaning, Calculation, and Sources keep the explanation separate from the final value."
            ]
        ),
        WalkthroughStep(
            id: "build",
            title: "Build palettes for real interfaces",
            summary: "Design color roles, coordinate Light and Dark appearances, and preview your own words as you work.",
            symbolName: "swatchpalette",
            motif: .swatches,
            points: [
                "Move through Design, Light & Dark, Recommend, Check, and Export as connected stages of one palette task.",
                "Your heading, body, cue, detail, and button text remain visible throughout the Build workspace.",
                "Model Assist is optional. It can suggest colors and explanations, while On Color Theory performs every calculation."
            ]
        ),
        WalkthroughStep(
            id: "check",
            title: "Check the question you actually have",
            summary: "Contrast, color difference, gamut, and reliance on color answer different questions.",
            symbolName: "checkmark.shield",
            motif: .compare,
            points: [
                "Choose the analysis that matches the design decision you need to make.",
                "Read the plain-language result before opening the method and equation.",
                "On Color Theory names assumptions and limitations instead of turning every result into a universal pass or fail."
            ]
        ),
        WalkthroughStep(
            id: "reference-help",
            title: "Return to definitions and Help whenever needed",
            summary: "Reference explains the terms and evidence. Help routes you back to the right tool.",
            symbolName: "books.vertical",
            motif: .books,
            points: [
                "Search Reference using the words you already know, then open one term at a time.",
                "Use Help for sampling, Light and Dark design, Model Assist, result authority, shortcuts, recovery, and reset guidance.",
                "Open this walkthrough again from Start here in Help whenever you want a refresher."
            ]
        )
    ]
}

/// The first-run walkthrough, shown once and reachable afterward from
/// Help.
struct WalkthroughView: View {
    @ObservedObject var model: AppModel
    @AppStorage(AppPreferenceKeys.completedInitialWalkthrough) private var completedInitialWalkthrough = false
    @Environment(\.appTextScale) private var textScale
    @Environment(\.appSemanticPalette) private var semanticPalette
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var currentIndex: Int

    init(model: AppModel, initialStep: Int = 0) {
        self.model = model
        let lastIndex = max(WalkthroughStep.all.count - 1, 0)
        _currentIndex = State(initialValue: min(max(initialStep, 0), lastIndex))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                windowHeader
                Divider()
                slideReader
                Divider()
                navigationControls
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .top
            )
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("On Color Theory Walkthrough")
    }

    private var currentStep: WalkthroughStep {
        WalkthroughStep.all[currentIndex]
    }

    private var isLastStep: Bool {
        currentIndex == WalkthroughStep.all.count - 1
    }

    private var windowHeader: some View {
        Group {
            if textScale >= 1.3 {
                VStack(alignment: .leading, spacing: AppMetrics.compact) {
                    walkthroughIdentity
                    skipButton
                }
            } else {
                HStack(spacing: AppMetrics.compact) {
                    walkthroughIdentity
                    Spacer(minLength: 12)
                    skipButton
                }
            }
        }
        .padding(.horizontal, AppMetrics.section)
        .padding(.vertical, AppMetrics.regular)
        .fixedSize(horizontal: false, vertical: true)
        .frame(height: textScale >= 1.3 ? 188 : 88, alignment: .leading)
        .layoutPriority(2)
    }

    private var walkthroughIdentity: some View {
        HStack(spacing: AppMetrics.compact) {
            DesignedSymbolIcon(symbolName: "sparkles", motif: .orbit, size: 42)

            VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                Text("On Color Theory walkthrough")
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h1)
                Text("A short, guided introduction. You can open it again from Help.")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var skipButton: some View {
        Button("Skip walkthrough") {
            finish()
        }
        .buttonStyle(.bordered)
        .appFont(.body)
        .keyboardShortcut(.cancelAction)
    }

    private var slideReader: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                progressHeader
                slideHeader
                pointsCard
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(AppMetrics.section)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(minHeight: 0, maxHeight: .infinity)
        .layoutPriority(0)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            HStack {
                Text("STEP \(currentIndex + 1) OF \(WalkthroughStep.all.count)")
                    .appFont(.caption)
                    .foregroundStyle(semanticPalette.accent)
                Spacer()
                Text("About two minutes total")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(
                value: Double(currentIndex + 1),
                total: Double(WalkthroughStep.all.count)
            )
            .tint(semanticPalette.accent)
            .accessibilityLabel("Walkthrough progress")
            .accessibilityValue("Step \(currentIndex + 1) of \(WalkthroughStep.all.count)")
        }
    }

    @ViewBuilder
    private var slideHeader: some View {
        if textScale >= 1.3 {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                slideIcon
                slideTitle
            }
        } else {
            HStack(alignment: .center, spacing: AppMetrics.roomy) {
                slideIcon
                slideTitle
            }
        }
    }

    private var slideIcon: some View {
        DesignedSymbolIcon(
            symbolName: currentStep.symbolName,
            motif: currentStep.motif,
            size: textScale >= 1.3 ? 70 : 86
        )
    }

    private var slideTitle: some View {
        VStack(alignment: .leading, spacing: AppMetrics.snug) {
            Text(currentStep.title)
                .appFont(.largeTitle)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)
            Text(currentStep.summary)
                .appFont(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pointsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                Text("What to know")
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)

                ForEach(Array(currentStep.points.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: AppMetrics.compact) {
                        Text("\(index + 1)")
                            .appFont(.headline)
                            .frame(width: 30, height: 30)
                            .background(semanticPalette.accent.opacity(0.12), in: Circle())
                            .accessibilityHidden(true)

                        Text(point)
                            .appFont(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Point \(index + 1). \(point)")
                }
            }
        }
    }

    private var navigationControls: some View {
        VStack(spacing: AppMetrics.compact) {
            HStack(spacing: AppMetrics.snug) {
                ForEach(WalkthroughStep.all.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == currentIndex ? semanticPalette.accent : Color.secondary.opacity(0.24))
                        .frame(width: index == currentIndex ? 24 : 8, height: 8)
                }
            }
            .accessibilityHidden(true)

            HStack(spacing: AppMetrics.compact) {
                Button("Previous", systemImage: "arrow.left") {
                    move(to: currentIndex - 1)
                }
                .buttonStyle(.bordered)
                .appFont(.body)
                .disabled(currentIndex == 0)
                .keyboardShortcut(.leftArrow, modifiers: [])

                Spacer()

                Text("\(currentIndex + 1) of \(WalkthroughStep.all.count)")
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Spacer()

                Button(isLastStep ? "Start using On Color Theory" : "Next", systemImage: isLastStep ? "checkmark" : "arrow.right") {
                    if isLastStep {
                        finish()
                    } else {
                        move(to: currentIndex + 1)
                    }
                }
                .buttonStyle(.borderedProminent)
                .appFont(.body)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, AppMetrics.section)
        .padding(.vertical, AppMetrics.regular)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.52))
        .fixedSize(horizontal: false, vertical: true)
        .frame(height: textScale >= 1.3 ? 96 : 77)
        .layoutPriority(2)
    }

    private func move(to index: Int) {
        guard WalkthroughStep.all.indices.contains(index) else { return }
        currentIndex = index
        AccessibilityAnnouncer.announce(
            "Step \(index + 1) of \(WalkthroughStep.all.count). \(WalkthroughStep.all[index].title)"
        )
    }

    private func finish() {
        completedInitialWalkthrough = true
        model.selectedSection = .home
        openWindow(id: AppWindowID.main)
        dismissWindow(id: AppWindowID.walkthrough)
    }
}
