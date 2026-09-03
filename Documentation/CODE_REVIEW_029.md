# Code review, On Color Theory 0.28.0 to 0.29.0

Reviewed on September 1, 2026 against the source tree, 21,474 lines of Swift
across 54 files, plus documentation and scripts. No Swift toolchain and no macOS
were available, so nothing in this round is compiler verified. Every change was
checked by bracket balance, by reading, and by the two new gates. The build and
the test suite have to be run on a Mac before this ships.

## Findings, by severity

### 1. Every color-vision palette failed the deficiency it was named for

Severity: high. Fixed.

`AppColorVisionPalette` offers Protan, Deutan, and Tritan modes. Simulating each
condition and measuring CIE76 separation between the five semantic roles gives
the following worst pairs, before the change.

| Mode | Scheme | Simulation | Pair | Separation |
| --- | --- | --- | --- | --- |
| Deutan | dark | deuteranopia | accent, secondaryCue | 1.7 |
| Deutan | light | deuteranopia | accent, secondaryCue | 3.3 |
| Protan | dark | protanopia | accent, secondaryCue | 4.2 |
| Tritan | light | tritanopia | accent, warning | 6.5 |
| Universal | light | tritanopia | accent, positive | 3.3 |

Thirty three pairs fell below a 24 delta E floor in total. A separation of 1.7 is
not a near miss. Those two roles are one color for that reader.

The cause was structural. All five roles were separated by hue, and hue is the
axis a dichromat viewer loses. Deutan set its accent to violet and its secondary
cue to blue, which are adjacent on the surviving axis, and Protan set the same
pair the other way around.

The repair holds each role near its original hue and saturation and spreads the
roles across lightness, which every viewer keeps. All five modes now clear both
floors under the simulations they are meant to survive. `Universal` is held to
all three simulations at once, which is the hardest case and took the largest
change.

Two values are worth reviewing by eye rather than by number.
`deutan light accent` resolves to `#21143E`, which is very dark for an accent,
and `protan light critical` to `#4A131C`. Both are consequences of holding
4.5 to 1 against white while staying separable, and both pass, but you may want
to hand-tune them.

### 2. The color-vision setting reached about a third of the interface

Severity: high. Fixed.

Forty call sites across sixteen files used `Color.accentColor`, which follows
the accent chosen in macOS System Settings rather than the app's palette. Two of
them were `SelectableCardChrome` and `IndexedSelectionBadge` in
`AppAccessibility.swift`, which every screen reuses to show selection. Choosing
Protan or Monochrome therefore left selection state, step badges, link color,
and most emphasis unchanged.

All forty now read `appSemanticPalette`. Sixteen view types gained the
environment declaration. `AppSectionIdentity.neutral` was a static property and
could not read the environment, so it falls back to `.secondary` instead.

This is the same defect Rank & Folder carried at 1.0.1, at a similar scale, and
it is worth adding the grep to a gate on the other projects too.

### 3. The app icon was generated media with embedded provenance

Severity: high. Fixed.

`OnColorTheoryAppIcon.png`, `OnColorTheoryAppIcon.svg`, and the built `.icns` each
carried a signed content provenance manifest from the tool that produced the
image, including a recorded unbound watermark action. That last entry means an
invisible watermark was written into the pixels, so stripping the metadata chunk
would not have removed the claim.

Separately, `Scripts/generate-app-icons.sh` was building the `.svg` by base64
encoding the PNG into a single `<image>` tag. The vector file contained no
geometry and never had.

`Scripts/build-icon.py` replaces it and generates the mark from paths. Nothing
in the tree now carries generator provenance.

### 4. Thirty nine em and en dashes in source and documentation

Severity: medium. Fixed.

Including three in palette titles and explanations a reader sees, where the two
color names in each pair were joined by an en dash. Numeric ranges became
`0 to 255`, compound names took a hyphen, and paired concepts were spelled out.
`THIRD_PARTY_NOTICES.md` is left verbatim, since that text is reproduced from
upstream licenses and must not be edited to suit a local style rule.

Note that a scan of the compiled binary reported zero. That was wrong. GNU
`strings` splits on the first non-ASCII byte, so every affected line was silently
dropped from its output. Source scanning found them immediately.

### 5. Banned lexicon in shipped strings, identifiers, and documentation

Severity: medium. Fixed.

