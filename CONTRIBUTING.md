# Contributing to On Color Theory

## Before you start

The project is a Swift package (`swift-tools-version: 6.2`) targeting
macOS 14 and later, with one pinned dependency, SwiftMath.

## Running the app

Run `Scripts/build-app.sh debug` to build and stage a debug `.app`
bundle under `Build/`. Pass `release` for a release build.

## Running the tests

Run `swift test` to run the two test targets, covering the color
conversion core and the Ollama network client. Before opening a pull
request, also run `Scripts/standards/run-all.sh`, which checks writing
standards, the interface palette, the layout scale, and documentation
coverage, and fails the same way a CI job would.

## Adding a lesson

Learn's four lessons are cases of `LearningLessonID` in
`LearnLibraryView.swift`; a new lesson adds a case there, with a title,
summary, symbol, and icon motif, plus its own view file alongside
`SurroundingsLessonView.swift` and `GamutLessonView.swift`.

## Adding a glossary term

Reference's glossary is the `ReferenceCatalog` enum in
`ReferenceView.swift`; a new term is a `ReferenceConcept` entry there,
with its equation and sources.

## Style

`Scripts/standards/writing_gate.py` runs over source, documentation,
and scripts, and rejects em dashes, en dashes, contractions, banned
lexicon, historical or version-referencing comments, and non-American
spelling outside a real API name or a cited title.
`Scripts/standards/doc_coverage.py` requires a `///` doc comment on
every top-level type.

## Accessibility

`Scripts/standards/palette_audit.py` checks every semantic color
against WCAG 2.2 contrast and against the three dichromat simulations,
so a new color needs to clear both before it is used. New interface
additions should carry VoiceOver labels consistent with existing views.
