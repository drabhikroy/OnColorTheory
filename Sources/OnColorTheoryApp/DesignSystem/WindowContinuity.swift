import AppKit
import SwiftUI

/// Saves and restores window position and size per window.
///
/// A restored frame is checked against the current screens before it is used,
/// since a window saved on a display that has since been detached would
/// reopen off screen.
enum AppWindowContinuity {
    /// The prefix AppKit puts in front of every saved frame key.
    ///
    /// Resetting preferences has to find these keys again by prefix, so the
    /// string lives here rather than being written out a second time in
    /// `ApplicationDefaults`. Two literals that have to agree, in two files,
    /// is how a rename leaves orphaned window frames behind.
    static let autosavePrefix = "OnColorTheory."

    /// The full key AppKit stores a frame under, used when clearing them.
    static let frameKeyPrefix = "NSWindow Frame " + autosavePrefix

    static func autosaveName(for identifier: String) -> String {
        let normalized = identifier
            .lowercased()
            .map { character in
                character.isLetter || character.isNumber ? character : "-"
            }
        return autosavePrefix + String(normalized)
    }
}

/// Reaches the hosting `NSWindow` so its frame can be saved and restored.
///
/// SwiftUI does not expose the window, and the lookup has to wait until the
/// view is in a window, which is why it is deferred rather than run during
/// layout.
private struct WindowContinuityView: NSViewRepresentable {
    let identifier: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        configure(view, coordinator: context.coordinator)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        configure(nsView, coordinator: context.coordinator)
    }

    private func configure(_ view: NSView, coordinator: Coordinator) {
        DispatchQueue.main.async {
            guard let window = view.window, coordinator.window !== window else { return }
            coordinator.window = window

            let name = AppWindowContinuity.autosaveName(for: identifier)
            window.setFrameAutosaveName(name)
            let restored = window.setFrameUsingName(name)
            if restored, !Self.isVisible(window.frame) {
                window.center()
            }
        }
    }

    private static func isVisible(_ frame: CGRect) -> Bool {
        NSScreen.screens.contains { screen in
            frame.intersection(screen.visibleFrame).width >= 80
                && frame.intersection(screen.visibleFrame).height >= 80
        }
    }

    final class Coordinator {
        weak var window: NSWindow?
    }
}

extension View {
    func restoreWindowGeometry(_ identifier: String) -> some View {
        background(WindowContinuityView(identifier: identifier).frame(width: 0, height: 0))
    }
}
