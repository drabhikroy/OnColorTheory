# Build 026 validation record

**Version:** 0.26.0 (26)  
**Validation date:** August 31, 2026  
**Platform:** macOS, Swift 6.2 toolchain

## Automated behavior and calculation checks

The complete test run passed with 99 tests in 22 suites. Coverage includes:

- sRGB, linear-light, XYZ, Lab, LCh, Oklab, OkLCh, HSL, Display P3, alpha, and luminance conversions;
- all 34 published supplemental CIEDE2000 reference pairs;
- WCAG contrast, source-over compositing, gamut boundaries, interpolation, and interface-palette evaluation;
- parsing, serialization, code export, scientific evidence, lesson handoffs, and Reference content;
- Color Tray persistence and failure recovery, workspace migration and recovery, single-instance window identities, screen-sample normalization, and editing commands;
- Model Assist schema, request boundaries, safe model names, transport rules, cancellation, natural-language rationale requirements, and local cleanup boundaries;
- Dark appearance registration, ordinary reset behavior, complete first-run reset behavior, and walkthrough state.

## Rendered interface review

The visual test run produced 174 interface images. The reviewed states include Home, app shell, Help Start here, Help Reset On Color Theory, every main workspace, focused destinations, Light and Dark appearances, enlarged text, increased contrast, Differentiate Without Color, reduced motion, and reduced transparency.

Direct inspection confirmed:

- the luminous app identity appears on Home and remains recognizable at small app-icon sizes;
- the Home headline is exactly "See color more clearly";
- the Reset topic uses the established rounded Help presentation and clearly separates ordinary reset from optional local cleanup;
- the Reset explanation names the Dark default, recoverable Trash behavior, walkthrough rule, and external-server boundary;
- the version has adequate spacing in the Help sidebar.

## Build and artifact checks

- The production Swift build completed successfully.
- `codesign --verify --deep --strict` passed for the app bundle.
- The bundle reports version 0.26.0 and build 26.
- `AppIcon.icns`, `Assets.car`, the high-resolution PNG, and the self-contained SVG are present in the bundle.
- The icon-generation and app-build scripts passed shell syntax checks.
- The SVG passed XML validation, the asset catalog JSON passed JSON validation, and the app property list passed property-list validation.
- The release archive passed a complete ZIP integrity test.

## Security and recovery review

- No arbitrary network-load entitlement is enabled.
- External addresses require HTTPS; HTTP is limited to localhost and private-network destinations.
- Model prompts and results remain size-bounded and schema-validated, and model output cannot supply scientific calculations.
- Reset cleanup is limited to the standard local Ollama application and model locations.
- Local cleanup moves items to the Trash instead of permanently deleting them.
- Reset never sends model or application deletion requests to an external server.
- Color Tray persistence failure prevents a reset from being reported as a complete first-run reset.
- Source, tests, scripts, and documentation contain no em dash glyphs, placeholder task markers, forced casts, forced `try`, or generated-code attributions. Runtime source and scripts contain no historical implementation comments.

Public distribution still requires Apple Developer signing and notarization. Manual VoiceOver, keyboard-only workflow, real Ollama installation, external-server, privacy, comprehension, and representative-user testing remain external release gates.

## Deliverables

- `Build/On Color Theory-026-v0.26.0.zip`  
  SHA-256: `ae51f5458e05118eb3a72279f287dd7ad13029b8dc342f1bc2bf1ee781aa4144`
- `Build/On Color Theory App Icon.svg`  
  SHA-256: `7a2efc9b63a0b4f1daec9376ce2a19a2ce61522b6ae6866a883e0666d8cb7e1b`
- `Sources/OnColorTheoryApp/Resources/Brand/OnColorTheoryAppIcon.png`  
  SHA-256: `75d8d46a5f4e603ef5877ec909d712af3cd51d8dbed19e2dd592955391066840`
