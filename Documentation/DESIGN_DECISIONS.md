# Evidence-based design ledger

This ledger records consequential interface decisions and their basis. It distinguishes peer-reviewed evidence, accessibility standards, platform guidance, established practice, and aesthetic judgment rather than presenting every choice as a scientific finding.

## Decision hierarchy

1. Direct peer-reviewed evidence.
2. Accessibility standards and guidance.
3. Current macOS Human Interface Guidelines and native platform behavior.
4. Established human-computer interaction practice.
5. Usability testing, particularly with disabled users and readers with varied color-science knowledge.
6. Aesthetic judgment within the preceding constraints.

## D-001  -  Home plus a flat six-workspace sidebar

**Task:** Give people stable access to six broad modes without making them understand the scientific taxonomy first.

**Decision:** Use one native, relatively flat sidebar with Home followed by six visible workspaces, each with a label and familiar SF Symbol. Do not expose nested scientific topic trees in primary navigation.

**Basis:** macOS platform convention; W3C cognitive-accessibility guidance on consistent, familiar controls and visible labels.

**Limitation:** The exact six-section taxonomy remains a product hypothesis and needs navigation testing.

## D-002  -  One primary activity with optional Inspector

**Task:** Keep Convert visibly about conversion while preserving scientific context.

**Decision:** The center is the primary task. The right Inspector is separately toggleable and secondary. The persistent Color Tray is a focused toolbar popover rather than a fourth permanent region.

**Basis:** Apple split-view/inspector conventions; cognitive-load and signaling principles; consistency with native Mac workflows.

**Limitation:** The ideal inspector width is not settled by research and must be tested at different window and text sizes.

## D-003  -  Progressive scientific depth

**Task:** Keep the full mathematics available without forcing every equation into the initial scan path.

**Decision:** Present a directly selectable map whose stages match the chosen output representation. The selected stage uses two adjacent reading surfaces when width and text scale permit: one for the result, what changes, and why the change matters; another for the centered LaTeX rule, an in-words reading, and substituted values. The layout stacks at narrow widths or enlarged text sizes. Only one stage is expanded at a time, but every stage is directly reachable. There is no separate “advanced user” identity.

**Basis:** Multimedia-learning evidence for signaling, coherence, and learner control, applied with the boundary conditions reported in later meta-analysis; Apple guidance on adaptable layout and text enlargement.

**Limitation:** Even one equation can be cognitively dense. Line length, spoken equivalents, text scaling, and direct usability testing remain necessary.

## D-004  -  Neutral chrome; color only where color is the subject

**Task:** Avoid an exhausting interface and prevent chrome color from competing with scientific color samples.

**Decision:** Navigation, panels, labels, and borders inherit semantic macOS materials and colors. Swatches contain textual numeric identification, so appearance is never the only information channel.

**Basis:** WCAG 2.2 use-of-color and contrast guidance; platform appearance conventions.

**Limitation:** The current milestone has not completed formal contrast audits across every macOS appearance and increased-contrast setting.

## D-005  -  Reader-controlled typography

**Task:** Satisfy the requested distinctive open-source typography without imposing it on readers for whom it is less comfortable.

**Decision:** Default to Atkinson Hyperlegible Next at 17 points for body text, avoid light weights, provide 100 to 160% scaling, and include a macOS system-font override. Render mathematics from LaTeX with a dedicated redistributable math font and a plain-language accessibility label.

**Basis:** Typography research does not support a universal most-legible face; Apple guidance for custom fonts, minimum sizes, and non-light weights; font design purpose and OFL licensing.

**Limitation:** Needs direct user testing. See `TYPOGRAPHY_RESEARCH.md`.

## D-006  -  Persistent color records preserve interpretation

**Task:** Let colors move among Learn, Convert, Build, and Check without silently losing scientific context.

**Decision:** The tray stores original representation, interpreted color space, alpha, profile description, conversion history, source, label, and lock state. Storage is local JSON written atomically in Application Support.

**Basis:** Scientific reproducibility and local-first product architecture.

**Limitation:** ICC profile embedding and migration/version metadata are not yet implemented.

## D-007  -  Model proposals cannot become measurements

**Task:** Prepare optional local palette completion without allowing probabilistic output to masquerade as calculation.

**Decision:** `PaletteModelProvider` returns only candidate colors and rationale. A distinct deterministic evaluation layer owns conversion, gamut, color difference, contrast, and color-vision findings.

**Basis:** System safety and scientific reproducibility; established separation-of-concerns practice.

**Limitation:** No inference provider ships in milestone 0.1. Provider downloads, license display, checksums, and hardware-fit checks are future work.

## D-008  -  Reference-white adaptation is visible

**Task:** Prevent apparently similar Lab numbers from concealing different reference-white assumptions.

**Decision:** Convert reports sRGB-derived XYZ under D65, exposes the Bradford D65-to-D50 transform as its own stage, and reports CSS CIELAB/LCh under D50. Oklab/OkLCh remain explicitly D65-relative.

**Basis:** CIE colorimetry; current CSS Color 4 conversion requirements and reference algorithms.

**Limitation:** Bradford is one chromatic-adaptation transform and should not be presented as a complete model of every observer or viewing condition.

## D-009  -  Input errors are not silent normalization

**Task:** Teach what numeric component ranges mean while accepting both current and legacy RGB syntax.

**Decision:** Accept modern CSS space/slash syntax, legacy comma syntax, percentages, and convenience unwrapped components. Reject out-of-range values with a textual explanation rather than silently clamping them.

**Basis:** CSS Color 4 syntax; the product rule that transformations must be inspectable.

**Limitation:** Browsers can accept and clamp some out-of-range CSS values. The app's stricter teaching behavior is therefore explicitly not a browser-parser emulator.

## D-010  -  Contrast results keep their context

**Task:** Make WCAG contrast useful without implying that one badge settles every accessibility question.

**Decision:** Show the measured ratio alongside separate AA, AAA, normal-text, large-text, and non-text criteria. Threshold decisions use the unrounded value even when the visible ratio is rounded for reading. A translucent foreground is composited over the entered background, while a translucent background is rejected until its own backdrop is known.

**Basis:** WCAG 2.2 Contrast (Minimum), Contrast (Enhanced), and Non-text Contrast; deterministic calculation and transparent-assumption rules.

**Limitation:** The ratio does not model font rendering, ambient light, display calibration, user vision, gradients, imagery, interaction states, or the broader accessibility of the design.

## D-011  -  One information layer at a time

**Task:** Preserve scientific depth without making the default interface feel like a data report.

**Decision:** Convert pairs input and output horizontally when space permits, then presents an always-visible map whose stages can be opened in any order. The selected explanation and calculation remain in distinct, non-nested cards. Direct source links stay beside the stage and require no disclosure. Check leads with one preview, a plain-language verdict, and one threshold scale. Reference is a single-term reader with Previous and Next navigation. The Inspector starts closed and folds secondary measurements into disclosures. Visuals always retain text and numeric labels so color is never the sole carrier of meaning.

**Basis:** Multimedia-learning evidence for coherence, signaling, segmentation, and learner control; cognitive-accessibility guidance; the product's progressive-depth rule.

**Limitation:** Progressive disclosure can reduce discoverability. Labels, keyboard access, increased-text rendering, and direct usability testing remain necessary.

## D-012  -  Lessons use one concept and one visualization at a time

**Task:** Extend the product beyond tools without recreating the density of a textbook page.

**Decision:** A lesson has a short introduction, a directly selectable part map, one concept card, one purpose-built visualization, one qualifying point, and direct sources. Previous and Next remain available, but they are not the only route. The first lesson follows the active Convert color through encoded channels, linear light, and reference-white assumptions.

**Basis:** Multimedia-learning evidence for signaling, spatial contiguity, coherence, and learner-controlled segmentation; the product rule that scientific assumptions stay visible.

**Limitation:** The lesson sequence and explanatory language require comprehension testing with readers who have varied mathematical and color-science backgrounds.

## D-013  -  A task-oriented landing dashboard

**Task:** Let people understand the scope of the app and choose a destination without reading a long introduction or interpreting the sidebar alone.

**Decision:** Start on Home. Show the current color as a compact continuation card, then present the six workspaces in an adaptive card grid. Every card uses the same order: symbol, name, short task description, and explicit action. At enlarged text sizes, the grid reduces its column count rather than compressing the wording.

**Basis:** Apple guidance for a broad, flat sidebar, familiar symbols, logical grouping, sufficient spacing, adaptable layouts, and minimizing text truncation. Peer-reviewed dashboard research supports treating layout order and visual complexity as design variables that affect search behavior. Cards are a platform-informed grouping device here, not a scientifically privileged component.

**Limitation:** Card labels, order, and descriptions remain product hypotheses. They need task-based usability testing, including keyboard and VoiceOver navigation, before release.

## D-014  -  Conversion explanations follow the requested result

**Task:** Prevent the learning sequence from implying that every representation requires the same scientific operations.

**Decision:** Build a separate deterministic route for each output. RGB and HEX stop after serialization, HSL stops after rearranging encoded channels, Display P3 converts through D65 XYZ, Oklab and OkLCh remain D65-relative, and only the D50 XYZ, CIELAB, and CIE LCh paths include chromatic adaptation. Changing the representation resets the selected stage to its first step.

**Basis:** CSS Color 4 conversion definitions and reference algorithms; CIE colorimetry; the product rule that assumptions and transformations stay visible.

**Limitation:** The app currently teaches one canonical path from sRGB input. Future support for ICC profiles and other source spaces will require additional paths rather than relabeling this one.

## D-015  -  Stable controls, selectable explanations, and definitions in context

**Task:** Reduce interaction effort while making unfamiliar terminology and equations accessible.

**Decision:** Keep Previous, progress, and Next or Start Over in fixed left, center, and right positions above variable-height content. Reading text is selectable throughout the app. Every equation has visible LaTeX, a selectable in-words rendering, and a Copy LaTeX control. Unfamiliar terms have adjacent definition controls: macOS hover help gives a brief definition, while activation opens a plain-language explanation, a distinction, and direct evidence links.

