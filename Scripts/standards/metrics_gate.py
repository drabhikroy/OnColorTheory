"""
Layout scale check.

Spacing, padding, and corner radius literals have to sit on the scale defined in
`Sources/OnColorTheoryApp/DesignSystem/AppMetrics.swift`. The scale is read out of
that file rather than repeated here, so the two cannot disagree.

The check exists because the app previously held twenty five distinct spacing
values, twenty two padding values, and eighteen corner radii. No single number
was wrong, but no two screens agreed, which is what made the interface read as
unsettled from page to page.

Exit status is non-zero on any off-scale value.
"""

import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
SOURCES = os.path.join(ROOT, "Sources")
METRICS = os.path.join(
    SOURCES, "OnColorTheoryApp", "DesignSystem", "AppMetrics.swift"
)

CONSTANT = re.compile(r"static let (\w+): CGFloat = (\d+(?:\.\d+)?)")

SPACING_NAMES = {
    "hairline", "tight", "snug", "compact", "regular", "roomy", "section", "page",
}
RADIUS_NAMES = {"radiusSmall", "radiusMedium", "radiusLarge", "radiusHeader"}

CHECKS = [
    ("spacing", re.compile(r"spacing:\s*(\d+(?:\.\d+)?)\s*[,)\]]"), "spacing"),
    ("padding", re.compile(r"\.padding\((\d+(?:\.\d+)?)\)"), "spacing"),
    ("padding", re.compile(r"(?<!\.)padding:\s*(\d+(?:\.\d+)?)\s*[,)\]]"), "spacing"),
    ("padding", re.compile(r"\.padding\(\.\w+,\s*(\d+(?:\.\d+)?)\)"), "spacing"),
    ("cornerRadius", re.compile(r"cornerRadius:\s*(\d+(?:\.\d+)?)\s*[,)]"), "radius"),
]


def read_scale():
    text = open(METRICS, encoding="utf-8").read()
    spacing, radius = set(), set()
    for name, value in CONSTANT.findall(text):
        if name in SPACING_NAMES:
            spacing.add(float(value))
        elif name in RADIUS_NAMES:
            radius.add(float(value))
    # Zero is always allowed. A deliberately butted layout is a real intent, not
    # a missing value, and there is no sensible token for the absence of a gap.
    spacing.add(0.0)
    if not spacing or not radius:
        raise SystemExit("could not read the scale from AppMetrics.swift")
    return {"spacing": spacing, "radius": radius}


def main():
    scale = read_scale()
    findings = []
    for root, _, names in os.walk(SOURCES):
        for name in names:
            if not name.endswith(".swift") or name == "AppMetrics.swift":
                continue
            path = os.path.join(root, name)
            relative = os.path.relpath(path, ROOT)
            for number, line in enumerate(open(path, encoding="utf-8"), 1):
                for label, pattern, kind in CHECKS:
                    for match in pattern.finditer(line):
                        value = float(match.group(1))
                        if value not in scale[kind]:
                            findings.append(
                                (relative, number, label, value, line.strip())
                            )

    for relative, number, label, value, line in findings:
        print("%s:%d  %s %g is off the scale\n    %s" % (relative, number, label, value, line[:100]))

    print()
    print("scale: spacing %s, radius %s" % (
        sorted(scale["spacing"]), sorted(scale["radius"])
    ))
    if findings:
        print("%d off-scale values" % len(findings))
        return 1
    print("Layout scale pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