`Journey` appeared in nine identifiers including `ConversionJourneyBuilder` and
`CoordinateJourneyGraphic`, now `Route`. `Enable`, `Translate`, `Actionable`,
`Guarantee`, `Strengthen`, `Techniques`, `Ensure`, and `Drawn` were rewritten in
prose. Swift and platform vocabulary such as `alignment` and
`CGRect.intersection` is allow-listed in the gate rather than renamed.

### 6. Section icons were indistinguishable in the sidebar

Severity: medium. Fixed.

`DesignedSymbolIcon` drew motif artwork, then covered it with an opaque disc
occupying 46 percent of the frame, then drew the symbol at 27 percent of the
frame on top. At the sidebar size of 30 points the motif was a few pixels and
carried nothing, so seven sections resolved into seven near-identical rounded
squares in the same accent gradient.

Below 40 points the motif and disc are now suppressed and the symbol renders at
52 percent of the frame in the accent color. At card size the motif returns.

### 7. Section identity discarded its own input

Severity: low. Documented rather than changed.

`AppSectionIdentity.init(section:palette:)` ignores `section` entirely and always
returns `palette.accent`. Seven per-section hues would have to stay distinct from
each other and from the five semantic roles at once, which no palette survives
under simulation, so the behavior is correct and the parameter is what misleads.
A doc comment now states this. Removing the parameter would touch every call
site and is a separate change.

### 8. Toolbar carried six labeled controls

Severity: low. Fixed.

Model Assist, Color Tray, Inspector, Display, and Help all rendered with title
and icon, plus the window controls. Settings, Help, and the walkthrough moved
into one menu, leaving three controls in the primary group.

### 9. Documentation coverage

Severity: medium. Partially fixed.

Of 278 top-level types, 11 carried a doc comment. Comment density sat below one
percent in forty three of fifty four files, and at zero in most.

All 278 top-level types are now documented. Comments explain why a choice was
made where that is not obvious rather than restating the name, for example why
`TransferFunctions` carries the sign through instead of clamping, why Lab is
calculated under D50 while Oklab stays under D65, why `LCHColor` holds an
optional hue rather than zero for a neutral, why `AppEnvironmentHost` exists at
all, and why `AdaptivePairLayout` is a custom layout rather than a
`ViewThatFits`.

`Scripts/standards/doc_coverage.py` now fails the build on any undocumented
top-level type.

### 10. Historical comments

Severity: low. Nothing found.

The scan for version references, `TODO`, `FIXME`, `previously`, `formerly`, and
similar came back empty across the whole tree. The writing gate now checks for
them on every run so it stays that way.

### 11. Property list gaps

Severity: low. Fixed.

Added `NSHumanReadableCopyright`, `LSApplicationCategoryType`, and
`ITSAppUsesNonExemptEncryption`. `LSMinimumSystemVersion` remains 14.0 and the
binary remains arm64 only, so Intel Macs cannot launch it. That is a product
decision rather than a defect and was left alone.

### 12. Force unwrapping

Severity: informational. Left alone.

Eighteen `URL(string:)!` calls on compile-time constant literals, and one
`firstIndex(of: self)!` on a `CaseIterable` conformance in `OllamaSetupView`.
None can fail at runtime given the values present. Converting them would add
handling for conditions that cannot occur.

## Addendum: one compile error from the accent migration, found on first build

Severity: high. Fixed.

`Sources/OnColorTheoryApp/Features/Check/GamutAnalysisView.swift` failed to
build. `GamutAnalysisView` declares its environment palette as
`semanticPalette`, not `palette`, and the blanket `Color.accentColor` to
`palette.accent` replacement in finding 2 wrote a bare `palette.accent`
reference into that scope regardless. `palette` was never in scope there.

The verification run at the end of that pass checked every type using
`palette.<role>` for the substring `appSemanticPalette` anywhere in its body,
to confirm an environment declaration existed. That check passed here, because
`@Environment(\.appSemanticPalette) private var semanticPalette` contains the
substring `appSemanticPalette` regardless of what the property is actually
named. The check confirmed a declaration existed without confirming it matched
the name being used. This is a gap in the review, not a limitation with an
excuse.

A second scan, keyed on the actual variable name used at each call site rather
than on that substring, found exactly one occurrence across the tree and
confirmed no matching occurrence in the other direction. The single line is
fixed.

## Second round findings

### 13. Console noise at launch is not a defect in this app

Severity: informational. No change.

The `com.apple.linkd.autoShortcut` errors and the App Intents registration
failures come from running the bare executable rather than the app bundle. The
last line gives it away, since a process with no `Info.plist` has no bundle
identifier for the intents framework to register against. This app declares no
App Intents at all, so nothing is being lost.