**Basis:** Apple guidance for consistent controls, selectable macOS text, keyboard access, tooltips, and adaptable layouts; W3C cognitive-accessibility guidance on consistent interaction and understandable language.

**Limitation:** Hover help is supplemental because it is unavailable to touch and some assistive technologies. Definitions therefore remain keyboard-accessible, clickable, and available in the Reference workspace.

## D-016  -  Explore begins with prediction and a visual comparison

**Task:** Turn a scientific distinction into an experiment without presenting another long technical page.

**Decision:** The first Explore lab isolates one variable: the interpolation space. Before results appear, the user chooses two opaque sRGB colors and records whether two mixing methods will agree. Observation then combines a labeled slider, two independently calculated gradient bands, numeric result cards, and Convert handoff in one card. A separate explanation card keeps the qualification, contextual definitions, visible LaTeX, in-words readings, and primary source together. Critical values are available as text and VoiceOver descriptions rather than being encoded only by color.

**Basis:** CSS Color 4 distinguishes encoded-sRGB interpolation from linear-light interpolation and identifies linear spaces as appropriate for modeling the physical mixing of emitted light. Predict, Observe, Explain research supports eliciting a prediction before observation and explanation. Apple chart guidance supports a prominent visual message, a concise textual summary, direct labels, keyboard access, and not requiring interaction to reveal critical information after the observation begins.

**Limitation:** Linear-light interpolation is not perceptually uniform, and this laboratory does not simulate a calibrated display, ambient conditions, or an individual observer. Future experiments should keep their own scientific boundaries explicit instead of reusing this explanation indiscriminately.

## D-017  -  Palette Studio evaluates roles and relationships, not a palette in the abstract

**Task:** Make palette construction useful and visually direct without presenting a dense matrix of measurements or implying that one score establishes accessibility.

**Decision:** The first Build workspace assigns four colors to concrete interface roles: canvas, body text, accent, and accent text. Editing and a live interface preview stay side by side when space permits. A separate card evaluates only three named relationships: ordinary body text on canvas at 4.5:1, ordinary accent text on accent at 4.5:1, and accent against canvas at 3:1 when that accent is itself a required interface or graphical cue. Each row retains its pair, exact unrounded result, threshold, text-and-symbol status, and direct handoff to Check. Export and evidence remain visible in compact cards. At enlarged text sizes, major cards stack and all preview and export text follows the app's text scale.

**Basis:** WCAG 2.2 Contrast (Minimum) and Non-text Contrast; Apple accessibility guidance on adequate contrast, adaptable text, and conveying information without color alone; the product's deterministic-science boundary; CSS Custom Properties Level 1 for named reusable export values.

**Limitation:** These relationships do not test focus states, disabled states, gradients, images, typography rendering, color-vision differentiation, gamut, ambient conditions, or task usability. The app therefore reports relationship-specific results and explicitly avoids a whole-palette “accessible” badge. Starter palettes and role names remain design hypotheses that require user testing.

## D-018  -  Check isolates one question and keeps the model visible

**Task:** Add serious color-difference analysis without turning Check into a dense dashboard or implying that one number decides perceptibility or acceptability.

**Decision:** Start Check with four explicit task cards and show only the selected analysis. Contrast and difference use three primary cards in the same order: editable input, a directly labeled visual result, and the calculation with assumptions and sources. Color reliance adds one compact review-prompt card because the complete design, not the pair alone, determines whether color carries meaning; gamut adds a channel-boundary card because out-of-range coordinates are the result being explained. The difference view places the two colors side by side, reports CIEDE2000 as a relative value rather than a verdict, and visualizes the signed lightness, chroma, and hue-direction terms before showing the LaTeX combination. Definitions stay beside unfamiliar terms, and primary sources remain direct links. Pair-based tasks retain the exact pair when the user switches between them.

**Basis:** ISO/CIE 11664-6:2022 defines the CIEDE2000 formula as an improved correlation with perceived color-difference magnitude relative to CIELAB; Sharma, Wu, and Dalal document and test the implementation while explicitly excluding psychophysical applicability from that paper's scope. The single-task structure also follows the product's progressive-depth and consistent-interaction rules.

**Limitation:** CIEDE2000 is still a model from colorimetric coordinates, not a simulation of an individual observer or a universal noticeability or acceptability threshold. The side-by-side previews are device-dependent, the difference bars compare only their magnitudes within the current pair, and the neutral preview cannot establish whether a complete design conveys meaning without color.

## D-019  -  Learn begins with a small library and contrasts questions before formulas

**Task:** Expand Learn without dropping readers into another long page or teaching that every two-color number answers the same design question.

**Decision:** Learn opens to a small card library rather than directly inside a lesson. Every card states its question, scope, and length before the reader enters. Each lesson retains a directly selectable three-part map and stable Previous, progress, and Next positions. The second lesson keeps one labeled pair visible while first presenting two questions, then isolates foreground/background contrast, then isolates modeled color difference. The deliberately low-contrast sample is limited to one short line; all explanatory and numeric content remains independently readable. The exact pair can open in the corresponding Check analysis.

**Basis:** WCAG 2.2 defines contrast as a relative-luminance relationship used with named content criteria. ISO/CIE 11664-6:2022 defines CIEDE2000 as a color-difference formula with improved correlation to relative perceived difference magnitude. Apple layout guidance supports logical grouping, adaptable layouts, and progressive disclosure when it helps people find essential information without crowding the view.

**Limitation:** Four lessons are not a complete color-science curriculum. The examples demonstrate bounded relationships but do not establish perceptual thresholds, reading performance for an individual, calibrated device appearance, or every accessibility requirement. Lesson order, labels, and comprehension still require direct testing with readers at varied levels of color-science experience.

## D-020  -  Explore begins with a choice and isolates one compositing relationship

**Task:** Expand Explore without dropping readers directly into an active experiment or turning transparency into an unlabeled visual effect.

**Decision:** Explore now opens to a two-card experiment library. Each card names one bounded question and the shared Predict, Observe, Explain rhythm before entry. The existing mixing experiment retains its controls and calculation but adds a stable return path and a focused experiment header. The new transparency experiment fixes one source color and contribution over two named opaque backdrops. Observation uses two result cards with exact HEX and RGB values plus labeled contribution bars; explanation defines alpha in context, renders one source-over rule from LaTeX with an in-words equivalent, states the encoded-sRGB and opaque-backdrop assumptions, and links directly to both W3C specifications. The same deterministic compositor also supplies effective foreground colors to Check. At enlarged text sizes, input and result pairs stack instead of compressing.

**Basis:** W3C Compositing and Blending Level 1 defines simple alpha compositing and the Porter-Duff source-over operator. CSS Color 4 defines alpha for CSS colors and connects its processing to compositing. Predict, Observe, Explain evidence supports recording an expectation before revealing an observation, while the app's existing progressive-depth and adaptable-layout rules support a small library and one-column enlarged-text presentation.

**Limitation:** This experiment uses simple source-over on encoded sRGB components over opaque backdrops. It does not reproduce a complete browser or display pipeline, blending modes, group opacity, high-dynamic-range rendering, translucent backdrops, calibrated appearance, or an individual observer. The two-card library and wording remain usability hypotheses requiring direct testing.

## D-021  -  Reference supports browsing and search without exposing every term at once

**Task:** Make twenty-four definitions and their evidence easy to find without returning to a long menu, a dense glossary wall, or sources hidden behind an extra disclosure.

**Decision:** Reference opens to four topic cards with plain-language descriptions and term counts. One inline search filters term names, categories, summaries, and key distinctions immediately as the reader types. A topic reveals short term cards; selecting one opens the existing one-term reading model. The reader keeps Previous, position, and Next in stable locations, then presents the definition, key distinction, an equation only for five concepts where it materially helps, its selectable in-words equivalent, and direct source links with limitations already visible. Enlarged text changes grids to one column rather than compressing wording. Every term belongs to exactly one topic, and automated coverage checks prevent terms from becoming unreachable.

**Basis:** Apple's current Search Fields guidance recommends descriptive placeholder text, immediate results while typing, and simplified results. W3C cognitive-accessibility guidance recommends clear hierarchy, headings, boundaries, search, and more than one way to find content. WCAG guidance on consistent navigation supports retaining the same relative position for repeated reader controls. The one-term surface also preserves the product's progressive-depth rule.

**Limitation:** The four topic names, their grouping, search ranking, and card wording remain information-architecture hypotheses. Search currently filters locally by substring rather than supporting synonyms, spelling correction, recent searches, or ranking by observed user intent. These choices require task-based testing with keyboard, VoiceOver, magnification, and readers at different levels of color-science familiarity.

## D-022  -  A context lesson separates identical values from perceived appearance

**Task:** Introduce perceptual context through a meaningful visual comparison without presenting an illusion as a universal result or surrounding it with a dense theory page.

**Decision:** The third Learn lesson fixes both center patches at the exact same opaque sRGB value and labels that value below each patch. Only the neutral surround changes. The first part establishes numeric identity, the second exposes one adjustable surrounding value, and the third uses a compact spatial relationship - fixed target plus different context leading to context-dependent appearance - to distinguish what the app calculates from what the demonstration illustrates. The final surface reports the target HEX and D50 Lab coordinates but deliberately supplies no universal effect size. Every part retains the same navigation positions, direct definitions, selectable wording, and visible sources; enlarged text stacks the paired fields rather than shrinking them.

**Basis:** Kingdom's peer-reviewed review distinguishes brightness, lightness, and contextual effects while describing continuing theoretical disagreement. CIE 248:2022 defines CIECAM16 as a viewing-condition-specific transformation between tristimulus values and perceptual attribute correlates. These support showing that context matters and stating viewing conditions explicitly; they do not support assigning the simplified display one observer-independent perceptual result.

**Limitation:** The on-screen comparison depends on display behavior, ambient conditions, geometry, adaptation, and observer. It is a teaching demonstration, not a calibrated psychophysical measurement, a complete color-appearance model, or evidence that everyone will see the same direction or magnitude of change. The explanatory sequence and terminology still require comprehension and accessibility testing.

## D-023  -  Check treats color reliance as a design review, not an automated verdict

