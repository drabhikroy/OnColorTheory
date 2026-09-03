# Typography decision  -  milestone 0.1

## Decision

Use **Atkinson Hyperlegible Next** as the default reading typeface, with Atkinson's regular, semibold, and bold variable-weight instances used for hierarchy. Keep standard macOS control behavior, a system-font fallback, and an explicit reader preference that switches the app to the macOS system font.

The bundled font is an unmodified variable TrueType file from the Google Fonts distribution:

- Family: Atkinson Hyperlegible Next
- Upstream: https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext
- Font SHA-256: `5a455d1cfa099b601ab70751bb9673e8fe1854dc4500c80e1a220d0d75e31745`
- License: SIL Open Font License 1.1
- License SHA-256: `aca6a428580965d2297d1b718042dd427c2a9443ece3b0d02d758e161e0c4030`
- Retrieved: 2026-08-27

The OFL text remains beside the source font and is copied into the built app bundle. OFL 1.1 permits an unmodified font to be embedded and redistributed with software when its copyright and license travel with it.

## Why it fits

Braille Institute designed the family for character recognition by readers with low vision. The design deliberately differentiates frequently confused forms, including `B/8`, `I/l/1`, `O/0`, and `p/q`, and uses open counters and distinct tails. The 2025 Next release adds seven weights, italics, a variable build, and support for more than 150 languages. Those characteristics suit both explanatory prose and dense numerical color values.

The face is substantially less typical in macOS software than San Francisco, Inter, Helvetica, or Arial, while remaining a restrained text face rather than a decorative novelty.

## What the evidence does and does not establish

No claim is made that Atkinson Hyperlegible Next is universally the most readable font. A systematic review of typeface legibility for adults with low vision found inconsistent results, and a 2025 peer-reviewed review concludes that legibility varies with the reading situation. Typeface, print size, weight, spacing, visual acuity, display conditions, language, and reader familiarity interact.

The selection therefore combines:

1. Published evidence favoring contextual testing over a universal-font claim.
2. The font's purpose-built character differentiation.
3. Its practical UI weight and language coverage.
4. A redistribution-safe license.
5. A system-font override and larger-text preference.

Atkinson itself still requires usability testing with low-vision readers, neurodivergent readers, and people using different scripts. The font's stated design intent is not a substitute for that testing.

## Alternatives considered

### Luciole

Luciole is unusually relevant: it was designed for low-vision readers, is less common, and has been evaluated in a peer-reviewed study of 145 French readers. The study found a slight advantage over some tested faces and a subjective preference among about half of participants with low vision - not a universal advantage. The current open distribution is suitable for redistribution. Luciole remains the leading candidate for a future user-selectable reading face, but Atkinson Next's seven-weight variable family is a better fit for this milestone's interface hierarchy and broad language coverage.

### Inclusive Sans

Inclusive Sans is OFL-licensed and explicitly designed around accessibility and character-level legibility. It is a sound alternative, but Atkinson's documented confused-character treatment and larger production family make it more suitable for this numerical workbench.

### macOS system font

San Francisco has the best native metrics, optical sizing, control integration, and OS-level familiarity. It does not meet the requested open-source and less-typical identity, so it remains an always-available reader preference rather than the default.

## Implementation constraints

- Body text begins at 15 points, above Apple's 13-point macOS default and 10-point minimum.
- Light, thin, and ultralight weights are not used.
- Reader text scales from 100% to 160% in Settings because macOS does not provide Dynamic Type.
- Long explanatory text is allowed to wrap and major workspaces scroll vertically.
- Numeric fields use tabular/monospaced-digit presentation where supported.
- Interface meaning never depends on typeface alone.

## Sources

- Braille Institute, Atkinson Hyperlegible family: https://www.brailleinstitute.org/freefont/
- SIL Open Font License 1.1: https://openfontlicense.org/
- Apple Human Interface Guidelines, Typography: https://developer.apple.com/design/human-interface-guidelines/typography
- Russell-Minda et al. (2007), *The Legibility of Typefaces for Readers with Low Vision: A Research Review*: https://doi.org/10.1177/0145482X0710100703
- Beier & Thiessen (2025), *Applying cognitive and perceptual science to typeface choices*: https://doi.org/10.1080/00140139.2025.2541255
- Perin et al. (2023), *Luciole, a new font for people with low vision*: https://pubmed.ncbi.nlm.nih.gov/37137180/
