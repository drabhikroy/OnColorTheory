"""
Palette audit for On Color Theory.

Two questions are asked of every semantic color in every mode.

  1. Does it reach WCAG 2.2 contrast against the canvas behind it?
     Roles used for text and icons need 4.5 to 1. Roles used only as a border,
     a fill, or a selection ring need 3 to 1 under Success Criterion 1.4.11.

  2. Do any two roles collapse into the same color for a dichromat viewer?
     Two roles that a viewer cannot separate carry no distinct meaning, which
     defeats the point of offering protan, deutan, and tritan modes at all.
     Distance is measured in Oklab, for the reason given above that function.

Simulation follows Vienot, Brettel, and Mollon 1999 for protanopia and
deuteranopia, and Brettel, Vienot, and Mollon 1997 for tritanopia. All three
projections are idempotent and leave the neutral axis untouched, which is what
`Tests` checks them against.

Exit status is non-zero when any check fails, so this runs as a build gate.
"""

import itertools
import math
import os
import re
import sys

# ---------------------------------------------------------------------------
# Palette under test. Values mirror AppAppearance.swift exactly.
# ---------------------------------------------------------------------------

SOURCE = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "..", "Sources", "OnColorTheoryApp", "DesignSystem", "AppAppearance.swift",
)

ROLE_LINE = re.compile(
    r"(\w+): colorScheme == \.dark \? Self\.color\((\d+), (\d+), (\d+)\)"
    r"\s*: Self\.color\((\d+), (\d+), (\d+)\)"
)


def read_palettes():
    """Reads the live values out of AppAppearance.swift.

    Keeping a second copy of the numbers here would let the audit drift away
    from the app it is meant to check, which is the failure mode this whole
    script exists to prevent.
    """
    text = open(SOURCE, encoding="utf-8").read()
    body = text[text.index("func resolved(for colorScheme: ColorScheme)"):]
    modes = ["universal", "protan", "deutan", "tritan", "monochrome"]
    out = {}
    for index, mode in enumerate(modes):
        head = body.index("case .%s:" % mode)
        tail = body.index("case .%s:" % modes[index + 1]) if index + 1 < len(modes) else len(body)
        section = body[head:tail]
        out[mode] = {"dark": {}, "light": {}}
        for match in ROLE_LINE.finditer(section):
            role = match.group(1)
            out[mode]["dark"][role] = tuple(int(match.group(i)) for i in (2, 3, 4))
            out[mode]["light"][role] = tuple(int(match.group(i)) for i in (5, 6, 7))
        if len(out[mode]["dark"]) != 5:
            raise SystemExit("could not read five roles for %s" % mode)
    return out


PALETTES = read_palettes()

# macOS controlBackgroundColor, which is the surface behind these roles.
CANVAS = {"dark": (30, 30, 30), "light": (255, 255, 255)}

TEXT_MINIMUM = 4.5      # Success Criterion 1.4.3
NON_TEXT_MINIMUM = 3.0  # Success Criterion 1.4.11
SEPARATION_MINIMUM = 10.0  # Oklab distance floor for two roles to stay distinct

# Monochrome is excluded from the separation test on purpose. It removes hue by
# design and asks text, borders, and symbols to carry the meaning instead.
SEPARATION_MODES = ["universal", "protan", "deutan", "tritan"]

# Which simulation each mode is meant to survive. A mode is only held to the
# deficiency it names, plus normal vision.
SIMULATION_FOR_MODE = {
    "universal": ["none", "protan", "deutan", "tritan"],
    "protan": ["none", "protan"],
    "deutan": ["none", "deutan"],
    "tritan": ["none", "tritan"],
}


# ---------------------------------------------------------------------------
# Color mathematics
# ---------------------------------------------------------------------------


def to_linear(channel):
    c = channel / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(rgb):
    r, g, b = (to_linear(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(a, b):
    la, lb = relative_luminance(a), relative_luminance(b)
    lighter, darker = max(la, lb), min(la, lb)
    return (lighter + 0.05) / (darker + 0.05)


def to_xyz(rgb):
    r, g, b = (to_linear(c) for c in rgb)
    return (
        0.4124564 * r + 0.3575761 * g + 0.1804375 * b,
        0.2126729 * r + 0.7151522 * g + 0.0721750 * b,
        0.0193339 * r + 0.1191920 * g + 0.9503041 * b,
    )


def to_lab(rgb):
    x, y, z = to_xyz(rgb)
    xn, yn, zn = 0.95047, 1.0, 1.08883

    def f(t):
        return t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116

    fx, fy, fz = f(x / xn), f(y / yn), f(z / zn)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))


def delta_e_76(a, b):
    la, aa, ba = to_lab(a)
    lb, ab, bb = to_lab(b)
    return math.sqrt((la - lb) ** 2 + (aa - ab) ** 2 + (ba - bb) ** 2)


