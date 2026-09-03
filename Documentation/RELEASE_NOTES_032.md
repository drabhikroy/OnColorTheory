# On Color Theory 0.32.0 (build 32)

## Landing screen

Home opens with the app's own name, its icon at eighty four points, the version, and a paragraph saying what the app is for, followed by the line explaining that one color travels with you between workspaces. Buttons for the walkthrough and for Help sit underneath.

This is the screen 0.31.0 should have added. That release put a landing page in `docs/index.html` for GitHub Pages, which is a web page for people who have not installed anything. The request was for the screen the app opens on, the way the other apps in this family do it. The web page stays where it is, since it is useful for a release page, but it was never the thing being asked for.

Home previously opened on the phrase "See color more clearly", which is a slogan rather than an introduction. Someone who has just installed something wants the name of what they opened and a sentence saying what it does. The version sits with the title because it is the first thing anyone is asked for when they report a problem.

## Everything from 0.31.0

The wayfinding work is unchanged and is described in the 0.31.0 notes: two named sidebar groups, a question and a first step on every workspace, Home cards led by the question, and the working color explained rather than merely present.

## Not verified

Nothing here is compiler verified. Run `swift build` and `swift test` first.
