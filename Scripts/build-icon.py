"""
Builds the On Color Theory app icon.

Everything is generated from the palette block below, so swapping the six hex
values is the only edit needed to bring the mark in line with the section icons
inside the app. Overlap colors are not chosen by eye. They are calculated by
screen compositing the three base colors, which is the same additive result the
Mixing experiment demonstrates, so the mark stays honest about its own subject.

Outputs go both to Build/icon for inspection and straight into the asset
catalog and the brand folder, so the app and the review copies cannot drift.

The previous script produced a file with an .svg extension that held one
base64 PNG and no geometry at all. This one emits real paths, so the mark can
be recolored and rescaled without loss.
"""

import math
import os
import struct
import zlib

from PIL import Image, ImageDraw, ImageFilter

# ---------------------------------------------------------------------------
# Palette. Replace these six values with the app's own section icon colors.
# ---------------------------------------------------------------------------

# Hues taken from AppSemanticPalette, universal dark, at full chroma. The
# interface values themselves are tuned for text and cue contrast against a
# window background, which leaves them too pale to carry a mark at 32 points.
# Holding the hues and raising the chroma keeps the icon in agreement with the
# section icons while staying legible small.
BASE_R = (238, 43, 161)    # secondaryCue hue, 324 degrees
BASE_G = (43, 238, 189)    # positive hue, 165 degrees
BASE_B = (43, 153, 238)    # accent hue, 206 degrees

PLATE_TOP = (30, 36, 48)
PLATE_BOTTOM = (12, 15, 22)
RING_STROKE = (255, 255, 255)

# ---------------------------------------------------------------------------
# Geometry. Apple sizes a macOS app icon plate at 824 points inside a 1024
# point canvas and leaves the rest to the shadow, so those numbers are fixed.
# ---------------------------------------------------------------------------

CANVAS = 1024
PLATE = 824
SQUIRCLE_N = 5.0          # exponent that matches the continuous corner curve
DISC_RADIUS = 199.0
DISC_OFFSET = 110.0       # distance from center to each disc center
RING_RADIUS = 366.0
RING_WIDTH = 9.0
SUPERSAMPLE = 4


