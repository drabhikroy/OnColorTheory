import SwiftUI

@MainActor
/// Which term the definition window is showing.
///
/// A single shared instance, because there is one definition window and any
/// term button anywhere in the app can point it somewhere new.
final class DefinitionWindowSelection: ObservableObject {
    static let shared = DefinitionWindowSelection()

    @Published private(set) var conceptID: String?

    private init() {}

    func select(_ conceptID: String) {
        self.conceptID = conceptID
    }
}

/// Opens the definition window on one term, placed beside the term itself.
struct TermHelpButton: View {
    @Environment(\.appSemanticPalette) private var palette
    let conceptID: String
    var showsTerm = true
    @Environment(\.openWindow) private var openWindow

    private var concept: ReferenceConcept? {
        ReferenceCatalog.concepts.first { $0.id == conceptID }
    }

    var body: some View {
        if let concept {
            Button {
                DefinitionWindowSelection.shared.select(conceptID)
                openWindow(id: AppWindowID.definition)
            } label: {
                if showsTerm {
                    Label(concept.term, systemImage: "info.circle")
                        .labelStyle(.titleAndIcon)
                } else {
                    Image(systemName: "info.circle")
                }
            }
            .buttonStyle(.plain)
            .appFont(.callout)
            .foregroundStyle(palette.accent)
            .frame(minWidth: 20, minHeight: 20)
            .contentShape(Rectangle())
            .help(concept.shortDefinition)
            .accessibilityLabel("Define \(concept.term)")
            .accessibilityHint(concept.shortDefinition)
        }
    }
}

/// A row of term buttons, drawn only when there are terms to offer.
struct TermHelpRow: View {
    let conceptIDs: [String]

    var body: some View {
        if !conceptIDs.isEmpty {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppMetrics.compact) {
                    definitionButtons
                }

                VStack(alignment: .leading, spacing: AppMetrics.snug) {
                    definitionButtons
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder
    private var definitionButtons: some View {
        ForEach(conceptIDs, id: \.self) { conceptID in
            TermHelpButton(conceptID: conceptID)
        }
    }
}

/// The definition window, showing whichever term was last asked for.
struct TermDefinitionWindow: View {
    let conceptID: String?

    var body: some View {
        if let conceptID,
           let concept = ReferenceCatalog.concepts.first(where: { $0.id == conceptID }) {
            TermDefinitionContent(concept: concept)
        } else {
            ContentUnavailableView(
                "Definition unavailable",
                systemImage: "questionmark.circle",
                description: Text("Return to On Color Theory and open the definition again.")
            )
        }
    }
}

/// One term's definition, its distinction from nearby terms, and its
/// sources.
private struct TermDefinitionContent: View {
    let concept: ReferenceConcept

    private var evidence: [EvidenceRecord] {
        concept.evidenceIDs.compactMap(EvidenceRegistry.record(withID:))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            Text(concept.term)
                .appFont(.title2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)

            Text(concept.summary)
                .appFont(.body)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: AppMetrics.tight) {
                Text("Important distinction")
                    .appFont(.headline)
                Text(concept.distinction)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !evidence.isEmpty {
                Divider()
                ForEach(evidence) { record in
                    Link(destination: record.sourceURL) {
                        Label(record.title, systemImage: "arrow.up.right")
                    }
                    .appFont(.callout)
                }
            }
        }
        .padding(AppMetrics.regular)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .textSelection(.enabled)
    }
}
