# Build 027 validation record

**Version:** 0.27.0 (27)  
**Validation date:** August 31, 2026  
**Platform:** macOS, Swift 6.2 toolchain

## Automated checks

The complete test run passed with 99 tests in 22 suites. The run includes the deterministic color calculations, parsers, conversion paths, CIEDE2000 references, WCAG decisions, gamut checks, alpha compositing, persistence and recovery, Help and reset behavior, Model Assist boundaries, accessibility profiles, window identities, and version metadata.

The visual run produced 174 interface images. Direct review of Home in Light, Dark, and full-shell states confirmed that:

- the revised icon has lower saturation, lower highlight intensity, and less bloom;
- the geometry, color-space relationships, coordinate system, and measurement hub remain unchanged;
- the icon remains recognizable at the 16-pixel app-icon size;
- Home clips the image to a continuous rounded rectangle in both Light and Dark appearances;
- no square outer canvas appears around the icon.

## Build and artifact checks

- The production build completed successfully.
- Strict code-signature verification passed.
- The bundle reports version 0.27.0 and build 27.
- The bundle contains `AppIcon.icns`, `Assets.car`, the PNG master, and the self-contained SVG.
- The icon-generation and build scripts passed shell syntax checks.
- The SVG, asset catalog JSON, and application property list passed format validation.
- The release archive passed a complete ZIP integrity check.
- Source, tests, scripts, and documentation contain no em dash glyphs or generated-code attributions.

Public distribution still requires Apple Developer signing and notarization.

## Deliverables

- `Build/On Color Theory-027-v0.27.0.zip`  
  SHA-256: `d315f7daf98ede71607213ce6f28b5d34b141fb2ba822afa0cb2610f19afe59c`
- `Build/On Color Theory App Icon.svg`  
  SHA-256: `b28b5b434c2a09c0845235f2d3a8925c849fbacad5ca7b919d0a6a6a48133f06`
- `Sources/OnColorTheoryApp/Resources/Brand/OnColorTheoryAppIcon.png`  
  SHA-256: `dda834ef77a18a1908cb909228854b4a0f9d6edd5dc5fc2d79eb12a70d9d36c8`
