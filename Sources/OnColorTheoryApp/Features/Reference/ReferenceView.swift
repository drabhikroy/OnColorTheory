import SwiftUI

/// One reference term.
///
/// `distinction` is separate from `summary` because most confusion in this
/// subject comes from terms that sound interchangeable and are not.
struct ReferenceConcept: Identifiable, Hashable, Sendable {
    let id: String
    let term: String
    let category: String
    let summary: String
    let distinction: String
    let evidenceIDs: [String]

    var shortDefinition: String {
        guard let sentenceEnd = summary.firstIndex(of: ".") else { return summary }
        return String(summary[...sentenceEnd])
    }

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return true }

        return [term, category, summary, distinction]
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(normalizedQuery)
    }
}

/// Every reference term the app defines, held in one place so a definition
/// shown in a tooltip and one shown in Reference cannot diverge.
enum ReferenceCatalog {
    static let concepts: [ReferenceConcept] = [
        ReferenceConcept(
            id: "hex-notation",
            term: "HEX notation",
            category: "Notation",
            summary: "A compact way to write encoded sRGB channel values using hexadecimal digits. CSS accepts three, four, six, or eight digits; the optional fourth channel is alpha.",
            distinction: "HEX is a notation, not a color space. Its digits only become meaningful when their color space and encoding are known.",
            evidenceIDs: ["w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "rgb-model",
            term: "RGB color model",
            category: "Color model",
            summary: "An additive coordinate model that describes a color as amounts of red, green, and blue primaries. CSS rgb() and rgba() represent encoded sRGB unless another color space is explicitly named.",
            distinction: "RGB numbers alone do not define a color. Primaries, white point, transfer function, and viewing assumptions supply the missing meaning.",
            evidenceIDs: ["w3c-css-color-4", "iec-srgb"]
        ),
        ReferenceConcept(
            id: "srgb",
            term: "sRGB",
            category: "RGB color space",
            summary: "A standardized RGB color space with defined primaries, a D65 reference white, and a nonlinear encoding function. It remains the default color space for common CSS color syntax.",
            distinction: "sRGB is more than a set of RGB numbers, and a physical display can still depart from its reference conditions even when content is tagged correctly.",
            evidenceIDs: ["iec-srgb", "w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "encoded-linear",
            term: "Encoded and linear-light RGB",
            category: "Signal encoding",
            summary: "Encoded sRGB values use a piecewise transfer function for storage and interchange. Linear-light values are proportional to light and are required for operations such as physically meaningful mixing and XYZ conversion.",
            distinction: "The sRGB transfer function is piecewise, not a single simple gamma. Calculations on encoded components can produce incorrect light relationships.",
            evidenceIDs: ["iec-srgb", "w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "color-interpolation",
            term: "Color interpolation",
            category: "Color calculation",
            summary: "A method for calculating colors between two endpoints in a stated color space. The interpolation space determines what the component numbers mean while they are averaged.",
            distinction: "There is no single best interpolation space for every purpose. Linear-light spaces model the numeric combination of emitted light, while perceptual spaces are designed for more even-looking changes.",
            evidenceIDs: ["w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "display-p3",
            term: "Display P3",
            category: "RGB color space",
            summary: "An RGB color space that uses the wider P3 primaries with a D65 reference white and the Display P3 encoding defined by CSS Color 4.",
            distinction: "Display P3 coordinates are not interchangeable with sRGB coordinates. A device can also support some P3 content without reproducing the entire Display P3 gamut under every condition.",
            evidenceIDs: ["w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "alpha",
            term: "Alpha",
            category: "Compositing",
            summary: "A value that controls how a source color is combined with a backdrop. In common unpremultiplied notation, zero is fully transparent and one is fully opaque.",
            distinction: "Alpha is not a perceptual color dimension. The visible result depends on the backdrop and the compositing method.",
            evidenceIDs: ["w3c-css-color-4", "w3c-compositing-1"]
        ),
        ReferenceConcept(
            id: "cie-xyz",
            term: "CIE XYZ",
            category: "Colorimetric space",
            summary: "A tristimulus coordinate system derived from standardized color-matching functions. It provides a common connection space between many color representations.",
            distinction: "XYZ values are not cone responses and cannot uniquely identify a spectrum. Different spectra can produce the same tristimulus coordinates under specified conditions.",
            evidenceIDs: ["cie-015-2018", "w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "reference-white",
            term: "Reference white",
            category: "Viewing condition",
            summary: "The chromaticity treated as neutral white for a color space or calculation. sRGB and Oklab commonly use D65, while CSS CIELAB and LCh use D50-adapted XYZ.",
            distinction: "A white point is part of a color's interpretation. Lab coordinates calculated relative to different whites should not be compared as though they share the same basis.",
            evidenceIDs: ["cie-015-2018", "w3c-css-color-4", "iec-srgb"]
        ),
        ReferenceConcept(
            id: "chromatic-adaptation",
            term: "Chromatic adaptation",
            category: "Color appearance",
            summary: "A computational transformation used to relate white-relative color coordinates under different reference whites. This app uses the Bradford transform when adapting sRGB D65 XYZ to the D50 basis used by CSS Lab.",
            distinction: "A chromatic-adaptation transform is a model used in a defined workflow; it is not a complete simulation of an individual observer adapting to a scene.",
            evidenceIDs: ["w3c-css-color-4", "cie-015-2018"]
        ),
        ReferenceConcept(
            id: "cielab",
            term: "CIELAB",
            category: "Approximately uniform space",
            summary: "A nonlinear, white-relative color space with L* for lightness and a* and b* for opponent-like axes. The app reports CSS-compatible Lab relative to D50.",
            distinction: "L* is neither physical luminance nor HSL lightness. CIELAB is only approximately perceptually uniform and does not predict every observer or viewing condition.",
            evidenceIDs: ["cie-015-2018", "w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "ciede2000",
            term: "CIEDE2000 (ΔE00)",
            category: "Color-difference calculation",
            summary: "A standardized formula that estimates the relative magnitude of a color difference from two CIELAB coordinates. It adjusts lightness, chroma, and hue contributions because equal geometric distances in CIELAB are not equally perceptible everywhere.",
            distinction: "A larger ΔE00 means a larger difference within this model, but no universal value settles whether a person will notice or accept a difference. Viewing conditions, size, surroundings, display behavior, task, and observer all matter.",
            evidenceIDs: ["iso-cie-11664-6-2022", "sharma-ciede2000-2005", "cie-015-2018"]
        ),
        ReferenceConcept(
            id: "chroma",
            term: "Chroma",
            category: "Color attribute",
            summary: "A coordinate describing distance from a neutral color at the same lightness in a stated color space. CIEDE2000 uses a modified CIELAB chroma when estimating color difference.",
            distinction: "Chroma is not interchangeable with saturation or colorfulness. Its numeric meaning depends on the color space and calculation in which it is defined.",
            evidenceIDs: ["cie-015-2018", "iso-cie-11664-6-2022"]
        ),
        ReferenceConcept(
            id: "cie-lch",
            term: "CIE LCh",
            category: "Polar color space",
            summary: "A cylindrical rearrangement of CIELAB: L* is lightness, C* is chroma, and h is hue angle. It preserves the same D50 reference basis used by the corresponding Lab coordinates here.",
            distinction: "Hue becomes undefined when chroma approaches zero, and an LCh coordinate is not a promise that a particular RGB display can reproduce the color.",
            evidenceIDs: ["cie-015-2018", "w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "oklab",
            term: "Oklab and OkLCh",
            category: "Perceptual color space",
            summary: "A newer Lab-like space designed for improved perceptual behavior in image-processing tasks. OkLCh is its polar form, and CSS defines both relative to D65 XYZ.",
            distinction: "Oklab is not a CIE standard and is not a complete model of color appearance. It remains a mathematical approximation with defined use cases.",
            evidenceIDs: ["w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "hsl",
            term: "HSL",
            category: "Cylindrical RGB representation",
            summary: "A convenient cylindrical rearrangement of encoded sRGB using hue, saturation, and lightness controls. It is widely used for authoring interfaces and CSS syntax.",
            distinction: "HSL lightness is not luminance or perceptual lightness. Equal numeric changes do not imply equal perceived changes.",
            evidenceIDs: ["w3c-css-color-4"]
        ),
        ReferenceConcept(
            id: "wcag-contrast",
            term: "WCAG contrast ratio",
            category: "Accessibility metric",
            summary: "A ratio derived from the relative luminances of two sRGB colors. WCAG 2.2 uses exact thresholds from 3:1 to 7:1 for specified text, interface, and graphical contexts.",
            distinction: "A passing ratio is one requirement, not proof of readability or accessibility. Font rendering, size, weight, context, states, display conditions, and individual vision still matter.",
            evidenceIDs: ["w3c-wcag-22-contrast", "iec-srgb"]
        ),
        ReferenceConcept(
            id: "relative-luminance",
            term: "Relative luminance",
            category: "Accessibility calculation",
            summary: "A normalized value calculated from linearized sRGB components for the WCAG contrast method, where zero represents the darkest reference value and one the lightest.",
            distinction: "WCAG relative luminance is a defined calculation from color values. It is not a direct measurement of a display's physical luminance in a room.",
            evidenceIDs: ["w3c-wcag-22-contrast", "iec-srgb"]
        ),
        ReferenceConcept(
            id: "gamut",
            term: "Gamut",
            category: "Color-space boundary",
            summary: "The range of colors that a color space or device can represent under stated conditions.",
            distinction: "A coordinate can be mathematically valid yet fall outside a particular RGB gamut, so that device or color space cannot reproduce it without adjustment.",
            evidenceIDs: ["w3c-css-color-4-gamut"]
        ),
        ReferenceConcept(
            id: "gamut-mapping",
            term: "Gamut mapping",
            category: "Color reproduction",
            summary: "The process of choosing an in-gamut replacement when a destination color space or device cannot reproduce a source color unchanged.",
            distinction: "Channel clipping is one simple method, but it can shift hue. More advanced methods balance changes in lightness, chroma, and hue for a stated destination and purpose.",
            evidenceIDs: ["w3c-css-color-4-gamut"]
        ),
        ReferenceConcept(
            id: "simultaneous-contrast",
            term: "Simultaneous contrast",
            category: "Perceptual context",
            summary: "A contextual effect in which a target can appear lighter, darker, or differently colored when its nearby surroundings change even though the target stimulus is unchanged.",
            distinction: "The demonstration shows that context can matter. It does not measure a universal shift or establish that every observer will experience the same effect with the same strength.",
            evidenceIDs: ["kingdom-lightness-2011"]
        ),
        ReferenceConcept(
            id: "color-appearance",
            term: "Color appearance",
            category: "Perception model",
            summary: "The perceptual attributes associated with a color under stated viewing conditions. Color-appearance models relate colorimetric input and viewing context to defined appearance correlates.",
            distinction: "A color-appearance model is not a direct readout of one person's experience. Its predictions depend on the model, input data, and specified viewing conditions.",
            evidenceIDs: ["cie-248-2022-ciecam16", "cie-015-2018"]
        ),
        ReferenceConcept(
            id: "color-reliance",
            term: "Color as the only cue",
            category: "Accessibility review",
            summary: "A design relies on color alone when a color difference carries information, indicates an action, prompts a response, or distinguishes an element without another visible cue such as text, shape, pattern, or position.",
            distinction: "Color remains useful and can reinforce meaning. WCAG asks that the meaning also be available through another visible means when color is carrying information.",
            evidenceIDs: ["w3c-wcag-22-use-of-color"]
        ),
        ReferenceConcept(
            id: "neutral-preview",
            term: "Neutral light and dark preview",
            category: "Diagnostic visualization",
            summary: "A visualization that replaces each color with a neutral sRGB value chosen to preserve its calculated relative luminance. It helps reveal light and dark structure while removing hue from the comparison.",
            distinction: "This preview is not a simulation of color-vision deficiency and cannot determine whether a complete design conveys its meaning without color.",
            evidenceIDs: ["w3c-wcag-22-use-of-color", "iec-srgb"]
        )
    ]

    static func search(_ query: String) -> [ReferenceConcept] {
        concepts.filter { $0.matches(query) }
    }
}

/// The four groupings terms are browsed by.
///
/// These are an information architecture hypothesis rather than a taxonomy
/// taken from the standards, and they need task-based testing.
enum ReferenceTopicID: String, CaseIterable, Identifiable, Sendable {
    case writingAndReproduction = "writing-and-reproduction"
    case lightMixingAndLayers = "light-mixing-and-layers"
    case measuringColor = "measuring-color"
    case comparisonAndAccessibility = "comparison-and-accessibility"

    var id: Self { self }

    var title: String {
        switch self {
        case .writingAndReproduction: "Writing and reproducing color"
        case .lightMixingAndLayers: "Light, mixing, and layers"
        case .measuringColor: "Measuring color"
        case .comparisonAndAccessibility: "Comparing colors and accessibility"
        }
    }

    var summary: String {
        switch self {
        case .writingAndReproduction:
            "Distinguish notations such as HEX from the color spaces and boundaries that give their numbers meaning."
        case .lightMixingAndLayers:
            "Understand stored values, light-proportional calculations, interpolation, and transparency."
        case .measuringColor:
            "Connect standardized coordinates to reference whites, adaptation, lightness, chroma, and hue."
        case .comparisonAndAccessibility:
            "Choose a contrast or color-difference calculation by the question it is designed to answer."
        }
    }

    var symbolName: String {
        switch self {
        case .writingAndReproduction: "textformat.abc"
        case .lightMixingAndLayers: "square.3.layers.3d"
        case .measuringColor: "ruler"
        case .comparisonAndAccessibility: "checkmark.shield"
        }
    }

    var iconMotif: DesignedIconMotif {
        switch self {
        case .writingAndReproduction: .type
        case .lightMixingAndLayers: .layers
        case .measuringColor: .measure
        case .comparisonAndAccessibility: .compare
        }
    }

    var conceptIDs: [String] {
        switch self {
        case .writingAndReproduction:
            ["hex-notation", "rgb-model", "srgb", "display-p3", "hsl", "gamut", "gamut-mapping"]
        case .lightMixingAndLayers:
            ["encoded-linear", "color-interpolation", "alpha"]
        case .measuringColor:
            ["cie-xyz", "reference-white", "chromatic-adaptation", "cielab", "chroma", "cie-lch", "oklab", "simultaneous-contrast", "color-appearance"]
        case .comparisonAndAccessibility:
            ["wcag-contrast", "relative-luminance", "ciede2000", "color-reliance", "neutral-preview"]
        }
    }

    var concepts: [ReferenceConcept] {
        conceptIDs.compactMap { conceptID in
            ReferenceCatalog.concepts.first { $0.id == conceptID }
        }
    }
}

/// An equation with a reading of it in words, since an equation alone is not
/// reachable by a screen reader.
struct ReferenceEquation: Hashable, Sendable {
    let title: String
    let latex: String
    let reading: String
}

extension ReferenceConcept {
    var equation: ReferenceEquation? {
        switch id {
        case "color-interpolation":
            ReferenceEquation(
                title: "Component interpolation",
                latex: ColorMixingMath.encodedEquation,
                reading: ColorMixingMath.encodedReading
            )
        case "alpha":
            ReferenceEquation(
                title: "Source over an opaque backdrop",
                latex: AlphaCompositingMath.opaqueBackdropEquation,
                reading: AlphaCompositingMath.opaqueBackdropReading
            )
        case "wcag-contrast":
            ReferenceEquation(
                title: "WCAG contrast ratio",
                latex: ContrastMath.ratioEquation,
                reading: ContrastMath.ratioReading
            )
        case "relative-luminance":
            ReferenceEquation(
                title: "WCAG relative luminance",
                latex: ContrastMath.relativeLuminanceEquation,
                reading: ContrastMath.relativeLuminanceReading
            )
        case "ciede2000":
            ReferenceEquation(
                title: "CIEDE2000 weighted-term combination",
                latex: ColorDifferenceMath.combinationEquation,
                reading: ColorDifferenceMath.combinationReading
            )
        default:
            nil
        }
    }
}

/// The Reference workspace, browsable by topic and searchable by term.
struct ReferenceView: View {
    @ObservedObject var model: AppModel
    @Environment(\.appTextScale) private var textScale
    @State private var query: String
    @State private var selectedTopicID: ReferenceTopicID?
    @State private var selectedConceptID: String?

    init(
        model: AppModel,
        initialTopic: ReferenceTopicID? = nil,
        initialConceptID: String? = nil,
        initialQuery: String? = nil
    ) {
        self.model = model
        let restoredTopic = model.workspaceSession.referenceTopicRawValue
            .flatMap(ReferenceTopicID.init(rawValue:))
        let restoredConceptID = model.workspaceSession.referenceConceptID.flatMap { identifier in
            ReferenceCatalog.concepts.contains(where: { $0.id == identifier }) ? identifier : nil
        }
        _query = State(initialValue: initialQuery ?? model.workspaceSession.referenceQuery)
        _selectedTopicID = State(initialValue: initialTopic ?? restoredTopic)
        _selectedConceptID = State(initialValue: initialConceptID ?? restoredConceptID)
    }

    private var selectedConcept: ReferenceConcept? {
        guard let selectedConceptID else { return nil }
        return ReferenceCatalog.concepts.first { $0.id == selectedConceptID }
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchResults: [ReferenceConcept] {
        ReferenceCatalog.search(normalizedQuery)
    }

    private var activeConcepts: [ReferenceConcept] {
        if let selectedTopicID {
            return selectedTopicID.concepts
        }
        if !normalizedQuery.isEmpty {
            return searchResults
        }
        return ReferenceCatalog.concepts
    }

    private var selectedIndex: Int {
        guard let selectedConceptID else { return 0 }
        return activeConcepts.firstIndex { $0.id == selectedConceptID } ?? 0
    }

    var body: some View {
        WorkspaceCanvas(section: .reference) {
            Group {
                if let selectedConcept {
                    readerPage(concept: selectedConcept)
                } else if let selectedTopicID {
                    topicPage(topic: selectedTopicID)
                } else {
                    landingPage
                }
            }
        }
        .navigationTitle("Reference")
        .textSelection(.enabled)
        .onChange(of: query) { _, value in
            model.updateWorkspaceSession { $0.referenceQuery = value }
        }
        .onChange(of: selectedTopicID) { _, topic in
            model.updateWorkspaceSession { $0.referenceTopicRawValue = topic?.rawValue }
        }
        .onChange(of: selectedConceptID) { _, identifier in
            model.updateWorkspaceSession { $0.referenceConceptID = identifier }
        }
    }

    private var landingPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                referenceHeader
                searchField

                if normalizedQuery.isEmpty {
                    topicLibrary
                } else {
                    searchResultLibrary
                }
            }
            .frame(maxWidth: 1_100, alignment: .leading)
            .padding(AppMetrics.page)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var referenceHeader: some View {
        WorkspaceHeader(section: .reference)
    }

    private var searchField: some View {
        HStack(spacing: AppMetrics.snug) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Search terms and explanations", text: $query)
                .textFieldStyle(.plain)
                .appFont(.body)
                .accessibilityLabel("Search the color reference")

            if !query.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") {
                    query = ""
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppMetrics.regular)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(nsColor: .separatorColor).opacity(0.65), lineWidth: 1)
        }
    }

    private var topicLibrary: some View {
        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            PanelHeading(
                title: "Browse by topic",
                summary: "\(ReferenceCatalog.concepts.count) terms grouped into four starting points."
            )

            LazyVGrid(columns: columns, alignment: .leading, spacing: AppMetrics.regular) {
                ForEach(ReferenceTopicID.allCases) { topic in
                    ReferenceTopicCard(topic: topic) {
                        query = ""
                        selectedTopicID = topic
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var searchResultLibrary: some View {
        if searchResults.isEmpty {
            ContentUnavailableView(
                "No matching terms",
                systemImage: "magnifyingglass",
                description: Text("Try a color space, calculation, notation, or design question.")
            )
            .appFont(.body)
            .frame(maxWidth: .infinity, minHeight: 260)
        } else {
            VStack(alignment: .leading, spacing: AppMetrics.regular) {
                VStack(alignment: .leading, spacing: AppMetrics.tight) {
                    Text("Search results")
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    Text("\(searchResults.count) \(searchResults.count == 1 ? "term" : "terms")")
                        .appFont(.callout)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: AppMetrics.regular) {
                    ForEach(searchResults) { concept in
                        ReferenceTermCard(concept: concept) {
                            selectedTopicID = nil
                            selectedConceptID = concept.id
                        }
                    }
                }
            }
        }
    }

    private func topicPage(topic: ReferenceTopicID) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                Button("All reference topics", systemImage: "chevron.left") {
                    selectedTopicID = nil
                }
                .appFont(.callout)

                DestinationHeader(
                    title: topic.title,
                    summary: topic.summary
                )

                PanelHeading(
                    title: "Choose one term",
                    summary: "The reader keeps only that term and its evidence in view."
                )

                LazyVGrid(columns: columns, alignment: .leading, spacing: AppMetrics.regular) {
                    ForEach(topic.concepts) { concept in
                        ReferenceTermCard(concept: concept) {
                            selectedConceptID = concept.id
                        }
                    }
                }
            }
            .frame(maxWidth: 1_020, alignment: .leading)
            .padding(AppMetrics.page)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func readerPage(concept: ReferenceConcept) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.section) {
                Button(readerBackTitle, systemImage: "chevron.left") {
                    selectedConceptID = nil
                }
                .appFont(.callout)

                conceptNavigation
                conceptReader(concept: concept)
            }
            .frame(maxWidth: 820, alignment: .leading)
            .padding(AppMetrics.page)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var readerBackTitle: String {
        if let selectedTopicID {
            return "Terms in \(selectedTopicID.title)"
        }
        if !normalizedQuery.isEmpty {
            return "Search results"
        }
        return "All reference topics"
    }

    private var conceptNavigation: some View {
        HStack(spacing: AppMetrics.regular) {
            Button("Previous", systemImage: "chevron.left") {
                selectConcept(at: selectedIndex - 1)
            }
            .disabled(selectedIndex == 0)
            .frame(minWidth: 120, alignment: .leading)

            Spacer()

            Text("Term \(selectedIndex + 1) of \(activeConcepts.count)")
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer()

            Button("Next", systemImage: "chevron.right") {
                selectConcept(at: selectedIndex + 1)
            }
            .disabled(selectedIndex == activeConcepts.count - 1)
            .buttonStyle(.borderedProminent)
            .frame(minWidth: 120, alignment: .trailing)
        }
        .appFont(.body)
        .frame(minHeight: 34)
    }

    private func conceptReader(concept: ReferenceConcept) -> some View {
        let evidence = concept.evidenceIDs.compactMap(EvidenceRegistry.record(withID:))

        return AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.roomy) {
                VStack(alignment: .leading, spacing: AppMetrics.tight) {
                    Text(concept.category)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                    Text(concept.term)
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                }

                Text(concept.summary)
                    .appFont(.body)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    Label("The key distinction", systemImage: "info.circle")
                        .appFont(.headline)
                    Text(concept.distinction)
                        .appFont(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let equation = concept.equation {
                    ReferenceEquationPanel(equation: equation)
                }

                if !evidence.isEmpty {
                    VStack(alignment: .leading, spacing: AppMetrics.compact) {
                        Text("Sources and limitations")
                            .appFont(.headline)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h3)
                        ForEach(evidence) { record in
                            ReferenceEvidenceRow(record: record)
                        }
                    }
                }
            }
        }
    }

    private var columns: [GridItem] {
        if textScale >= 1.3 {
            return [GridItem(.flexible(), spacing: AppMetrics.regular, alignment: .top)]
        }
        return [GridItem(.adaptive(minimum: 320, maximum: 500), spacing: AppMetrics.regular, alignment: .top)]
    }

    private func selectConcept(at index: Int) {
        guard activeConcepts.indices.contains(index) else { return }
        selectedConceptID = activeConcepts[index].id
    }
}

/// One topic as a card in the browse grid.
private struct ReferenceTopicCard: View {
    let topic: ReferenceTopicID
    let action: () -> Void
    @Environment(\.appSemanticPalette) private var semanticPalette

    var body: some View {
        let accent = semanticPalette.accent

        VStack(alignment: .leading, spacing: AppMetrics.regular) {
            HStack(alignment: .top, spacing: AppMetrics.compact) {
                    DesignedSymbolIcon(symbolName: topic.symbolName, motif: topic.iconMotif, size: 54)

                Spacer()

                VStack(alignment: .trailing, spacing: AppMetrics.hairline) {
                    Text("\(topic.concepts.count)")
                        .appFont(.title2)
                        .monospacedDigit()
                    Text("\(topic.concepts.count) \(topic.concepts.count == 1 ? "term" : "terms")")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                Text(topic.title)
                    .appFont(.title2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h3)
                Text(topic.summary)
                    .appFont(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Button("Browse topic", systemImage: "arrow.right", action: action)
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .appFont(.body)
        }
        .padding(AppMetrics.roomy)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
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

/// One term as a card, showing its summary before it is opened.
private struct ReferenceTermCard: View {
    let concept: ReferenceConcept
    let action: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                Text(concept.category)
                    .appFont(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: AppMetrics.tight) {
                    Text(concept.term)
                        .appFont(.title2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h3)
                    Text(concept.shortDefinition)
                        .appFont(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 5)

                Button("Read definition", systemImage: "arrow.right", action: action)
                    .buttonStyle(.bordered)
                    .appFont(.callout)
            }
            .frame(maxWidth: .infinity, minHeight: 185, alignment: .leading)
        }
    }
}

/// A term's equation with its reading.
private struct ReferenceEquationPanel: View {
    let equation: ReferenceEquation

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            HStack(alignment: .firstTextBaseline) {
                Text(equation.title)
                    .appFont(.headline)
                Spacer()
                CopyValueButton(
                    value: equation.latex,
                    description: "\(equation.title) equation as LaTeX",
                    label: "Copy LaTeX"
                )
            }

            MathEquationView(
                latex: equation.latex,
                accessibilityLabel: equation.reading,
                baseFontSize: 24
            )

            Text(equation.reading)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppMetrics.regular)
        .appSubtleSurface(cornerRadius: 10)
    }
}

/// One cited source, linked out to the standard or paper itself.
private struct ReferenceEvidenceRow: View {
    let record: EvidenceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tight) {
            Link(destination: record.sourceURL) {
                Label(record.title, systemImage: "arrow.up.right.square")
            }
            .appFont(.body)

            Text("\(record.category.rawValue) · \(record.version) · reviewed \(record.lastReviewed)")
                .appFont(.caption)
                .foregroundStyle(.secondary)

            Text(record.limitation)
                .appFont(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
