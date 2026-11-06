#!/usr/bin/env python3
"""Original GYLT scenes in the Meadow Dusk palette: layered dunes, an arch, suns. Drawn at 2x and downsampled."""
import math, os, sys
from PIL import Image, ImageDraw

W, H, S = 1200, 800, 2

def hexc(h):
    h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def lerp(a, b, t): return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))

def vgrad(img, top, bottom, y0=0, y1=None):
    d = ImageDraw.Draw(img); y1 = y1 or img.height
    for y in range(y0, y1):
        d.line([(0, y), (img.width, y)], fill=lerp(hexc(top), hexc(bottom), (y - y0) / max(1, y1 - y0)))

def dune(img, base, amp, phase, top, bottom, freq=1.0):
    """A soft hill silhouette filled with a vertical gradient."""
    w, h = img.size
    pts = [(0, h)]
    for x in range(0, w + 8, 8):
        t = x / w
        y = base + amp * (math.sin(t * math.pi * 1.4 * freq + phase) * .6 + math.sin(t * math.pi * 3.1 * freq + phase * 1.7) * .25)
        pts.append((x, y))
    pts.append((w, h))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    layer = Image.new("RGB", img.size)
    vgrad(layer, top, bottom, int(base - amp), h)
    img.paste(layer, (0, 0), mask)

def disc(img, cx, cy, r, fill):
    ImageDraw.Draw(img).ellipse([cx - r, cy - r, cx + r, cy + r], fill=hexc(fill))

def arch(img, cx, base_y, w, h, fill, inner=None):
    d = ImageDraw.Draw(img)
    r = w / 2
    d.rectangle([cx - r, base_y - h + r, cx + r, base_y], fill=hexc(fill))
    d.ellipse([cx - r, base_y - h, cx + r, base_y - h + 2 * r], fill=hexc(fill))
    if inner:
        iw = w * .62; ir = iw / 2
        d.rectangle([cx - ir, base_y - h + r + 20 * S, cx + ir, base_y - 6 * S], fill=hexc(inner))
        d.ellipse([cx - ir, base_y - h + r + 20 * S - ir, cx + ir, base_y - h + r + 20 * S + ir], fill=hexc(inner))

def star(img, x, y, r, fill="#FFE9E2"):
    disc(img, x, y, r, fill)

def finish(img, name):
    out = img.resize((W, H), Image.LANCZOS)
    out.save(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "GYLT", "Resources", "Assets.xcassets", "Art", name.replace(".png", "") + ".imageset", name))

def canvas():
    return Image.new("RGB", (W * S, H * S))

def custom():
    im = canvas(); vgrad(im, "#CDB8F5", "#FFD9EC")
    disc(im, 840 * S, 300 * S, 150 * S, "#FFF3E0"); disc(im, 840 * S, 300 * S, 104 * S, "#FFFFFF")
    dune(im, 470 * S, 60 * S, 0.4, "#8FA6FF", "#4A6BEA", 0.9)
    dune(im, 560 * S, 70 * S, 2.0, "#6F8CFF", "#3350C8", 1.0)
    dune(im, 660 * S, 70 * S, 4.1, "#FFB224", "#F0501A", 0.8)
    for x, y, r in [(180, 140, 5), (300, 90, 3), (470, 170, 4), (640, 80, 3), (110, 270, 3)]: star(im, x * S, y * S, r * S, "#FFFFFF")
    finish(im, "gylt-custom.png")

def blocked():
    im = canvas(); vgrad(im, "#1B2040", "#3A2A5C")
    disc(im, 940 * S, 190 * S, 120 * S, "#FF9BD2")
    sky = lerp(hexc("#1B2040"), hexc("#3A2A5C"), 160 / 800)
    disc(im, 984 * S, 160 * S, 104 * S, "#%02x%02x%02x" % sky)
    for x, y, r in [(150, 120, 4), (260, 200, 3), (420, 110, 4), (560, 190, 3), (700, 90, 3), (80, 260, 3), (780, 250, 3)]: star(im, x * S, y * S, r * S, "#FFC5E6")
    dune(im, 520 * S, 60 * S, 1.0, "#5A3E80", "#2A2048", 0.9)
    dune(im, 610 * S, 60 * S, 3.2, "#3E2C66", "#1C1636", 1.0)
    arch(im, 520 * S, 640 * S, 250 * S, 360 * S, "#FF9BD2", "#FFC5E6")
    # a padlock on the door
    d = ImageDraw.Draw(im)
    d.rectangle([488 * S, 520 * S, 552 * S, 580 * S], fill=hexc("#232A45"))
    d.arc([498 * S, 488 * S, 542 * S, 540 * S], 180, 360, fill=hexc("#232A45"), width=8 * S)
    d.ellipse([514 * S, 540 * S, 526 * S, 552 * S], fill=hexc("#FF9BD2"))
    dune(im, 700 * S, 50 * S, 5.0, "#2A2048", "#120E26", 1.1)
    finish(im, "gylt-blocked.png")

def milestone():
    im = canvas(); vgrad(im, "#14131B", "#3A1F40")
    cx, cy = 600 * S, 560 * S
    for r, c in [(520, "#4A2A55"), (420, "#7A2E63"), (330, "#C23F5A"), (250, "#F0501A"), (170, "#FDB927"), (100, "#FFE9B8")]:
        disc(im, cx, cy, r * S, c)
    dune(im, 590 * S, 50 * S, 0.8, "#FF9A3D", "#C23F1A", 0.9)
    dune(im, 660 * S, 50 * S, 2.6, "#3A1F40", "#1A1024", 1.0)
    for x, y, r in [(150, 120, 4), (300, 220, 3), (900, 140, 4), (1040, 260, 3), (780, 90, 3), (420, 90, 3)]: star(im, x * S, y * S, r * S, "#FFE9E2")
    finish(im, "gylt-milestone.png")

if __name__ == "__main__":
    pass  # images are written straight into the asset catalog
    custom(); blocked(); milestone()
    print("drawn")
