import AppKit
import SwiftUI

/// The four system accessibility settings the interface responds to, gathered
/// into one value so a view observes a single change rather than four.
struct AppAccessibilityPreferences: Equatable, Sendable {
    let increasedContrast: Bool
    let differentiateWithoutColor: Bool
    let reduceMotion: Bool
    let reduceTransparency: Bool

    static let standard = AppAccessibilityPreferences(
        increasedContrast: false,
        differentiateWithoutColor: false,
        reduceMotion: false,
        reduceTransparency: false
    )

    static let frameworkAudit = AppAccessibilityPreferences(
        increasedContrast: true,
        differentiateWithoutColor: true,
        reduceMotion: true,
        reduceTransparency: true
    )
}

/// Carries the accessibility preferences down the view tree.
private struct AppAccessibilityPreferencesKey: EnvironmentKey {
    static let defaultValue = AppAccessibilityPreferences.standard
}

extension EnvironmentValues {
    var appAccessibilityPreferences: AppAccessibilityPreferences {
        get { self[AppAccessibilityPreferencesKey.self] }
        set { self[AppAccessibilityPreferencesKey.self] = newValue }
    }
}

@MainActor
/// Speaks a change that has no visible focus move, such as opening a
/// workspace, which a screen reader would otherwise pass over in silence.
enum AccessibilityAnnouncer {
    static func announce(
        _ message: String,
        priority: NSAccessibilityPriorityLevel = .medium
    ) {
        let application = NSApplication.shared
        guard let window = application.mainWindow ?? application.keyWindow else { return }
        NSAccessibility.post(
            element: window,
            notification: .announcementRequested,
            userInfo: [
                .announcement: message,
                .priority: priority.rawValue
            ]
        )
    }
}

/// The border and fill for a selectable card.
///
/// Selection is shown by border weight as well as by color, so the state does
/// not rest on hue alone, and both thicken under Increased Contrast.
struct SelectableCardChrome: View {
    @Environment(\.appSemanticPalette) private var palette
    let isSelected: Bool
    var cornerRadius: CGFloat = AppMetrics.radiusMedium

    @Environment(\.appAccessibilityPreferences) private var accessibilityPreferences

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(fillColor)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            }
    }

    private var fillColor: Color {
        if isSelected {
            return palette.accent.opacity(accessibilityPreferences.increasedContrast ? 0.16 : 0.09)
        }
        return Color(nsColor: .controlBackgroundColor)
    }

    private var strokeColor: Color {
        if isSelected { return palette.accent }
        return Color(nsColor: .separatorColor)
            .opacity(accessibilityPreferences.increasedContrast ? 1 : 0.55)
    }

    private var strokeWidth: CGFloat {
        if isSelected { return accessibilityPreferences.increasedContrast ? 3 : 1.5 }
        return accessibilityPreferences.increasedContrast ? 1.5 : 1
    }
}

/// A numbered badge that becomes a checkmark when Differentiate Without Color
/// is on, so selection is legible without relying on the fill color.
struct IndexedSelectionBadge: View {
    @Environment(\.appSemanticPalette) private var palette
    let index: Int
    let isSelected: Bool

    @Environment(\.appAccessibilityPreferences) private var accessibilityPreferences

    var body: some View {
        Group {
            if isSelected && accessibilityPreferences.differentiateWithoutColor {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
            } else {
                Text("\(index)")
                    .appFont(.callout)
                    .monospacedDigit()
            }
        }
        .frame(width: 30, height: 30)
        .background(
            isSelected
                ? palette.accent
                : Color.secondary.opacity(accessibilityPreferences.increasedContrast ? 0.24 : 0.13),
            in: Circle()
        )
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .overlay {
            if accessibilityPreferences.increasedContrast {
                Circle().stroke(Color.primary.opacity(0.65), lineWidth: 1)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A quiet background that becomes opaque under Reduce Transparency and gains
/// a border under Increased Contrast.
private struct AppSubtleSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat

    @Environment(\.appAccessibilityPreferences) private var accessibilityPreferences

    func body(content: Content) -> some View {
        content
            .background(fillColor, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if accessibilityPreferences.increasedContrast {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                }
            }
    }

    private var fillColor: Color {
        if accessibilityPreferences.reduceTransparency {
            return Color(nsColor: .controlBackgroundColor)
        }
        return Color.secondary.opacity(accessibilityPreferences.increasedContrast ? 0.12 : 0.06)
    }
}

extension View {
    func appSubtleSurface(cornerRadius: CGFloat = AppMetrics.radiusMedium) -> some View {
        modifier(AppSubtleSurfaceModifier(cornerRadius: cornerRadius))
    }
}
