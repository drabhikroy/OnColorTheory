# Product Context and Critical Tasks

**Application:** On Color Theory  
**Status:** Product hypotheses to validate with intended users  
**Recorded:** August 28, 2026

## Product purpose

On Color Theory is a native macOS application for learning, analyzing, constructing, and interpreting color. It should preserve technical depth while helping a broad audience understand what a result means, what assumptions produced it, what can be changed, and what the application cannot determine.

It is not a substitute for a calibrated instrument, a complete browser or print pipeline, an individual observer model, professional accessibility testing, or human judgment about a complete design.

## Intended audiences

These groups are working hypotheses, not validated personas.

### Curious newcomer

- May recognize HEX or RGB but not know what a color space, transfer function, reference white, gamut, or color-difference formula means.
- Needs a clear starting task, visible examples, ordinary-language explanations, and control over pacing.
- Should not have to open equations or sources to understand the essential result.

### Student or educator

- Wants connected explanations, demonstrations, exact calculations, and direct sources.
- May move repeatedly between Learn, Explore, Convert, Check, and Reference.
- Needs examples that expose assumptions without presenting one screen as a complete curriculum.

### Designer or developer

- Often begins with an existing color or pair and wants a conversion, comparison, palette role, or accessibility-related check.
- Needs copyable values, persistent colors, exact handoffs, keyboard routes, and concise limits.
- May understand interface design while having uneven color-science knowledge.

### Experienced color practitioner

- Wants to inspect coordinates, equations, reference conditions, precision, standards, and implementation boundaries efficiently.
- Should be able to select any stage directly and skip explanatory sequences without losing access to their evidence.
- Must not receive simplified wording that changes the scientific claim.

### People using different access methods

- May use VoiceOver, keyboard-only navigation, magnification, enlarged text, increased contrast, reduced motion, reduced transparency, alternative color-discrimination strategies, or combinations of these.
- May also work under fatigue, interruption, bright light, low display brightness, or unfamiliar terminology.
- Access needs are not a separate audience; they can occur in every group above.

## Expected prior knowledge

The default path may assume that a person understands ordinary color words and can identify a color sample. It must not assume prior knowledge of:

- encoded versus linear-light RGB;
- reference whites such as D65 or D50;
- CIE XYZ, CIELAB, LCh, Oklab, or OkLCh;
- chromatic adaptation;
- relative luminance or WCAG contrast thresholds;
- CIEDE2000;
- alpha compositing;
- color-space gamut or gamut mapping;
- display calibration, ICC profiles, or rendering intent.

When these concepts are necessary, the interface introduces their practical meaning before depending on their formal names or notation where feasible.

## Common misconceptions to test

- A HEX value is the color itself rather than an encoded value interpreted in a stated color space.
- Equal RGB numbers have the same meaning in every RGB color space.
- HSL lightness is a coordinate over encoded sRGB and is not perceptual lightness.
- A contrast ratio and a color-difference value answer the same question.
- One color-difference number creates a universal noticeability or acceptability threshold.
- A swatch shown on one display proves how the color appears everywhere.
- An out-of-gamut result identifies one objectively correct replacement color.
- Grayscale or a transformed pair establishes complete accessibility conformance.
- A model-generated palette rationale is a scientific measurement.

## Critical task map

| Area | Intended outcome | Information needed before starting | Consequence of mistakes | State that should persist |
|---|---|---|---|---|
| Home | Choose the workspace that matches the current question | Plain descriptions of each destination and the current color | Extra navigation and uncertainty | Current color and last active workspace |
| Learn | Build a correct bounded understanding of one relationship | Lesson scope, number of parts, and example | Scientific misconception or false generalization | Current lesson, part, and valid lesson control values |
| Explore | Predict, change one variable, observe, and explain the result | Fixed assumptions and what can be changed | Confusing display behavior with the isolated calculation | Current experiment, valid inputs, prediction, and observation state |
| Convert | Convert one color representation and inspect its path | Input syntax, source space, destination representation | Copying an invalid or misunderstood value | Last valid color, notation, representation, and selected stage |
| Build | Assign colors to interface roles and inspect named relationships | Meaning of each role and limits of the preview/checks | Treating a partial check as whole-interface conformance | Named palette roles, selected studio phase, and export language; saved colors remain separate in the tray |
| Check | Analyze one explicitly named relationship | Required colors, reference space, assumptions, and scope | Misstating conformance, perceptibility, gamut, or meaning | Current colors, selected analysis, and information level |
| Reference | Find and distinguish an unfamiliar concept | Search term or topic | Applying the wrong concept or assumption | Search query, topic, and term reader position |
| Color Tray | Preserve, retrieve, lock, or remove colors with provenance | What is saved and whether saving succeeded | Losing work or restoring the wrong interpretation | Records, provenance, lock state, and storage errors |
| Inspector | Read the current color's compact coordinates and context | Current color | Detaching a value from its reference conditions | Current color and useful disclosure state during the session |

## Use contexts to validate

- First use without color-science training
- Repeated professional use with keyboard shortcuts
- Mouse and trackpad input
- Keyboard-only navigation
- VoiceOver navigation and value review
- Enlarged app text and display scaling
- Light, dark, and increased-contrast appearances
- Differentiate Without Color, Reduced Motion, and Reduced Transparency
- Grayscale and common CVD diagnostic simulations
- Bright room, dim room, low display brightness, and external monitors
- Interrupted work and app relaunch
- Offline use
- Failed local persistence
- Future local-model work that takes noticeable time or fails

## Critical validation questions

Behavior and comprehension must be measured separately.

- Can a newcomer identify the correct workspace for a stated question?
- Can the person explain what the reported result measures in their own words?
- Can they distinguish a calculated value, an illustrative preview, a standard threshold, a model proposal, and a human decision?
- Can they state at least one important limitation without being prompted to open a separate help page?
- Can they predict what the next step or changed control will do?
- Can they recover from invalid input and a failed save without losing valid work?
- Can keyboard and VoiceOver users complete the same critical tasks and confirm the resulting state?
- Does explanatory material help newcomers without obstructing experienced users?
- Does confidence track interpretation accuracy rather than the visual polish of the result?

Observed testing should revise these hypotheses. Applicable accessibility, safety, privacy, and platform requirements remain in force when a preference conflicts with them.
