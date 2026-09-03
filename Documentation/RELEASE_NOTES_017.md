# Build 017  -  Resizable tools and model-assisted palette starts

**Version:** 0.17.0 (17)  
**Date:** August 30, 2026  
**Status:** Development preview

## What changed

- Stabilized the interface-cue theme hierarchy so changing to or from System accent no longer replaces the Settings content tree or resets its scroll position.
- Moved Reading preview into the end of Reading and removed its redundant standalone section.
- Replaced the fixed Inspector, Tray, and definition popovers with independently resizable macOS windows; Settings is now resizable horizontally, vertically, and from its corners too.
- Kept the app's text size, font, appearance, cue palette, and macOS accessibility preferences consistent across every auxiliary window.
- Shortened screen-sample processing by analyzing the already-normalized sRGB pixel directly instead of serializing and reparsing it; the canonical 8-bit color and alpha still match the displayed Hex and RGB values.
- Added optional Ollama settings with guided local discovery/model download and an externally managed server path.
- Added installed-model selection, connection status, local/external privacy disclosure, and model-specific error reporting.
- Added a fourth Palette Studio stage, Recommend, for requesting four role colors and rationales from the selected model.
- Validated model output as four opaque `#RRGGBB` roles, then calculated the existing three named relationship checks with On Color Theory's deterministic engine before a proposal can be applied.
- Removed the unused manual-model placeholder card and stale tray/inspector toggle helpers.

## Verification

- 75 tests across 19 suites pass.
- New tests prove typed screen colors bypass text parsing, structured model proposals preserve role order, invalid or alpha-bearing model colors are rejected, and model discovery selects an installed provider.
- The full visual matrix renders the new Recommend page along with every existing primary and focused workspace, Settings, Inspector states, cue palettes, light/dark appearances, enlarged text, and combined system-accessibility preferences.
- Debug and release app bundles build and pass strict ad-hoc code-signature verification.
- The packaged archive is `Build/On Color Theory-017-v0.17.0.zip`.

## Ollama boundary

Ollama and model weights are not bundled. Guided local setup requires Ollama to be installed and running once; On Color Theory can then discover, download, and select models through its local API. External mode uses the address supplied by the user and warns that the brief and current palette are sent there. Model licensing remains model-specific.

Model output is advisory. Contrast, conversion, gamut, difference, and simulation results remain deterministic app calculations and are not read from the model response.

## Remaining release gates

Build 017 is not an accessibility certification or external release candidate. Manual window restoration, focus, keyboard, VoiceOver, screen-sampler permission/cancellation/multi-display behavior, narrow-window text expansion, Ollama download cancellation and progress, unreachable and slow servers, model quality, prompt-injection resistance, representative-user comprehension, and privacy review remain open. Public distribution also requires Developer ID signing and notarization.