**Task:** Address the original grayscale and use-of-color requirement without implying that a transformed two-color pair can determine accessibility or simulate every kind of color vision.

**Decision:** Add a Check task titled “Review meaning without color.” It preserves the current pair, shows the original colors beside equal-channel sRGB neutrals that retain each color's calculated WCAG relative luminance, and labels both exact outputs. Two visible luminance bars report the defined values and separation without a threshold. A separate card then asks whether the complete design names the meaning, reinforces it through shape, symbol, pattern, position, or underline, and retains those cues in interaction and status states. The calculation card renders the luminance and equal-channel rules from LaTeX, includes selectable readings and Copy LaTeX controls, and links directly to WCAG Use of Color and the sRGB standard. The analysis choices use equal-height cards and become one column at enlarged text sizes.

**Basis:** WCAG 2.2 Success Criterion 1.4.1 requires that color not be the only visual means of conveying information, indicating action, prompting a response, or distinguishing an element. W3C's G14 technique recommends making the same information visible in text, while other sufficient methods include symbols and patterns. IEC 61966-2-1 and WCAG's relative-luminance calculation provide the deterministic basis for the neutral preview.

**Limitation:** The neutral preview removes hue from one pair but is not a color-vision-deficiency simulation, an observer model, or a complete conformance test. It cannot inspect the design's semantics, labels, patterns, focus treatment, interaction states, programmatic relationships, or task usability. The review prompts still require human judgment and testing with disabled users.

## D-024  -  Gamut analysis separates boundary detection from mapping choice

**Task:** Show whether a wide-gamut color can be represented in sRGB without turning a color-space boundary into a vague warning or presenting one replacement color as objectively correct.

**Decision:** Add a fourth Check task titled “See color-space limits.” A validating field and three directly adjustable component controls accept one opaque, in-range Display P3 source. The deterministic engine decodes the source with the shared transfer function, converts Display P3 to XYZ D65 and then to sRGB with CSS Color 4's rational matrices, and reports whether all three encoded destination channels remain within 0 to 1. The result precedes the calculation, with the source and a simple channel-clipped sRGB comparison shown side by side. Three labeled range bars keep the raw converted coordinates visible and use direction arrows and text - not color alone - to identify crossed boundaries. Equations, in-words readings, copy controls, definitions, sources, and limits remain visible in one card sequence. The Check chooser becomes a balanced two-by-two grid and stacks to one column for enlarged text.

**Basis:** CSS Color 4 defines Display P3 with D65, the sRGB transfer curve, in-gamut component ranges, exact conversion sample code, and gamut mapping as a separate process for out-of-gamut destination colors. Its current gamut-mapping section explains why independent channel clipping can shift hue and defines higher-quality alternatives. The app therefore uses clipping only as the most direct boundary visualization, not as a normative or preferred production result.

**Limitation:** This tool tests a reference-space relationship for one SDR color. It does not measure this Mac or another device, inspect ICC profiles, map an image, predict appearance, handle HDR, or choose a production rendering intent. The Display P3 preview depends on the active display and system color management. Input is intentionally restricted to opaque Display P3 components from 0 to 1 even though CSS can preserve out-of-range values during intermediate calculations.

## D-025  -  The gamut lesson follows one color while separating calculation from choice

**Task:** Teach why a color can fit Display P3 but cross an sRGB boundary without duplicating the denser Check workbench or implying that a crossed boundary selects its own replacement color.

**Decision:** Add a fourth three-part Learn lesson built around the same opaque Display P3 example used by Check. The first part contrasts source coordinates with the different color produced by interpreting the same numbers as sRGB. The second converts the intended Display P3 color through XYZ D65, then shows each raw sRGB destination coordinate against its 0 to 1 boundary with direction arrows and text labels. The third keeps the original and a simple clipped comparison visible while separating detected boundary, mapping choice, and in-range destination into three named stages. A directly selectable lesson map and stable Previous, progress, and Next positions remain at the top of every part; the final action opens the exact source color in Check. Enlarged-text snapshots now cover every part rather than only the first.

**Basis:** CSS Color 4 defines Display P3 and sRGB as distinct color spaces, supplies their conversions through XYZ D65, and treats gamut mapping as a separate operation after a destination color is found to be out of gamut. Its current gamut-mapping discussion notes that independent channel clipping can alter hue. Reusing the same deterministic example and handoff preserves the product's boundary between learning explanation and scientific calculation while its three-part structure follows the existing progressive-depth and segmenting rules.

**Limitation:** The lesson demonstrates one SDR reference-space relationship, not a device measurement, calibrated appearance prediction, image-wide rendering intent, or HDR workflow. The simple clipped swatch is illustrative rather than a recommended or CSS gamut-mapped result, and visible swatches depend on the active display and system color management. The sequence and language still require comprehension testing with readers at varied levels of color-science experience.

## D-026  -  A general-audience framework becomes a release gate, not a compliance claim

**Task:** Prevent incremental feature work and visual refinement from drifting away from comprehension, accessibility, platform behavior, scientific status, and product-specific validation.

**Decision:** Adopt the product owner's *General-Audience Technical Application Design Framework* version 1.1 as the project's design-governance baseline. Preserve its distinctions among standards, platform guidance, empirical evidence, synthesis, policy, and product-specific testing. Every consequential feature or redesign must record its user problem, applicable framework domains, evidence, alternatives, accessibility behavior, validation plan, and visible limitations. Each critical screen must eventually pass the framework's screen review, appearance matrix, keyboard, VoiceOver, comprehension, usability, and reliability gates before an external release candidate. Automated calculations and renderings remain scoped evidence; they are never presented as proof that a workflow is understandable or accessible in practice. The Build 011 baseline and open gates are recorded in `Documentation/DESIGN_FRAMEWORK_AUDIT.md`.

**Basis:** The framework's governing principle - preserving technical depth while reducing unnecessary effort - matches this product's existing evidence hierarchy, progressive-depth model, scientific authority boundaries, and standing requirement to improve each affected interface deliberately. Its explicit separation of task success, comprehension, experience, and access corrects a common evaluation gap for technical software.

**Limitation:** Adoption does not establish ISO or WCAG certification, complete Apple-platform conformance, usability, comprehension, or accessibility. Build 011 has extensive deterministic and visual automation but has not completed manual keyboard, VoiceOver, increased-contrast, reduced-motion, CVD, target-size, performance, or representative-user testing. Framework-created synthesis and policy must not be cited as if they were direct empirical findings.

## D-027  -  System accessibility preferences change shared presentation and feedback

**Task:** Make the existing interface respond consistently to macOS access preferences and communicate important state changes without adding another settings panel or redesigning every section independently.

**Decision:** Read Increase Contrast, Differentiate Without Color, Reduce Motion, and Reduce Transparency once at the app shell and pass a small, testable preference profile through the design system. Shared cards and nested surfaces receive stronger opaque boundaries in the combined accessibility profile. Selected lesson parts, conversion stages, and Check tasks retain border and fill cues while adding a visible checkmark when color differentiation is requested. Swatch labels replace material with an opaque surface when transparency is reduced. Copy, save, removal, invalid submitted input, workspace changes, and persistence failures use visible state plus AppKit accessibility announcements. Command-1 through Command-7 open the seven major destinations. A failed Color Tray write keeps the in-memory colors, presents a dismissible explanation, and avoids claiming the change was saved. Automated rendering now covers every primary section in light and dark appearances plus a combined increased-contrast, no-color, reduced-motion, and opaque-surface profile.

**Basis:** Apple's accessibility guidance recommends adequate target dimensions, keyboard access, testing with assistive technologies, sufficient contrast in light and dark appearances, and communication that does not depend on color alone. SwiftUI exposes the system accessibility appearance preferences through environment values, and AppKit provides announcement notifications for information that VoiceOver should present through speech or braille. The product framework also requires visible state, truthful persistence feedback, and testing preference combinations rather than isolated settings only.

**Limitation:** The combined automated profile is a diagnostic regression surface, not proof of keyboard, VoiceOver, CVD, reduced-motion, increased-contrast, or accessibility conformance. The app currently has little custom motion, so reading Reduce Motion mainly preserves a testable boundary for future components. Manual Accessibility Inspector, VoiceOver, Full Keyboard Access, target-size, focus-order, system-accent, display-scaling, and representative-user testing remain required.

## D-028  -  Dense workbenches separate action, interpretation, method, and reuse

**Task:** Reduce the visual and cognitive load in Convert, Build, and Check while adding appearance choices, color-vision-aware interface cues, larger controls, broader starter palettes, and reusable code output.

**Decision:** Convert keeps input and output together, then presents one compact scientific path and one selected stage. The result remains visible while Meaning, Calculation, and Sources become directly selectable sibling views; Previous and Next remain in a stable footer. Build becomes a three-phase workspace - Design, Check, and Export - rather than a single page of editor, preview, measurements, evidence, and code. Check replaces four large task cards with a compact analysis selector and separates Work and Results from Method and Sources; each analysis then uses its own appropriate composition. Principal controls use the large native control size and body-sized action labels. Code export is secondary in Convert and primary in Build, with deterministic snippets for CSS, Swift, JavaScript, Python, R, and JSON. Settings can follow macOS or request Light or Dark and can select system, blue to orange, protan-aware, deutan-aware, tritan-aware, or monochrome interface cues. These choices affect interface semantics only; analyzed swatches and calculated values are unchanged. Every custom cue retains text, a symbol, a boundary, or numeric state.

**Basis:** Apple's Color guidance recommends semantic system colors, light/dark/increased-contrast variants, and alternatives to color-only communication. SwiftUI's `preferredColorScheme` is the platform mechanism for a presentation-level appearance preference, and Apple's settings guidance supports a dedicated macOS Settings window for infrequently changed preferences. Existing segmenting and multimedia-learning evidence supports controlling the amount of simultaneously competing explanation, but does not prescribe the same pattern for every task. The adopted product framework requires progressive depth, stable navigation, meaningful target size, visible limitations, and separate evaluation of comprehension and access.

