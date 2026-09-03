# Build 024 validation record

## Calculation review

The calculation core was checked by method and by independent reference values:

- sRGB decoding and encoding match the CSS Color 4 breakpoint and a published 0.5 channel value. A one-hundred-step round trip checks the full encoded range.
- The sRGB matrix maps white to the CSS Color 4 D65 reference white, then chromatic adaptation maps it to a neutral D50 Lab white.
- WCAG contrast uses the current 0.04045 sRGB breakpoint, unrounded threshold decisions, alpha compositing over an opaque backdrop, and the published 1:1 to 21:1 range.
- Display P3 uses the rational CSS Color 4 matrices and tests destination channels before clipping.
- CIEDE2000 continues to match all 34 Sharma, Wu, and Dalal supplemental pairs, including the difficult hue-wrap cases.
- Encoded and linear-light interpolation, premultiplied alpha, and source-over endpoints retain dedicated known-value tests.

Primary references:

- W3C CSS Color Module Level 4: https://www.w3.org/TR/css-color-4/
- W3C WCAG 2.2 contrast explanation: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- W3C Compositing and Blending Level 1: https://www.w3.org/TR/compositing-1/
- Sharma, Wu, and Dalal supplemental CIEDE2000 data: https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/

## Security review

The review covered network input, model output, local persistence, external links, deletion, and packaging.

- App Transport Security no longer permits arbitrary loads.
- Remote Model Assist servers require HTTPS. Localhost, `.local`, loopback, link-local, and private-network addresses can use HTTP for Ollama compatibility.
- Server URLs reject embedded user names, passwords, queries, and fragments.
- Model traffic uses an ephemeral session with cookies and URL caching disabled.
- Version, model-list, generation, and deletion responses have explicit size limits.
- Model names use a narrow character set and a two-hundred-character limit before download or deletion.
- Design briefs are length-bounded and placed inside untrusted-content delimiters. Returned colors and explanations are schema-checked and length-bounded.
- Model and app removal require a confirmation. The app removal uses the macOS Trash instead of permanent deletion.
- Color Tray and workspace data are size-checked before decoding. Color Tray writes remain atomic.
- No credentials, tokens, prompts, model output, or Color Tray history are written by Model Assist.
- The only third-party package is SwiftMath 1.7.3, pinned through Swift Package Manager with its license bundled.

## Code and writing review

All source comments were inspected. Comments that remain explain a specification boundary, a non-obvious parser or renderer constraint, recovery behavior, or a signing requirement. No comments narrate old implementation history. Current interface copy and documentation use direct product language and contain no assistant or generation metadata. Em dash characters were removed from source, tests, scripts, and documentation.

## Automated and visual coverage

- 95 tests across 21 suites cover the deterministic core, persistence, Model Assist, application routing, and accessibility behavior.
- 166 rendered states cover the primary workspaces, focused lessons and experiments, Build stages, Model Assist, Help, Settings, Inspector, dark appearance, enlarged text, and combined accessibility preferences.
- Debug and release builds are required to compile before packaging. The finished app bundle is checked with strict signature verification.
