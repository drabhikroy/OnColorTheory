# Build 021: Standardized icon identity and clearer Model Assist

**Version:** 0.21.0 (21)  
**Date:** August 31, 2026  
**Status:** Development preview

## What changed

- Added one reusable multicolor icon system across the sidebar, workspace headers, Home cards, Learn paths, Build stages, Check diagnostics, Reference topics, and Help topics. Each identity combines color with its own geometry and central symbol.
- Replaced the remaining generic blue identity tiles in the major app destinations while leaving small functional control symbols native and familiar.
- Removed the large repeated illustrations from the Explore library cards. Each card now starts with its compact experiment icon, and the selected experiment repeats that icon at a larger size beside its heading.
- Renamed the standalone toolbar destination from **Ollama** to **Model Assist** and added a fixed native toolbar spacer before the Color Tray group on macOS 26.
- Renamed the setup window and commands to Model Assist while retaining clear Ollama installation, connection, model, and troubleshooting language where the underlying service matters.
- Tightened the palette prompt so the selected model explains its overall approach and every color choice in short, natural, accessible language.
- Reworked the recommendation result into **Overall approach** and **Why this color** sections before On Color Theory presents its independent calculated checks.
- Removed em dashes from all app source copy and replaced them with punctuation that is easier to scan.
- Began visible release versioning. Settings and Help now show **Version 0.21.0 (21)**, matching the app bundle and archive name.

## Verification

- 87 tests across 21 suites pass, including version formatting, complete workspace icon identity coverage, accessible model-explanation prompting, and the visual composition matrix.
- The source-copy audit contains no em dash characters.
- Light, dark, enlarged-text, and combined accessibility renderings cover the standardized icons. Focused snapshots cover the simplified Explore library, both selected experiments, Reference topic identity, Build and Check rails, Help, and Settings.
- Debug and release bundles build and pass strict ad-hoc code-signature verification.
- The packaged archive is `Build/On Color Theory-021-v0.21.0.zip`.

## Remaining release gates

Build 021 is not an accessibility certification or external release candidate. The fixed toolbar spacer is implemented with the macOS 26 native API in response to the live screenshot, but the packaged build still needs a final live toolbar check. Manual keyboard and VoiceOver completion, color-vision review, model-output comprehension and quality testing, privacy review, representative-user testing, Developer ID signing, and notarization remain open.