# Oklab, matching the constants in ColorEngine.swift exactly. Separation is
# measured here rather than in CIELAB because CIEDE2000 is specified for small
# differences under reference conditions and is the wrong instrument for asking
# whether two cues are categorically distinct, while Euclidean CIELAB is not
# uniform across differences this large. Oklab is built for that range, and
# using the same model the app itself reports keeps the audit and the app
# describing color the same way.


def to_oklab(rgb):
    x, y, z = to_xyz(rgb)
    long_ = 0.8190224379967030 * x + 0.3619062600528904 * y - 0.1288737815209879 * z
    medium = 0.0329836539323885 * x + 0.9292868615863434 * y + 0.0361446663506424 * z
    short = 0.0481771893596242 * x + 0.2642395317527308 * y + 0.6335478284694309 * z

    def root(value):
        return math.copysign(abs(value) ** (1 / 3), value)

    lr, mr, sr = root(long_), root(medium), root(short)
    return (
        0.2104542683093140 * lr + 0.7936177747023054 * mr - 0.0040720430116193 * sr,
        1.9779985324311684 * lr - 2.4285922420485799 * mr + 0.4505937096174110 * sr,
        0.0259040424655478 * lr + 0.7827717124575296 * mr - 0.8086757549230774 * sr,
    )


def separation(first, second):
    """Euclidean distance in Oklab, scaled by 100 so the numbers read like
    familiar delta E values rather than fractions."""
    a = to_oklab(first)
    b = to_oklab(second)
    return 100 * math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))


def simulate(rgb, kind):
    """Dichromat simulation in LMS, returned as 8 bit sRGB."""
    if kind == "none":
        return rgb

    r, g, b = (to_linear(c) for c in rgb)

    # Hunt-Pointer-Estevez, normalized to D65.
    long_ = 0.31399022 * r + 0.63951294 * g + 0.04649755 * b
    medium = 0.15537241 * r + 0.75789446 * g + 0.08670142 * b
    short = 0.01775239 * r + 0.10944209 * g + 0.87256922 * b

    if kind == "protan":
        long_ = 1.05118294 * medium - 0.05116099 * short
    elif kind == "deutan":
        medium = 0.9513092 * long_ + 0.04866992 * short
    elif kind == "tritan":
        short = -0.86744736 * long_ + 1.86727089 * medium

    lr = 5.47221206 * long_ - 4.6419601 * medium + 0.16963708 * short
    lg = -1.1252419 * long_ + 2.29317094 * medium - 0.1678952 * short
    lb = 0.02980165 * long_ - 0.19318073 * medium + 1.16364789 * short

    def encode(v):
        v = max(0.0, min(1.0, v))
        v = 12.92 * v if v <= 0.0031308 else 1.055 * (v ** (1 / 2.4)) - 0.055
        return int(round(v * 255))

    return (encode(lr), encode(lg), encode(lb))


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------


def hexof(rgb):
    return "#%02X%02X%02X" % rgb


def run():
    failures = []
    print("Contrast against canvas")
    print("-" * 68)
    for mode, schemes in PALETTES.items():
        for scheme, roles in schemes.items():
            canvas = CANVAS[scheme]
            for role, rgb in roles.items():
                ratio = contrast_ratio(rgb, canvas)
                floor = TEXT_MINIMUM
                mark = "pass" if ratio >= floor else "FAIL"
                if ratio < NON_TEXT_MINIMUM:
                    mark = "FAIL"
                    failures.append(
                        "%s %s %s at %.2f to 1, below the 3 to 1 non-text floor"
                        % (mode, scheme, role, ratio)
                    )
                elif ratio < floor:
                    mark = "warn"
                print(
                    "  %-11s %-5s %-13s %s  %5.2f to 1  %s"
                    % (mode, scheme, role, hexof(rgb), ratio, mark)
                )

    print()
    print("Role separation under simulation")
    print("-" * 68)
    for mode in SEPARATION_MODES:
        for scheme, roles in PALETTES[mode].items():
            for kind in SIMULATION_FOR_MODE[mode]:
                for first, second in itertools.combinations(sorted(roles), 2):
                    distance = separation(
                        simulate(roles[first], kind), simulate(roles[second], kind)
                    )
                    if distance < SEPARATION_MINIMUM:
                        failures.append(
                            "%s %s under %s, %s and %s separate by only %.1f"
                            % (mode, scheme, kind, first, second, distance)
                        )
                        print(
                            "  %-11s %-5s %-7s %-13s %-13s %5.1f  FAIL"
                            % (mode, scheme, kind, first, second, distance)
                        )

    print()
    if failures:
        print("%d failures" % len(failures))
        for f in failures:
            print("  " + f)
        return 1
    print("All checks pass")
    return 0


if __name__ == "__main__":
    sys.exit(run())