def screen(a, b):
    """Additive compositing of two opaque colors, per channel."""
    return tuple(255 - (255 - x) * (255 - y) // 255 for x, y in zip(a, b))


MIX_RG = screen(BASE_R, BASE_G)
MIX_RB = screen(BASE_R, BASE_B)
MIX_GB = screen(BASE_G, BASE_B)
MIX_RGB = screen(MIX_RG, BASE_B)


def hexof(c):
    return "#%02X%02X%02X" % c


def disc_centers():
    """Three disc centers, evenly spaced, with the blue disc at the top."""
    out = []
    for degrees in (90.0, 210.0, 330.0):
        radians = math.radians(degrees)
        out.append(
            (
                CANVAS / 2 + DISC_OFFSET * math.cos(radians),
                CANVAS / 2 - DISC_OFFSET * math.sin(radians),
            )
        )
    return out


CENTERS = disc_centers()
COLORS = [BASE_B, BASE_R, BASE_G]


# ---------------------------------------------------------------------------
# Vector output
# ---------------------------------------------------------------------------


def squircle_path(cx, cy, half, exponent, steps=720):
    """Superellipse traced as a closed polyline, tight enough to read as a curve."""
    points = []
    for i in range(steps):
        theta = 2 * math.pi * i / steps
        ct, st = math.cos(theta), math.sin(theta)
        x = half * math.copysign(abs(ct) ** (2.0 / exponent), ct)
        y = half * math.copysign(abs(st) ** (2.0 / exponent), st)
        points.append((cx + x, cy + y))
    body = " ".join("%.2f,%.2f" % p for p in points)
    return "M " + body.replace(" ", " L ", 1) + " Z"


def svg(with_ring):
    cx = cy = CANVAS / 2
    plate = squircle_path(cx, cy, PLATE / 2, SQUIRCLE_N)
    (bx, by), (rx, ry), (gx, gy) = CENTERS

    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
        'width="%d" height="%d" role="img" aria-labelledby="title desc">'
        % (CANVAS, CANVAS, CANVAS, CANVAS),
        "<title id=\"title\">On Color Theory</title>",
        "<desc id=\"desc\">Three additive color fields overlapping to white on a "
        "dark plate.</desc>",
        "<defs>",
        '<linearGradient id="plate" x1="0" y1="0" x2="0" y2="1">'
        '<stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/>'
        "</linearGradient>" % (hexof(PLATE_TOP), hexof(PLATE_BOTTOM)),
        '<clipPath id="plateClip"><path d="%s"/></clipPath>' % plate,
        '<clipPath id="clipB"><circle cx="%.2f" cy="%.2f" r="%.2f"/></clipPath>'
        % (bx, by, DISC_RADIUS),
        '<clipPath id="clipR"><circle cx="%.2f" cy="%.2f" r="%.2f"/></clipPath>'
        % (rx, ry, DISC_RADIUS),
        '<clipPath id="clipG"><circle cx="%.2f" cy="%.2f" r="%.2f"/></clipPath>'
        % (gx, gy, DISC_RADIUS),
    ]

    if with_ring:
        parts.append(
            '<linearGradient id="ring" x1="0" y1="0" x2="1" y2="1">'
            '<stop offset="0" stop-color="%s" stop-opacity="0.85"/>'
            '<stop offset="1" stop-color="%s" stop-opacity="0.30"/></linearGradient>'
            % (hexof(RING_STROKE), hexof(RING_STROKE))
        )

    parts.append("</defs>")
    parts.append('<path d="%s" fill="url(#plate)"/>' % plate)
    parts.append('<g clip-path="url(#plateClip)">')

    if with_ring:
        parts.append(
            '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="none" stroke="url(#ring)" '
            'stroke-width="%.1f"/>' % (cx, cy, RING_RADIUS, RING_WIDTH)
        )

    # Base discs, then every overlap painted on top as a flat clipped fill.
    # Clipping avoids blend modes, which not every renderer honors the same way.
    circle = '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="%s"/>'
    parts.append(circle % (bx, by, DISC_RADIUS, hexof(BASE_B)))
    parts.append(circle % (rx, ry, DISC_RADIUS, hexof(BASE_R)))
    parts.append(circle % (gx, gy, DISC_RADIUS, hexof(BASE_G)))

    parts.append(
        '<g clip-path="url(#clipB)">' + circle % (rx, ry, DISC_RADIUS, hexof(MIX_RB)) + "</g>"
    )
    parts.append(
        '<g clip-path="url(#clipB)">' + circle % (gx, gy, DISC_RADIUS, hexof(MIX_GB)) + "</g>"
    )
    parts.append(
        '<g clip-path="url(#clipR)">' + circle % (gx, gy, DISC_RADIUS, hexof(MIX_RG)) + "</g>"
    )
    parts.append(
        '<g clip-path="url(#clipB)"><g clip-path="url(#clipR)">'
        + circle % (gx, gy, DISC_RADIUS, hexof(MIX_RGB))
        + "</g></g>"
    )

    parts.append("</g></svg>")
    return "\n".join(parts)


# ---------------------------------------------------------------------------
# Raster output
# ---------------------------------------------------------------------------


def squircle_mask(size, half, exponent):
    """Antialiased superellipse mask, rendered oversized and then reduced."""
    s = size * SUPERSAMPLE
    img = Image.new("L", (s, s), 0)
    draw = ImageDraw.Draw(img)
    pts = []
    for i in range(1440):
        theta = 2 * math.pi * i / 1440
        ct, st = math.cos(theta), math.sin(theta)
        x = half * math.copysign(abs(ct) ** (2.0 / exponent), ct)
        y = half * math.copysign(abs(st) ** (2.0 / exponent), st)
        scale = s / CANVAS
        pts.append(((CANVAS / 2 + x) * scale, (CANVAS / 2 + y) * scale))
    draw.polygon(pts, fill=255)
    return img.resize((size, size), Image.LANCZOS)