**Alternatives considered:** A single scrolling page retained maximum simultaneous visibility but repeated the exact overload reported by the product owner. Applying the same tab structure to all three workspaces would have been superficially consistent but would ignore their different tasks. Full-screen color-vision simulation was rejected for this milestone because it could distort scientific swatches and imply an observer model the app does not implement. The selected approach therefore uses task-specific chunking and palette-aware interface cues without modifying source colors.

**Limitation:** The custom cue palettes are design hypotheses, not simulations, treatments, or promises that every cue is distinguishable for every person with a named color-vision condition. Their names describe the conflicts they try to avoid, not validated individual outcomes. Automated renderings and code tests do not establish findability, comprehension, keyboard or VoiceOver efficiency, real CVD usability, or comfort under sustained use. Those manual and representative-user gates remain open.

## D-029  -  Section identity comes from task-specific composition and an adaptive spectrum

**Task:** Correct an app-wide presentation that remained visually repetitive after content was segmented. The repeated white-card grid made Learn, Explore, Convert, Build, Check, and Reference feel like variations of one page, weakened orientation, and left the requested broader palette largely invisible.

**Relevant framework domains:** Architectural UI/UX and Cognitive Friction; Attention and Perceptual Hierarchy; Information Architecture; Aesthetics and Visual Ergonomics; Chromatics and Color Psychology; Accessibility and Inclusive Design; Adaptation and Platform Conventions.

**Decision:** Give every primary destination a stable visual identity and a composition that matches its task. Home is a chromatic launch dashboard; Learn is a numbered path; Explore is a visual experiment gallery; Convert is an input/output workbench followed by a persistent vertical process map; Build is a three-stage studio rail; Check is a question-first diagnostic rail; and Reference is a search-led field guide. A shared eight-color spectrum supplies section accents, subtle backgrounds, and decorative relationships in separately tuned light and dark values. Selecting a color-vision-aware cue preference replaces the entire interface spectrum, not only success and warning colors. Scientific samples, component colors, gamut results, and user-authored palettes remain exact and outside this decorative system. Labels, symbols, borders, selection marks, position, and text continue to carry every essential meaning.

**Basis:** Apple color guidance supports semantic, appearance-adaptive colors and requires alternatives to color-only communication. Apple macOS guidance supports a stable sidebar and native control behavior. Research on visual complexity and prototypical structure supports controlling competition and retaining familiar organization, while it does not prescribe one universal layout. The adopted framework requires the visible structure to match the person's task, assigns color a supporting rather than exclusive role, and treats light and dark appearances as separate perceptual conditions.

**Alternatives considered:** Merely tinting the existing cards was rejected because the information architecture would still look and behave the same in every section. Giving every screen an unrelated visual language was rejected because it would increase relearning and weaken navigation predictability. A single brand accent was retained as an available system preference but rejected as the only default visual signal because it could not provide the requested breadth or section orientation.

**Accessibility review:** The wider spectrum is redundant by design and never changes a scientific value. Increased Contrast and Reduce Transparency still reinforce shared boundaries and surfaces; Differentiate Without Color retains visible selection marks; Reduce Motion adds no decorative animation; large text triggers stacking rather than narrower columns. Automated snapshots cover the shell, all primary sections, major focused states, light, dark, enlarged text, and the combined accessibility profile.

**Validation:** Build 014 includes deterministic palette-count coverage, app-shell rendering, a full-height Convert rendering, and the existing cross-section visual matrix. Manual keyboard, VoiceOver, focus, measured contrast, CVD simulation, display-scaling, novice comprehension, expert efficiency, and perceived-aesthetics testing remain required before an external release candidate.

**Limitation:** Section accents and compositions are evidence-informed design hypotheses, not results validated with the intended audience. An eight-color palette does not promise distinguishability, preference, cultural fit, or sustained-use comfort. The protan-, deutan-, and tritan-aware spectra avoid selected conflicts but are not observer simulations or individualized accommodations.

## D-030  -  Resume valid task context without taking over the launch experience

**Task:** Help people return after navigation, interruption, or relaunch without forcing them to reconstruct a lesson, experiment, conversion, palette, diagnostic, or reference search, and without restoring an invalid draft as if it were valid work.

**Relevant framework domains:** User, Task, and Context; Cognitive Friction; Mental Models and Predictability; Temporal UX; Error and Recovery; Accessibility and Inclusive Design; Performance and State Continuity.

**Decision:** Store one typed, versioned `WorkspaceSession` behind `WorkspaceSessionStore`. The session records the last non-Home workspace and each workspace's compact, meaningful state: selected content and part, valid color inputs, experiment position and reveal state, named palette roles, selected diagnostic and information level, and Reference search or reading position. Views restore only known enum values and bounded state. Color editors update the session after successful parsing, so an unfinished invalid draft remains visible during the current edit but does not replace the last valid restorable color. Home shows a section-colored “Continue where you left off” card with a plain-language title, detail, and explicit action; launch still begins on Home so the person chooses whether to resume. Provenance-bearing Color Tray records remain a separate store. Normal app models use live local persistence, while models created with a custom test tray receive an isolated in-memory session unless a store is explicitly injected.

**Basis:** Apple's launch guidance recommends restoring previous state so people can continue where they left off, and Apple's SwiftUI state-restoration sample describes return to a prior interaction point as continuity that helps people finish active tasks quickly. The project's critical-task map already identifies the state worth retaining in every workspace, and the adopted framework requires explicit interruption and resumption behavior. The session is small, local, and non-sensitive, so a versioned encoded value in `UserDefaults` is proportionate to the current single-window app.

**Alternatives considered:** Scattered `@AppStorage` values in individual views would make validation, schema changes, and test isolation harder. Persisting every transient field would restore invalid drafts and incidental disclosure state without proving that doing so helps the task. Automatically reopening the last workspace would reduce one click but remove the orientation and choice supplied by Home. Using the Color Tray as session storage would conflate temporary working context with intentionally saved, provenance-bearing records.

**Accessibility review:** The resume card retains a text heading, task title, explanatory detail, section symbol, bordered surface, and fully labeled button; color is supplementary. Its horizontal layout stacks when the available width or enlarged text requires it. The saved state does not change scientific colors or accessibility preferences, and returning to Home remains available through the sidebar and Command-1.

**Validation:** Two deterministic tests verify that custom-tray models do not read or write the live session and that an explicitly shared store restores a saved conversion and workspace. The full 68-test suite passes. The visual matrix renders the no-history Home state, resumed Home state, light, dark, enlarged text, the combined system-accessibility profile, and all six selectable interface-cue palettes in both appearances.

**Limitation:** Automated state and rendering tests do not establish that people understand the resume copy, expect the chosen state boundaries, or can resume efficiently with keyboard or VoiceOver. Manual clean-launch, relaunch, interruption, focus restoration, multiwindow semantics, schema-migration, corrupted-store, and representative-user testing remain open. Invalid drafts intentionally are not restored, which protects the last valid calculation but may surprise someone who expected unfinished text to survive a relaunch.

## D-031  -  Color serves defined roles while Learn and Inspector expose one task at a time

**Task:** Respond to direct product feedback that the interface had become too colorful, dense, repetitive, and inconsistently aligned; add a way to inspect pixels inside or outside the app; and make light/dark and color-vision options easy to find.

**Relevant framework domains:** Cognitive Friction; Attention and Perceptual Hierarchy; Information Architecture; Interaction and Affordances; Aesthetics and Visual Ergonomics; Chromatics; Accessibility and Inclusive Design; Adaptation and Platform Conventions; Evaluation and Evidence.

**Decision:** Supersede the decorative-spectrum portion of D-029. Navigation, workspace headers, shared cards, selection, and principal actions now use one structural accent. Positive, caution, and critical colors remain separate semantic roles, and exact scientific samples keep their source colors. Decorative spectrum ribbons, large section motifs, colored workspace glows, per-card section hues, and the unused eight-color spectrum data are removed. Home, Learn, Explore, and Reference retain different task structures, but their shared parts now use the same neutral surfaces, accent rail, icon container, and action hierarchy.

Learn replaces four simultaneous full-detail cards with four compact numbered selectors and one focused preview. Only the selected path exposes its summary, three-part structure, and primary action, and that action remains bottom-trailing at ordinary text sizes. At enlarged text sizes, the selector and preview stack rather than compressing. The redundant Learn handoff explanation and Explore method footer are removed because their destinations already communicate those behaviors. The Home working-color panel and Inspector swatch no longer repeat representations shown immediately elsewhere.

The Color Inspector adds a labeled system pixel sampler. A selection from this app, another app, or another display is converted to sRGB and becomes the shared working color without changing the active workspace. Hex, RGB, and Alpha use an explicit three-column grid: labels share one leading edge, definition buttons share a second, and values share a third. Column widths expand with the app's text scale. The Inspector and global toolbar both link to Settings, where the sections are visibly named Appearance and Color-vision accessibility.

**Basis:** The product owner's screenshots supplied direct task evidence: competing card colors obscured hierarchy, four simultaneous lesson actions increased choice load, adaptive card actions did not form a stable line, and generic `LabeledContent` alignment did not express the requested coordinate columns. The adopted framework assigns color a supporting role, favors progressive depth, asks repeated parts to share geometry, and requires important settings to be findable. Native macOS controls remain the default: `NSColorSampler` provides the cross-application selection interaction, and `SettingsLink` opens the app's Settings scene.

**Alternatives considered:** Keeping section-specific colors but lowering opacity would preserve the same number of competing identities. Recoloring every scientific visual to the structural accent would erase data meaning. Four collapsible lesson cards would still present four action locations and introduce disclosure state. A custom magnifier would duplicate platform behavior and increase permission, focus, and multi-display risk. A menu-only Settings route would remain undiscoverable to someone who did not already know where to look.

**Accessibility review:** Essential state continues to use text, symbols, borders, position, or numeric values rather than hue alone. The sampler button has a direct label and hint, uses the system's cancel behavior, and announces a successful sample. Screen sampling changes no workspace navigation. The Inspector alignment is rendered at 100% and 160% text sizes; the large-text label, definition, and value columns remain intact. Color-vision cue presets still alter interface roles only and remain explicitly described as neither simulations nor promises.

