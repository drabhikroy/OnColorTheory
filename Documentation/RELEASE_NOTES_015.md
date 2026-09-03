# Build 015  -  Workspace continuity

**Version:** 0.15.0 (15)  
**Date:** August 30, 2026  
**Status:** Development preview

## What changed

- Added a typed, versioned workspace session stored locally through a dedicated boundary.
- Restored last-valid state across Learn, Explore, Convert, Build, Check, and Reference.
- Added a Home “Continue where you left off” card with task-specific resume copy and an explicit return action.
- Kept invalid color drafts out of the persisted calculation state while retaining them during the current edit.
- Kept the persistent Color Tray separate from temporary workspace context and its provenance rules.
- Made custom-tray `AppModel` instances use isolated in-memory sessions by default, while normal app launches continue to use live persistence.
- Corrected the sidebar working-color accessibility label so it announces the actual HEX value.
- Expanded visual coverage to render the resumed Home state in all six interface-cue palettes under both light and dark appearances.

## Verification

- 68 tests across 17 suites pass.
- The visual composition suite renders every primary workspace in light, dark, enlarged-text, and combined accessibility states, plus focused workspaces, equations, error states, and all selectable interface-cue palettes.
- The debug and release app bundles build and pass strict ad-hoc code-signature verification.
- The packaged archive is `Build/On Color Theory-015-v0.15.0.zip`.

## Remaining release gates

Build 015 is not an accessibility certification or external release candidate. Manual Finder launch, clean relaunch, keyboard, VoiceOver, focus restoration, display scaling, measured contrast and target sizes, diagnostic color-vision simulation, schema corruption and migration, performance, comprehension, and representative-user testing remain open. Public distribution also requires Developer ID signing and notarization.
