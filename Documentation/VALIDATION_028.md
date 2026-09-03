# Build 028 validation

Validated on September 1, 2026 for On Color Theory 0.28.0 (28).

## First-run walkthrough

- The first launch opens a dedicated On Color Theory Walkthrough window instead of opening Help.
- The walkthrough contains seven distinct slides covering Home, the working color and Inspector, Learn and Explore, Convert, Build, Check, and Reference with Help.
- Each slide has a short summary, three focused points, visible progress, Previous and Next controls, a skip route, and a final Start using On Color Theory action.
- The walkthrough records that it has appeared and does not open automatically on later launches.
- Start here in Help can reopen the same walkthrough without creating a second copy.
- A complete reset that removes both local Ollama and local models restores the true first-run state. Other reset choices preserve the completed-walkthrough preference.
- Enlarged text keeps the title and navigation areas stable while the central reading area scrolls.
- Keyboard routes cover Escape, Return, and the left arrow. Step changes also issue accessibility announcements.

## Icon review

- The app icon keeps the established color-coordinate artwork and geometry.
- Midtones, saturation, and glow were adjusted to sit between the brighter Build 026 version and the darker Build 027 version.
- The 1,254 by 1,254 pixel master regenerated all required macOS icon sizes.
- The same artwork is included as PNG, self-contained SVG, asset-catalog resources, and the compiled `AppIcon.icns`.

## Automated checks

- 100 tests in 22 suites passed.
- The calculation suite covers sRGB transfer functions, D65 and D50 conversion, Bradford adaptation, Display P3 boundaries, Oklab, HSL, alpha compositing, WCAG contrast, CIEDE2000 against all 34 published supplemental pairs, color reliance, and export stability.
- Persistence, corrupt-state recovery, reset boundaries, Color Tray limits, screen sampling, model response limits, network rules, and single-instance window identity passed.
- 182 rendered interface states passed, including all seven walkthrough slides and an enlarged-text walkthrough state.
- The final walkthrough render was reviewed in Dark appearance and at 160 percent text size.

## Source and security review

- Swift source contains no forced casts, forced `try`, `fatalError`, unsafe bit casts, or unsafe-memory calls.
- App source, tests, scripts, support files, and documentation contain no task markers or machine-attribution notes.
- External Model Assist addresses require HTTPS. Cleartext HTTP remains limited to loopback and private-network addresses chosen by the user.
- Model traffic uses an ephemeral session, bounded request content, validated model names, structured color responses, and bounded explanation length.
- Local cleanup targets only the standard Ollama application and model locations and moves them to the Trash. It never changes an external server.
- Saved Color Tray and workspace data are size-checked before decoding, written atomically, and recover visibly from malformed or future-schema data.
- The app requests local-network access only for an Ollama server selected by the user. Model Assist remains optional and off by default.
- Zsh syntax, property-list syntax, asset JSON, and SVG XML validation passed.
- No em dash characters remain in app copy, source comments, tests, scripts, or documentation.

This is a focused static, automated, and artifact review. Public distribution still requires Apple Developer signing, notarization, and the manual accessibility, privacy, representative-user, and model-quality gates listed in the design framework audit.

## Production artifact

- Release compilation completed successfully for arm64 macOS 14 or newer.
- The app reports version 0.28.0 and build 28.
- Strict deep code-signature verification passed with the local ad hoc signature.
- The archive integrity test reported no compressed-data errors.
- `On Color Theory-028-v0.28.0.zip` SHA-256: `648e1a872f03523619dbe7f16d419d7a0d8b967d7f70c97e291c9e749a0b0d69`
- App icon PNG SHA-256: `0b7d9e3b40463f08a59227db806f1b0a60b27d46e6cf1877ad5489d91b50d69b`
- App icon SVG SHA-256: `d3b3d13572a1b9a8709f178da4a5e88d05ae2e653a5740bac4eafb08906a3143`
