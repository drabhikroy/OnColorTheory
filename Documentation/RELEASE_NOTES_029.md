# On Color Theory 0.29.0

## Color vision palettes

Every palette failed the deficiency it was named for. The audit added in this
release simulates protanopia, deuteranopia, and tritanopia and measures how far
apart the five semantic roles stay. Under deuteranopia the Deutan palette put
its accent and its secondary cue 1.7 delta E apart, which is one color, not two.
Protan separated its accent and secondary cue by 4.2, and Tritan separated its
accent and warning by 6.5. Thirty three pairs failed in total.

The cause was that all five roles were separated by hue alone. A viewer with
dichromacy works with roughly two dimensions rather than three, so five
hue-separated roles cannot survive. The roles now spread across lightness as
well, which is the channel that stays intact. Every mode clears both floors,
4.5 to 1 contrast against its canvas and 24 delta E between any two roles under
the simulations that mode is meant to survive.

## The color vision setting now reaches the interface

Forty places in the interface used the accent selected in macOS System Settings
rather than the app's own palette, including the two selection primitives that
every screen reuses. Choosing Protan, Deutan, Tritan, or Monochrome therefore
changed very little. Those forty places now read the palette.

## App icon

The previous icon was generated media. All three icon files carried a signed
provenance manifest naming the generator, and the manifest recorded that an
invisible watermark had been written into the pixels, so removing the metadata
would not have removed the claim. The file with the .svg extension held one
base64 PNG and no geometry, and the icon builder script produced that wrapper
deliberately.

The icon is now generated from geometry. Its three overlapping fields take their
hues from the interface palette, and their overlap colors are calculated by
screen compositing rather than picked, so the mark performs the additive result
the Mixing experiment teaches. The plate follows the 824 in 1024 macOS grid with
transparent corners, and the asset catalog carries every required size.

## Interface

- Sidebar icons drop their motif artwork below 40 points and draw the symbol at
  twice the size instead. At 30 points the motif was smaller than a few pixels
  and an opaque disc covered nearly half of it, so seven sections resolved into
  seven near-identical squares.
- The toolbar drops from six labeled controls to three. Settings, Help, and the
  walkthrough move into one menu, since they are opened occasionally rather than
  while working.
- Section identity resolves to the palette accent, and says why in the source.
  Seven per-section hues would have to stay distinct from each other and from
  the five semantic roles at once, which no palette survives under simulation.

## Writing standards

Thirty nine em and en dashes are gone from source and documentation, along with
every banned lexicon term. Third party notices are left verbatim, since that
text is reproduced from upstream licenses.

## Documentation

All 278 top-level types now carry a doc comment. Comments explain why a choice
was made where that is not obvious, rather than restating the name. Examples
include why the transfer functions carry the sign through instead of clamping,
why CIELAB is calculated under D50 while Oklab stays under D65, why LCh holds an
optional hue rather than zero for a neutral, and why auxiliary windows need
their own environment host.

## Build gates

`Scripts/standards/run-all.sh` runs both new checks. The writing gate looks for
dashes, contractions, banned terms, and historical comments. The palette audit
reads its values straight out of `AppAppearance.swift` rather than holding a
copy, so it cannot drift away from the app it checks.

`Scripts/build-icon.py` replaces `Scripts/generate-app-icons.sh` and writes the
asset catalog, the brand files, and an icns from one set of geometry.

## Property list

Added `NSHumanReadableCopyright`, `LSApplicationCategoryType`, and
`ITSAppUsesNonExemptEncryption`.

## Build fix after first review

`GamutAnalysisView` failed to build. Its environment palette is named
`semanticPalette`, and the accent migration wrote a bare `palette.accent` into
that scope. One line, now reads `semanticPalette.accent`. See
`Documentation/CODE_REVIEW_029.md` for how the original verification missed it.

## Second round

**Separation is measured in Oklab.** The first pass used CIE76 in CIELAB, which
is not uniform across differences this large. Under the sounder metric eleven
pairs from that pass failed, and every palette was solved again. The
implementation reproduces Ottosson's published reference values exactly, and the
three dichromat projections are checked for idempotence and for leaving the
neutral axis untouched.

**Palette values are now constrained to stay correct, not only separable.** Each
role sits inside a hue window, a lightness band, and a chroma floor, so no role
can be pushed toward white or black to win distance at the cost of meaning.

**One layout scale.** `AppMetrics.swift` defines it and a new gate enforces it.
Twenty five spacing values, twenty two padding values, and eighteen corner radii
became eight and four. Five hundred and twenty three literals moved.

**Heading structure reaches assistive technology.** The page header is level one
and panel headings are level two, so rotor navigation can tell them apart. The
decorative eyebrow above a panel heading no longer reads aloud.

**The "drawn" rule is now sense-specific.** It is allowed for actual rendering
and banned where it means pulled or derived. The gate checks the phrase rather
than the word.