**Validation:** Deterministic tests cover NSColor-to-sRGB normalization, alpha preservation, and updating the working color without changing workspaces. Dedicated Inspector snapshots cover light, dark, and 160% text. The full matrix continues to render every primary workspace, focused lesson/check/reference states, light, dark, enlarged text, combined system-accessibility preferences, and all six cue palettes. Seventy-one automated tests pass.

**Limitation:** A sampled screen pixel is not the underlying source asset, its original color-space metadata, a calibrated device measurement, or a promise that transparency can be recovered from composited screen output; most displayed pixels are opaque. The system sampler's permission, cancellation, focus return, multi-display, and assistive-technology behavior still require manual testing. The calmer palette, focused Learn selector, settings links, and revised copy have not yet been evaluated with representative novice or experienced users.

## D-032  -  Auxiliary tools become windows and Ollama proposes rather than calculates

**Task:** Correct Settings scroll loss when changing System accent, keep Reading preview with its controls, make secondary tools freely resizable, shorten screen-sample processing, and add optional local or external Ollama model selection to Palette Studio without confusing model suggestions with scientific results.

**Relevant framework domains:** Cognitive Friction; Information Architecture; Interaction and Affordances; Temporal UX; Error and Recovery; Trust, Privacy, and Automation; Accessibility and Inclusive Design; Performance and State Continuity; Adaptation and Platform Conventions; Evaluation and Evidence.

**Decision:** Keep the interface-theme modifier in one stable SwiftUI branch and make System accent an optional tint value, so switching presets changes environment data rather than replacing the Settings subtree. Reading preview now follows the font controls in the Reading section. Inspector, Color Tray, contextual definitions, and Settings become independent macOS windows with minimum usable sizes and unrestricted growth in both dimensions. Each secondary window receives the same typography, appearance, cue palette, and system-accessibility environment as the main window.

The system sampler continues to normalize `NSColor` into sRGB, but the typed value now enters the converter directly after canonical 8-bit normalization rather than passing through a string serializer and parser. This removes avoidable work while keeping the displayed representation and analyzed channels identical.

Ollama recommendations are opt-in and follow the two-path setup pattern studied in Chenoot: guided setup on this Mac or an externally managed endpoint. The guided path expects the Ollama service to be installed and running, then lets On Color Theory discover, download, and select models through the local API; it does not silently install or bundle an executable. External setup accepts a user-supplied HTTP or HTTPS address and explicitly states which palette context leaves the Mac. Build adds Recommend between Design and Check. The provider requests a JSON-schema-constrained four-role proposal, rejects incomplete, malformed, or alpha-bearing values, and passes only the accepted colors into the existing deterministic evaluator. The UI attributes rationale to the selected model and attributes all contrast results to On Color Theory.

**Basis:** The product owner's observed scroll reset, fixed popup geometry, separated Reading preview, sampler delay, and request for Chenoot-like Ollama choices are direct product evidence. Stable view identity preserves scroll and focus state when only a preference value changes. Independent windows are the native macOS mechanism for user-controlled two-dimensional resizing. Chenoot demonstrates a clear local-managed versus externally managed mental model; Ollama's official API supplies installed-model discovery through `GET /api/tags`, model download through `POST /api/pull`, and schema-constrained non-streaming generation through `POST /api/generate`.

**Alternatives considered:** Retaining popovers and only increasing their default dimensions would not give users durable horizontal and vertical control. Storing and restoring an estimated Form scroll position would treat the symptom while the theme modifier continued to change structural identity. Parsing the sampled pixel through the public text path preserved one code path but added unnecessary serialization and quantization work. Bundling or downloading an Ollama executable was rejected for this milestone because executable provenance, checksums, updates, lifecycle, code signing, removal, and failure recovery need a dedicated security and distribution design. Allowing the model to return contrast verdicts was rejected because it would violate the app's scientific authority boundary.

**Accessibility and privacy review:** Auxiliary content retains native window controls, keyboard focus behavior, selectable text, appearance preferences, enlarged typography, high-contrast surfaces, no-color selection marks, and reduced-transparency behavior. The local path says that prompts remain on this Mac; the external path says that the brief, current palette, and output traverse the selected server and recommends HTTPS outside a trusted local network. Model suggestions identify their provider and local/external status. Every deterministic check retains text, value, threshold, and symbol rather than color-only status.

**Validation:** Seventy-five tests across nineteen suites pass. New coverage proves the interactive color path bypasses a deliberately rejecting parser, structured proposals retain the four role positions, invalid and alpha-bearing output is rejected, and installed-model discovery selects a usable provider. The visual matrix renders all four Build stages, Settings, light/dark and enlarged text, combined accessibility preferences, and the existing Inspector states. Debug and release bundles compile and pass strict ad-hoc signature verification.

**Limitation:** Guided setup manages models but still requires the Ollama application or service to be installed and running; it is not Chenoot's fully app-owned runtime. Downloads currently provide indeterminate progress and no explicit cancel control. The app does not authenticate an external server, verify a model's license, quality, provenance, or safety, or prevent a model from returning poor rationale. Cleartext HTTP is available for user-selected local networks and does not provide transport confidentiality. Window focus restoration, size persistence, keyboard and VoiceOver behavior, sampler latency on multiple displays, real server failures, download interruption, model-output quality, privacy expectations, and representative-user comprehension remain manual release gates.

## D-033  -  Persist useful geometry, recover saved work, and preview model disclosure

**Task:** Move beyond isolated feature fixes by hardening continuity, keyboard and enlarged-text operation, optional-model privacy and interruption behavior, and saved-work recovery as one release-readiness milestone.

**Relevant framework domains:** Interaction and Affordances; Temporal UX; Error and Recovery; Trust, Privacy, and Automation; Accessibility and Inclusive Design; Performance and State Continuity; Adaptation and Platform Conventions; Evaluation and Evidence.

**Decision:** Assign every app-owned window a stable frame-autosave identity. AppKit restores its last size and position, while a visibility check recenters windows that would otherwise be effectively off-screen after a display change. Add direct commands for saved-work resumption and optional Ollama setup. The setup assistant uses an enlarged-text compact step picker in place of the sidebar, restores focus to address and model fields, and exposes native keyboard equivalents for its principal actions.

Before model generation, Build can reveal the exact destination, purpose, current role values, and design brief that will be sent, plus a concise list of excluded data. Local and external actions use different verbs. Design briefs and returned prose are bounded; user content is delimited as untrusted data; model names are validated; generation and downloads can be canceled; changing provider state invalidates older operations; and common reachability, timeout, TLS, and cancellation failures receive task-specific guidance. Ollama's server version is shown after a successful connection. The four-role schema and deterministic-science boundary from D-032 remain unchanged.

Advance `WorkspaceSession` to schema 2 with an explicit schema-1 migration. If stored data is unreadable, contains an invalid working color, or declares a future schema, keep the original bytes as a recovery copy, replace the active value with a valid fresh session, and explain the fallback on Home. This avoids a repeat-failure loop without pretending the damaged state was restored.

**Basis:** The product owner requested a larger, non-incremental pass after observing appearance refresh, alignment, density, window, sampler, light/dark palette, and Ollama-onboarding problems across earlier builds. Apple window autosave is proportionate for local macOS geometry continuity. Preflight data disclosure supports an informed local/external choice, while cancellation and stale-operation guards keep slow provider work under the person's control. Versioned migration and recoverable fallback make the existing persistence promise testable rather than assuming all older or damaged data will decode forever.

**Alternatives considered:** A custom geometry store would duplicate AppKit behavior and require more display-coordinate policy. Automatically sending the request when Recommend opens would weaken consent and task control. Logging full prompts for diagnostics would expand sensitive local retention and was rejected. Attempting best-effort field salvage from arbitrary corrupt JSON could produce silent semantic errors; preserving the raw recovery copy and starting from validated state is safer. Deleting future-schema data outright would make downgrade recovery impossible.

**Accessibility and privacy review:** Essential disclosure uses headings and text rather than color. Enlarged-text setup reflows rather than compressing the rail. Fields have explicit focus targets and submit behavior, and principal routes have keyboard commands. The request review omits files, account data, Color Tray history, and calculated scientific results. Cleartext external endpoints remain allowed for user-operated local networks but are labeled as lacking transport protection. Recovery notices are visible, dismissible, and announced without forcing navigation away from Home.

**Validation:** Eighty-four tests across twenty suites pass. Deterministic coverage includes stable window identifiers, schema-1 migration, corrupt and future-schema recovery, server-version discovery, request delimiting and brief limits, response-prose limits, model-name validation, progress handling, and network guidance. The rendering matrix includes all five setup steps, enlarged text in dark appearance, the expanded request disclosure, and the workspace-recovery state. Debug and release bundles pass strict ad-hoc signature verification.

**Limitation:** AppKit frame autosave and automated rendering do not establish correct focus or geometry across every real display arrangement. The recovery copy has no in-app export or field-level salvage interface. The app does not authenticate an external Ollama server, inspect provider retention, verify model provenance or licenses, or establish model quality. Manual keyboard, VoiceOver, sampler, real-server, interrupted-transfer, privacy, comprehension, and representative-user validation remain mandatory before an external release candidate.

## D-034  -  Relationship artwork becomes iconography while Help stays task-oriented

**Task:** Reuse the visual language already working in Explore, separate optional model administration from the saved-color tool group, and place a well-designed Help destination beside Display without adding another primary workspace to the sidebar.

**Relevant framework domains:** Cognitive Friction; Attention and Perceptual Hierarchy; Information Architecture; Interaction and Affordances; Aesthetics and Visual Ergonomics; Chromatics; Accessibility and Inclusive Design; Adaptation and Platform Conventions; Evaluation and Evidence.

**Decision:** Extract the overlapping-circle and layered-rectangle Explore relationships into reusable artwork with feature and compact scales. Keep the large diagrams at the top of each experiment card and replace the generic symbol tile below them with the compact form of the same artwork. The compact icons retain distinct circle-versus-rectangle silhouettes and their arrow-versus-layer center symbols, so the two colors remain supportive rather than exclusive identifiers.

