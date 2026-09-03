# On Color Theory 0.31.0 (build 31)

Follows 0.30.0, which renamed the app and rebuilt how it looks. This release changes how it works. No color mathematics, no analysis, and no stored data changed.

## Why this release exists

0.30.0 made the app quieter without making it easier to follow. A reader could still not tell what was going on, where to go, what to do, or why. Those are wayfinding failures, and none of them are fixed by spacing or type.

## Wayfinding

0.30.0 changed how the app looks and left how it works alone, which is why it still read as hard to follow.

The six workspaces are now split into two named sidebar groups, "Work on a color" and "Understand color", so the first decision is between two obviously different intents rather than among six abstract peers. No workspace was merged. The breadth against depth literature is consistent that broad, shallow structures beat narrow, deep ones, and that result replicates for blind screen reader users, so fewer destinations would have pushed content deeper for no gain.

Each workspace now carries a question written in the reader's words, a summary, and a named first step. The question is the same string in three places: the Home card that offers it, the heading of the page it opens, and the label a screen reader announces. Home leads its cards with the question rather than the workspace name, and the whole card is one control rather than a container holding a small button.

The working color, which travels between workspaces and is the app's central idea, was never stated anywhere. It keeps its place in the sidebar footer and gains a hint, an accessibility hint, and one introducing sentence on Home.

## Landing page

`docs/index.html` is a self-contained page for GitHub Pages. The hero is a live color whose sRGB, CIELAB, OkLCh, luminance, and WCAG verdict update as you change it, computed with the same constants the app uses so the two agree rather than merely resemble each other. It is set in Atkinson Hyperlegible, the typeface the app bundles, and its hero band is a neutral gray because judging a color against a colored surround shifts what you see.

## What was deliberately not done

The obvious fix is fewer destinations, and the evidence points the other way, so no workspace was merged.

Studies of the breadth against depth tradeoff converge on moderately broad, shallow structures outperforming narrow, deep ones, replicated from Miller in 1981 through Landauer and Nachbar in 1985 to Larson and Czerwinski in 1998. Hochheiser and Lazar replicated the result with nineteen blind screen reader users and found the same direction. Six top level destinations sits inside the favorable range, and merging would push content one level deeper for no gain, at the cost of the readers this app cares most about.

What actually fails is information scent in the sense Pirolli and Card give it: a reader predicts where a link leads from the words on it. Someone holding "is my text readable" finds no trigger word in "Check". Supplying the words they are already holding addresses the failure that is really occurring.

Merging Learn into Explore would also collapse two different instructional modes. Learn is expository; Explore runs predict, observe, explain, which is a structure in its own right rather than a second copy of the same lessons.

## Not verified

Nothing here is compiler verified. Run `swift build` and `swift test` first.

Question wording is a claim about what readers arrive holding, and it has not been tested with any reader. The two group split is defensible but not the only defensible one, since Convert could be argued into either group. Both want a usability session rather than another pass over the source.

The hint on the working color is only read on hover, and its introducing sentence is only on Home, so someone entering through a lesson may still not learn that the color travels with them.
