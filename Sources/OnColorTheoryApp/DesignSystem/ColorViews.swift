import AppKit
import SwiftUI

/// The standard grouped surface.
///
/// One card separates itself from the page with a fill and a hairline, and
/// with nothing else. A fill, a border, a colored corner stripe, and a shadow
/// each say "this is a group" on their own, so carrying several at once buys
/// nothing and costs a great deal once forty of these are on screen together.
///
/// The hairline stays because `windowBackgroundColor` and
/// `controlBackgroundColor` sit close together in dark mode, so a fill alone is
/// not reliably visible. It is drawn at low opacity in normal use and at full
/// strength under Increased Contrast, where a boundary has to be unmistakable.
struct AppCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content
    @Environment(\.appAccessibilityPreferences) private var accessibilityPreferences

    init(
        padding: CGFloat = AppMetrics.roomy,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(nsColor: .controlBackgroundColor),
                in: RoundedRectangle(cornerRadius: AppMetrics.radiusLarge, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge, style: .continuous)
                    .stroke(
                        Color(nsColor: .separatorColor)
                            .opacity(accessibilityPreferences.increasedContrast ? 1 : 0.30),
                        lineWidth: accessibilityPreferences.increasedContrast ? 1.5 : 1
                    )
            }
    }
}

/// Places two views side by side, or stacked once the width or the text size
/// will not hold the pair.
///
/// A custom layout rather than `ViewThatFits` because the split is uneven and
/// the threshold has to account for the text scale.
struct AdaptivePairLayout: Layout {
    let horizontalThreshold: CGFloat
    let leadingFraction: CGFloat
    let spacing: CGFloat

    init(
        horizontalThreshold: CGFloat,
        leadingFraction: CGFloat = 0.42,
        spacing: CGFloat = AppMetrics.regular
    ) {
        self.horizontalThreshold = horizontalThreshold
        self.leadingFraction = leadingFraction
        self.spacing = spacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard subviews.count >= 2 else {
            return subviews.first?.sizeThatFits(proposal) ?? .zero
        }

        let width = proposal.width ?? horizontalThreshold
        let sizes = measuredSizes(width: width, subviews: subviews)
        let height = isHorizontal(width: width)
            ? max(sizes.leading.height, sizes.trailing.height)
            : sizes.leading.height + spacing + sizes.trailing.height
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard subviews.count >= 2 else {
            subviews.first?.place(
                at: bounds.origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
            )
            return
        }

        let sizes = measuredSizes(width: bounds.width, subviews: subviews)
        if isHorizontal(width: bounds.width) {
            subviews[0].place(
                at: bounds.origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: sizes.leading.width, height: sizes.leading.height)
            )
            subviews[1].place(
                at: CGPoint(x: bounds.minX + sizes.leading.width + spacing, y: bounds.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: sizes.trailing.width, height: sizes.trailing.height)
            )
        } else {
            subviews[0].place(
                at: bounds.origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: bounds.width, height: sizes.leading.height)
            )
            subviews[1].place(
                at: CGPoint(x: bounds.minX, y: bounds.minY + sizes.leading.height + spacing),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: bounds.width, height: sizes.trailing.height)
            )
        }
    }

    private func isHorizontal(width: CGFloat) -> Bool {
        width >= horizontalThreshold
    }

    private func measuredSizes(
        width: CGFloat,
        subviews: Subviews
    ) -> (leading: CGSize, trailing: CGSize) {
        if isHorizontal(width: width) {
            let usableWidth = max(width - spacing, 0)
            let leadingWidth = usableWidth * leadingFraction
            let trailingWidth = usableWidth - leadingWidth
            return (
                subviews[0].sizeThatFits(ProposedViewSize(width: leadingWidth, height: nil)),
                subviews[1].sizeThatFits(ProposedViewSize(width: trailingWidth, height: nil))
            )
        }

        return (
            subviews[0].sizeThatFits(ProposedViewSize(width: width, height: nil)),
            subviews[1].sizeThatFits(ProposedViewSize(width: width, height: nil))
        )
    }
}

/// Progress through a numbered sequence, showing the count in text as well as

extension SRGBColor {
    var opaque: SRGBColor {
        SRGBColor(red: red, green: green, blue: blue)
    }

    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    var accessibleDescription: String {
        "\(hex), sRGB red \(red8), green \(green8), blue \(blue8), alpha \(alpha8)"
    }
}

extension DisplayP3Color {
    var swiftUIColor: Color {
        Color(.displayP3, red: red, green: green, blue: blue)
    }

    var accessibleDescription: String {
        "Display P3 red \(Format.decimal(red, places: 3)), green \(Format.decimal(green, places: 3)), blue \(Format.decimal(blue, places: 3))"
    }
}

