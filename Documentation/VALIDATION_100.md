# 1.0.0 validation

Two parts, kept apart on purpose.

The first part records what was checked and how. Every item in it was carried out against the source or by independent calculation, and each one names its method so the claim can be repeated.

The second part is the work that needs a built, running app. None of it has been done. It is written as a checklist rather than as findings, because recording an unrun check as a result is the one thing a validation record must never do. The Build 028 record covers the same ground for that build and shows the shape a completed run takes.

## Verified by calculation

- CIEDE2000 was reimplemented independently from the Swift source and run against all 34 pairs of the Sharma, Wu and Dalal supplemental verification dataset. Zero mismatches. Worst absolute error 5 by 10 to the negative 5. The mean hue branch, which is the part implementations most often get wrong, resolves correctly in both directions.
- sRGB to XYZ D65, Bradford adaptation to D50, and CIELAB were reimplemented from the same matrices in the source. sRGB white maps to L star 100 with a and b both 0, and to the D50 white point to five decimal places.
- The sRGB primaries expressed in CIELAB differ from the CSS Color 4 published values by a CIEDE2000 of 0.0046, which is Bradford matrix rounding rather than an error.
- Display P3 agrees with the CSS Color 4 reference values to 5 by 10 to the negative 5.
- WCAG relative luminance and contrast reproduce the published worked examples at 4.54 to 1 and 3.03 to 1, and white on black returns exactly 21 to 1.
- All five WCAG threshold values in the source are correct at 4.5, 3, 3, 7, and 4.5, and large text is defined in the interface as 18 point regular or 14 point bold.

## Verified in the source

- The four standards gates pass: writing, palette audit, layout scale, and documentation coverage at 276 of 276 types.
- No subprocess execution, dynamic code loading, web view, script engine, or unsafe pointer use. No forced `try`, forced cast, `fatalError`, or `preconditionFailure`. No logging.
- Address validation refuses embedded credentials, query strings, and fragments, and accepts only two schemes. Plaintext is refused to any host that is not parsed as loopback, private, or link local. Thirty four host cases covering both directions are tests.
- Model output is bounded before decoding, checked for exact shape, parsed through the real parser, and length capped on every free text field. Model supplied text renders through the `String` overload of `Text`, which does not interpret Markdown.
- Stored data is JSON rather than an archived object graph, size checked before reading, written atomically, and preserved rather than overwritten when unreadable.
- No credentials, tokens, or accounts anywhere in the source.
- Zero invisible or zero width characters across every text file. Every non-ASCII character present is one the interface uses.
- Every image regenerated from the vector script. All PNG files carry only header, data, and end chunks, with no text, EXIF, or provenance metadata.
- Every heading carries a level as well as the header trait, at 9, 30, and 4 across the three levels.
- American spelling throughout, now enforced by the writing gate rather than by inspection.
- Property list parses and its identity keys are correct. Landing page markup is well formed. Every relative link in the README resolves to a file that exists.

## Still to complete on a built app

Run `swift build`, then `swift test`, then `Scripts/standards/run-all.sh`, then `Scripts/build-app.sh`.

- [ ] The package compiles with no errors and no warnings.
- [ ] The full test suite passes, including the host validation and wayfinding tests added for this release.
- [ ] First launch opens the walkthrough. Quitting and relaunching does not reopen it. Home, Help, and About each reopen it on request without creating a second window.
- [ ] The Home screen shows the app name, the icon, and the version, and the six task cards read correctly at default text size.
- [ ] The sidebar shows two named groups, and every workspace heading matches the question on its card.
- [ ] Cards are visible against the page in both Light and Dark appearance. This is the item most likely to need a change, since the card hairline opacity was chosen from the color definitions rather than from a screen.
- [ ] Body text at the new size is comfortable at the default text scale, and the type hierarchy holds at 160 percent.
- [ ] VoiceOver rotor navigation moves through each screen by heading, and the levels match the visual structure.
- [ ] The five color vision palettes render as the audit predicts, including the three tritan values that separate by lightness rather than by hue.
- [ ] The About window opens from the menu, and its three links open the correct pages.
- [ ] The signed app launches from a Control click and Open on a machine that has never run it.
