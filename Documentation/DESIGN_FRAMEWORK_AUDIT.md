# General-Audience Design Framework Baseline

**Application:** On Color Theory  
**Application baseline:** Build 029, version 0.29.0  
**Framework reviewed:** *General-Audience Technical Application Design Framework*, version 1.1, August 28, 2026  
**Audit date:** August 31, 2026

## Status and purpose

The framework is adopted as the project's design-governance baseline. It is especially well suited to this application because it treats comprehension, scientific status, interaction, visual presentation, accessibility, and validation as separate but connected responsibilities.

This adoption is not a claim of external certification or completed accessibility conformance. Framework items marked as synthesis, policy, or test remain project rules or hypotheses. Consequential decisions must cite the underlying standard, platform guidance, or research rather than presenting the framework itself as empirical proof.

Build 028 is a development preview. It has automated mathematical, structural, rendering, adaptive-appearance, screen-sample normalization and direct analysis, searchable-help, model-schema validation and request-boundary coverage, code-export, recoverable persistence, workspace-session migration, deterministic recovery, bounded reset, and first-run walkthrough coverage, but it has not completed the framework's manual accessibility, privacy, model-quality, or product-specific comprehension gates.

## Status language

- **Verified:** supported by an automated test or direct artifact inspection within its stated scope.
- **Implemented, not validated:** present in the interface or architecture but not yet tested with the intended audience or access method.
- **Partial:** some criteria are present while consequential checks remain open.
- **Open:** not yet implemented or formally assessed.
- **Not currently applicable:** the current product has no workflow that invokes the criterion; reassess when that changes.

Passing a rendering test proves that a view can be produced at the tested size and appearance. It does not prove that the view is understandable, operable with assistive technology, or comfortable to use.

## Current alignment

The application already aligns well with several governing principles:

