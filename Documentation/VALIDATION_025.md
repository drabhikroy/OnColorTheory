# Build 025 validation

Validated on August 31, 2026.

## Automated behavior

- 96 tests passed across 21 suites.
- The calculation suite covers sRGB transfer functions, D65 and D50 reference whites, source-over compositing, premultiplied interpolation, WCAG threshold decisions, Display P3 conversion, Oklab, CIELAB, HSL scope, and all 34 published CIEDE2000 supplemental pairs.
- Persistence, migration, window identity, screen-sample normalization, model response limits, model deletion, external-server transport rules, and native editing command selectors passed.

## Rendered interface

- 173 interface states rendered successfully in `Build/VisualQA025`.
- The matrix includes all primary workspaces, both appearances, enlarged text, combined accessibility preferences, every Help topic, Inspector states, Model Assist setup steps, Build recommendation states, and recovery cases.
- Direct image review confirmed the new Home icon, the Settings reading preview, Help version spacing, and shared Help action panels in light and dark appearances.

## Release artifact

- The release bundle reports version 0.25.0 and build 25.
- The app icon catalog compiled into both `AppIcon.icns` and `Assets.car`.
- The SVG and PNG brand masters are present in the app resource bundle.
- Strict deep code-signature verification passed for the ad-hoc development bundle.
- The release archive passed a complete ZIP integrity check.

Archive SHA-256: `e594239bde29484b08ed9bd95d300fe000b4f2579aa494be54ab625efc3f918e`

SVG SHA-256: `2f2932db25a3baafa2e928e4f302059a765a9b410533fc66c55c2028dae6be8b`

The bundle is suitable for local development and review. Public distribution still requires an Apple Developer identity and notarization.