Place Ollama in its own toolbar item immediately before the existing primary-action group because installation and model administration are optional system-level tasks, not Color Tray operations. Keep Color Tray, Inspector, Display, and Help in one group; Help follows Display because it explains both app-wide presentation and task operation. Help opens a single persistent, independently resizable window rather than becoming an eighth workspace or a transient popover.

Organize Help by six user tasks: starting, inspecting screen colors, designing Light & Dark palettes, optional Ollama models, understanding result authority, and shortcuts/troubleshooting. Search matches everyday task language. Each topic gives a short answer, bounded steps, limitations where needed, and direct actions into the relevant workspace, Inspector, Settings, or Ollama setup. At enlarged text sizes, replace the rail with a top search field and topic menu. Help describes model suggestions as optional and advisory, distinguishes app appearance from palette design, and separates calculated, illustrated, proposed, and context-dependent results.

**Basis:** The product owner's screenshot identifies the Explore relationship motifs as successful visual communication and directly requests their use in place of existing icons. The requested toolbar order establishes two different conceptual groupings: optional Ollama setup stands alone, while Help belongs with shared app tools and follows Display. The adopted framework favors task language, progressive disclosure, redundant chromatic cues, direct recovery paths, and help that moves a person back into the task rather than reproducing the interface as a manual.

**Alternatives considered:** Turning the motifs into raster assets would make cue-palette, appearance, and scale adaptation harder than retaining native SwiftUI geometry. Replacing the large diagrams with only compact icons would remove useful relationship previews. Adding Ollama to the sidebar would imply it is a core color workspace. Putting Help in a popover would constrain resizing, search results, enlarged text, and multi-step guidance. A glossary-only Help view was rejected because Reference already serves technical definitions; Help needs task routes and troubleshooting.

**Accessibility and privacy review:** Both Explore icons retain shape and symbol differences, and remain accessibility-hidden beside explicit experiment text. Help has searchable text, headings, selectable copy, labeled native controls, direct button names, dark rendering, and an enlarged-text reflow. The model topic repeats the optional and scientific-authority boundaries without exposing prompts, Color Tray history, or account data. Help actions change only the explicitly named navigation or window state.

**Validation:** Eighty-five tests across twenty-one suites pass. Help search has deterministic task-language coverage. The visual matrix renders the revised Explore library in light, dark, enlarged text, cue-palette, and combined accessibility states, plus Help start, Light & Dark, Ollama, and enlarged-text troubleshooting screens. Debug and release bundles pass strict ad-hoc signature verification.

**Limitation:** The automated harness renders the views but not the containing native macOS toolbar. Computer Use permission was unavailable, so a live visual check must still confirm the exact standalone gap before Ollama and the grouped ordering of Color Tray, Inspector, Display, and Help. Search quality, terminology, focus entry and restoration, complete keyboard and VoiceOver operation, and representative-user help comprehension remain manual release gates.

## D-035: Standardized identity icons and accessible model explanations

**Task:** Replace generic blue identity tiles across the app, reduce repeated Explore artwork, separate Model Assist from the shared toolbar group, make model reasoning understandable to a general audience, and give every install an identifiable version.

**Relevant framework domains:** Cognitive Friction; Attention and Perceptual Hierarchy; Information Architecture; Aesthetics and Visual Ergonomics; Chromatics; Accessibility and Inclusive Design; Trust, Privacy, and Automation; Evaluation and Evidence.

**Decision:** Define one reusable SwiftUI icon family with a consistent rounded tile, adaptive cue colors, distinct geometric motifs, and a familiar central symbol. Apply it to workspace headers and navigation plus major in-workspace destinations in Learn, Build, Check, Reference, and Help. Keep small action symbols native because they communicate standard control behavior rather than destination identity. The icon system uses color as a supporting cue; geometry, position, labels, and the central symbol remain redundant identifiers.

In Explore, remove the large relationship illustration from each unselected library card. Use the compact relationship icon as the card identity, then repeat it at a larger size beside the selected experiment title. This preserves recognition between selection and destination while reducing duplicated visual weight.

Rename the top-level optional-model destination to Model Assist. On macOS 26, place a fixed native toolbar spacer between it and the Color Tray, Inspector, Display, and Help group. Continue to name Ollama inside setup instructions when the specific runtime, download, API, or troubleshooting step matters.

Ask the selected model for an overall approach and an explanation for each role in short, natural language that does not assume color-science training. Label those two levels explicitly in the result. The model still supplies only proposed colors and prose; deterministic app services remain the sole source of contrast, conversion, gamut, difference, and simulation results. Remove em dashes from app copy as a product writing rule. Show the bundle version and build in Settings and Help.

**Basis:** The product owner's screenshots identify generic blue identity tiles as inconsistent with the successful Explore motifs, show that the optional-model toolbar item was still visually joined to the shared group, and request less duplicated illustration in the Explore library. Consistent icon construction supports recognition while distinct geometry and labels avoid color-only identification. Repeating a selected item's compact identity in the destination supports continuity without giving every unselected card a large decorative panel. Explicit explanation labels and plain-language prompt instructions help people distinguish model intent from deterministic findings.

**Alternatives considered:** Giving every destination a bespoke large illustration would increase visual noise and maintenance cost. Recoloring existing SF Symbols blue would not create the requested designed identity. Replacing every small control icon would weaken platform familiarity. Calling the toolbar item Ollama would expose an implementation choice before the user's task. Adding an ordinary gap inside a toolbar group would not create a separate native toolbar bubble on macOS 26.

**Accessibility and privacy review:** Every designed icon appears beside text and retains non-color geometry and symbols. Icons are hidden from assistive technology where adjacent text already supplies the name. Cue palettes and appearance still flow through the shared semantic environment. Model explanations remain bounded, attributed, advisory, and separated from calculated results. The request disclosure and local or external destination remain unchanged.

**Validation:** Eighty-seven tests across twenty-one suites pass. New deterministic tests cover distinct workspace icon motifs, version formatting, natural-language prompt requirements, and the absence of em dashes in the model prompt. The visual composition matrix covers the icon family in normal, dark, enlarged-text, and combined accessibility appearances plus focused Explore, Reference, Build, Check, Help, and Settings states. Debug and release bundles pass strict ad-hoc signature verification.

**Limitation:** Automated rendering cannot establish recognition, comfort, or meaning with intended users. Model instructions cannot promise that every installed model writes equally well, so representative output review remains necessary. The macOS 26 toolbar spacer still needs final inspection in the packaged live app. Manual VoiceOver, keyboard, focus, color-vision, comprehension, privacy, signing, and notarization gates remain open.

## D-036: Independent model controls and recommendation-in-context previews

**Task:** Complete the visible separation of Model Assist, make primary workspace identity equally prominent, and let people judge a proposed palette in a realistic text context before reviewing calculated checks.

**Relevant framework domains:** Attention and Perceptual Hierarchy; Information Architecture; Interaction and Affordances; Aesthetics and Visual Ergonomics; Chromatics; Accessibility and Inclusive Design; Visualization and Epistemic Communication; Trust, Privacy, and Automation; Evaluation and Evidence.

**Decision:** On macOS 26, opt Model Assist out of the native toolbar's shared background, render it as its own glass capsule, and retain a fixed spacer before the Color Tray, Inspector, Display, and Help group. This establishes two visual groups rather than relying on spacing inside one shared capsule.

Use an 82-point `AppSectionIcon` in the shared workspace header. Learn, Convert, Build, and Check therefore match the prominent identity already used when a person opens an Explore experiment or Reference destination. Navigation rows and local task controls retain compact identities so scale continues to communicate hierarchy.

After a model returns a valid four-role proposal and accessible rationale, show a deterministic sample interface made from those roles. The example contains a heading, reading text, a labeled accent cue, and an action. It uses model-proposed colors but app-authored sample copy, so the relationship is easy to compare across proposals. The independent On Color Theory checks remain immediately after the preview and remain the only source of displayed contrast calculations.

**Basis:** The product owner's live screenshot showed that a toolbar spacer alone did not break the native shared capsule. SwiftUI on macOS 26 exposes explicit shared-background visibility and glass button treatment for this grouping problem. The requested larger workspace icons require one hierarchy rule across all primary destinations. A text-on-palette example helps people assess how role colors work together and exposes hierarchy or readability concerns that isolated swatches cannot show, while the separate deterministic checks preserve the authority boundary.

**Alternatives considered:** Adding more toolbar spacing without changing shared-background participation was rejected because the earlier build still rendered one joined capsule. A custom taken toolbar would weaken native behavior and add avoidable maintenance. Enlarging only the Learn icon would keep the hierarchy inconsistent. Model-authored sample text would add variability without improving color evaluation. Showing the preview after the checks would make the proposal harder to understand before its narrower measured relationships appear.

**Accessibility and privacy review:** The standalone toolbar control retains a text label and familiar processor symbol. Large header identities remain beside explicit headings and are hidden from assistive technology when redundant. The palette example includes semantic text hierarchy plus a labeled and shaped accent cue, so meaning does not depend on hue alone. The example sends no additional information to the model and stores no new personal data.

**Validation:** Eighty-seven tests across twenty-one suites pass. The visual composition matrix now includes a completed recommendation with the proposed four-role preview. Direct image inspection covers the larger Learn, Convert, Build, and Check header identities. Debug and release bundles pass strict ad-hoc signature verification.

**Limitation:** Automated view rendering does not include the containing native toolbar. Computer Use permission is unavailable in this environment, so the independent capsule needs one final live check in the packaged macOS app. Representative-user evaluation must still test whether the example helps people judge light, dark, and dual-appearance palettes and whether model explanations remain understandable across supported model sizes.

## D-037: Single-instance routing, framed destinations, and editable preview copy

**Task:** Stop Help and other entry points from creating duplicate app windows, make destination headers visually consistent, keep the walkthrough current, and let people test their own interface copy in a recommended palette.

**Relevant framework domains:** Cognitive Friction; Attention and Perceptual Hierarchy; Information Architecture; Interaction and Affordances; Aesthetics and Visual Ergonomics; Accessibility and Inclusive Design; Adaptation and Platform Conventions; Performance and State Continuity; Trust, Privacy, and Automation; Evaluation and Evidence.