/// A color field with a swatch, hexadecimal and component entry, and the
/// system picker.
struct EditableColorInput: View {
    let title: String
    @Binding var color: SRGBColor
    var allowsOpacity = false
    var swatchSize: CGFloat = 64
    var supportingText: String? = nil

    @State private var input: String
    @State private var showsError = false
    @Environment(\.appSemanticPalette) private var semanticPalette

    private let colorCore = ColorCore()

    init(
        title: String,
        color: Binding<SRGBColor>,
        allowsOpacity: Bool = false,
        swatchSize: CGFloat = 64,
        supportingText: String? = nil
    ) {
        self.title = title
        _color = color
        self.allowsOpacity = allowsOpacity
        self.swatchSize = swatchSize
        self.supportingText = supportingText
        _input = State(initialValue: color.wrappedValue.hex)
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppMetrics.compact) {
            ColorSwatchView(color: color, showsLabel: false)
                .frame(width: swatchSize, height: swatchSize)

            VStack(alignment: .leading, spacing: AppMetrics.snug) {
                Text(title)
                    .appFont(.headline)

                HStack(spacing: AppMetrics.snug) {
                    TextField("HEX or RGB", text: $input)
                        .appFont(.value)
                        .monospacedDigit()
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(applyInput)
                        .accessibilityLabel("\(title) color value")
                        .accessibilityValue(showsError ? "Invalid value" : "Valid value")
                        .accessibilityHint(
                            showsError
                                ? "Enter a valid HEX or RGB color."
                                : "Enter a HEX or RGB color, then press Return."
                        )

                    ColorPicker(
                        "Choose \(title.lowercased())",
                        selection: Binding(
                            get: { color.swiftUIColor },
                            set: { selected in updateFromPicker(selected) }
                        ),
                        supportsOpacity: allowsOpacity
                    )
                    .labelsHidden()
                }

                if showsError {
                    Label("Enter a valid HEX or RGB color.", systemImage: "exclamationmark.triangle")
                        .appFont(.caption)
                        .foregroundStyle(semanticPalette.warning)
                } else if let supportingText {
                    Text(supportingText)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(color.cssRGB)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppMetrics.compact)
        .appSubtleSurface(cornerRadius: 10)
        .onChange(of: color) { _, newValue in
            let displayed = allowsOpacity ? newValue : newValue.opaque
            if input != displayed.hex { input = displayed.hex }
            showsError = false
        }
        .onChange(of: input) { _, newValue in
            guard let parsed = try? colorCore.analyze(newValue).parsed.color else { return }
            let accepted = allowsOpacity ? parsed : parsed.opaque
            if accepted != color { color = accepted }
            showsError = false
        }
        .accessibilityElement(children: .contain)
    }

    private func applyInput() {
        guard let parsed = try? colorCore.analyze(input).parsed.color else {
            showsError = true
            AccessibilityAnnouncer.announce("Enter a valid HEX or RGB color.", priority: .high)
            return
        }
        color = allowsOpacity ? parsed : parsed.opaque
        input = color.hex
        showsError = false
    }

    private func updateFromPicker(_ selected: Color) {
        guard let converted = NSColor(selected).usingColorSpace(.sRGB) else { return }
        color = SRGBColor(
            red: Double(converted.redComponent),
            green: Double(converted.greenComponent),
            blue: Double(converted.blueComponent),
            alpha: allowsOpacity ? Double(converted.alphaComponent) : 1
        )
        input = color.hex
        showsError = false
    }
}

/// The backdrop behind translucent swatches, so partial alpha is visible
/// rather than blending into the surface.
struct CheckerboardView: View {
    let squareSize: CGFloat