def render(with_ring, size=CANVAS):
    s = size * SUPERSAMPLE
    scale = s / CANVAS

    plate = Image.new("RGB", (s, s))
    top, bottom = PLATE_TOP, PLATE_BOTTOM
    for row in range(s):
        t = row / max(1, s - 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        ImageDraw.Draw(plate).line([(0, row), (s, row)], fill=color)

    draw = ImageDraw.Draw(plate)

    if with_ring:
        r = RING_RADIUS * scale
        w = max(1, int(round(RING_WIDTH * scale)))
        box = [s / 2 - r, s / 2 - r, s / 2 + r, s / 2 + r]
        draw.ellipse(box, outline=(150, 160, 185), width=w)

    def disc(center, radius):
        cx, cy = center[0] * scale, center[1] * scale
        r = radius * scale
        mask = Image.new("L", (s, s), 0)
        ImageDraw.Draw(mask).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
        return mask

    masks = [disc(c, DISC_RADIUS) for c in CENTERS]
    mb, mr, mg = masks

    def paint(mask, color):
        plate.paste(Image.new("RGB", (s, s), color), (0, 0), mask)

    def both(a, b):
        return Image.fromarray(
            (
                __import__("numpy").minimum(
                    __import__("numpy").asarray(a, dtype="uint16"),
                    __import__("numpy").asarray(b, dtype="uint16"),
                )
            ).astype("uint8")
        )

    paint(mb, BASE_B)
    paint(mr, BASE_R)
    paint(mg, BASE_G)
    paint(both(mb, mr), MIX_RB)
    paint(both(mb, mg), MIX_GB)
    paint(both(mr, mg), MIX_RG)
    paint(both(both(mb, mr), mg), MIX_RGB)

    plate = plate.resize((size, size), Image.LANCZOS)
    mask = squircle_mask(size, PLATE / 2, SQUIRCLE_N)

    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Soft shadow under the plate, matching the way system icons sit on a surface.
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow.paste(Image.new("RGBA", (size, size), (0, 0, 0, 105)), (0, 0), mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.016))
    out.alpha_composite(shadow, (0, int(size * 0.012)))

    body = plate.convert("RGBA")
    body.putalpha(mask)
    out.alpha_composite(body)
    return out


# ---------------------------------------------------------------------------
# icns container
# ---------------------------------------------------------------------------

ICNS_TYPES = [
    (b"icp4", 16),
    (b"icp5", 32),
    (b"ic11", 32),
    (b"ic12", 64),
    (b"ic07", 128),
    (b"ic13", 256),
    (b"ic08", 256),
    (b"ic14", 512),
    (b"ic09", 512),
    (b"ic10", 1024),
]


def write_icns(master, path):
    chunks = []
    for ostype, px in ICNS_TYPES:
        import io

        buf = io.BytesIO()
        master.resize((px, px), Image.LANCZOS).save(buf, format="PNG", optimize=True)
        data = buf.getvalue()
        chunks.append(ostype + struct.pack(">I", len(data) + 8) + data)
    body = b"".join(chunks)
    with open(path, "wb") as fh:
        fh.write(b"icns" + struct.pack(">I", len(body) + 8) + body)


ICONSET = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]


def main():
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Build", "icon")
    os.makedirs(out, exist_ok=True)

    for name, ring in (("discs", False), ("ring", True)):
        with open(os.path.join(out, "icon-%s.svg" % name), "w") as fh:
            fh.write(svg(ring))
        master = render(ring)
        master.save(os.path.join(out, "preview-%s-1024.png" % name))
        # Small size proof sheet, since legibility at 32 points is the real test.
        sheet = Image.new("RGBA", (16 + 32 + 64 + 128 + 80, 128), (0, 0, 0, 0))
        x = 0
        for px in (16, 32, 64, 128):
            sheet.alpha_composite(master.resize((px, px), Image.LANCZOS), (x, 128 - px))
            x += px + 20
        sheet.save(os.path.join(out, "sizes-%s.png" % name))

    chosen = render(False)

    # The asset catalog is written directly, so the app picks the new icon up
    # without a second copying step that could go stale.
    catalog = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "..", "Support", "AppAssets.xcassets", "AppIcon.appiconset",
    )
    for name, px in ICONSET:
        chosen.resize((px, px), Image.LANCZOS).save(os.path.join(catalog, name))

    brand = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "..", "Sources", "OnColorTheoryApp", "Resources", "Brand",
    )
    chosen.save(os.path.join(brand, "OnColorTheoryAppIcon.png"))
    with open(os.path.join(brand, "OnColorTheoryAppIcon.svg"), "w") as handle:
        handle.write(svg(False))

    iconset = os.path.join(out, "OnColorTheory.iconset")
    os.makedirs(iconset, exist_ok=True)
    for name, px in ICONSET:
        chosen.resize((px, px), Image.LANCZOS).save(os.path.join(iconset, name))
    write_icns(chosen, os.path.join(out, "AppIcon.icns"))

    print("overlap colors calculated by screen compositing")
    print("  red over green ", hexof(MIX_RG))
    print("  red over blue  ", hexof(MIX_RB))
    print("  green over blue", hexof(MIX_GB))
    print("  all three      ", hexof(MIX_RGB))


if __name__ == "__main__":
    main()
