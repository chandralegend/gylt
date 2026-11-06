#!/usr/bin/env python3
"""GYLT logo: Meadow Dusk. Marks are drawn as plain SVG shapes (no fonts), so they scale and recolour cleanly.

Run: python3 build_logo.py concepts   -> concepts board
     python3 build_logo.py kit        -> final kit (svg + png) for the chosen direction
Needs rsvg-convert (brew install librsvg) for the PNGs.
"""
import math, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
INK, INK2 = "#16141D", "#201D2A"
CREAM = "#F6F0E6"
LAV, LAV_DEEP, LAV_SOFT = "#B9A6F5", "#6F59C9", "#CDBEF8"
BUTTER, PEACH, BLOSSOM, SKY, MINT = "#F6D68B", "#F5B08B", "#F7A9D3", "#9DB6FF", "#9ADBB6"

# ---------------------------------------------------------------- wordmark (round strokes, one weight)
def wordmark(color, sw=13, h=60, gap=16, sun=None):
    """G Y L T drawn with round-capped strokes. Returns (svg group, width). Each letter sits in a box of height h."""
    r = h / 2 - sw / 2 + 1
    cx, cy = r + sw / 2, h / 2
    a0 = math.radians(-42)
    sx, sy = cx + r * math.cos(a0), cy + r * math.sin(a0)
    ex, ey = cx + r, cy
    G = (f'<path d="M{sx:.1f} {sy:.1f} A{r:.1f} {r:.1f} 0 1 0 {ex:.1f} {ey:.1f} H{cx + 2:.1f}" />', 2 * r + sw)
    w = 46
    Y = (f'<path d="M{sw/2:.1f} {sw/2:.1f} L{w/2:.1f} {h*0.52:.1f} L{w - sw/2:.1f} {sw/2:.1f} M{w/2:.1f} {h*0.52:.1f} V{h - sw/2:.1f}" />', w)
    L = (f'<path d="M{sw/2 + 4:.1f} {sw/2:.1f} V{h - sw/2:.1f} H{w - 2:.1f}" />', w)
    T = (f'<path d="M{sw/2:.1f} {sw/2:.1f} H{w - sw/2:.1f} M{w/2:.1f} {sw/2:.1f} V{h - sw/2:.1f}" />', w)
    x, parts = 0, []
    for shape, width in (G, Y, L, T):
        parts.append(f'<g transform="translate({x:.1f} 0)">{shape}</g>')
        x += width + gap
    total = x - gap
    group = f'<g fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round">{"".join(parts)}</g>'
    return group, total

# ---------------------------------------------------------------- marks
def dunes(clip_id, x0, x1, y0, y1, colors=(PEACH, BLOSSOM)):
    """Two layered hills filling the bottom of the box, clipped by `clip_id`."""
    w, h = x1 - x0, y1 - y0
    return (f'<g clip-path="url(#{clip_id})">'
            f'<path d="M{x0} {y0 + h*0.62:.1f} Q{x0 + w*0.3:.1f} {y0 + h*0.42:.1f} {x0 + w*0.6:.1f} {y0 + h*0.6:.1f} T{x1} {y0 + h*0.55:.1f} V{y1} H{x0}Z" fill="{colors[0]}"/>'
            f'<path d="M{x0} {y0 + h*0.8:.1f} Q{x0 + w*0.35:.1f} {y0 + h*0.62:.1f} {x0 + w*0.7:.1f} {y0 + h*0.8:.1f} T{x1} {y0 + h*0.76:.1f} V{y1} H{x0}Z" fill="{colors[1]}"/></g>')

def mark_doorway(body=LAV, sky=(SKY, BLOSSOM), **_):
    """A. The doorway: an arch with the meadow and a rising sun inside."""
    return f'''<defs>
<clipPath id="door"><path d="M82 196 V112 a38 38 0 0 1 76 0 V196 Z"/></clipPath>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{sky[0]}"/><stop offset="1" stop-color="{sky[1]}"/></linearGradient>
</defs>
<path d="M56 206 V108 a64 64 0 0 1 128 0 V206 Z" fill="{body}"/>
<path d="M82 196 V112 a38 38 0 0 1 76 0 V196 Z" fill="url(#sky)"/>
<circle cx="120" cy="140" r="21" fill="{BUTTER}" clip-path="url(#door)"/>
{dunes("door", 82, 158, 112, 196)}
'''

