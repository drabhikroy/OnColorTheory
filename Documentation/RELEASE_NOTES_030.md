# On Color Theory 0.30.0 (build 30)

## Renamed

The app was called Color Science. That name was already taken, so it is now On
Color Theory, after the pseudo-Aristotelian treatise *De Coloribus*, rendered in
English as *On Colors*, crossed with the ordinary sense of color theory.

The rename reaches the bundle identifier (`app.oncolortheory.learning`), the
saved-session key, and the window autosave prefix. Nothing had shipped publicly
under the old identifiers, so there is no stored state to migrate. Anyone
running a local build from before this release will find their saved workspace
and window positions unread, which is a first-launch experience rather than data
loss.

The window autosave prefix and the key prefix used to clear saved frames were
two separate string literals in two files that had to agree. They are one
constant now, with a test that fails if they ever disagree.

A presentation release. No color mathematics, no analysis, and no stored data changed. Every gate that passed in 0.29.0 still passes, and the layout scale is now stricter than it was.

## Why this release exists

The app was doing too much to say the same thing. Forty three cards each drew four separate devices to announce that they were a group. Every page opened with a boxed header that repeated the sidebar row the reader had just clicked. Twenty five uppercased labels sat above headings, mostly restating the card beneath them. Four of the eight text roles occupied a single point band, so nothing below a title had a size of its own. The result was busy in a way that no individual screen was responsible for.

## Cards

`AppCard` now separates itself from the page with a fill and a hairline. The full-strength border, the accent corner stripe, and the fourteen point shadow are gone. The hairline draws at low opacity normally and at full strength under Increased Contrast, where a boundary has to be unmistakable. It stays rather than going to fill alone because the window and control background colors sit close together in dark mode.

Card radius moved from twenty, the page-level value, to fourteen. `AppMetrics.radiusHeader` was removed outright, so the layout gate now rejects a twenty point radius anywhere. The two workspaces that hand-rolled their own gradient, tinted border, and shadow rather than using the shared card, Explore and Reference, use the shared card treatment.

## Headings

The page header is a title and one supporting line, set directly on the page. The card, the eighty two point icon, the accent capsule, the border, and the label above the title are gone from all seven workspaces.

`DestinationHeader` gained a `context` slot for a fact a title cannot carry, such as "Step 3 of 5" or "Foundation, 3 short parts". That line is spoken rather than hidden, because a reader who cannot see the page needs a position in a sequence as much as anyone. Labels that carried no information were removed rather than relabeled.

`PanelHeading` has no slot for a small uppercased label at all.

## Type

The eight roles are 12, 14, 16, 18, 21, 25, and 30 points, rising by roughly an eighth per step, with `value` at the body size and differing by monospacing. Body drops by one point. Large numeric readouts keep the largest role, since a measured value should be the biggest thing on a results card. The Reference reader term dropped a step, since it was outranking the page title above it.

## Density

Check lost a navigation layer. The strip above the results was a bordered panel that repeated the selected rail button's title and summary word for word before offering the level picker; it is now a plain title and the picker.

Thirteen dividers were removed under one rule: a divider earns its place only when the block after it has no heading of its own, because a heading already separates. The remaining twenty six sit between a rail and a reader, between list rows, or in a menu, which is what a divider is for.

Convert lost two dividers and two micro-labels above headings. Home lost a hand-rolled hero card and three shouted labels. The Explore experiment cards lost a caption that read identically on all four of them.

## Heading levels

Every heading in the app now carries a level as well as the header trait: eight at level one, forty seven at level two, four at level three. Fifty three of these had the trait and no level, so VoiceOver rotor navigation saw them as a flat list of equal items.

The previous release notes deferred this on the grounds that telling a heading from a control label needs the running app. That reasoning was wrong. An element carrying the header trait has already been declared a heading by whoever wrote it; the only open question was its level, and nesting answers that. A window's own title is level one, a card or section heading on a page is level two, and a heading for an item nested inside such a section is level three.

One heading changed type role in the process. "Sources and limitations" sat at `title2`, the same size as the concept term above it inside the same reader, which is the flatness the type scale exists to prevent. It drops to `headline`.

## Shared components

Eighteen hand-built heading blocks, a `title2` with the header trait followed by a `callout` summary, became `PanelHeading` calls. Heading level, spacing, and type role are now decided in one place rather than re-decided at each site.

## Housekeeping

Six hundred and seven spacing and padding literals moved onto named `AppMetrics` constants, along with card padding, every pair-layout gutter, and the two default radii the layout gate could not see because they were default parameter values. The pair layout's own default gutter was eighteen points, which was not on the scale at all. The only bare numbers left in layout code are deliberate zeros.

Net change across thirty two files is 970 lines added and 1,103 removed.

## Menu, About, and license

The menu bar gains an About window, replacing the stock About item. It carries
the app mark, the version, the author line, and links to the license, the
releases page, and the source. The Help menu gains the same three links.

Release notes are a link rather than bundled text, because notes written into
the app can only describe the build they shipped in. The copy a reader has is
always one version behind the one they are about to install.

`LICENSE.md` is at the repository root, reproducing the PolyForm Noncommercial
License 1.0.0 word for word with the Required Notice naming the copyright
holder. The author and license lines also appear in Settings under About and in
the Help footer. The writing gate now skips license files, since editing one to
satisfy a house style rule would change its legal meaning.

## Corrections

`workspaceSession` is no longer `@Published`. A session write is a side effect
of almost every interaction and many of those writes originate inside a SwiftUI
update, which is what produced twenty four repetitions of "Publishing changes
from within view updates is not allowed" in the console. The value still changes
synchronously, so a read straight after a write sees the new session; only the
notification is deferred, and it is coalesced.

One evidence record cited the right paper by the wrong title. The Kingdom
citation's DOI, journal, volume, pages, and PMID were all correct, but its title
was a paraphrase rather than the published one.

## Not verified

Nothing here is compiler verified. Run `swift build` and `swift test` first.

The visual result is unreviewed. Two judgments in particular want a running app:

- The hairline opacity was chosen from the color definitions, not from a screen. If cards read as faint, that is one number in `AppCard`.
- Body text is one point smaller than it was. The text scale preference still multiplies the whole ladder, so the hierarchy holds at every setting.

The heading levels themselves are worth a VoiceOver pass. The nesting rule is sound, but a level assigned from source structure can still disagree with how a screen actually reads.
