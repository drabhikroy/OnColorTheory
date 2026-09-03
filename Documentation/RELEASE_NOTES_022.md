# Build 022: Independent Model Assist and contextual palette previews

**Version:** 0.22.0 (22)  
**Date:** August 31, 2026  
**Status:** Development preview

## What changed

- Changed the macOS 26 toolbar composition so Model Assist opts out of the shared toolbar background, receives its own native glass capsule, and stays separated from the grouped Color Tray, Inspector, Display, and Help controls.
- Enlarged the main Learn, Convert, Build, and Check workspace identity icons to 82 points. These headers now match the strong selected-destination treatment already used by Explore and Reference.
- Added a representative text example to every completed model recommendation. It combines the proposed canvas, body text, accent, and accent-text roles in a heading, paragraph, labeled cue, and action.
- Kept the example explicitly illustrative. On Color Theory still calculates every contrast relationship independently and presents those checks after the visual example.
- Refactored the existing live palette example into one reusable component so manual and model-proposed palettes share the same role-based presentation.
- Advanced the visible app and bundle version to **Version 0.22.0 (22)**.

## Verification

- 87 tests across 21 suites pass.
- The visual composition matrix includes a completed model-recommendation state in addition to the full light, dark, enlarged-text, accessibility, workspace, Help, and Settings coverage.
- Direct visual inspection confirms the larger Learn, Convert, Build, and Check header identities and the four-role recommendation example.
- Debug and release bundles build and pass strict ad-hoc code-signature verification.
- The packaged archive is `Build/On Color Theory-022-v0.22.0.zip`.

## Remaining release gates

Build 022 is not an accessibility certification or external release candidate. The toolbar now uses explicit shared-background opt-out and an independent native glass button, but Computer Use permission is unavailable in this environment, so the packaged toolbar still needs a final live visual check. Manual keyboard and VoiceOver completion, color-vision review, model-output comprehension and quality testing, privacy review, representative-user testing, Developer ID signing, and notarization remain open.