- Technical depth is segmented rather than removed.
- Plain-language meaning, visual examples, formal terms, equations, and sources are kept in distinct layers.
- Previous, progress, and Next positions remain stable within staged explanations.
- Definitions appear beside unfamiliar terms instead of depending on a separate glossary lookup.
- Reading text is selectable, and equations include selectable readings and copyable LaTeX.
- Color-state results use text, symbols, direction, or numeric values rather than hue alone.
- Scientific calculations, versioned evidence, and optional model proposals have separate authority boundaries.
- Native macOS navigation, controls, menus, independently resizable single-instance auxiliary windows, and accessibility APIs are preferred.
- Primary sections, every Learn part, every Check analysis, and important focused views have light, dark, and enlarged-text rendering coverage.
- Every primary section also renders in light and dark high-contrast appearances with Differentiate Without Color, Reduce Motion, and Reduce Transparency enabled together; selected staged controls add a checkmark under this profile.
- Copy, save, removal, submitted-input errors, workspace changes, and persistence failures provide accessibility announcements in addition to visible state.
- Invalid numeric and color input is explained rather than silently normalized.
- The Color Tray preserves useful state between sessions and reports an unsuccessful write without discarding the current in-memory colors.
- A typed, versioned workspace session restores last-valid task context for all six workspaces, while Home offers a user-controlled return route instead of redirecting automatically.
- Convert, Build, and Check no longer expose action, result, method, evidence, and export at the same visual level. Each uses a task-specific depth control, and every selected phase has focused rendering coverage.
- Appearance and interface-cue preferences are stored in the native macOS Settings window; custom cue palettes do not alter analyzed swatches and explicitly avoid claiming color-vision simulation or conformance.
- Display settings are linked from both the global toolbar and Color Inspector, so Follow Mac, Light, Dark, reading, and color-vision-aware cue choices do not depend on knowing the macOS Settings shortcut.
- The Color Inspector can invoke the system screen sampler, normalize the selected pixel to sRGB, update the working color without changing workspaces, and present Hex, RGB, and Alpha in three explicit aligned columns.
- Switching to or from System accent keeps one stable Settings content hierarchy; Reading preview remains in Reading, and Settings, Inspector, Color Tray, and definition windows can grow horizontally or vertically.
- Optional Ollama recommendations disclose local or external execution, validate a four-role schema, and route accepted colors through the same deterministic Palette Studio checks instead of accepting model-authored scientific results.
- The Ollama request preview identifies the destination, purpose, current palette, exact brief, and excluded data before generation; requests and returned rationale are length-bounded and generation can be canceled.
- Every app-owned window has one stable scene identity and restores a stable size and position, with on-screen recovery after display changes. Repeated Help, walkthrough, menu, setup, tray, or toolbar actions reuse the existing destination window; the setup assistant and walkthrough reflow at enlarged text and expose direct keyboard actions.
- Workspace sessions migrate from schema 1 to schema 2. Unreadable, invalid, or future-schema state falls back visibly while retaining a recovery copy instead of repeatedly failing at launch.
- A standalone Model Assist toolbar control opts out of the native shared toolbar background, supplies its own glass capsule, and uses a fixed spacer before the saved-color tools. The adjacent shared group keeps Color Tray, Inspector, Display, and Help together, with Help placed directly after Display.
- Searchable Help explains seven common task areas, exposes direct routes to the relevant workspace or window, and reflows from a topic rail to a compact menu at enlarged text sizes.
- A reusable designed-icon family gives workspace headers, sidebar entries, Home cards, Learn paths, Build stages, Check diagnostics, Reference topics, and Help topics consistent multicolor identities with distinct geometry and central symbols. Workspace pages, focused experiments, lesson readers, Reference topics, Help topics, and Model Assist steps share one rounded destination-header surface. Normal text keeps the icon beside the heading; enlarged text stacks it above the copy.
- Explore's overlapping-circle and layered-rectangle motifs now serve as its compact library icons and as larger selected-experiment headings. The redundant shape and central symbol remain visible alongside the two-color relationships.
- Model Assist asks the selected model for an overall approach and a plain-language explanation for every color. The interface labels those explanations separately from On Color Theory's deterministic calculations and places an editable heading, body, cue heading, cue detail, and button preview before the calculated checks. Custom preview copy persists with the Build workspace.
- A dedicated seven-slide walkthrough replaces the former first-run Help launch. It appears once, offers visible progress and predictable navigation, remains directly available from Help, and reopens after a complete first-run reset.
- Help routes Light & Dark and Recommend actions to the exact Build stage rather than only opening the workspace.
- Version 0.29.0 (29) is visible in Settings and Help as well as in the app bundle.
- New installations begin in Dark appearance while preserving explicit Follow Mac or Light choices. Help provides a bounded reset that clears app-owned state without rerunning the walkthrough, plus separately confirmed local Ollama and model cleanup. Selecting both cleanup choices returns the app to its complete first-run state. Local items move to the Trash, and external servers are never changed.
- CSS, Swift, JavaScript, Python, R, and JSON exports are deterministic, selectable, and directly copyable.
- The app no longer applies one card-grid composition to every destination: Learn is a numbered path, Explore a visual gallery, Convert a workbench with a vertical process map, Build a studio rail, Check a diagnostic rail, and Reference a searchable field guide.
- A restrained semantic set gives structural elements one accent and reserves positive, caution, and critical colors for those roles. Cue presets replace these interface roles, while labels, symbols, borders, and position retain meaning and analyzed scientific colors remain untouched.

## Domain audit

