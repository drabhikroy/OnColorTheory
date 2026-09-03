# Build 018  -  Immediate appearance, dual-mode palettes, and guided Ollama setup

**Version:** 0.18.0 (18)  
**Date:** August 30, 2026  
**Status:** Development preview

## What changed

- Replaced competing per-view color-scheme overrides with one application-level macOS appearance setting. Switching from a forced appearance to Follow Mac now updates the content and native window chrome together without requiring the app to move to the background.
- Consolidated numeric metadata into one reusable three-column label, help, and value grid. Inspector Values, Measures, and Context now align consistently, and the same row component fixes matching coordinate displays elsewhere in the app.
- Added a fifth Palette Studio stage, Light & Dark, for maintaining a distinct palette for each appearance rather than treating dark mode as a color inversion.
- Added light and dark starter sets, editable role values, paired previews, three deterministic relationship checks per appearance, and one-click transfer between either appearance and the main Design stage.
- Added adaptive CSS export using `prefers-color-scheme: dark` and embedded focused links for adaptive theme exploration, pair testing, and contrast education.
- Replaced the long inline Ollama form with a dedicated, independently resizable five-step setup assistant.
- Made the optional boundary explicit before setup and added local or external connection guidance, the official macOS download route, Ollama-app detection, connection checks, installed-model selection, and a direct handoff to Build → Recommend.
- Added conservative Mac architecture/memory-based Qwen 3 starting points with visible approximate download sizes. External servers instead show a clear warning that this Mac cannot determine the server's fit.
- Added streamed Ollama model-download status, determinate progress when the server supplies byte counts, and cancellation.
- Kept all model output advisory: the selected model proposes only four colors and rationales, while On Color Theory calculates every displayed scientific and accessibility-related measurement.

## Verification

- 76 tests across 19 suites pass, including the complete visual composition matrix.
- A new deterministic test verifies that adaptive CSS contains separate light and dark role sets under the system appearance media query.
- Debug and release bundles build and pass strict ad-hoc code-signature verification.
- The packaged archive is `Build/On Color Theory-018-v0.18.0.zip`.

## Sources used for the new guidance

- [Ollama for macOS](https://docs.ollama.com/macos)
- [Ollama macOS download](https://ollama.com/download/mac)
- [Qwen 3 model library](https://ollama.com/library/qwen3)
- [Leonardo adaptive color](https://leonardocolor.io/)
- [Adobe Color contrast analyzer](https://color.adobe.com/create/color-contrast-analyzer)
- [W3C contrast guidance](https://www.w3.org/WAI/perspectives/contrast.html)

## Remaining release gates

Build 018 is not an accessibility certification or external release candidate. Manual Follow Mac testing across live macOS appearance changes, window restoration, keyboard and VoiceOver review, narrow-window text expansion, real Ollama installs across representative Apple silicon and Intel systems, slow and interrupted model transfers, model quality, prompt-injection resistance, representative-user comprehension, privacy review, Developer ID signing, and notarization remain open.
