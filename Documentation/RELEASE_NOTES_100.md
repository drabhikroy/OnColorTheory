# On Color Theory 1.0.0

The first public release.

On Color Theory is a macOS app for learning how color numbers behave, and for checking the ones you are about to use. Convert a color between notations and inspect every stage of the conversion. Test whether people can actually read it. Build a palette of named roles and export it to code. Find out why any of it works the way it does. One color travels with you: pick it once, and every workspace picks it up from there.

The name nods to *De Coloribus*, handed down in the Aristotelian corpus and rendered in English as *On Colors*, alongside the ordinary sense of color theory. Much of the material inside began as teaching material, built for the color portion of a data visualization course taught as an assistant professor at West Virginia University, and collected here in a form that does not depend on being in the room to explain it.

## Get it running

1. Download `OnColorTheory-1.0.0.dmg` from the assets below.
2. Open it, then drag On Color Theory to your Applications folder.
3. The build is signed locally rather than notarized, so the first launch needs **Control-click, then Open**, rather than a plain double-click. macOS will ask once; after that it opens normally.
4. On first launch, a short walkthrough introduces the workspaces. It will not reappear unless you open it again yourself, from Home, Help, or About.

`SHA256SUMS.txt` in the assets lets you confirm what you downloaded matches what was built.

Requires macOS 14 Sonoma or later, on Apple silicon.

## What is inside

**Work on a color.** Convert reads one color back in any supported notation. Check answers four questions about it: contrast against the five WCAG 2.2 thresholds, whether it fits a destination color space, how far apart two colors really are, and whether meaning survives without color. Build designs named roles rather than loose swatches and exports them.

**Understand color.** Learn runs four lessons on light, vision, measurement, and reproduction, each in three short parts. Explore asks you to predict a result, change one thing, then compare what you saw against the calculation. Reference holds definitions, equations, and standards, each with its source and the boundary of what it can tell you.

## Built to be checked, not taken on faith

Five color vision palettes, each audited to WCAG 2.2 AA against the deficiency it is named for. Every heading carries a level, so a screen reader can move through a page by structure. Text scale is adjustable, and Increased Contrast, Reduce Transparency, Reduce Motion, and Differentiate Without Color are all honored.

CIEDE2000 matches all thirty four pairs of the Sharma, Wu and Dalal verification dataset. CIELAB, Bradford adaptation, and Display P3 agree with the CSS Color 4 reference values. WCAG contrast reproduces the published worked examples. Every calculation names the standard behind it and states what it cannot tell you.

No account and no telemetry. Nothing is sent anywhere unless you turn on palette suggestions, which are off by default and talk only to an Ollama server you name, on this Mac or one you choose. Plaintext is refused to anything outside your own network. A [security review](https://github.com/drabhikroy/OnColorTheory/blob/main/Documentation/SECURITY_REVIEW_100.md) was carried out before this release.

## Planned for a later release

A **Brief History of Color** section and a **Color Theory** section. Neither ships in 1.0.0.

## More

Source, documentation, and the design decisions behind the app are all in the [repository](https://github.com/drabhikroy/OnColorTheory).

## License

Copyright 2026 Abhik Roy. Licensed under the PolyForm Noncommercial License 1.0.0. Personal study, teaching, academic research, and use by nonprofit and government organizations are all permitted. Commercial use is not.