    var body: some View {
        Canvas { context, size in
            let columns = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))
            for row in 0..<rows {
                for column in 0..<columns {
                    let isDark = (row + column).isMultiple(of: 2)
                    let rectangle = CGRect(
                        x: CGFloat(column) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(
                        Path(rectangle),
                        with: .color(isDark ? Color.secondary.opacity(0.20) : Color.secondary.opacity(0.08))
                    )
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// A color with its value in text.
///
/// The label is part of the swatch rather than optional decoration, since a
/// swatch with no numeric identification carries its meaning in hue alone.
struct ColorSwatchView: View {
    let color: SRGBColor
    var showsLabel = true
    @Environment(\.appAccessibilityPreferences) private var accessibilityPreferences

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CheckerboardView(squareSize: 12)
            Rectangle().fill(color.swiftUIColor)
            if showsLabel {
                Text(color.hex)
                    .appFont(.value)
                    .monospacedDigit()
                    .padding(.horizontal, AppMetrics.snug)
                    .padding(.vertical, AppMetrics.tight)
                    .background {
                        if accessibilityPreferences.reduceTransparency {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.regularMaterial)
                        }
                    }
                    .padding(AppMetrics.snug)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Color swatch")
        .accessibilityValue(color.accessibleDescription)
    }
}

/// One label and value pair, optionally linked to a reference term.
struct AlignedValueRowData: Sendable {
    let label: String
    let value: String
    var definitionID: String? = nil
}

/// Label and value rows on one shared label column, so the values line up and
/// can be read down.
struct AlignedValueGrid: View {
    let rows: [AlignedValueRowData]
    var labelWidth: CGFloat = 176
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow(alignment: .firstTextBaseline) {
                    Text(row.label)
                        .appFont(.body)
                        .frame(width: resolvedLabelWidth, alignment: .leading)
                        .gridColumnAlignment(.leading)

                    Group {
                        if let definitionID = row.definitionID {
                            TermHelpButton(conceptID: definitionID, showsTerm: false)
                        } else {
                            Color.clear
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(width: textScale >= 1.3 ? 28 : 20, alignment: .leading)
                    .gridColumnAlignment(.leading)

                    Text(row.value)
                        .appFont(.value)
                        .monospacedDigit()
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .gridColumnAlignment(.leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resolvedLabelWidth: CGFloat {
        textScale >= 1.3 ? labelWidth * 1.28 : labelWidth
    }
}

/// A single labeled value on the same column width the grid uses.
struct CoordinateRow: View {
    let label: String
    let value: String
    var definitionID: String? = nil
    var labelWidth: CGFloat = 176

    var body: some View {
        AlignedValueGrid(
            rows: [
                AlignedValueRowData(
                    label: label,
                    value: value,
                    definitionID: definitionID
                )
            ],
            labelWidth: labelWidth
        )
    }
}

/// Copies a value, announcing what was copied rather than only that
/// something was.
struct CopyValueButton: View {
    let value: String
    let description: String
    var label = "Copy"
    var isBordered = false
    @State private var copied = false

    private var copyButton: some View {
        Button(copied ? "Copied" : label) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(value, forType: .string)
            copied = true
            AccessibilityAnnouncer.announce("Copied \(description)")
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                copied = false
            }
        }
        .appFont(.body)
        .frame(minHeight: 30)
        .accessibilityLabel("Copy \(description)")
        .accessibilityValue(copied ? "Copied" : "Ready")
        .accessibilityHint("Copies \(description) to the clipboard")
    }

    @ViewBuilder
    var body: some View {
        if isBordered {
            copyButton.buttonStyle(.bordered)
        } else {
            copyButton.buttonStyle(.borderless)
        }
    }
}

/// The export snippet, closed by default so code does not sit in the scan path
/// of readers who are not exporting.
struct CodeExportDisclosure: View {
    let title: String
    let supportingText: String
    @Binding var language: CodeExportLanguage
    let snippet: (CodeExportLanguage) -> String
    @State private var isExpanded: Bool

    init(
        title: String,
        supportingText: String,
        language: Binding<CodeExportLanguage>,
        initiallyExpanded: Bool = false,
        snippet: @escaping (CodeExportLanguage) -> String
    ) {
        self.title = title
        self.supportingText = supportingText
        _language = language
        self.snippet = snippet
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: AppMetrics.compact) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AppMetrics.compact) {
                        languagePicker
                        Spacer(minLength: 12)
                        copyButton
                    }
                    VStack(alignment: .leading, spacing: AppMetrics.snug) {
                        languagePicker
                        copyButton
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    Text(snippet(language))
                        .appFont(.body)
                        .monospaced()
                        .textSelection(.enabled)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(AppMetrics.compact)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appSubtleSurface(cornerRadius: 10)
            }
            .padding(.top, AppMetrics.compact)
        } label: {
            VStack(alignment: .leading, spacing: AppMetrics.hairline) {
                Label(title, systemImage: "chevron.left.forwardslash.chevron.right")
                    .appFont(.headline)
                Text(supportingText)
                    .appFont(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var languagePicker: some View {
        Picker("Language", selection: $language) {
            ForEach(CodeExportLanguage.allCases) { language in
                Text(language.rawValue).tag(language)
            }
        }
        .pickerStyle(.menu)
        .appFont(.body)
        .frame(minWidth: 160, alignment: .leading)
    }

    private var copyButton: some View {
        CopyValueButton(
            value: snippet(language),
            description: "\(language.rawValue) code",
            label: "Copy \(language.rawValue)",
            isBordered: true
        )
    }
}