**Decision:** Declare the main app and definition reader as SwiftUI `Window` scenes rather than `WindowGroup` scenes. Keep stable identifiers for every app-owned window and route Help, menu, Model Assist, and Color Tray actions through those identifiers. A repeated action reuses and brings forward the existing window. Help can change the shared workspace selection before showing the single main window, so Start with Learn navigates the active app rather than constructing another shell.

Use one generic `DestinationHeader` for primary workspace pages and focused destinations. The component owns the rounded surface, border, top accent, text hierarchy, and responsive orientation. At ordinary text size the identity remains to the left of the copy. At enlarged text size it stacks above the copy. Focused experiments, lesson readers, Reference topics, Help topics, and Model Assist steps now use this same structure.

Represent preview copy as five named values: heading, body text, cue heading, cue detail, and button label. Place an aligned editor directly above both the manual palette preview and the completed model-recommendation preview. Bound each field, provide a Restore sample action, preserve nondefault copy in the typed workspace session, and include every text role in the preview's accessibility value. The text remains user-authored or app-authored content and is not added to the model request.

Update Start here into a seven-step walkthrough of the current product. Route its Light and Dark and recommendation actions to their exact Build stages. Update the final Model Assist step to explain custom preview copy before the independent checks and application action.

**Basis:** The product owner's screenshot showed one app shell opening from Help as another shell rather than navigating the active app. A multi-instance `WindowGroup` permits that result, while a stable `Window` scene encodes the requested one-window rule. The screenshots also showed a framed Convert header and an unframed focused Explore header, making the inconsistent hierarchy directly observable. Testing a palette with realistic copy requires control over every visible text role, especially button text and labeled accents, because line length and hierarchy can affect practical judgment even when the color values do not change.

**Alternatives considered:** Manually searching AppKit windows before every `openWindow` call was rejected because it would duplicate scene management already provided by a single SwiftUI `Window`. Closing Help before navigation would hide the symptom but would not prevent duplicate main scenes. Adding independent header modifiers to each feature was rejected because the treatments could drift again. A single freeform text area was rejected because it could not map copy reliably to headings, paragraphs, cues, and buttons. Sending preview copy back to the model was rejected because it would expand the request boundary without being needed for visual evaluation.

**Accessibility and privacy review:** Window reuse reduces focus ambiguity, but real VoiceOver focus transfer still requires manual testing. Every framed header retains a text heading beside a redundant icon. Enlarged text stacks instead of compressing. Preview inputs use explicit labels, support multiline entry, and remain visible independently of the colored result. The preview accessibility value names all color and copy roles. Custom copy stays in the local workspace session and is not sent during generation.

**Validation:** Eighty-nine tests across twenty-one suites pass. New coverage verifies unique window identifiers, preview-copy persistence, custom-text Help search, and version formatting. The 166-state visual matrix covers focused headers, the current Help walkthrough, Model Assist setup, and the editable recommendation preview across normal, dark, enlarged-text, and combined accessibility states. Debug and release bundles pass strict ad-hoc signature verification.

**Limitation:** Automated rendering does not exercise native scene focus or prove that every repeated action raises the expected window on a real desktop. Manual repeated-action testing remains required for Help, toolbar, shortcuts, Color Tray, Model Assist, Settings, Inspector, and definitions. Representative-user testing must still confirm that the framed hierarchy and five preview fields improve orientation and palette judgment without adding excessive form complexity.

## Core guidance sources

- Apple Human Interface Guidelines, Typography: https://developer.apple.com/design/human-interface-guidelines/typography
- Apple Human Interface Guidelines, Layout: https://developer.apple.com/design/human-interface-guidelines/layout
- Apple Human Interface Guidelines, Sidebars: https://developer.apple.com/design/human-interface-guidelines/sidebars
- Apple Human Interface Guidelines, Accessibility: https://developer.apple.com/design/human-interface-guidelines/accessibility
- Apple Human Interface Guidelines, Color: https://developer.apple.com/design/human-interface-guidelines/color
- Apple Human Interface Guidelines, Launching: https://developer.apple.com/design/human-interface-guidelines/launching
- Apple Developer Documentation, Restoring your app’s state with SwiftUI: https://developer.apple.com/documentation/swiftui/restoring-your-app-s-state-with-swiftui
- Apple Developer Documentation, Adding a settings interface to your app: https://developer.apple.com/documentation/foundation/adding-a-settings-interface-to-your-app
- Apple Developer Documentation, ColorScheme: https://developer.apple.com/documentation/swiftui/colorscheme
- Apple Developer Documentation, Accessible appearance: https://developer.apple.com/documentation/swiftui/accessible-appearance
- Apple Developer Documentation, accessibility announcements: https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct/notification/announcementrequested
- Apple Human Interface Guidelines, Offering Help: https://developer.apple.com/design/human-interface-guidelines/offering-help
- Apple Human Interface Guidelines, Search Fields: https://developer.apple.com/design/human-interface-guidelines/search-fields
- Apple Human Interface Guidelines, Charts: https://developer.apple.com/design/human-interface-guidelines/charts
- Cromley, Kunze, and Dane, “A meta-analysis of Richard Mayer's multimedia learning research: Searching for boundary conditions of design principles across multiple media types” (2025): https://www.sciencedirect.com/science/article/abs/pii/S1747938X25000673
- Rey et al., “A Meta-Analysis of the Segmenting Effect” (2019): https://eric.ed.gov/?id=EJ1217373
- “The Effects of Layout Order on Interface Complexity: An Eye-Tracking Study for Dashboard Design” (2024): https://pmc.ncbi.nlm.nih.gov/articles/PMC11435723/
- “Designing, Developing, and Evaluating an Interactive E-Book Based on the Predict-Observe-Explain Method” (2022): https://pmc.ncbi.nlm.nih.gov/articles/PMC9645743/
- W3C WCAG 2.2, Use of Color: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- W3C WCAG 2.2, Contrast Minimum: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- W3C WCAG 2.2, Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- W3C CSS Custom Properties Level 1: https://www.w3.org/TR/css-variables-1/
- W3C Compositing and Blending Level 1, Source Over: https://www.w3.org/TR/compositing-1/#porterduffcompositingoperators_srcover
- W3C CSS Color Module Level 4: https://www.w3.org/TR/css-color-4/
- W3C, Cognitive Accessibility Guidance: https://www.w3.org/WAI/WCAG2/supplemental/#cognitiveaccessibilityguidance
- ISO/CIE 11664-6:2022, Colorimetry  -  Part 6: CIEDE2000 colour-difference formula: https://www.cie.co.at/publications/colorimetry-part-6-ciede2000-colour-difference-formula-1
- Sharma, Wu, and Dalal, “The CIEDE2000 Color-Difference Formula: Implementation Notes, Supplementary Test Data, and Mathematical Observations” (2005): https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/ciede2000noteCRNA.pdf
- Kingdom, “Lightness, brightness and transparency: a quarter century of new ideas, captivating demonstrations and unrelenting controversy” (2011): https://pubmed.ncbi.nlm.nih.gov/20858514/
- CIE 248:2022, The CIE 2016 Colour Appearance Model for Colour Management Systems: CIECAM16: https://www.cie.co.at/publications/cie-2016-colour-appearance-model-colour-management-systems-ciecam16
- Chenoot repository and Ollama setup pattern: https://github.com/drabhikroy/chenoot
- Ollama API, List models: https://docs.ollama.com/api/tags
- Ollama API, Pull a model: https://docs.ollama.com/api/pull
- Ollama API, Generate a completion: https://docs.ollama.com/api/generate
- Ollama structured outputs: https://docs.ollama.com/capabilities/structured-outputs

## D-030  -  Semantic roles separate by lightness, not by hue alone

**Task:** Keep five semantic roles distinguishable for readers with protanopia, deuteranopia, or tritanopia.

**Decision:** Spread the five roles across lightness as well as hue in every color-vision mode, and check the result mechanically before the build proceeds.

**Basis:** Dichromacy reduces the usable color signal to approximately two dimensions, one of which is lightness. Vienot, Brettel, and Mollon 1999 and Brettel, Vienot, and Mollon 1997 give the simulations; all three projections are idempotent and leave the neutral axis untouched, which is what the tests check them against. WCAG 2.2 Success Criteria 1.4.3 and 1.4.11 give the contrast floors. `Scripts/standards/palette_audit.py` applies both and reads its values out of `AppAppearance.swift` so the check cannot drift from the app.

Separation is measured as Euclidean distance in Oklab. CIEDE2000 is specified for small differences under reference conditions and is the wrong instrument for a categorical question, and Euclidean CIELAB is not uniform across differences this large. Each role is additionally held inside a hue window and a chroma floor, because a search told only to make the distances as large as possible runs every role toward white or black, which satisfies the inequality and destroys the role at the same time.

**What this replaced:** Every mode previously separated its roles by hue alone. Under its own named simulation the Deutan palette placed accent and secondary cue 1.7 delta E apart, Protan placed accent and secondary cue 4.2 apart, and Tritan placed accent and warning 6.5 apart. Thirty three pairs failed in total. The named modes therefore did not deliver what their names claimed.

**Limitation:** A simulation is a model of one form of a condition, not a reading of an individual's experience. Passing the audit does not establish that a particular reader can tell two cues apart. Testing with readers who have these conditions remains open, and every role still carries a label, a symbol, or a position as well.

**Open question:** Five roles is close to the limit of what a dichromat palette holds gracefully. Where warm roles collide, as warning and critical do under tritanopia, the only remaining axis is lightness, which is why the Tritan critical value reads muted rather than alarming. Whether warning and critical ever need to be separable from each other by color, as opposed to by symbol and position, has not been established from the interface itself.

## D-031  -  One source of truth for the accent

**Task:** Make the color-vision setting reach the whole interface rather than a fraction of it.

**Decision:** No view refers to the accent selected in macOS directly. Every accent reads through `appSemanticPalette`.

**Basis:** A setting that changes little of what it claims to change is worse than no setting, because it invites the reader to conclude the modes do not help them.

**What this replaced:** Forty call sites used `Color.accentColor`, including `SelectableCardChrome` and `IndexedSelectionBadge`, which every screen reuses for selection state.

