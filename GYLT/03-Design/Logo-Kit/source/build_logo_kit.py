#!/usr/bin/env python3
"""Build the GYLT logo kit from its pixel grids.

Everything in ../svg, ../png and ../web is generated from the grids below, so edit a grid and re-run:

    python3 build_logo_kit.py

SVGs are written as merged pixel rows (crisp at any size). PNGs and web icons are painted pixel by pixel
at whole-number scales, so they stay sharp; that part needs Pillow (`python3 -m pip install pillow`).
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.dirname(HERE)

INK, PAPER, CORAL = "#1C1B18", "#F5F4F0", "#FF6548"
PAL = {
    "#": INK,        # outline and features
    "W": "#ECEBE6",  # cap
    "h": "#FFFFFF",  # cap gleam
    "g": "#8F8E86",  # cap shade / brim
    "d": "#64635C",  # cap band
    "b": CORAL,      # face
    "B": "#C23F20",  # face shade
    "l": "#FF8A70",  # face top edge, nose
    "H": "#FFE6DE",  # cheek gleam
    "e": PAPER,      # eye white
}

# ---------------------------------------------------------------- grids
CAP = [
    "......############......",
    "....##WWWWWWWWWWWW##....",
    "...#gWWWWWWWWWWWhWW#....",
    "..#ggWWWWWWWWWWWWhWW#...",
    "..#ggWWWWWWWWWWWWWWW#...",
    "..#gdddddddddddddddd#...",
    ".##ddddddddddddddddd####",
    ".#ddddddddddddddddddggg#",
    ".#######################",
]
# Face interiors are 20 columns; column 0 is the shaded left edge; features mirror p <-> 20-p.
GRUMPY = [
    "B" + "l"*19,
    "B" + "b"*19,
    "Bbb##bbbbbbbbbbb##bb",   # brows, outer ends high
    "Bbbbb##bbbbbbb##bbbb",
    "Bbbbbbb##bbb##bbbbbb",   # brows meet in a furrow
    "Bbbb#####bbb#####bbb",   # upper lids
    "Bbbb#ee##bbb##ee#bbb",   # glaring eyes
    "Bbbbb###bbbbb###bbbb",   # lower lids
    "BHHbbbbbb###bbbbbbbb",   # cheek gleam, nose bridge
    "BHbbbbbb#lll#bbbbbbb",   # nose
    "Bbbbbbbb#BlB#bbbbbbb",   # nostrils
    "Bbbbbbbbb###bbbbbbbb",
    "B" + "b"*19,
    "Bbbbbbb#######bbbbbb",   # mouth
    "Bbbbbb#bbbbbbb#bbbbb",   # frown
    "Bbbbb#bbb###bbb#bbbb",   # frown corners, goatee
    "Bbbbbbbbb###bbbbbbbb",
    "Bbbbbbbbbb#bbbbbbbbb",
    "BB" + "b"*17 + "B",
]
PLEASED = [
    "B" + "l"*19,
    "B" + "b"*19,
    "Bbb####bbbbbbb####bb",   # relaxed brows
    "B" + "b"*19,
    "Bbbbb##bbbbbbb##bbbb",   # closed, happy eyes
    "Bbbb#bb#bbbbb#bb#bbb",
    "B" + "b"*19,
    "BHHbbbbbb###bbbbbbbb",
    "BHbbbbbb#lll#bbbbbbb",
    "Bbbbbbbb#BlB#bbbbbbb",
    "Bbbbbbbbb###bbbbbbbb",
    "B" + "b"*19,
    "Bbbbb#bbbbbbbbb#bbbb",   # smile
    "Bbbbbb#########bbbbb",
    "B" + "b"*19,
    "Bbbbbbbbb###bbbbbbbb",
    "Bbbbbbbbb###bbbbbbbb",
    "Bbbbbbbbbb#bbbbbbbbb",
    "BB" + "b"*17 + "B",
]
SMALL = [  # 16 × 16 cut for favicons: brows, eyes, nose, frown — no gleams or goatee detail
    "....########....",
    "...#WWWWWWhW#...",
    "..#gWWWWWWWWW#..",
    ".#ddddddddddddg#",
    ".###############",
    ".#Blllllllllll#.",
    ".#Bb##bbbbb##b#.",
    ".#Bbbb#bbb#bbb#.",
    ".#Bb###bbb###b#.",
    ".#Bb#e#bbb#e#b#.",
    ".#Bbbbb###bbbb#.",
    ".#Bbbbbbbbbbbb#.",
    ".#Bbbb#####bbb#.",
    ".#Bbb#bb#bb#bb#.",
    ".#BBbbbbbbbbbB#.",
    "..############..",
]

def coach(face):
    rows = CAP + [".#" + r + "#." for r in face] + [".." + "#"*20 + ".."]
    for i, r in enumerate(rows):
        assert len(r) == 24, (i, r, len(r))
    return rows

COACH, COACH_PLEASED = coach(GRUMPY), coach(PLEASED)
for i, r in enumerate(SMALL):
    assert len(r) == 16, (i, r, len(r))

LETTERS = {  # 2-unit strokes, 9 units tall
    "G": [".#####.", "##...##", "##.....", "##.....", "##.####", "##...##", "##...##", "##...##", ".#####."],
    "Y": ["##....##", "##....##", ".##..##.", "..####..", "...##...", "...##...", "...##...", "...##...", "...##..."],
    "L": ["##.....", "##.....", "##.....", "##.....", "##.....", "##.....", "##.....", "#######", "#######"],
    "T": ["########", "########", "...##...", "...##...", "...##...", "...##...", "...##...", "...##...", "...##..."],
}
WORD = ["", "", "", "", "", "", "", "", ""]
for i, ch in enumerate("GYLT"):
    for y in range(9):
        WORD[y] += (".." if i else "") + LETTERS[ch][y]

# ---------------------------------------------------------------- SVG
def runs(grid, ch, ox=0, oy=0):
    d = []
    for y, row in enumerate(grid):
        x = 0
        while x < len(row):
            if row[x] == ch:
                s = x
                while x < len(row) and row[x] == ch:
                    x += 1
                d.append(f"M{s+ox} {y+oy}h{x-s}v1h{s-x}z")
            else:
                x += 1
    return "".join(d)

def paint(grid, ox=0, oy=0, recolor=None):
    out = []
    for ch, col in PAL.items():
        d = runs(grid, ch, ox, oy)
        if d:
            out.append(f'<path fill="{(recolor or {}).get(ch, col)}" d="{d}"/>')
    return "".join(out)

def only(grid, ch, color, ox=0, oy=0):
    return f'<path fill="{color}" d="{runs(grid, ch, ox, oy)}"/>'

def svg(w, h, body, title, scale=10, bg=None):
    rect = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w*scale}" height="{h*scale}" '
            f'shape-rendering="crispEdges" role="img" aria-labelledby="t"><title id="t">{title}</title>{rect}{body}</svg>\n')

CH, CW, WWID, WH = len(COACH), 24, len(WORD[0]), 9

def write(rel, text):
    p = os.path.join(KIT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write(text)

# symbol
write("svg/gylt-coach.svg", svg(CW, CH, paint(COACH), "GYLT coach"))
write("svg/gylt-coach-pleased.svg", svg(CW, CH, paint(COACH_PLEASED), "GYLT coach, pleased"))
write("svg/gylt-coach-16.svg", svg(16, 16, paint(SMALL), "GYLT coach, 16 px cut", scale=2))
write("svg/gylt-coach-line-ink.svg", svg(CW, CH, only(COACH, "#", INK), "GYLT coach, one colour (ink)"))
write("svg/gylt-coach-line-white.svg", svg(CW, CH, only(COACH, "#", "#FFFFFF"), "GYLT coach, one colour (white)"))
# wordmark
for name, col in (("ink", INK), ("white", "#FFFFFF"), ("coral", CORAL)):
    write(f"svg/gylt-wordmark-{name}.svg", svg(WWID, WH, only(WORD, "#", col), f"GYLT wordmark ({name})"))
# lockups: stacked (primary) and horizontal; reversed = white wordmark for dark backgrounds
GAP_S, GAP_H = 3, 4
stack_w, stack_h = WWID, CH + GAP_S + WH
hor_w, word_y = CW + GAP_H + WWID, 14
for tag, wcol in (("", INK), ("-reversed", "#FFFFFF")):
    write(f"svg/gylt-lockup-stacked{tag}.svg",
          svg(stack_w, stack_h, paint(COACH, (WWID - CW)//2, 0) + only(WORD, "#", wcol, 0, CH + GAP_S), "GYLT stacked lockup"))
    write(f"svg/gylt-lockup-horizontal{tag}.svg",
          svg(hor_w, CH, paint(COACH) + only(WORD, "#", wcol, CW + GAP_H, word_y), "GYLT horizontal lockup"))
# app icon: coach on an ink tile (square master; platforms apply their own mask)
TILE = 40
write("svg/gylt-app-icon.svg", svg(TILE, TILE, paint(COACH, (TILE-CW)//2, (TILE-CH)//2 + 1), "GYLT app icon", scale=16, bg=INK))

# ---------------------------------------------------------------- PNG + web icons (exact pixels)
try:
    from PIL import Image
except ImportError:
    print("SVGs written. Install Pillow to build PNGs and web icons.")
    sys.exit(0)

def rgba(hexcol, a=255):
    h = hexcol.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)

def raster(grid, scale, recolor=None, size=None, bg=None, offset=None):
    gw, gh = len(grid[0]), len(grid)
    W, H = size or (gw*scale, gh*scale)
    img = Image.new("RGBA", (W, H), rgba(bg) if bg else (0, 0, 0, 0))
    ox, oy = offset if offset else ((W - gw*scale)//2, (H - gh*scale)//2)
    px = img.load()
    for y, row in enumerate(grid):
        for x, ch in enumerate(row):
            if ch in PAL:
                col = rgba((recolor or {}).get(ch, PAL[ch]))
                for yy in range(scale):
                    for xx in range(scale):
                        px[ox + x*scale + xx, oy + y*scale + yy] = col
    return img

def save(img, rel):
    p = os.path.join(KIT, rel); os.makedirs(os.path.dirname(p), exist_ok=True); img.save(p); return p

def compose(parts, W, H, bg=None):
    img = Image.new("RGBA", (W, H), rgba(bg) if bg else (0, 0, 0, 0))
    for im, (x, y) in parts:
        img.alpha_composite(im, (x, y))
    return img

word_ink = lambda col: {"#": col}
for s in (4, 8, 16):
    save(raster(COACH, s), f"png/gylt-coach@{s}x.png")
    save(raster(COACH_PLEASED, s), f"png/gylt-coach-pleased@{s}x.png")
    save(raster(WORD, s, word_ink(INK)), f"png/gylt-wordmark-ink@{s}x.png")
    save(raster(WORD, s, word_ink("#FFFFFF")), f"png/gylt-wordmark-white@{s}x.png")
    for tag, wcol in (("", INK), ("-reversed", "#FFFFFF")):
        save(compose([(raster(COACH, s), ((WWID-CW)//2*s, 0)), (raster(WORD, s, word_ink(wcol)), (0, (CH+GAP_S)*s))], stack_w*s, stack_h*s),
             f"png/gylt-lockup-stacked{tag}@{s}x.png")
        save(compose([(raster(COACH, s), (0, 0)), (raster(WORD, s, word_ink(wcol)), ((CW+GAP_H)*s, word_y*s))], hor_w*s, CH*s),
             f"png/gylt-lockup-horizontal{tag}@{s}x.png")

# web icons: favicons from the 16 cut, tiles from the full coach on ink
f16, f32, f48 = raster(SMALL, 1), raster(SMALL, 2), raster(SMALL, 3)
save(f16, "web/favicon-16.png"); save(f32, "web/favicon-32.png"); save(f48, "web/favicon-48.png")
f48.save(os.path.join(KIT, "web/favicon.ico"), sizes=[(16, 16), (32, 32), (48, 48)], append_images=[f16, f32])
write("web/favicon.svg", svg(16, 16, paint(SMALL), "GYLT", scale=2))
save(raster(COACH, 5, size=(180, 180), bg=INK), "web/apple-touch-icon.png")
save(raster(COACH, 5, size=(192, 192), bg=INK), "web/icon-192.png")
save(raster(COACH, 14, size=(512, 512), bg=INK), "web/icon-512.png")
save(raster(COACH, 11, size=(512, 512), bg=INK), "web/maskable-512.png")   # inside the 80 % safe zone
write("web/site.webmanifest", json.dumps({
    "name": "GYLT — Get Your Life Together", "short_name": "GYLT",
    "icons": [
        {"src": "icon-192.png", "sizes": "192x192", "type": "image/png"},
        {"src": "icon-512.png", "sizes": "512x512", "type": "image/png"},
        {"src": "maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"},
    ],
    "theme_color": PAPER, "background_color": PAPER, "display": "standalone",
}, indent=2) + "\n")
write("web/head-snippet.html", "\n".join([
    '<link rel="icon" href="/favicon.ico" sizes="48x48">',
    '<link rel="icon" href="/favicon.svg" type="image/svg+xml">',
    '<link rel="apple-touch-icon" href="/apple-touch-icon.png">',
    '<link rel="manifest" href="/site.webmanifest">',
    f'<meta name="theme-color" content="{PAPER}">', ""]))
print("GYLT logo kit built:", KIT)