Run `Scripts/build-app.sh` and launch `Build/On Color Theory.app` and the bundle
identifier line stops. The `linkd` messages may persist for a locally signed,
un-notarized build. They are system noise and cost nothing.

### 14. Separation was measured with the wrong instrument

Severity: high. Fixed.

The first round measured role separation as CIE76 delta E in CIELAB. That was
the wrong choice twice over. CIELAB is not uniform across differences this
large, and the alternative already in the app, CIEDE2000, is specified for
small differences under reference conditions and is not an instrument for
asking whether two cues are categorically distinct.

Separation is now measured in Oklab, which is built for this range and which
the app already reports. The implementation uses the constants from
`ColorEngine.swift` and reproduces Ottosson's published reference values for
white, black, and the three primaries exactly.

Under the sounder metric, eleven pairs from the first round's repair failed. The
palettes were solved again against it.

The simulations were checked against three properties they must hold. All three
projections are idempotent, none moves the neutral axis, and each collapses the
confusion its condition names. Those checks pass.

### 15. Palette values were separable but not always correct

Severity: medium. Fixed.

A search told only to make distances as large as possible runs every role toward
white or black, which satisfies the inequality and destroys the role. That is
how the first round produced a near-black accent. Each role is now confined to a
hue window, a lightness band, and a chroma floor, so it stays a color a reader
would name correctly.

Every mode now clears 4.5 to 1 contrast and an Oklab separation of at least 12.8
under the simulations it is meant to survive. For scale, white to black is 100
on that measure and red to green is 52.

Three values remain worth your eye rather than your build. Under tritanopia the
warm roles collapse, so `warning` and `critical` can only separate by lightness,
which is why Tritan dark critical `#C49492` reads muted and Tritan dark warning
`#FCD5B9` reads pale. Universal light critical `#4D1E0C` is a dark brown red.
These are consequences of holding five roles apart, not arbitrary picks.

### 16. There was no layout scale

Severity: high. Fixed.

This is the measurable form of the interface reading as messy. The source held
twenty five distinct spacing values, twenty two padding values, and eighteen
corner radii, every one a bare number at the point of use. No single number was
wrong. No two screens agreed, so each page carried its own rhythm.

`AppMetrics.swift` defines the scale and `Scripts/standards/metrics_gate.py`
enforces it. Five hundred and twenty three literals moved onto it. Most moved by
one or two points. Anything that depended on a specific gap will have shifted
and is worth a look with the app running.

Call sites still use numeric literals rather than the named tokens. The gate
enforces the values either way; migrating the call sites is mechanical and
pending.

### 17. No heading structure reached assistive technology

Severity: high. Fixed.

Both shared heading components carried the header trait and no level, so every
heading in the app was flat and equal and rotor navigation could not tell a page
title from a panel title. The page header is now level one and panel headings
are level two.

The decorative eyebrow above a panel heading was also audible, so a screen
reader read a shouted, uppercased repetition of the surrounding card name before
each panel title. The page level header had always hidden its own eyebrow. The
panel heading now does too.

**Still open.** This covers headings that go through the two shared components.
Group titles written as plain styled text inside a card are not covered. A scan
turns up roughly a hundred candidates, but most are control labels rather than
headings, and telling the two apart is not reliably decidable from source. That
pass needs the app running.

## Open items

- **Nothing is compiler verified.** Run `swift build`, `swift test`, and
  `Scripts/build-app.sh` on your Mac before anything else.
- **Three palette values read oddly** for the structural reason given in
  finding 15.
- **Palette changes are unreviewed visually.** The numbers pass; how the modes
  look in use has not been seen.
- **The layout snap is unreviewed visually.** Five hundred and twenty three
  values moved.
- **Toolbar and sidebar changes are unreviewed visually** for the same reason.
- **Heading levels inside cards** need the pass described in finding 17.

## What runs as a gate now

`Scripts/standards/run-all.sh` runs both checks and exits non-zero on any
finding.

`writing_gate.py` looks for em and en dashes, contractions, banned lexicon, and
historical comments across Swift, Markdown, shell, JSON, plist, and Python.
Upstream license text is skipped.

`palette_audit.py` parses the live values out of `AppAppearance.swift` rather
than holding a second copy, then checks WCAG contrast against each canvas and
CIE76 separation between every role pair under the simulations each mode is
meant to survive. Keeping a copy of the numbers here is exactly the drift this
script exists to prevent.