## D-032  -  Section icons show their motif only where it can be seen

**Task:** Let seven sections be told apart in the sidebar.

**Decision:** Below 40 points the motif artwork is not drawn and the symbol doubles in size against the palette accent. At card size the motif returns.

**Basis:** Apple guidance on drawing symbols at the size they will be read. A shape smaller than a few points carries no information and costs contrast.

**What this replaced:** At the sidebar size of 30 points the motif occupied a few pixels and an opaque disc covered 46 percent of the icon, so seven sections resolved into seven near-identical squares.

**Limitation:** The 40 point cutoff is a judgment, not a measured threshold, and should be checked against enlarged text sizes.

## D-033  -  One layout scale

**Task:** Make the app read the same from page to page.

**Decision:** Spacing, padding, and corner radius come from a fixed scale defined in `AppMetrics.swift`. `Scripts/standards/metrics_gate.py` reads that file and rejects any off-scale literal.

**Basis:** Consistent rhythm is what lets a reader carry an expectation from one screen to the next. The steps grow roughly geometrically rather than in equal increments, because a scale with a step every four points offers so many near-identical choices that it stops constraining anything.

**What this replaced:** Twenty five distinct spacing values, twenty two padding values, and eighteen corner radii, all written as bare numbers at the point of use. No single number was wrong and no two screens agreed. Five hundred and twenty three literals were moved onto the scale.

**Limitation:** The snap was mechanical, by nearest step. Most moves were one or two points, but any layout that depended on a specific gap will have shifted and needs looking at.

## D-034  -  Headings are exposed to assistive technology with levels

**Task:** Let a screen reader user move through a screen by structure rather than reading it in full.

**Decision:** The page header is level one and every panel heading is level two, through the two shared heading components. The decorative eyebrow above a panel heading is hidden.

**Basis:** VoiceOver rotor navigation depends on heading level, not only on the header trait. A trait alone says an element is a heading; it does not say where it sits.

**What this replaced:** Both components carried the header trait and no level, so every heading in the app was flat and equal. The page header hid its eyebrow and the panel heading did not, so a screen reader read a shouted, uppercased repetition of the surrounding card name before each panel title.

**Limitation:** This covers headings that go through the two shared components. Group titles written as plain styled text inside a card are not covered and need a pass with the running app, since telling a heading from a control label is not reliably decidable from source.

## D-035  -  One surface treatment carries one meaning

**Task:** Let a reader see at a glance which parts of a screen are grouped, on pages that put more than forty cards in front of them.

**Decision:** `AppCard` separates itself from the page with a fill and a hairline, and with nothing else. The hairline draws at low opacity normally and at full strength under Increased Contrast. Card radius is `radiusLarge`, and `radiusHeader` no longer exists, so no panel can claim the visual weight of a page.

**Basis:** A fill, a border, a colored corner stripe, and a shadow each say "this is a group" on their own. Applying several at once buys no additional clarity and multiplies visual weight by the number of cards on screen. The hairline stays rather than going to fill alone because `windowBackgroundColor` and `controlBackgroundColor` sit close together in dark mode, where a fill by itself is not reliably visible.

**What this replaced:** Every card drew a fill, a full-strength border, a forty two point accent stripe across its top left corner, and a fourteen point shadow. Two workspaces additionally hand-rolled their own gradient and tinted border rather than using the shared card at all.

**Limitation:** The hairline opacity was chosen from the semantic color definitions rather than from the running app. If cards read as too faint on a Pro Display XDR, that number is the one to change, and it is in one place.

## D-036  -  A page header states the screen, not the section

**Task:** Open each workspace with the reader's task rather than with a restatement of the row they clicked.

**Decision:** `WorkspaceHeader` is a title and one supporting line set directly on the page, with no surface, no icon, and no label above the title. `DestinationHeader` keeps a `context` slot for a fact the title cannot carry, such as a position in a sequence, and that line is spoken rather than hidden. `PanelHeading` has no slot for a small uppercased label at all.

**Basis:** The sidebar already names each workspace and shows its icon. A boxed header repeating both spent roughly the top third of every first screen. Of the twenty five uppercased labels above headings, most restated the name of the card underneath them; the few that carried real information, such as which step of five a setup page was, are information and belong in the reading order rather than hidden from it.

**What this replaced:** A bordered card holding an eighty two point icon, an accent capsule, a thirty two point title, an uppercased accent label, and a paragraph.

**Limitation:** Hiding a decorative label from a screen reader and then removing it are different fixes, and the second one is only correct because the labels that remain are informative. Any new label added above a heading has to clear that bar.

## D-037  -  Size carries the type hierarchy

**Task:** Let a reader tell a heading from body text without depending on weight or color.

**Decision:** The eight roles are twelve, fourteen, sixteen, eighteen, twenty one, twenty five, and thirty points, rising by roughly an eighth per step, with `value` sharing the body size and differing by monospacing.

**Basis:** Two neighboring roles should be distinguishable by size alone. Colored or bolded text at the same size as its surroundings is a weaker signal, and it is the first thing to fail under a color vision simulation or a high contrast setting.

**What this replaced:** Headline, body, and value all at seventeen points with callout at sixteen, so four of the eight roles occupied a one point band and everything below a title read as one flat level.

**Limitation:** Body drops from seventeen points to sixteen. The text scale preference still multiplies the whole scale, so the ladder holds at every setting, but the default reading size is now one point smaller than it was.

## D-038  -  Every heading carries a level, assigned by nesting

**Task:** Let a screen reader user move through any screen in the app by structure.

**Decision:** Every element carrying the header trait also carries a level. A window's own title is level one, a card or section heading on a page is level two, and a heading for an item nested inside such a section is level three. Eighteen hand-built heading blocks were replaced by `PanelHeading` calls so that the level is decided by the component rather than at each site.

**Basis:** VoiceOver rotor navigation reads the level, not the trait. A trait alone says an element is a heading; without a level, every heading in the app is an equal sibling and the rotor gives a flat list. The level is decidable from nesting, because an element that already carries the header trait has been declared a heading by whoever wrote it.

**What this replaced:** Fifty three headings with the trait and no level, against six with both. `D-034` covered only the two shared components and left the rest.

**Limitation:** A level assigned from source nesting can still disagree with how a screen reads aloud, so this wants a VoiceOver pass. One heading also had to change type role, since it sat at the same size as the heading it was nested under.

## D-039  -  Wayfinding is a labeling problem, not a counting problem

**Task:** Let someone arriving with a question reach the workspace that answers it, without first learning the app's vocabulary.

**Decision:** Six workspaces stay. They are split into two named sidebar groups, "Work on a color" and "Understand color". Each workspace carries a `question` written in the reader's words, a `summary`, and a `firstStep`. The question is the heading on the workspace page, the lead line on its Home card, and the phrase the reader clicked, all the same string.

**Basis:** The obvious fix is fewer destinations, and the evidence points the other way. Studies of the breadth against depth tradeoff converge on moderately broad, shallow structures outperforming narrow, deep ones, replicated repeatedly from Miller in 1981 through Landauer and Nachbar in 1985 to Larson and Czerwinski in 1998. Hochheiser and Lazar replicated the result with nineteen blind screen reader users and found the same direction, which matters here more than anywhere. Six top level destinations sits inside the favorable range; merging them would push content one level deeper for no gain.

What actually fails is information scent, in the sense Pirolli and Card give it: a reader predicts where a link leads from the words on it. Someone holding "is my text readable" finds no trigger word in "Check", so they cannot predict the destination and have to guess. Supplying the words they are already holding fixes the failure that is really occurring.

Merging Learn into Explore would also collapse two different instructional modes. Learn is expository and Explore runs predict, observe, explain, which is a structure in its own right rather than a second copy of the same lessons.

**What this replaced:** Six ungrouped peers whose descriptions were written in the app's terms, a Home screen that repeated those same six names under "Choose what you want to do", and no workspace naming its first action.

**Limitation:** Question wording is a claim about what readers arrive holding, and it has not been tested with any. The grouping split is defensible but not the only defensible one; Convert could be argued into either group. Both want a usability session rather than another pass over the source.

## D-041  -  American spelling is a gate, not a memory

**Task:** Prevent British spelling from reaching a public release a second time, after it shipped twice in prose before anyone caught it.

**Decision:** `writing_gate.py` carries a list of British spellings built from the productive rules, -our, -re, -ise and -isation, doubled consonants before a suffix, -t past tense forms, and ae or oe reduced to e, rather than the handful of words that happened to be remembered. Two exemptions are explicit rather than silent: `URLError.Code.cancelled` is a real Foundation API name, and two CIE citations reproduce that body's own published title, which genuinely is spelled with a u. The gate now also reads `.html` and `.svg`, which it did not before, so the landing page and the icon's embedded title and description are covered.

**Basis:** The word had already been written twice, once in the README and once carried into a release note copied from it, before it was noticed by inspection rather than by any check. A person rereading their own prose does not reliably catch their own house style violations, which is the entire reason the other rules in this file exist as gates instead of guidelines. Spelling is not different in kind from a banned word or a dash.

**What this replaced:** No check existed. The two prior instances were found and fixed by hand, once each time.

**Limitation:** The list is a curated set built from documented spelling rules, not a dictionary, so an irregular pair outside those rules would still pass silently until it is added. The two exemptions are matched by literal string containment, so a citation added later needs its own line here rather than inheriting a pattern.

## D-040  -  The working color is stated once rather than framed permanently

**Task:** Make the app's central object visible without adding chrome to every screen.

**Decision:** The working color stays in the sidebar footer where it already lived. It gains a hint and an accessibility hint saying that it follows the reader between workspaces, and Home introduces it in a sentence and labels the panel with where to find it again.

**Basis:** A color that travels between workspaces is the app's spine, and nothing on screen said so, which leaves a reader to infer the model from behavior. Naming it costs one sentence. Giving it a persistent bar of its own would cost vertical space on all seven screens to restate something true but static, which is the kind of permanent furniture the previous release spent its effort removing.

**Limitation:** A hint is only read on hover, and the Home sentence is only read on Home. Someone who enters through a lesson may still not learn that the color travels.
