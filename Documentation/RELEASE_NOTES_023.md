# Build 023: Single-instance navigation and editable palette previews

**Version:** 0.23.0 (23)  
**Date:** August 31, 2026  
**Status:** Development preview

## What changed

- Replaced the multi-instance main and definition scenes with one stable window for each. Help, keyboard routes, Model Assist, Color Tray, and toolbar actions now bring an existing destination window forward instead of creating another copy.
- Added one explicit set of unique scene identifiers for the main app, Color Tray, Inspector, Model Assist, Help, and definition reader.
- Consolidated workspace and focused-destination headers into one reusable rounded surface with the same border, accent marker, icon scale, title hierarchy, and adaptive behavior.
- Applied the framed treatment to workspace pages, selected Explore experiments, all four lesson readers, Reference topics, Help topics, and Model Assist setup steps.
- Added editable palette-preview fields for the heading, body text, cue heading, cue detail, and button label. The same copy appears in manual and model-proposed previews and persists with the Build workspace.
- Added bounded field lengths, a Restore sample action, aligned labels, enlarged-text adaptation, and a complete accessibility value for the preview.
- Rewrote the Start here Help topic as a current seven-step walkthrough covering every workspace, Inspector, Color Tray, Light and Dark design, optional Model Assist, custom preview copy, deterministic checks, and handoffs.
- Updated Help and Model Assist actions so Light and Dark and Recommend open the exact Build stage.
- Advanced the visible app and bundle version to **Version 0.23.0 (23)**.

## Verification

- 89 tests across 21 suites pass.
- New deterministic coverage verifies unique app-owned scene identities, custom preview-copy persistence, updated Help search language, and version formatting.
- The 166-state visual composition matrix covers the shared framed headers and editable preview in normal, dark, enlarged-text, and combined accessibility settings.
- Debug and release bundles build and pass strict ad-hoc code-signature verification.
- The packaged archive is `Build/On Color Theory-023-v0.23.0.zip`.

## Remaining release gates

Build 023 is not an accessibility certification or external release candidate. Automated rendering cannot prove real-window focus ordering, so repeated Help, shortcut, setup, tray, toolbar, and definition actions still need a manual live-app pass. Manual keyboard and VoiceOver completion, color-vision review, custom-copy usability, model-output comprehension and quality testing, privacy review, representative-user testing, Developer ID signing, and notarization remain open.
