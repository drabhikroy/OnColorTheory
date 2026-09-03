import SwiftUI

/// The tray of colors set aside for later, in its own window.
///
/// Removal is staged through `pendingRemoval` rather than applied immediately,
/// since a tray entry can represent work that is not recoverable once gone.
struct ColorTrayView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var store: ColorTrayStore
    @State private var pendingRemoval: ColorRecord?
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.compact) {
            HStack {
                VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                    Text("Color Tray")
                        .appFont(.title2)
                    Text("\(store.colors.count) saved \(store.colors.count == 1 ? "color" : "colors")")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    model.isTrayPresented = false
                    dismissWindow(id: AppWindowID.tray)
                }
                .appFont(.body)
                .keyboardShortcut(.cancelAction)
            }

            if let persistenceError = store.persistenceError {
                HStack(alignment: .top, spacing: AppMetrics.snug) {
                    Label(persistenceError, systemImage: "exclamationmark.triangle.fill")
                        .appFont(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Color Tray storage error")
                        .accessibilityValue(persistenceError)

                    Spacer(minLength: 8)

                    Button("Dismiss") {
                        store.dismissPersistenceError()
                    }
                    .appFont(.callout)
                }
                .padding(AppMetrics.compact)
                .appSubtleSurface(cornerRadius: 10)
            }

            if store.colors.isEmpty {
                ContentUnavailableView(
                    "No Saved Colors",
                    systemImage: "tray",
                    description: Text("Use Add to Color Tray anywhere a color appears.")
                )
                .appFont(.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppMetrics.snug) {
                        ForEach(store.colors) { record in
                            ColorTrayRow(
                                record: record,
                                isSelected: record.id == model.selectedTrayColorID,
                                select: {
                                    model.selectTrayColor(record)
                                    openWindow(id: AppWindowID.main)
                                    dismissWindow(id: AppWindowID.tray)
                                },
                                toggleLock: {
                                    store.toggleLock(id: record.id)
                                    AccessibilityAnnouncer.announce(
                                        record.isLocked ? "Unlocked \(record.label)" : "Locked \(record.label)"
                                    )
                                },
                                requestRemoval: { pendingRemoval = record }
                            )
                        }
                    }
                }
            }
        }
        .padding(AppMetrics.regular)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(
            "Remove this color?",
            isPresented: Binding(
                get: { pendingRemoval != nil },
                set: { if !$0 { pendingRemoval = nil } }
            ),
            presenting: pendingRemoval
        ) { record in
            Button("Remove", role: .destructive) {
                store.remove(id: record.id)
                AccessibilityAnnouncer.announce("Removed \(record.label) from the Color Tray")
                pendingRemoval = nil
            }
            Button("Cancel", role: .cancel) {
                pendingRemoval = nil
            }
        } message: { record in
            Text("\(record.label), \(record.color.hex), will be removed from the persistent Color Tray.")
        }
        .textSelection(.enabled)
    }
}

/// One tray entry, with its lock, its selection state, and its remove
/// control.
private struct ColorTrayRow: View {
    @Environment(\.appSemanticPalette) private var palette
    let record: ColorRecord
    let isSelected: Bool
    let select: () -> Void
    let toggleLock: () -> Void
    let requestRemoval: () -> Void

    var body: some View {
        HStack(spacing: AppMetrics.compact) {
            Button(action: select) {
                HStack(spacing: AppMetrics.compact) {
                    ColorSwatchView(color: record.color, showsLabel: false)
                        .frame(width: 46, height: 46)
                    VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                        HStack(spacing: AppMetrics.tight) {
                            Text(record.label)
                                .appFont(.headline)
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .accessibilityLabel("Selected")
                            }
                        }
                        Text(record.color.hex)
                            .appFont(.value)
                            .monospacedDigit()
                            .textSelection(.enabled)
                        Text("\(record.originalColorSpace.rawValue) · \(record.source)")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select \(record.label)")
            .accessibilityValue(record.color.accessibleDescription)

            Button(action: toggleLock) {
                Label(record.isLocked ? "Unlock" : "Lock", systemImage: record.isLocked ? "lock.fill" : "lock.open")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help(record.isLocked ? "Unlock \(record.label)" : "Lock \(record.label)")
            .frame(minWidth: 24, minHeight: 24)
            .accessibilityLabel(record.isLocked ? "Unlock \(record.label)" : "Lock \(record.label)")

            Button(role: .destructive, action: requestRemoval) {
                Label("Remove", systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help("Remove \(record.label)")
            .frame(minWidth: 24, minHeight: 24)
            .accessibilityLabel("Remove \(record.label)")
        }
        .padding(AppMetrics.compact)
        .background(
            isSelected ? palette.accent.opacity(0.09) : Color.secondary.opacity(0.055),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isSelected ? palette.accent.opacity(0.48) : Color(nsColor: .separatorColor).opacity(0.35),
                    lineWidth: 1
                )
        }
    }
}