| Domain | Build 028 status | Evidence and remaining work |
|---|---|---|
| 1. User, Task, and Context | Partial | The six section purposes and individual task cards are explicit. Formal audience profiles, core-task records, interruption contexts, and contextual inquiry remain open. |
| 2. Cognitive Friction | Partial | Libraries, local explanations, exact handoffs, and task-specific phases reduce simultaneous choices and reading. Learn now presents four compact selectors beside one focused preview and one primary action instead of four competing summaries and actions. Each critical screen still needs the framework's seven-question audit with intended users. |
| 3. Attention and Hierarchy | Implemented, not validated | Primary results precede optional code, equations, and sources; selected phases are visually inspected in light, dark, and enlarged configurations. Attention order has not been tested with intended users. |
| 4. Mental Models and Predictability | Partial | Navigation, terminology, and staged controls are stable. User testing must confirm that the visible structure predicts actual behavior. |
| 5. Learning and Explanation | Partial | Worked examples, segmentation, signaling, active exploration, and sources are implemented. Explain-back and concept-transfer testing remain open. |
| 6. Information Architecture | Partial | A stable sidebar, direct return paths, Reference search, and distinct section compositions are implemented. Task Help adds search, seven plain-language topics, a direct route to the standalone walkthrough, exact workspace/tool routes, and a bounded reset destination. Learn, Explore, Convert, Build, Check, and Reference expose task-specific maps rather than sharing one library or segmented-control pattern. Findability and backtracking require task testing. |
| 7. Progressive Depth | Partial | Convert separates Meaning, Calculation, and Sources; Build separates Design, Recommend, Check, and Export; Check separates results from method. Novice and experienced-user testing remains open. |
| 8. Interaction and Affordances | Partial | Native labeled controls, explicit accessibility values, persistent selected states, enlarged principal controls, visible-plus-announced copy/save/error feedback, and a system screen-sampling action are present. A complete state, focus, disabled-state, permission, and custom-control audit remains open. |
| 9. Motor Ergonomics | Partial | Command-1 through Command-7 open every primary section; commands also cover saved-work resumption, Ollama setup, Help, color actions, and setup navigation. Help actions route directly to the named destination. The app uses large native control sizing, and small definition/tray actions have minimum hit frames. Critical-path keyboard completion, measured target dimensions, pointer travel, and non-drag alternatives still require formal verification. |
| 10. Temporal UX | Partial | Deterministic work is immediate, sampled pixels avoid representation reparsing, the tray persists, and workspace context resumes. Ollama connection, generation, and download work has visible busy state, determinate progress when byte counts are available, cancellation, stale-operation protection, timeouts, and usable common-network errors. Real slow-server and interruption testing remains open. |
| 11. Error and Recovery | Partial | Focused parsers reject invalid input with specific guidance, submitted errors are announced, experiments can reset, valid task state is restorable, and failed Color Tray writes preserve in-memory colors. Workspace-session migration, corrupt/future-state recovery copies, fresh fallback, visible dismissal, app reset, and recoverable local cleanup through the Trash are covered. Undo scope and preservation of partially valid drafts still need a workflow audit. |
| 12. Aesthetics and Visual Ergonomics | Implemented, not validated | Neutral shared surfaces, restrained scientific visuals, and task-specific compositions are implemented and visually reviewed. A standardized multicolor icon family identifies workspaces and major destinations without tinting entire cards or using color as the only cue. Workspace and focused-destination headers now share one rounded surface, prominent identity scale, border, and orientation behavior. Perceived visual quality and sustained-use comfort have not been measured with users. |
| 13. Typography | Partial, with automated coverage | Atkinson Hyperlegible Next, a system-font alternative, 100 to 160% scaling, readable LaTeX, and glyph registration tests are present. Production-size reading comfort still requires testing. |
| 14. Content and Terminology | Partial | Plain-language descriptions, stable terminology, contextual definitions, limitations, and direct sources are present. Novice comprehension, localization, text expansion, and cultural review remain open. |
| 15. Chromatics | Partial | One structural accent, semantic positive/caution/critical colors, redundant cues, six optional cue palettes, and one standardized multicolor identity palette are implemented. Identity icons also retain distinct geometry and central symbols, so color is never their only differentiator. The protan-, deutan-, and tritan-aware choices are explicitly not simulations or validated accommodations. Grayscale, diagnostic simulation, ambient-light, and real-user review remain open. |
| 16. Visualization and Epistemic Communication | Partial | Calculated values, illustrative previews, assumptions, limitations, and model proposals are distinguished. A proposed palette appears in an editable text interface before the independent checks, without presenting that preview as a scientific verdict. Likely nonexpert interpretations and meaningful precision require a cross-screen audit and user testing. |
| 17. Accessibility and Inclusive Design | Partial | Headings, labels, values, selectable text, larger controls, visible-plus-announced status, light/dark rendering, enlarged-text adaptation, and a combined system-preference snapshot matrix are present. Manual VoiceOver, keyboard, focus, CVD, measured-target, and real preference-combination gates remain open. |
| 18. Motion | Partial | The current interface uses little nonessential custom motion and receives Reduce Motion through the shared preference profile. System-provided transitions and any future custom motion still require manual verification. |
| 19. Trust, Privacy, and Automation | Partial | The provider boundary prevents a model proposal from becoming an authoritative scientific result. Settings distinguish on-Mac and external execution; a preflight disclosure shows the exact brief, palette, destination, and excluded data. Requests isolate untrusted brief content, constrain output shape and prose length, and label cleartext external transport. Reset cleanup only targets standard local Ollama locations, moves them to the Trash, and never changes an external server. Authentication, retention, consent, model provenance, output quality, and independent privacy review remain open. |
| 20. Adaptation and Platform Conventions | Partial | Native macOS structure, single-instance resizable windows, app-owned window size/position restoration, follow-system/light/dark appearance, system or custom cue palettes, persistent text scale, a system-font choice, enlarged-text setup reflow, and four system accessibility bridges are present. Manual focus restoration, display scaling, changed-display restoration, and preference-combination testing remain open. |
| 21. Performance and State Continuity | Partial | A typed workspace session restores last-valid context, custom preview copy, and other task state, migrates older state, and retains a recovery copy for corrupt or newer state; a separate tray retains provenance; sampled pixels bypass text parsing; and isolated stores keep tests deterministic. Manual relaunch/interruption testing, real-server performance, and measured performance budgets remain open. |
| 22. Evaluation and Evidence | Partial | One hundred automated tests across twenty-two suites cover deterministic results, catalog integrity, LaTeX, handoffs, exports, preferences, screen sampling, searchable Help, walkthrough structure, native editing commands, unique app-window identities, persisted custom preview copy, Ollama version discovery, schema and request boundaries, network guidance, accessible explanation prompting, app version formatting, icon identity coverage, persistence failure and migration, accessibility profiles, all cue palettes, focused phases, setup steps, request disclosure, reset boundaries, recovery, and 182 rendered interface states. Behavior, comprehension, experience, privacy, model quality, and access testing with representative users remain open. |