def mark_porthole(ring=LAV, **_):
    """B. The closing ring: a ring nearly closed around the meadow. The gap is what is left to do."""
    r, sw = 80, 20
    a0, a1 = math.radians(-70), math.radians(215)          # arc from -70deg clockwise to 215deg; gap at the top right
    sx, sy = 120 + r * math.cos(a0), 120 + r * math.sin(a0)
    ex, ey = 120 + r * math.cos(a1), 120 + r * math.sin(a1)
    return f'''<defs>
<clipPath id="port"><circle cx="120" cy="120" r="64"/></clipPath>
<linearGradient id="sky2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{LAV_SOFT}"/><stop offset="1" stop-color="{BLOSSOM}"/></linearGradient>
</defs>
<circle cx="120" cy="120" r="64" fill="url(#sky2)"/>
<circle cx="120" cy="108" r="22" fill="{BUTTER}" clip-path="url(#port)"/>
{dunes("port", 56, 184, 56, 184)}
<path d="M{sx:.1f} {sy:.1f} A{r} {r} 0 1 1 {ex:.1f} {ey:.1f}" fill="none" stroke="{ring}" stroke-width="{sw}" stroke-linecap="round"/>
<circle cx="{120 + r * math.cos(math.radians(-100)):.1f}" cy="{120 + r * math.sin(math.radians(-100)):.1f}" r="0" fill="none"/>'''

def mark_sunrise_g(body=LAV, **_):
    """C. The G: a round G whose centre is the sun, set on a dune."""
    r, sw = 72, 26
    a0 = math.radians(-38)
    sx, sy = 120 + r * math.cos(a0), 118 + r * math.sin(a0)
    return f'''<path d="M{sx:.1f} {sy:.1f} A{r} {r} 0 1 0 {120 + r} 118 H122" fill="none" stroke="{body}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="116" cy="114" r="20" fill="{BUTTER}"/>
<path d="M56 222 Q96 198 140 214 T196 208" fill="none" stroke="{PEACH}" stroke-width="10" stroke-linecap="round"/>'''

MARKS = {"A": ("Doorway", mark_doorway), "B": ("Closing ring", mark_porthole), "C": ("Sunrise G", mark_sunrise_g)}

# ---------------------------------------------------------------- assembly
def png(svg_path, png_path, width):
    subprocess.run(["rsvg-convert", "-w", str(width), "-o", png_path, svg_path], check=True)

MARK_BOX = (56, 44, 184, 206)          # the doorway's artwork bounds inside its 240 grid (x0, y0, x1, y1)

def mono_doorway(color):
    """One colour: the arch frame, the sun and one hill. Reads on any single-colour surface."""
    return (f'<path fill-rule="evenodd" fill="{color}" d="M56 206 V108 a64 64 0 0 1 128 0 V206 Z M82 196 V112 a38 38 0 0 1 76 0 V196 Z"/>'
            f'<circle cx="120" cy="142" r="17" fill="{color}"/>'
            f'<path d="M82 196 V176 Q104 160 124 176 T158 172 V196 Z" fill="{color}"/>')

def svg(w, h, body, bg=None, defs=""):
    rect = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{defs}{rect}{body}</svg>\n'

def place(fn, cx, cy, height, **kw):
    """Draw a mark so its artwork is centred on (cx, cy) with the given height."""
    x0, y0, x1, y1 = MARK_BOX
    k = height / (y1 - y0)
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    return f'<g transform="translate({cx - mx * k:.2f} {cy - my * k:.2f}) scale({k:.4f})">{fn(**kw)}</g>'

def icon_svg(fn=mark_doorway, size=1024):
    """The app icon: the doorway on a dusk gradient with a soft glow under it. Full bleed (iOS rounds the corners)."""
    defs = (f'<defs><linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2D2347"/><stop offset="0.55" stop-color="{INK}"/><stop offset="1" stop-color="#1A1426"/></linearGradient>'
            f'<radialGradient id="glow" cx="0.5" cy="0.78" r="0.55"><stop offset="0" stop-color="{PEACH}" stop-opacity="0.38"/><stop offset="1" stop-color="{PEACH}" stop-opacity="0"/></radialGradient></defs>')
    body = (f'<rect width="{size}" height="{size}" fill="url(#dusk)"/><rect width="{size}" height="{size}" fill="url(#glow)"/>'
            + place(fn, size / 2, size * 0.5, size * 0.60))
    return svg(size, size, body, defs=defs)

def wordmark_svg(color, sw=13):
    wm, ww = wordmark(color, sw=sw)
    pad = sw
    return svg(round(ww + 2 * pad), 60 + 2 * pad, f'<g transform="translate({pad} {pad})">{wm}</g>'), (ww, 60)

