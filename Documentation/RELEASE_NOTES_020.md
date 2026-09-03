# Build 020  -  Visual experiment icons and task-focused Help

**Version:** 0.20.0 (20)  
**Date:** August 31, 2026  
**Status:** Development preview

## What changed

- Promoted Explore's overlapping-light and layered-transparency illustrations into reusable compact experiment icons, replacing the generic SF Symbols inside both experiment cards.
- Preserved redundant shape and central-symbol cues so the icons do not depend on distinguishing the two colors.
- Added a standalone **Ollama** toolbar tab immediately before the shared app-tool group. It opens the existing optional five-step install, connection, model download, and application assistant directly.
- Added **Help** immediately after **Display** in the shared Color Tray, Inspector, Display, and Help group.
- Added a separately resizable Help window with persistent geometry, search, six task-based topics, and direct routes into the relevant app workspace or tool.
- Added focused guidance for starting a task, sampling and inspecting screen colors, designing coordinated Light & Dark palettes, deciding whether to use Ollama, interpreting calculated/illustrated/proposed results, keyboard navigation, window recovery, saved-work recovery, and connection troubleshooting.
- Added an enlarged-text Help layout that replaces the topic rail with a compact searchable menu rather than compressing two columns.
- Added Command-Shift-/ as the Help shortcut and a native On Color Theory Help menu command.

## Verification

- 85 tests across 21 suites pass, including the complete visual composition matrix.
- Search coverage verifies task-language discovery across Help topics.
- New Help snapshots cover the start, Light & Dark, Ollama, and enlarged-text troubleshooting states. Existing Explore snapshots now exercise the compact motif icons in light, dark, enlarged-text, and combined accessibility appearances.
- Debug and release bundles build and pass strict ad-hoc code-signature verification.
- The packaged archive is `Build/On Color Theory-020-v0.20.0.zip`.

## Remaining release gates

Build 020 is not an accessibility certification or external release candidate. Computer Use permission was unavailable during this build, so the exact native toolbar-item spacing and grouping still requires a live visual check even though the standalone and grouped item structures compile. Manual keyboard and VoiceOver completion, Help search and destination comprehension with intended users, real display-change restoration, screen-sampler behavior, representative Ollama testing, privacy review, Developer ID signing, and notarization also remain open.
