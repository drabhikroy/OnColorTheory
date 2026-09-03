# On Color Theory

[![License](https://img.shields.io/badge/license-PolyForm%20Noncommercial%201.0.0-blue)](LICENSE)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-arm64-black?logo=apple&logoColor=white)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey)](#requirements)
[![Release](https://img.shields.io/github/v/release/drabhikroy/tessera)](https://github.com/drabhikroy/tessera/releases/latest)

On Color Theory is a native macOS learning and analysis app built with Swift and SwiftUI. Version 1.0.0 establishes the app shell, deterministic color core, Learn, Explore, Convert, Build, Check, and Reference workspaces, persistent Color Tray, Color Inspector, evidence metadata, and optional model-assisted palette recommendations.

![The Home screen, showing the two workspace groups and the working color](Documentation/screenshots/home.png)

## Run the project

Open `Package.swift` in Xcode 26 or newer, select the `OnColorTheoryApp` scheme, and run it on macOS 14 or newer.

From Terminal:

```sh
swift run OnColorTheoryApp
```

Run the automated checks:

```sh
swift test
```

Create an ad-hoc signed app bundle:

```sh
Scripts/build-app.sh release
```

The bundle is written to `Build/On Color Theory.app`. It is intended for local development; public distribution will still require the normal Apple Developer signing and notarization flow.

The app icon is generated from geometry rather than stored as artwork. `Scripts/build-icon.py` holds the three base colors and the plate dimensions, and writes the asset catalog, the brand PNG and SVG, and an icns from one source. Editing the six palette constants at the top of that script and running it again rebuilds every size.

Numbered archives use `On Color Theory-###-vMAJOR.MINOR.PATCH.zip`. The zero-padded build number is also stored in the app bundle, so Finder ordering and the app's internal identity stay aligned.

## Optional Model Assist recommendations

Ollama is not bundled and model recommendations are off by default. Choose the independently grouped **Model Assist** control in the main toolbar, or press Command-Option-O. The dedicated assistant explains the optional boundary, connection, installation, system-sized model choices, live download progress and cancellation, and exactly where to apply a suggestion:

- **Set up in On Color Theory** connects to Ollama on this Mac at `127.0.0.1:11434`; the assistant links to the official macOS installer, detects Ollama in Applications, recommends a conservative Qwen 3 starting size from the Mac's architecture and memory, and can discover, download, select, and delete models after Ollama is running. The assistant can also move the local Ollama app to the Trash after confirmation.
- **Use an external server** connects to an address supplied by the user and lists the models installed there. Remote hosts require HTTPS. HTTP remains available for localhost and private local-network addresses. The interface warns that the design brief and current palette are sent to that server.

Before generation, the Recommend stage can show the exact four-role design brief, current palette, destination, and excluded information. Local generation is labeled separately from sending a request to an external server. Requests are length-bounded, treat the design brief as untrusted data, and use Ollama's structured-output API. Returned values must be opaque `#RRGGBB` colors with bounded prose. The persistent interface preview supports an editable heading, body, cue heading, cue detail, and button label using the Studio, Light, Dark, or model-suggested palette. Custom preview copy remains available throughout all five Build stages. The model's text and colors remain a proposal; the deterministic app core independently calculates all displayed relationship results.

## What is implemented

- A native Home dashboard plus a visually indexed sidebar for Learn, Explore, Convert, Build, Check, and Reference. A shared multicolor icon system gives each workspace and major in-workspace destination a consistent shape, palette, and central symbol, with a prominent 82-point identity and one rounded header treatment across workspace and focused-destination pages. The app has its own color-coordinate icon in the bundle and on Home.
- A versioned workspace session that restores the last valid working state for Learn, Explore, Convert, Build, Check, and Reference across navigation and app relaunches, migrates older sessions, and preserves a recovery copy when stored data is unreadable or from a newer schema.
- A Home “Continue where you left off” card that names the saved task and returns to it without forcing an automatic redirect on launch.
- Task-specific compositions instead of one repeated card grid: a numbered Learn path, visual Explore gallery, Convert workbench, five-stage Build studio, Check diagnostic dashboard, and searchable Reference field guide.
- One restrained structural accent across navigation, headers, cards, and actions, with separate positive, caution, and critical status roles. Scientific swatches remain exact, while labels, symbols, borders, and position retain meaning.
- A system-responsive accessibility layer for Increase Contrast, Differentiate Without Color, Reduce Motion, and Reduce Transparency, with stronger shared surfaces and a visible checkmark for selected stages when hue should not distinguish state.
- Settings for following macOS appearance or choosing Light or Dark, plus six interface-cue palettes. Protan-, deutan-, tritan-aware, and monochrome choices never alter the scientific colors being analyzed and retain labels, symbols, and borders as the primary cues.
- Large native control sizing throughout the app, with body-sized labels for the principal actions in Convert, Build, and Check.
- Direct Command-1 through Command-7 navigation for Home, Learn, Explore, Convert, Build, Check, and Reference.
- A dedicated Learn library with four compact numbered paths, one focused lesson preview, one consistently positioned primary action, clear scope and length, and a return route from every lesson.
- A first Learn lesson with a directly selectable concept map, following the active color from encoded sRGB channels through linear light and reference-white assumptions one visualization at a time.
- A second three-part visual lesson that keeps one color pair visible while contrasting two different questions: WCAG foreground/background contrast and CIEDE2000 color difference.
- A third three-part perception lesson with two numerically identical center patches, fixed and adjustable surrounding fields, and a visual boundary between deterministic coordinates, viewing context, and individual appearance.
- A fourth three-part reproduction lesson that follows one Display P3 color through source interpretation, conversion into sRGB coordinates, destination-boundary detection, and the separate choice of a mapping method.
- Four deterministic lesson examples, stable Previous/progress/Next positions, contextual definitions, direct sources, and exact handoff into the corresponding Check analysis.
- A focused Explore gallery with compact, shape-redundant icons for two bounded Predict, Observe, Explain experiments and one-column adaptation at enlarged text sizes. The selected experiment repeats its icon at a larger scale beside the experiment heading.
- A mixing experiment that compares encoded-sRGB interpolation with linear-light interpolation while holding the opaque endpoints fixed.
- Editable color endpoints, example pairs, a movable mix position, two directly rendered gradient calculations, numeric result cards, and one-click handoff to Convert.
- Deterministic premultiplied-alpha interpolation in both encoded and linear-light sRGB, even though the first lab intentionally holds alpha opaque to isolate one variable.
- A transparency experiment that holds one partly transparent source fixed over two named opaque backdrops, then presents both exact visible results, source/backdrop contribution bars, contextual definitions, native LaTeX, and direct specifications.
- One shared deterministic source-over compositor for both the transparency experiment and WCAG contrast analysis, with translucent backdrops rejected until another underlying layer is known.
- A role-based Palette Studio for canvas, body text, accent, and accent text, with six light and dark starter palettes.
- A dedicated five-step optional Ollama assistant with official installation guidance, local-app detection, local or external connection checks, system-aware model starting points, installed-model selection, live download progress and cancellation, enlarged-text reflow, keyboard shortcuts, and a direct handoff to Build → Recommend.
- A Build recommendation stage where people can review exactly what will be sent, cancel generation, and see usable connection guidance; the selected model proposes four role colors, an overall approach, and a natural-language explanation for every choice. The shared text-on-palette preview supports custom heading, paragraph, cue, detail, and button copy, followed by the app's independent deterministic relationship checks before a suggestion can be applied.
- A persistent interface preview that keeps custom heading, paragraph, cue, detail, and button text available through all five Build stages. It can show the Studio, Light, Dark, or model-suggested palette without treating visual judgment as a scientific verdict.
- Separate deterministic checks for ordinary body text, ordinary text on an accent, and an accent used as a required UI or graphical cue; each result names its WCAG threshold and can open the exact pair in Check.
- One-click selection of whichever of black or white gives higher contrast on the accent, without claiming that this alone establishes readability.
- A persistent studio rail for Design, Light & Dark, Recommend, Check, and Export that keeps one Palette Studio task visible without losing the active palette.
- A focused Light & Dark stage with separate saved role palettes, editable light and dark starters, side-by-side previews, independent checks for both appearances, adaptive `prefers-color-scheme` CSS, and carefully scoped links to Leonardo, Adobe Color, and W3C contrast guidance.
- Copyable palette export for CSS, Swift, JavaScript, Python, R, and JSON, plus one-action saving of all roles to the persistent Color Tray.
- A separately toggleable, independently resizable Color Inspector with a system screen sampler that can pick a pixel inside or outside the app, preserve it as the working color, and report Values, Measures, and Context through one aligned label/help/value grid without reparsing an already-normalized pixel.
- Independently resizable, single-instance Color Tray, definition, Settings, Inspector, Model Assist setup, Help, and primary windows that remember their last useful position and size and recover on-screen if the display arrangement changes. Repeated actions bring the existing window forward rather than creating another copy.
- Visible Display access in the main toolbar and Inspector, leading to Follow Mac, Light, Dark, reading, and color-vision-aware interface-cue options.
- CSS hexadecimal parsing for 3-, 4-, 6-, and 8-digit notation.
- Modern and legacy CSS `rgb()`/`rgba()` input with number or percentage components and alpha.
- Encoded sRGB, linear sRGB, Display P3, CIE XYZ D65/D50, CIELAB/LCh D50, Oklab/OkLCh D65, HSL, alpha, and relative-luminance output.
- Copy controls for every serialized representation.
- A representation-specific conversion map: short notational outputs stop early, D65 targets avoid an irrelevant D50 step, and D50 Lab paths expose chromatic adaptation.
- Stable Previous, progress, and Next or Start Over controls below every variable-height conversion stage.
- A vertical conversion map beside one selected stage with separate Meaning, Calculation, and Sources views; native LaTeX equations retain selectable readings, substituted values, spoken equivalents, and Copy LaTeX controls.
- Optional code export beneath the current Convert result for CSS, Swift, JavaScript, Python, R, and JSON; non-CSS snippets explicitly use sRGB components.
- Contextual term definitions with brief native hover help and keyboard-accessible explanatory windows; reading text throughout the app is selectable.
- One reusable, validating HEX/RGB color editor across Explore, Build, and Check, with visible swatches, native pickers, direct text editing, and non-color error feedback.
- A two-color WCAG 2.2 contrast workbench with an actual-color preview, alpha compositing, exact threshold decisions, and separate AA, AAA, text, and non-text results.
- A persistent diagnostic rail for contrast, color difference, color-space limits, and meaning conveyed through color, followed by separate Work and Results or Method and Sources views.
- A deterministic CIEDE2000 comparison with a side-by-side visual, signed lightness/chroma/hue term bars, contextual definitions, visible LaTeX, direct CIE sources, and no unsupported universal pass/fail threshold.
- CIEDE2000 verification against all 34 supplemental reference pairs published by Sharma, Wu, and Dalal.
- A color-reliance review that compares the original pair with equal-channel neutral colors preserving calculated relative luminance, then prompts review of text, shape, pattern, position, and interaction states without claiming automated WCAG conformance or color-vision simulation.
- A Display P3-to-sRGB gamut check with validating CSS input, directly adjustable channels, an explicit in-range result, original and clipped previews, visualized converted-channel boundaries, native LaTeX, and no claim that simple clipping is the preferred gamut-mapping method.
- A Reference landing library that groups all twenty-four terms into four descriptive topic cards, with a single inline search across names, definitions, categories, and key distinctions.
- Topic-level term cards that reveal one short definition at a time, adapt to one column at enlarged text sizes, and keep a clear return path to the topic library.
- A focused single-term reader with stable Previous and Next positions, five contextual native-LaTeX equations, selectable in-words readings, Copy LaTeX controls, and versioned sources and limitations visible without another disclosure click.
- Focused presentation: paired color input and output at ordinary text sizes, one expanded conversion stage, one plain-language contrast verdict and threshold scale, and one reference term at a time.
- Persistent Color Tray records containing the original representation, color space, alpha, profile context, conversion history, source, label, and lock state.
- Recoverable Color Tray storage errors that keep the current in-memory colors available, state that persistence failed, and never imply that an unsuccessful write was saved.
- Isolated ephemeral workspace sessions for test-created models with custom Color Trays, while normal app launches retain live local persistence.
- A dedicated seven-slide first-run walkthrough with visible progress, accessible Previous and Next controls, a clear skip route, concise explanations, and a final start action. It appears once, remains available from Start here in Help, and reopens only after a complete first-run reset or a direct request.
- A searchable, task-oriented Help window with exact routes to the relevant workspace or tool, Light & Dark guidance, editable-preview guidance, optional Model Assist status and Ollama boundaries, result-authority explanations, keyboard routes, and recovery troubleshooting. Help adapts to a compact topic menu at enlarged text sizes and shows the installed app version.
- Keyboard commands for navigation, adding a color, toggling the tray or inspector, resuming saved work, opening Model Assist, and opening Help; the setup assistant also supports Return, Command-Return, Command-[, Escape, and Command-R where relevant.
- Atkinson Hyperlegible Next at a larger default reading size, with adjustable scaling and a system-font override; equations use SwiftMath's native LaTeX renderer with a shared image-backed AppKit surface that preserves left-to-right glyph order.
- A provider-neutral model contract and concrete Ollama provider in which models can propose palettes but cannot author scientific measurements.

## Architectural rule

The implementation keeps three responsibilities separate:

1. Deterministic science and mathematics calculate.
2. A versioned evidence registry explains and cites.
3. Optional machine-learning providers propose.

`PaletteProposal` deliberately has no contrast, gamut, color-difference, or color-vision fields. It carries only the provider identity, the proposed colors, and the model's own summary. Those findings are produced separately by `InterfacePaletteEvaluator`, which returns `PaletteRelationshipResult` values calculated by the app rather than supplied by a model.

## Current scientific scope

The conversion path begins with sRGB's D65 white, then exposes a Bradford D65-to-D50 chromatic-adaptation step before reporting CSS CIELAB and CIE LCh. Oklab and OkLCh remain D65-relative. Both white points are visible wherever their coordinates appear.

RGB values outside 0 to 255, percentages outside 0% to 100%, and alpha outside 0 to 1 are reported as input errors instead of being silently clamped. That is deliberately stricter than browser processing so the learning tool does not hide a normalization step.

HSL is reported as a coordinate model over encoded sRGB; the app does not call its lightness perceptual lightness.

CIEDE2000 is reported as a relative modeled difference between two D50 CIELAB coordinates. The app does not label any single value as universally noticeable or acceptable because those judgments depend on viewing conditions, task, display behavior, surroundings, and observer.

The learning material treats WCAG contrast and CIEDE2000 as separate measures. A contrast ratio evaluates a specified foreground/background relationship for a named accessibility use; a color-difference value estimates relative separation in its stated model. The app does not infer one from the other.

The surroundings lesson holds the center pixels at the same encoded sRGB value while nearby neutral fields change. It demonstrates that context can influence appearance without assigning a universal magnitude or treating a color coordinate as a complete prediction of an individual observer. CIECAM16 is cited as a viewing-condition-specific color-appearance model, not used as a claim that this simplified display predicts every contextual effect.

The color-reliance check creates an equal-channel sRGB preview that preserves the pair's calculated relative luminances. This removes hue from a bounded visualization but is not a simulation of any color-vision deficiency. Whether color is the only cue remains a question about the complete design, its meaning, and its interaction states, so the app presents review prompts rather than an automatic pass or fail.

The gamut check accepts an opaque Display P3 color whose source components stay inside the Display P3 reference range. It converts through XYZ D65 using the current CSS Color 4 matrices and tests the resulting encoded sRGB channels against the sRGB 0 to 1 range. The clipped sRGB swatch is an intentionally simple comparison, not the CSS gamut-mapped result, a device measurement, or a recommendation for production color mapping.

The transparency experiment uses simple source-over compositing of encoded sRGB components over opaque backdrops. It deliberately does not stand in for a complete browser or display pipeline and does not cover blend modes, group opacity, high-dynamic-range rendering, or translucent backdrops.

## Project notes

- [Typography research](Documentation/TYPOGRAPHY_RESEARCH.md)
- [Evidence-based design decisions](Documentation/DESIGN_DECISIONS.md)
- [General-audience design framework baseline and open release gates](Documentation/DESIGN_FRAMEWORK_AUDIT.md)
- [Product audiences, contexts, misconceptions, and critical tasks](Documentation/PRODUCT_CONTEXT.md)
- [Release notes for 1.0.0](Documentation/RELEASE_NOTES_100.md)
- [1.0.0 validation record](Documentation/VALIDATION_100.md)
- [Security review](Documentation/SECURITY_REVIEW_100.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)

## Planned

A **Brief History of Color** section and a **Color Theory** section will be added
in a later release. Neither ships in 1.0.0.

## About the name

*De Coloribus*, rendered in English as *On Colors*, comes down to us in the
Aristotelian corpus, and the name here nods to it alongside the ordinary sense
of color theory. Modern scholars agree the treatise is not Aristotle's own.
Attributions to Theophrastus and to Strato of Lampsacus have both been proposed
and both refuted, so it is conventionally cited as pseudo-Aristotle. The nod is
to the tradition, not a claim about who held the pen.

## Where this came from

Much of the material here began as teaching material. I built it for the color
portion of a data visualization course I taught as an assistant professor at
West Virginia University, and it accumulated over several semesters as
explanations, worked examples, and demonstrations that answered the questions
students actually asked. Collecting it into one app was a way to keep it in a
form I could still use, and to give it a shape that does not depend on being in
the room to explain it.

If any of it is useful to you, whether for teaching, for design work, or out of
plain curiosity about how color numbers behave, please take it and use it.

## License

Copyright 2026 Abhik Roy.

Licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE.md). Personal
study, hobby projects, teaching, academic research, and use by nonprofit and
government organizations are all permitted. Commercial use is not.
