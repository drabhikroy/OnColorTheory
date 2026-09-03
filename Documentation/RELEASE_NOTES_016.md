# Build 016  -  Focused color workspaces

**Version:** 0.16.0 (16)  
**Date:** August 30, 2026  
**Status:** Development preview

## What changed

- Replaced the decorative eight-color workspace spectrum with one consistent structural accent and separate semantic positive, caution, and critical roles.
- Removed spectrum ribbons, background color glows, large header motifs, per-card section hues, and unused spectrum data while leaving exact scientific colors untouched.
- Rebuilt the Learn library as four compact path selectors plus one focused preview and one consistently positioned primary action.
- Removed duplicate explanatory surfaces in Learn and Explore, the repeated representation in Home, and the duplicate Hex label on the Inspector swatch.
- Added a native screen sampler to the Color Inspector for selecting a pixel inside On Color Theory, another app, or another display.
- Normalized sampled pixels to sRGB and recorded the working color's Hex, RGB, and Alpha without changing the current workspace.
- Rebuilt Inspector values as three explicit aligned columns for labels, definition buttons, and values, including 160% text-size adaptation.
- Added visible Display access to the global toolbar and an Appearance & color-vision options link inside the Inspector.
- Renamed the Settings cue section to Color-vision accessibility and simplified its preview to the roles the app actually uses.

## Verification

- 71 tests across 17 suites pass.
- Focused sampling tests cover sRGB normalization, alpha preservation, and workspace continuity.
- Dedicated Inspector snapshots cover light, dark, and 160% text-size states.
- The complete visual matrix renders every primary workspace, focused workspaces, equations, error states, combined system-accessibility preferences, and all six selectable interface-cue palettes.
- Debug and release app bundles build and pass strict ad-hoc code-signature verification.
- The packaged archive is `Build/On Color Theory-016-v0.16.0.zip`.

## Remaining release gates

Build 016 is not an accessibility certification or external release candidate. Manual screen-sampler permission, cancellation, focus restoration, multi-display, keyboard, VoiceOver, display scaling, measured contrast and target sizes, diagnostic color-vision simulation, clean relaunch, schema migration, performance, comprehension, and representative-user testing remain open. Public distribution also requires Developer ID signing and notarization.