## Mandatory gates before an external release candidate

### Product definition

- Record intended novice and experienced audiences, core tasks, prior knowledge, common misconceptions, interruption points, and meaningful accessibility contexts.
- Map the primary workflow and state that must persist for every major section.

### Screen review

- Apply the framework's purpose, cognition, interaction, content, visual, accessibility, and scientific-communication checklist to every critical screen.
- Record exceptions and the evidence or task reason supporting them.
- Confirm that a card, disclosure, or staged sequence is used because it improves the current task - not because another section used the same pattern.

### Accessibility

- Complete each critical path with keyboard only.
- Complete each critical path with VoiceOver and verify labels, values, order, focus entry, focus restoration, and status announcements.
- Review light, dark, increased contrast, reduced transparency, reduced motion, enlarged text, display scaling, and visible focus.
- Review all meaningful states in grayscale and protan, deutan, and tritan simulations, then include people with relevant disabilities in product testing where color discrimination is central.
- Audit control target sizes and confirm no core action requires dragging or precise pointer movement without an alternative.

### Comprehension and usability

- Test novices and experienced users separately.
- Measure task completion and interpretation as different outcomes.
- Include explain-back questions for contrast, color difference, gamut, alpha compositing, color coordinates, and model-generated suggestions.
- Check confidence calibration: a person should know what the app calculates, illustrates, proposes, and cannot determine.

### Reliability and trust

- Verify persistence and resumption after navigation, appearance changes, resizing, relaunch, interruption, and recoverable failure.
- Define truthful progress, cancellation, local/remote disclosure, storage, and deletion before enabling an optional model provider.
- Establish performance budgets for interaction and any long-running work.

## Rule for future milestones

Every consequential feature or redesign must record:

1. the user and comprehension problem;
2. the relevant framework domains;
3. applicable standards, platform guidance, research, and known uncertainty;
4. credible alternatives considered;
5. the selected structure and why it fits this task;
6. keyboard, screen-reader, scaling, CVD, appearance, contrast, and motion behavior;
7. deterministic, visual, accessibility, and user-validation plans;
8. limitations that must remain visible.

Each milestone continues the standing product rule: improve affected interfaces deliberately, but do not apply one layout pattern blindly across unrelated sections.

## Next status

Build 028 introduces a dedicated, reusable seven-slide first-run walkthrough and removes the automatic Help launch. It also raises the app icon's midtones and color visibility to sit between the brighter Build 026 and darker Build 027 treatments. The remaining manual, privacy, model-quality, and representative-user gates above stay explicit requirements for an external release candidate. Build 028 should not be described as passing the complete framework release gate.