def lockup_svg(color, horizontal=True, bg=None):
    wm, ww = wordmark(color, sw=13)
    if horizontal:
        mh = 120
        s = 0.95
        body = place(mark_doorway, 70, 70, mh) + f'<g transform="translate(150 {70 - 30 * s:.1f}) scale({s})">{wm}</g>'
        return svg(round(150 + ww * s + 24), 140, body, bg=bg)
    s = 1.15
    body = place(mark_doorway, 200, 120, 190) + f'<g transform="translate({200 - ww * s / 2:.1f} 250) scale({s})">{wm}</g>'
    return svg(400, 340, body, bg=bg)

def mono_svg(color, bg=None):
    return svg(240, 240, place(lambda **_: mono_doorway(color), 120, 120, 170), bg=bg)

def kit():
    out = os.path.join(HERE, "kit"); os.makedirs(out, exist_ok=True)
    files = {
        "gylt-mark.svg": svg(240, 240, place(mark_doorway, 120, 120, 170)),
        "gylt-mark-mono-cream.svg": mono_svg(CREAM),
        "gylt-mark-mono-ink.svg": mono_svg(INK),
        "gylt-wordmark-cream.svg": wordmark_svg(CREAM)[0],
        "gylt-wordmark-ink.svg": wordmark_svg(INK)[0],
        "gylt-lockup-dark.svg": lockup_svg(CREAM, True),
        "gylt-lockup-light.svg": lockup_svg(INK, True),
        "gylt-stacked-dark.svg": lockup_svg(CREAM, False),
        "gylt-stacked-light.svg": lockup_svg(INK, False),
        "gylt-app-icon.svg": icon_svg(),
    }
    for name, content in files.items():
        open(os.path.join(out, name), "w").write(content)
    png(os.path.join(out, "gylt-app-icon.svg"), os.path.join(out, "gylt-app-icon-1024.png"), 1024)
    for n in ("gylt-mark", "gylt-lockup-dark", "gylt-lockup-light", "gylt-stacked-dark", "gylt-stacked-light"):
        png(os.path.join(out, n + ".svg"), os.path.join(out, n + ".png"), 1200 if "mark" not in n else 1024)
    # vector PDFs for the app's asset catalog (template wordmark, full-colour mark)
    for n in ("gylt-mark", "gylt-wordmark-ink"):
        subprocess.run(["rsvg-convert", "-f", "pdf", "-o", os.path.join(out, n + ".pdf"), os.path.join(out, n + ".svg")], check=True)
    # favicons and a social card
    for size, name in ((32, "favicon-32.png"), (180, "apple-touch-icon-180.png"), (512, "icon-512.png")):
        png(os.path.join(out, "gylt-app-icon.svg"), os.path.join(out, name), size)
    card = svg(1200, 630, f'<rect width="1200" height="630" fill="url(#d)"/>' + place(mark_doorway, 330, 315, 300)
               + f'<g transform="translate(520 235) scale(1.5)">{wordmark(CREAM)[0]}</g>'
               + f'<text x="522" y="402" font-family="Georgia, serif" font-size="40" font-weight="700" fill="{CREAM}">You said you would.</text>',
               defs=f'<defs><linearGradient id="d" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2D2347"/><stop offset="1" stop-color="{INK}"/></linearGradient></defs>')
    open(os.path.join(out, "gylt-social-card.svg"), "w").write(card)
    png(os.path.join(out, "gylt-social-card.svg"), os.path.join(out, "gylt-social-card.png"), 1200)
    print("kit:", ", ".join(sorted(os.listdir(out))))

def concepts():
    os.makedirs(os.path.join(HERE, "concepts"), exist_ok=True)
    W, H = 1500, 700
    out = [f'<rect width="{W}" height="{H}" fill="{INK}"/>']
    for i, (key, (name, fn)) in enumerate(MARKS.items()):
        x = 40 + i * 480
        out.append(f'<text x="{x}" y="52" font-family="Helvetica Neue, Arial" font-size="22" fill="{LAV}" font-weight="700">{key}  {name}</text>')
        out.append(f'<g transform="translate({x} 80)"><rect width="440" height="340" rx="28" fill="{INK2}"/><g transform="translate(100 50)">{fn()}</g></g>')
        out.append(f'<g transform="translate({x} 436)"><rect width="440" height="200" rx="28" fill="{CREAM}"/><g transform="translate(24 24) scale(0.66)">{fn()}</g>')
        wm, ww = wordmark(INK, sw=14)
        out.append(f'<g transform="translate(190 78) scale(0.8)">{wm}</g></g>')
    path = os.path.join(HERE, "concepts", "board.svg")
    open(path, "w").write(svg(W, H, "".join(out)))
    png(path, os.path.join(HERE, "concepts", "board.png"), 1500)

if __name__ == "__main__":
    {"concepts": concepts, "kit": kit}.get(sys.argv[1] if len(sys.argv) > 1 else "kit", kit)()
