import SwiftUI

/// The spacing and radius scale every layout in the app is built on.
///
/// The steps below are the only values layout code should use. Spacing chosen
/// freely at the point of use gives every screen a slightly different rhythm,
/// and an app whose pages disagree about spacing reads as unsettled even when
/// no single number is wrong.
///
/// The steps are deliberately few and unevenly spaced, growing roughly
/// geometrically, because a scale with a step every four points offers so many
/// near-identical choices that it stops being a constraint at all.
///
/// `Scripts/standards/metrics_gate.py` rejects any spacing, padding, or corner
/// radius literal that is not one of these.
enum AppMetrics {
    /// Between a label and the value it belongs to. Reads as one unit.
    static let hairline: CGFloat = 2

    /// Between lines of one thought, such as a title and its summary.
    static let tight: CGFloat = 4

    /// Between related rows inside a group.
    static let snug: CGFloat = 8

    /// The default gap between controls, and the inner padding of small chrome.
    static let compact: CGFloat = 12

    /// Between groups inside a card, and the inner padding of a card.
    static let regular: CGFloat = 16

    /// Between a heading and the content it introduces.
    static let roomy: CGFloat = 20

    /// Between cards on a page.
    static let section: CGFloat = 24

    /// The outer margin of a workspace, and the gap between major regions.
    static let page: CGFloat = 32

    /// Corner radius for small chrome such as badges and inline controls.
    static let radiusSmall: CGFloat = 6

    /// Corner radius for fields, swatches, and panels inside a card. The
    /// common case.
    static let radiusMedium: CGFloat = 10

    /// Corner radius for a card itself, and for anything that reads as a card.
    ///
    /// This is the largest radius the app uses. A wider one belongs to a
    /// window or a sheet, and using it on a card makes a small panel claim the
    /// weight of a whole page.
    static let radiusLarge: CGFloat = 14
}
