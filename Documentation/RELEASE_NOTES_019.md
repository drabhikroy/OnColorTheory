# Build 019  -  Continuity, recovery, and trustworthy model requests

**Version:** 0.19.0 (19)  
**Date:** August 31, 2026  
**Status:** Development preview

## What changed

- Added stable size-and-position restoration to the main window, Settings, Inspector, Color Tray, definition readers, and Ollama setup. A restored window is recentered when a changed display arrangement would leave it effectively off-screen.
- Added direct keyboard routes for continuing saved work and opening optional Ollama setup, plus setup-specific Back, Continue, Check connection, and Close actions.
- Reworked the Ollama assistant for enlarged text: its side rail becomes a compact step menu so the task remains readable in a narrower window.
- Added focus targets and submit actions for the external-server address and model-name fields.
- Added a preflight disclosure in Build → Recommend that shows the exact destination, purpose, current role values, and design brief sent to Ollama, along with the categories that remain excluded.
- Distinguished **Generate locally** from **Send and generate**, added generation cancellation, and added direct design-brief length feedback.
- Hardened Ollama handling with bounded request and response prose, strict four-role structured output, untrusted-content delimiters, useful server-version status, common network and TLS guidance, validated model names, and stale-operation protection after connection changes.
- Added workspace-session schema migration. Unreadable, invalid, or future-version state now produces a visible recovery message, retains the original bytes in a recovery copy, and writes a valid fresh session so launch does not enter a repeat-failure loop.
- Expanded visual coverage to every Ollama setup step, the enlarged-text dark setup, exact request review, and workspace recovery.

## Verification

- 84 tests across 20 suites pass, including the complete visual composition matrix.
- New deterministic coverage exercises session migration and corrupt/future-state recovery, window autosave identifiers, Ollama version discovery, request isolation and size limits, oversized response rejection, stale progress protection, model-name validation, and usable network guidance.
- Debug and release bundles build and pass strict ad-hoc code-signature verification.
- The packaged archive is `Build/On Color Theory-019-v0.19.0.zip`.

## Privacy and model boundary

Ollama remains optional, off by default, and not bundled. For the on-Mac path, On Color Theory connects only to the local loopback address. For an external server, the person supplies the address and the app distinguishes HTTPS from cleartext HTTP. The review disclosure shows the exact palette context sent before generation. Model output remains advisory: only four role colors and short rationales are accepted, while On Color Theory independently calculates every contrast, conversion, gamut, difference, and simulation result.

## Remaining release gates

Build 019 is not an accessibility certification or external release candidate. Manual keyboard and VoiceOver completion, focus restoration, real display-change window restoration, screen-sampler permission/cancellation/multi-display behavior, representative Ollama installs and interrupted transfers, model quality and adversarial prompt review, formal privacy review, intended-user comprehension and usability testing, Developer ID signing, and notarization remain open.
