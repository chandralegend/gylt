#!/usr/bin/env python3
"""Generate the GYLT screens canvas (Claude Design artifact) from the pixel design tokens.

    python3 build_canvas.py <canvas-root> [heights.json]

Writes <canvas-root>/project/*.dc.html + canvas.json, and preview.html next to this script
(local images, measurable heights). Icons: pixelarticons 1.8.1 (MIT).
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = sys.argv[1]
HEIGHTS = json.load(open(sys.argv[2])) if len(sys.argv) > 2 else {}
ICON_DIR = os.path.join(HERE, "icons")

BLOB = {"coach": "/_blob/89e23db533de83381c3fb725d2f4f829", "pleased": "/_blob/cf23cbd88c4c28699bf590d180c3061d",
        "sneaker": "/_blob/399de6c73ed993a5e4beff8d83aa4d26"}
LOCAL = {"coach": "../Logo-Kit/svg/gylt-coach.svg", "pleased": "../Logo-Kit/svg/gylt-coach-pleased.svg",
         "sneaker": "../../04-Prototype/dist/assets/stride-pixel.svg"}

# ------------------------------------------------------------------ tokens
ACC = "{{accent}}"
LIGHT = dict(bg="#F5F4F0", surface="#FFFFFF", fill="#ECEBE6", fill2="#E2E1DB", label="#1C1B18", label2="#64635C",
             label3="#8F8E86", sep="#E4E3DD", accentText="#C23F20", accentSoft="#FFE6DE", sheet="#F5F4F0", sheetGroup="#FFFFFF")
DARK = dict(bg="#141412", surface="#1F1E1B", fill="#2A2925", fill2="#34332E", label="#F4F3EF", label2="#A6A59D",
            label3="#6F6E67", sep="#2F2E2A", accentText="#FF8A70", accentSoft="#3A2520", sheet="#1E1D1A", sheetGroup="#2A2925")
SHADE, ON_ACC, ON_ACC2, INK = "#C23F20", "#1C1B18", "#4A2117", "#1C1B18"
UI = "font-family: 'Geist Mono', ui-monospace, monospace"
DISP = "font-family: 'Jersey 25', 'Geist Mono', monospace; font-weight: 400"

def poly(c, top_only=False):
    """Stepped pixel corner; c = corner size in px (4, 8 or 12)."""
    if c == 4:
        tl = "0 4px, 4px 4px, 4px 0"; tr = "calc(100% - 4px) 0, calc(100% - 4px) 4px, 100% 4px"
        br = "100% calc(100% - 4px), calc(100% - 4px) calc(100% - 4px), calc(100% - 4px) 100%"; bl = "4px 100%, 4px calc(100% - 4px), 0 calc(100% - 4px)"
    else:
        s = 8 if c == 8 else 12
        tl = f"0 {s}px, 4px {s}px, 4px 4px, {s}px 4px, {s}px 0"
        tr = f"calc(100% - {s}px) 0, calc(100% - {s}px) 4px, calc(100% - 4px) 4px, calc(100% - 4px) {s}px, 100% {s}px"
        br = f"100% calc(100% - {s}px), calc(100% - 4px) calc(100% - {s}px), calc(100% - 4px) calc(100% - 4px), calc(100% - {s}px) calc(100% - 4px), calc(100% - {s}px) 100%"
        bl = f"{s}px 100%, {s}px calc(100% - 4px), 4px calc(100% - 4px), 4px calc(100% - {s}px), 0 calc(100% - {s}px)"
    if top_only:
        return f"clip-path: polygon({tl}, {tr}, 100% 100%, 0 100%)"
    return f"clip-path: polygon({tl}, {tr}, {br}, {bl})"
PX_S, PX_M, PX_L = poly(4), poly(8), poly(12)
PX_O = "clip-path: polygon(0 30%, 10% 30%, 10% 10%, 30% 10%, 30% 0, 70% 0, 70% 10%, 90% 10%, 90% 30%, 100% 30%, 100% 70%, 90% 70%, 90% 90%, 70% 90%, 70% 100%, 30% 100%, 30% 90%, 10% 90%, 10% 70%, 0 70%)"

# ------------------------------------------------------------------ icons
PX = {}
for f in os.listdir(ICON_DIR):
    if f.endswith(".svg"):
        PX[f[:-4]] = " ".join(re.findall(r'\bd="([^"]+)"', open(os.path.join(ICON_DIR, f)).read()))
ALIAS = {"arrow": "arrow-right", "chevron": "chevron-right", "back": "chevron-left", "plan": "calendar", "coach": "headphone",
         "chart": "chart-bar", "unlock": "lock-open", "walk": "human-run", "sound": "volume-3", "mute": "volume-x", "spark": "zap",
         "settings": "sliders", "instagram": "camera", "tiktok": "music", "youtube": "video", "refresh": "reload", "key": "lock",
         "info": "info-box", "leaf": "heart"}
def ic(name, size=24, color="currentColor"):
    d = PX[ALIAS.get(name, name)]
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" shape-rendering="crispEdges" aria-hidden="true" '
            f'style="display: block; flex-shrink: 0"><path fill="{color}" d="{d}"></path></svg>')

WORD = ["", "", "", "", "", "", "", "", ""]
LET = {"G": [".#####.", "##...##", "##.....", "##.....", "##.####", "##...##", "##...##", "##...##", ".#####."],
       "Y": ["##....##", "##....##", ".##..##.", "..####..", "...##...", "...##...", "...##...", "...##...", "...##..."],
       "L": ["##.....", "##.....", "##.....", "##.....", "##.....", "##.....", "##.....", "#######", "#######"],
       "T": ["########", "########", "...##...", "...##...", "...##...", "...##...", "...##...", "...##...", "...##..."]}
for i, ch in enumerate("GYLT"):
    for y in range(9):
        WORD[y] += (".." if i else "") + LET[ch][y]
def runs(grid):
    d = []
    for y, row in enumerate(grid):
        x = 0
        while x < len(row):
            if row[x] == "#":
                s = x
                while x < len(row) and row[x] == "#": x += 1
                d.append(f"M{s} {y}h{x-s}v1h{s-x}z")
            else: x += 1
    return "".join(d)
WORD_D = runs(WORD)
def wordmark(scale, color):
    return (f'<svg width="{36*scale}" height="{9*scale}" viewBox="0 0 36 9" shape-rendering="crispEdges" role="img" aria-label="GYLT" '
            f'style="display: block"><path fill="{color}" d="{WORD_D}"></path></svg>')

# ------------------------------------------------------------------ components
def btn(label, kind, t, href=None, arrow=True, center=False):
    base = (f"display: flex; align-items: center; gap: 8px; min-height: 52px; padding: 0 24px; box-sizing: border-box; width: 100%; "
            f"font-size: 17px; font-weight: 600; {UI}; text-decoration: none; border: 0; cursor: pointer; {PX_M}; "
            f"justify-content: {'center' if center or not arrow else 'space-between'}")
    if kind == "accent":
        st = f"{base}; background: {ACC}; color: {ON_ACC}; box-shadow: inset 0 -4px 0 {SHADE}"
    elif kind == "ink":
        st = f"{base}; background: {INK}; color: #F5F4F0; box-shadow: inset 0 -4px 0 #000000"
    elif kind == "secondary":
        st = f"{base}; background: {t['fill']}; color: {t['label']}; box-shadow: inset 0 -4px 0 {t['fill2']}"
    else:  # plain
        st = (f"display: flex; align-items: center; justify-content: center; min-height: 44px; width: 100%; font-size: 15px; "
              f"font-weight: 500; {UI}; color: {t['label2']}; background: transparent; border: 0; text-decoration: none; cursor: pointer")
    inner = f"<span>{label}</span>" + (ic("arrow", 24) if arrow and kind != "plain" else "")
    if href:
        return f'<a href="{href}" style="{st}">{inner}</a>'
    return f'<button type="button" style="{st}">{inner}</button>'

def icon_btn(name, t, label, href=None, size=44):
    st = (f"width: {size}px; height: {size}px; display: flex; align-items: center; justify-content: center; background: {t['fill']}; "
          f"color: {t['label']}; border: 0; padding: 0; {PX_O}; flex-shrink: 0; text-decoration: none; cursor: pointer")
    if href:
        return f'<a href="{href}" aria-label="{label}" style="{st}">{ic(name, 24)}</a>'
    return f'<button type="button" aria-label="{label}" style="{st}">{ic(name, 24)}</button>'

def tile(name, t, accent=False):
    bg = ACC if accent else t["fill"]; fg = ON_ACC if accent else t["label"]
    return (f'<span style="width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; background: {bg}; '
            f'color: {fg}; flex-shrink: 0; {PX_S}">{ic(name, 24)}</span>')

BRAND = {  # third-party app icons stay as normal smooth icons (not pixelated)
    "instagram": ("linear-gradient(40deg, #FCA95C, #E0647E 50%, #9D69C3)", '<rect x="3" y="3" width="18" height="18" rx="5"></rect><circle cx="12" cy="12" r="4"></circle><circle cx="17.5" cy="6.5" r=".7" fill="currentColor" stroke="none"></circle>'),
    "tiktok": ("#111111", '<path d="M14 3v12a4 4 0 1 1-4-4m4-8c0 4 3 6 6 6" stroke-width="2.7"></path>'),
    "youtube": ("#E8453C", '<rect x="2" y="5" width="20" height="14" rx="4"></rect><path d="m10 9 5 3-5 3z" fill="currentColor" stroke="none"></path>'),
}
def brand_svg(name, size):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" '
            f'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="display: block; flex-shrink: 0">{BRAND[name][1]}</svg>')

def badge(name, size=28):
    return (f'<span style="width: {size}px; height: {size}px; display: flex; align-items: center; justify-content: center; background: {BRAND[name][0]}; '
            f'color: #FFFFFF; border-radius: {round(size * 0.3)}px; margin-left: -6px; box-shadow: 0 0 0 2px #FFFFFF">{brand_svg(name, 16)}</span>')

def row(t, icon_name, title, sub="", end="", chevron=False, done=False, href=None, first=False):
    sep = "" if first else (f"background-image: repeating-linear-gradient(90deg, {t['sep']} 0 4px, transparent 4px 8px); "
                            "background-size: calc(100% - 64px) 2px; background-repeat: no-repeat; background-position: 64px 0")
    st = (f"display: flex; align-items: center; gap: 12px; min-height: 60px; padding: 10px 16px; box-sizing: border-box; "
          f"width: 100%; text-decoration: none; color: {t['label']}; text-align: left; {sep}")
    strike = f"color: {t['label2']}; text-decoration: line-through" if done else ""
    body = (tile(icon_name, t) +
            f'<span style="flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px">'
            f'<span style="font-size: 17px; line-height: 22px; font-weight: 500; {strike}">{title}</span>'
            + (f'<span style="font-size: 13px; line-height: 18px; color: {t["label2"]}">{sub}</span>' if sub else "") +
            "</span>")
    if end or chevron:
        body += (f'<span style="display: flex; align-items: center; gap: 4px; font-size: 15px; color: {t["label2"]}">{end}'
                 + (f'<span style="color: {t["label3"]}">{ic("chevron", 12)}</span>' if chevron else "") + "</span>")
    if href:
        return f'<a href="{href}" style="{st}">{body}</a>'
    return f'<div style="{st}">{body}</div>'

def group(t, rows, extra=""):
    return f'<div style="background: {t["surface"]}; box-shadow: inset 0 0 0 2px {t["sep"]}; {PX_L}; {extra}">{"".join(rows)}</div>'

def section_head(t, title, right=""):
    return (f'<div style="display: flex; align-items: center; justify-content: space-between; margin: 28px 0 8px">'
            f'<h2 style="margin: 0; font-size: 30px; line-height: 28px; {DISP}">{title}</h2>{right}</div>')

def label(t, text, top=28):
    return f'<p style="margin: {top}px 4px 8px; font-size: 13px; line-height: 18px; font-weight: 500; color: {t["label2"]}">{text}</p>'

def footnote(t, text, margin="8px 16px 0"):
    return f'<p style="margin: {margin}; font-size: 13px; line-height: 18px; color: {t["label2"]}">{text}</p>'

def large_title(t, title, action_icon, action_label, href=None):
    return (f'<header style="display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 8px 0 4px">'
            f'<h1 style="margin: 0; font-size: 48px; line-height: 44px; {DISP}">{title}</h1>{icon_btn(action_icon, t, action_label, href)}</header>')

def tabbar(t, active):
    items = [("Main.dc.html", "home", "Today"), ("Plan.dc.html", "plan", "Plan"), ("Coach.dc.html", "coach", "Coach"), ("Progress.dc.html", "chart", "You")]
    out = []
    for href, name, text in items:
        on = text.lower() == active
        col = t["label"] if on else t["label3"]
        out.append(f'<a href="{href}" style="display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; '
                   f'min-width: 64px; min-height: 48px; font-size: 11px; font-weight: {600 if on else 500}; color: {col}; text-decoration: none"'
                   + (' aria-current="page"' if on else "") + f">{ic(name, 24)}<span>{text}</span></a>")
    return (f'<nav aria-label="App navigation" style="display: flex; justify-content: space-around; padding: 6px 8px 28px; '
            f'background: {t["bg"]}; border-top: 2px solid {t["sep"]}; flex-shrink: 0; margin-top: auto">{"".join(out)}</nav>')

def wave(color):
    hs = [8, 12, 20, 12, 20, 16, 8, 20, 12, 20, 8, 16, 8, 12, 20, 8, 20, 12]
    return ('<span style="flex: 1; display: flex; gap: 3px; align-items: center; justify-content: center; height: 20px">'
            + "".join(f'<span style="width: 4px; height: {h}px; background: {color}"></span>' for h in hs) + "</span>")

def voice_btn(t, text):
    return (f'<button type="button" style="display: flex; align-items: center; gap: 12px; width: 100%; min-height: 52px; padding: 0 16px 0 8px; '
            f'box-sizing: border-box; background: {t["fill"]}; color: {t["label"]}; border: 0; {PX_M}; {UI}; cursor: pointer">'
            f'<span style="width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; background: {ACC}; color: {ON_ACC}; {PX_O}">{ic("play", 24)}</span>'
            f'{wave(t["label2"])}<span style="font-size: 13px; color: {t["label2"]}">{text}</span></button>')

def ring(frac):
    N, c = 34, 17
    track, prog = [], []
    import math
    for y in range(N):
        for x in range(N):
            dx, dy = x + .5 - c, y + .5 - c
            d = math.hypot(dx, dy)
            if 14.6 <= d <= 16.6:
                a = math.atan2(dx, -dy)
                if a < 0: a += 2 * math.pi
                (prog if a / (2 * math.pi) < frac else track).append(f"M{x} {y}h1v1h-1z")
    return (f'<svg width="272" height="272" viewBox="0 0 34 34" shape-rendering="crispEdges" aria-hidden="true" style="display: block">'
            f'<path fill="{DARK["fill"]}" d="{"".join(track)}"></path><path fill="{ACC}" d="{"".join(prog)}"></path></svg>')

# ------------------------------------------------------------------ page shell
FONT = '<link href="https://fonts.googleapis.com/css2?family=Jersey+25&amp;family=Geist+Mono:wght@400..700&amp;display=swap" rel="stylesheet">'
def page(title, t, inner, height, tab=None, pad="16px 20px 32px"):
    h = f"height: {height}px; " if height else ""
    content = f'<div style="flex: 1; display: flex; flex-direction: column; padding: {pad}; box-sizing: border-box">{inner}</div>'
    root = (f'<div style="width: 390px; {h}box-sizing: border-box; display: flex; flex-direction: column; overflow: hidden; '
            f'background: {t["bg"]}; color: {t["label"]}; {UI}">{content}{tabbar(t, tab) if tab else ""}</div>')
    return title, root

def dc_file(title, root, height):
    props = json.dumps({"accent": {"editor": "color", "default": "#FF6548", "options": ["#FF6548", "#1C1B18", "#2F6BFF"]},
                        "$preview": {"width": 390, "height": height}}).replace("'", "&#39;")
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>GYLT — {title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
{FONT}
<style>
body{{margin:0}}
a{{color:#C23F20}}a:hover{{color:#1C1B18}}
</style>
</helmet>
{root}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{props}'>
class Component extends DCLogic {{
renderVals() {{
return {{ accent: this.props.accent ?? '#FF6548' }};
}}
}}
</script>
</body>
</html>
"""

# ------------------------------------------------------------------ screens
L, D = LIGHT, DARK
def img(key, w, h, extra=""):
    return f'<img src="@@{key}@@" alt="" width="{w}" height="{h}" style="display: block; image-rendering: pixelated; {extra}">'

def today():
    t = L
    days = []
    for i, d in enumerate("MTWTFSS"):
        if i < 4: dot = f'background: {t["fill"]}; color: {t["label"]}'; content = ic("check", 12)
        elif i == 4: dot = f'background: {t["label"]}; color: {t["bg"]}'; content = "6"
        else: dot = f'background: transparent; color: {t["label2"]}; box-shadow: inset 0 0 0 2px {t["sep"]}'; content = str(i + 2)
        days.append(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 6px; font-size: 12px; font-weight: 500; color: {t["label"] if i == 4 else t["label3"]}">'
                    f'<span>{d}</span><span style="width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; font-size: 15px; font-weight: 600; {dot}; {PX_O}">{content}</span></div>')
    hero = (f'<article style="position: relative; overflow: hidden; padding: 20px; min-height: 244px; box-sizing: border-box; background: {ACC}; color: {ON_ACC}; '
            f'display: flex; flex-direction: column; {PX_L}">'
            f'<p style="margin: 0; font-size: 13px; font-weight: 600; color: {ON_ACC2}; display: flex; align-items: center; gap: 6px">'
            f'<span style="width: 6px; height: 6px; background: {ON_ACC2}"></span>Up next · 6:30 PM</p>'
            f'<h2 style="margin: 12px 0 0; font-size: 44px; line-height: .9; {DISP}; position: relative; z-index: 1">Get off<br>the couch.</h2>'
            f'<p style="margin: 8px 0 0; font-size: 15px; color: {ON_ACC2}; position: relative; z-index: 1">Evening walk · 20 min</p>'
            + img("sneaker", 216, 90, "position: absolute; right: -16px; top: 64px") +
            f'<div style="margin-top: auto; padding-top: 20px; position: relative; z-index: 1">{btn("Let’s go", "ink", t, "Intervention.dc.html")}</div></article>')
    apps = '<span style="display: flex; margin-right: 4px">' + badge("instagram") + badge("tiktok") + badge("youtube") + "</span>"
    inner = (f'<div style="display: flex; align-items: center; justify-content: space-between; margin: 4px 0 20px">{wordmark(3, t["label"])}'
             f'<a href="Progress.dc.html" aria-label="Your progress" style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; '
             f'background: {t["fill"]}; color: {t["label"]}; font-size: 17px; font-weight: 600; text-decoration: none; {PX_O}">C</a></div>'
             f'<p style="margin: 0 0 4px; font-size: 15px; color: {t["label2"]}">Friday, November 6</p>'
             f'<h1 style="margin: 0; font-size: 56px; line-height: .92; {DISP}">You said<br>you would<span style="color: {ACC}">.</span></h1>'
             f'<div style="display: flex; justify-content: space-between; margin: 24px 0">{"".join(days)}</div>'
             + hero +
             f'<div style="margin-top: 12px">{group(t, [row(t, "shield", "3 apps paused", "When you start", apps, True, href="Blocked.dc.html", first=True)])}</div>'
             + section_head(t, "Rest of today", f'<a href="Plan.dc.html" style="font-size: 15px; font-weight: 500; color: {t["accentText"]}; text-decoration: none; display: flex; align-items: center; gap: 2px; min-height: 44px">1 of 3 done{ic("chevron", 12)}</a>')
             + group(t, [row(t, "bed", "Make your bed", "Done before the first scroll", f'<span style="width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; background: {t["label"]}; color: {t["bg"]}; {PX_O}">{ic("check", 12)}</span>', done=True, first=True),
                         row(t, "moon", "Call it a night", "Screens off. Tomorrow can wait.", "10:30 PM", True)]))
    return page("Today", t, inner, HEIGHTS.get("Main"), tab="today")

def topbar(t, middle, left=("close", "Change the plan", "SheetChangePlan.dc.html")):
    return (f'<div style="display: flex; align-items: center; justify-content: space-between; gap: 12px; min-height: 44px">'
            f'{icon_btn(left[0], t, left[1], left[2])}{middle}{icon_btn("mute", t, "Turn on coach audio")}</div>')

def ticket(t, rows):
    return f'<div style="background: {t["surface"]}; {PX_L}">{"".join(rows)}</div>'

def intervention():
    t = D
    inner = (topbar(t, f'<span style="flex: 1; text-align: center; font-size: 17px; font-weight: 600">Evening walk</span>')
             + f'<div style="display: flex; justify-content: center; margin-top: 16px">{img("coach", 120, 145)}</div>'
             + f'<div style="text-align: center; margin-top: 16px"><h1 style="margin: 0; font-size: 64px; line-height: .9; {DISP}">Shoes. Keys.<br><span style="color: {ACC}">Outside.</span></h1>'
             + f'<p style="margin: 12px auto 0; max-width: 300px; font-size: 17px; line-height: 23px; color: {t["label2"]}">You hired me for exactly this moment. Shoes on. Let’s go.</p></div>'
             + f'<div style="margin: 20px 0 12px">{voice_btn(t, "Hear coach")}</div>'
             + ticket(t, [row(t, "walk", "20-minute walk", end="Your promise", first=True), row(t, "shield", "3 apps paused", end="Until 7:00 PM")])
             + f'<div style="margin-top: auto; padding-top: 20px; display: flex; flex-direction: column; gap: 12px">'
             + btn("Let’s go", "accent", t, "Session.dc.html") + btn("Do the 5-minute version", "secondary", t, arrow=False)
             + btn("Change the plan", "plain", t, "SheetChangePlan.dc.html") + "</div>")
    return page("Intervention", t, inner, 844, pad="12px 20px 28px")

def session():
    t = D
    def control(content, text, primary=False, href=None, label_=None):
        size = 84 if primary else 72
        bg = ACC if primary else t["fill"]; fg = ON_ACC if primary else t["label"]
        sh = f"box-shadow: inset 0 -6px 0 {SHADE}; " if primary else ""
        circle = (f'<span style="width: {size}px; height: {size}px; display: flex; align-items: center; justify-content: center; background: {bg}; color: {fg}; '
                  f'{sh}font-size: 17px; font-weight: 600; {PX_O}{"; margin-top: -6px" if primary else ""}">{content}</span>')
        st = (f"display: flex; flex-direction: column; align-items: center; gap: 8px; width: 88px; font-size: 13px; font-weight: 500; "
              f"color: {t['label'] if primary else t['label2']}; text-decoration: none; background: transparent; border: 0; padding: 0; {UI}; cursor: pointer")
        aria = f' aria-label="{label_}"' if label_ else ""
        if href:
            return f'<a href="{href}"{aria} style="{st}">{circle}{text}</a>'
        return f'<button type="button"{aria} style="{st}">{circle}{text}</button>'
    pill = (f'<a href="Blocked.dc.html" style="display: flex; align-items: center; gap: 6px; min-height: 32px; padding: 0 12px; background: {t["fill"]}; '
            f'color: {t["label"]}; font-size: 13px; font-weight: 600; text-decoration: none; {PX_M}">{ic("shield", 12)}3 apps paused</a>')
    inner = (topbar(t, f'<span style="flex: 1; display: flex; justify-content: center">{pill}</span>')
             + f'<div style="text-align: center; margin-top: 20px"><p style="margin: 0; font-size: 32px; line-height: 30px; {DISP}">One foot, then the other.</p>'
             + f'<p style="margin: 4px 0 0; font-size: 15px; color: {t["label2"]}">Evening walk · 20 min</p></div>'
             + f'<div style="position: relative; width: 272px; height: 272px; align-self: center; margin: 24px 0 16px">{ring(0.72)}'
             + f'<div role="timer" style="position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center">'
             + f'<span style="font-size: 72px; line-height: .9; {DISP}; font-variant-numeric: tabular-nums">14:24</span>'
             + f'<span style="font-size: 15px; color: {t["label2"]}; margin-top: 8px">of 20 min</span></div></div>'
             + f'<p style="margin: 0 auto; max-width: 300px; text-align: center; font-size: 17px; line-height: 23px; color: {t["label2"]}">'
             + f'<span style="display: block; font-size: 13px; font-weight: 600; color: {t["label3"]}; margin-bottom: 4px">The Coach</span>“Good. You’re moving. I’ll leave you to it.”</p>'
             + f'<div style="display: flex; align-items: flex-start; justify-content: space-between; margin-top: auto; padding: 24px 4px 4px">'
             + control('5<span style="font-size: 11px">m</span>', "Minimum", label_="Switch to the minimum")
             + control(ic("pause", 24), "Pause", primary=True)
             + control(ic("check", 24), "Finish", href="SheetFinish.dc.html") + "</div>"
             + f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; padding-top: 12px">{btn("I’m stuck", "plain", t)}'
             + f'<p style="margin: 0; display: flex; align-items: center; gap: 6px; font-size: 13px; color: {t["label2"]}">{ic("lock", 12)}Apps open at 7:00 PM, or when you finish.</p></div>')
    return page("Session", t, inner, 844, pad="12px 20px 28px")

def blocked():
    t = D
    inner = (f'<p style="margin: 0; min-height: 44px; display: flex; align-items: center; justify-content: center; gap: 6px; font-size: 13px; font-weight: 600; color: {t["label2"]}">'
             f'{ic("shield", 12)}GYLT is holding the line</p>'
             + f'<div style="position: relative; width: 88px; height: 88px; margin: 40px auto 28px; background: linear-gradient(30deg, #FDA766, #E4546F 48%, #A157D1); color: #FFFFFF; display: flex; align-items: center; justify-content: center; border-radius: 20px">{brand_svg("instagram", 44)}'
             + f'<span style="position: absolute; right: -10px; bottom: -10px; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; background: #F4F3EF; color: #1C1B18; box-shadow: 0 0 0 4px #141412; {PX_O}">{ic("lock", 24)}</span></div>'
             + f'<div style="text-align: center"><h1 style="margin: 0; font-size: 60px; line-height: .9; {DISP}">The feed<br>can wait<span style="color: {ACC}">.</span></h1>'
             + f'<p style="margin: 12px auto 0; max-width: 290px; font-size: 17px; line-height: 23px; color: {t["label2"]}">You chose this time for yourself. Let’s keep that promise.</p></div>'
             + f'<div style="margin-top: 28px">' + ticket(t, [row(t, "walk", "Evening walk", end="20 min", first=True),
                                                         row(t, "clock", "Instagram opens", "Or as soon as you finish", "by 7:00 PM")]) + "</div>"
             + f'<div style="margin-top: auto; padding-top: 20px; display: flex; flex-direction: column; gap: 12px">'
             + btn("Back to my walk", "accent", t, "Session.dc.html") + btn("Do the 5-minute version", "secondary", t, arrow=False)
             + btn("Change the plan", "plain", t, "SheetChangePlan.dc.html")
             + f'<p style="margin: 0; text-align: center; font-size: 13px; color: {t["label2"]}">You set this rule. You’re still in control.</p></div>')
    return page("App block", t, inner, 844, pad="12px 20px 28px")

def complete():
    t = L
    pill = (f'<span style="display: flex; align-items: center; gap: 6px; min-height: 32px; padding: 0 12px; background: {t["accentSoft"]}; color: {t["accentText"]}; '
            f'font-size: 13px; font-weight: 600; {PX_M}">{ic("check", 12)}Minimum kept</span>')
    stat = lambda big, small_, unit="": (f'<div><p style="margin: 0; font-size: 44px; line-height: 40px; {DISP}">{big}'
                                         + (f'<span style="font-size: 24px; color: {t["label2"]}"> {unit}</span>' if unit else "")
                                         + f'</p><p style="margin: 2px 0 0; font-size: 13px; color: {t["label2"]}">{small_}</p></div>')
    inner = (f'<div style="display: flex; align-items: center; justify-content: space-between; margin-top: 4px">{wordmark(3, t["label"])}{pill}</div>'
             + f'<div style="display: flex; justify-content: center; margin: 28px 0 24px">{img("pleased", 120, 145)}</div>'
             + f'<div style="text-align: center"><h1 style="margin: 0; font-size: 56px; line-height: .92; {DISP}">You<br>showed up<span style="color: {ACC}">.</span></h1>'
             + f'<p style="margin: 12px auto 0; max-width: 300px; font-size: 17px; line-height: 23px; color: {t["label2"]}">5 minutes beats “I’ll do it tomorrow.” The minimum counts.</p>'
             + f'<div style="display: flex; justify-content: center; gap: 40px; margin: 28px 0 24px">{stat("5", "Out in the world", "min")}{stat("1", "Promise kept")}</div></div>'
             + group(t, [row(t, "unlock", "Apps released", "Your selected apps are available again.", first=True)])
             + f'<div style="margin-top: auto; padding-top: 20px; display: flex; flex-direction: column; gap: 12px">'
             + btn("Back to today", "ink", t, "Main.dc.html") + btn("Give me five more", "plain", t, "Session.dc.html")
             + f'<p style="margin: 0; text-align: center; font-size: 13px; color: {t["label2"]}">Walk completion · Self-reported</p></div>')
    return page("Complete", t, inner, 844, pad="12px 20px 28px")

def chips(t, items):
    return ('<div style="display: flex; gap: 6px; flex-wrap: wrap">' + "".join(
        f'<span style="min-height: 28px; display: flex; align-items: center; padding: 0 10px; background: {t["fill"]}; font-size: 13px; font-weight: 500; {PX_M}">{c}</span>' for c in items) + "</div>")

def card(t, icon_name, title, desc, chip_items, accent=False):
    return (f'<div style="background: {t["surface"]}; box-shadow: inset 0 0 0 2px {t["sep"]}; padding: 16px; {PX_L}">'
            f'<div style="display: flex; align-items: center; gap: 12px">{tile(icon_name, t, accent)}'
            f'<strong style="flex: 1; font-size: 17px; font-weight: 600">{title}</strong><span style="color: {t["label3"]}">{ic("chevron", 12)}</span></div>'
            f'<p style="margin: 10px 0 14px; font-size: 15px; line-height: 20px; color: {t["label2"]}">{desc}</p>{chips(t, chip_items)}</div>')

def plan():
    t = L
    switch = (f'<button type="button" role="switch" aria-checked="true" aria-label="Pause distractions during commitments" '
              f'style="position: relative; width: 52px; height: 32px; background: {ACC}; border: 0; padding: 0; flex-shrink: 0; {PX_S}">'
              f'<span style="position: absolute; left: 24px; top: 4px; width: 24px; height: 24px; background: #FFFFFF; {PX_S}"></span></button>')
    apps = '<span style="display: flex; margin-right: 4px">' + badge("instagram", 26) + badge("tiktok", 26) + badge("youtube", 26) + "</span>"
    sw_row = (f'<div style="display: flex; align-items: center; gap: 12px; min-height: 60px; padding: 10px 16px">{tile("shield", t)}'
              f'<span style="flex: 1; display: flex; flex-direction: column; gap: 2px"><span style="font-size: 17px; font-weight: 500">Pause distractions</span>'
              f'<span style="font-size: 13px; color: {t["label2"]}">Only during a commitment</span></span>{switch}</div>')
    inner = (large_title(t, "Promises", "plus", "Add a commitment")
             + f'<p style="margin: 4px 0 24px; font-size: 15px; line-height: 20px; color: {t["label2"]}">Keep it real. Give yourself a way to follow through.</p>'
             + f'<div style="display: flex; flex-direction: column; gap: 12px">'
             + card(t, "walk", "Evening walk", "A little fresh air before the evening disappears.", ["6:30 PM", "20 min", "5 min minimum"], accent=True)
             + card(t, "moon", "Call it a night", "A quieter end to the day.", ["10:30 PM", "Every day"]) + "</div>"
             + label(t, "Protect your time")
             + group(t, [sw_row, row(t, "lock", "Selected apps", "3 apps · essentials open", apps, True)])
             + footnote(t, "Every session has an end time. You can always pause or change the plan."))
    return page("Plan", t, inner, HEIGHTS.get("Plan"), tab="plan")

def coach():
    t = L
    seg = ""
    for name in ("Calm", "Direct", "Savage"):
        on = name == "Direct"
        st = (f"flex: 1; min-height: 38px; border: 0; font-size: 15px; {UI}; font-weight: {600 if on else 500}; "
              f"color: {t['label'] if on else t['label2']}; background: {t['surface'] if on else 'transparent'}; "
              + (f"box-shadow: inset 0 0 0 2px {t['sep']}; " if on else "") + PX_M)
        seg += f'<button type="button" aria-pressed="{str(on).lower()}" style="{st}">{name}</button>'
    hero = (f'<div style="position: relative; background: {t["surface"]}; box-shadow: inset 0 0 0 2px {t["sep"]}; padding: 20px; {PX_L}">'
            f'<p style="margin: 0; font-size: 13px; font-weight: 500; color: {t["label2"]}">Your accountability partner</p>'
            f'<h2 style="margin: 2px 0 0; font-size: 40px; line-height: 36px; {DISP}">The Coach</h2>'
            f'<p style="margin: 2px 0 0; font-size: 15px; color: {t["label2"]}">Firm. On your side.</p>'
            + img("coach", 72, 87, "position: absolute; right: 20px; top: 20px") +
            f'<p style="margin: 24px 0 16px; max-width: 280px; font-size: 20px; line-height: 26px; font-weight: 600">“You said you would. I’m here to help you mean it.”</p>'
            f'{voice_btn(t, "Device voice")}</div>')
    inner = (large_title(t, "Coach", "settings", "Settings")
             + f'<p style="margin: 4px 0 24px; font-size: 15px; line-height: 20px; color: {t["label2"]}">A little attitude. A lot of follow-through.</p>'
             + hero + label(t, "How should I talk to you?")
             + f'<div role="group" aria-label="Coach tone" style="display: flex; gap: 2px; padding: 3px; background: {t["fill"]}; {PX_M}">{seg}</div>'
             + footnote(t, "The attitude changes. Your boundaries don’t.")
             + label(t, "Make it yours")
             + group(t, [row(t, "coach", "Personality", end="The Coach", chevron=True, first=True), row(t, "sound", "Voice", end="Device voice", chevron=True),
                         row(t, "key", "AI &amp; voice keys", "Your providers. Your choice.", chevron=True)])
             + f'<div style="display: flex; justify-content: center; margin-top: 20px"><a href="#" style="display: flex; align-items: center; gap: 6px; min-height: 44px; font-size: 15px; '
               f'font-weight: 500; color: {t["accentText"]}; text-decoration: none">{ic("shield", 24)}What your coach can and can’t do</a></div>')
    return page("Coach", t, inner, HEIGHTS.get("Coach"), tab="coach")

def progress():
    t = L
    vals = [65, 90, 100, 90, 40, 0, 0]
    bars = "".join(f'<div style="flex: 1; height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: flex-end; gap: 8px; font-size: 12px; font-weight: 500; color: {t["label2"]}">'
                   f'<span style="width: 100%; max-width: 28px; height: {max(v, 4)}%; background: {ACC if i == 4 else t["fill2"]}; {PX_S}"></span><span>{"MTWTFSS"[i]}</span></div>'
                   for i, v in enumerate(vals))
    summary = (f'<div style="background: {t["surface"]}; box-shadow: inset 0 0 0 2px {t["sep"]}; padding: 20px; {PX_L}">'
               f'<p style="margin: 0; font-size: 13px; font-weight: 500; color: {t["label2"]}">Promises kept this week</p>'
               f'<p style="margin: 8px 0 6px; font-size: 80px; line-height: .85; {DISP}">16<span style="font-size: 32px; color: {t["label2"]}"> / 21</span></p>'
               f'<p style="margin: 0; font-size: 13px; line-height: 18px; color: {t["label2"]}">You’re showing up more often. That’s the part that matters.</p>'
               f'<div style="display: flex; align-items: flex-end; gap: 10px; height: 120px; margin: 20px 0 8px">{bars}</div>'
               f'<div style="display: flex; border-top: 2px solid {t["sep"]}; padding-top: 16px; margin-top: 16px">'
               f'<div style="flex: 1"><p style="margin: 0; font-size: 32px; line-height: 30px; {DISP}">2h 20m</p><p style="margin: 2px 0 0; font-size: 13px; color: {t["label2"]}">Time for yourself</p></div>'
               f'<div style="flex: 1; border-left: 2px solid {t["sep"]}; padding-left: 16px"><p style="margin: 0; font-size: 32px; line-height: 30px; {DISP}">4</p><p style="margin: 2px 0 0; font-size: 13px; color: {t["label2"]}">Days you showed up</p></div></div></div>')
    insight = (f'<div style="display: flex; gap: 12px; padding: 16px; background: {t["surface"]}; box-shadow: inset 0 0 0 2px {t["sep"]}; {PX_L}">{tile("leaf", t)}'
               f'<p style="margin: 0; font-size: 15px; line-height: 20px; color: {t["label2"]}"><strong style="display: block; color: {t["label"]}; font-weight: 600; margin-bottom: 2px">Your minimum is doing its job.</strong>'
               f'Three short walks still got you outside. Keep the five-minute option.</p></div>')
    empty = (f'<div style="padding: 20px 16px; text-align: center; background-image: repeating-linear-gradient(90deg, {t["sep"]} 0 4px, transparent 4px 8px); background-size: 100% 2px; background-repeat: no-repeat">'
             f'<p style="margin: 0 0 4px; font-size: 15px; color: {t["label2"]}">Your evening walk is still waiting.</p>'
             f'<a href="Intervention.dc.html" style="display: inline-flex; align-items: center; gap: 2px; min-height: 44px; font-size: 15px; font-weight: 500; color: {t["accentText"]}; text-decoration: none">Let’s go{ic("arrow", 12)}</a></div>')
    inner = (large_title(t, "Progress", "settings", "Settings")
             + f'<p style="margin: 4px 0 24px; font-size: 15px; line-height: 20px; color: {t["label2"]}">Small promises. Actual follow-through.</p>'
             + summary + section_head(t, "Perspective") + insight
             + section_head(t, "Today", f'<span style="font-size: 13px; color: {t["label2"]}">Nov 6 · sample</span>')
             + group(t, [row(t, "check", "Made your bed", "8:15 AM · Self-reported", first=True), empty]))
    return page("Progress", t, inner, HEIGHTS.get("Progress"), tab="you")

def sheet_screen(title, heading, lead, options, back_href):
    t = D
    rows = []
    for i, (icon_name, a, b, href) in enumerate(options):
        rows.append(row({**t, "surface": t["sheetGroup"]}, icon_name, a, b, chevron=True, href=href, first=(i == 0)))
    grp = f'<div style="background: {t["sheetGroup"]}; {PX_L}">{"".join(rows)}</div>'
    sheet = (f'<section role="dialog" aria-label="{heading}" style="margin-top: auto; background: {t["sheet"]}; padding: 8px 20px 40px; {poly(12, top_only=True)}">'
             f'<div style="width: 36px; height: 4px; background: {t["fill2"]}; margin: 0 auto 12px"></div>'
             f'<div style="display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 6px">'
             f'<h2 style="margin: 0; font-size: 34px; line-height: 32px; {DISP}">{heading}</h2>{icon_btn("close", t, "Close", back_href, 32)}</div>'
             f'<p style="margin: 0 0 20px; font-size: 15px; line-height: 20px; color: {t["label2"]}">{lead}</p>{grp}</section>')
    root = (f'<div style="width: 390px; height: 844px; box-sizing: border-box; display: flex; flex-direction: column; overflow: hidden; '
            f'background: {t["bg"]}; color: {t["label"]}; {UI}; position: relative">'
            f'<div aria-hidden="true" style="position: absolute; inset: 0; display: flex; justify-content: center; padding-top: 72px; opacity: .25">{img("coach", 120, 145)}</div>'
            f'<div style="position: relative; flex: 1; display: flex; flex-direction: column; background: rgba(0,0,0,.45)">{sheet}</div></div>')
    return title, root

SCREENS = [
    ("Main.dc.html", "Today", today, None),
    ("Intervention.dc.html", "The intervention", intervention, 844),
    ("Session.dc.html", "Active session", session, 844),
    ("Blocked.dc.html", "The app block", blocked, 844),
    ("Complete.dc.html", "The payoff", complete, 844),
    ("Plan.dc.html", "Your commitments", plan, None),
    ("Coach.dc.html", "Your coach", coach, None),
    ("Progress.dc.html", "Your progress", progress, None),
    ("SheetChangePlan.dc.html", "Sheet · Change the plan", lambda: sheet_screen("Change the plan", "Life happens.", "Change the plan deliberately. You’re always in control.",
        [("walk", "Do the 5-minute version", "Keep the minimum you agreed to.", "Session.dc.html"), ("clock", "Give me 30 minutes", "Move it and release restrictions.", "Main.dc.html"),
         ("leaf", "I need a rest day", "No catching up tomorrow.", "Main.dc.html"), ("unlock", "End this session", "Release restrictions. Marked unfinished.", "Main.dc.html")], "Intervention.dc.html"), 844),
    ("SheetFinish.dc.html", "Sheet · How did it go?", lambda: sheet_screen("How did it go", "How did it go?", "Keep the record honest. The timer is a guide — you tell us what happened.",
        [("check", "I did the full walk", "Self-reported. Apps released.", "Complete.dc.html"), ("walk", "I did the 5-minute minimum", "Recorded as the minimum.", "Complete.dc.html"),
         ("unlock", "I’m ending this one", "Marked unfinished. Apps released.", "Main.dc.html")], "Session.dc.html"), 844),
]

def build():
    os.makedirs(os.path.join(ROOT, "project"), exist_ok=True)
    preview, boards, order = [], {}, []
    rows_layout = [["Main.dc.html", "Intervention.dc.html", "Session.dc.html", "Blocked.dc.html", "Complete.dc.html"],
                   ["Plan.dc.html", "Coach.dc.html", "Progress.dc.html", "SheetChangePlan.dc.html", "SheetFinish.dc.html"]]
    built = {}
    for fname, name, fn, fixed in SCREENS:
        title, root = fn()
        h = fixed or HEIGHTS.get(fname.split(".")[0]) or 844
        built[fname] = (name, title, root, h)
        html = dc_file(title, root, h)
        for k, v in BLOB.items():
            html = html.replace(f"@@{k}@@", v)
        open(os.path.join(ROOT, "project", fname), "w").write(html)
        prev = root.replace(ACC, "#FF6548")
        for k, v in LOCAL.items():
            prev = prev.replace(f"@@{k}@@", v)
        preview.append(f'<section data-board="{fname.split(".")[0]}" style="display: inline-block; vertical-align: top; margin: 20px">{prev}</section>')
    y = 0
    for r, files in enumerate(rows_layout):
        x = 0
        row_h = max(built[f][3] for f in files)
        for f in files:
            boards[f] = {"x": x, "y": y, "w": 390, "h": built[f][3], "title": built[f][0], "is_interactive": True}
            order.append(f)
            x += 390 + 80
        y += row_h + 420
    canvas = {"v": 3, "createdOnFiles": {"v": 1, "at": "2026-11-06T18:30:00Z"}, "title": "GYLT screens", "launch": {"view": "canvas"},
              "pages": [], "boards": boards, "order": order,
              "notes": {
                  "flow": {"x": 0, "y": -300, "text": "The evening walk: intervention, session, block, payoff", "kind": "title1", "maxW": 2230},
                  "tabs": {"x": 0, "y": boards["Plan.dc.html"]["y"] - 300, "text": "Planning tabs and sheets", "kind": "title1", "maxW": 2230},
                  "about": {"x": 2430, "y": 0, "w": 420, "size": "m", "fill": "orange",
                            "text": "GYLT, pixel edition. Jersey 25 for display, Geist Mono for UI, pixelarticons (MIT) for icons, the pixel coach and GYLT wordmark from the logo kit. Coral #FF6548 is the only accent. Every artboard is clickable in Play: buttons and tabs link the screens."}},
              "designSystems": []}
    json.dump(canvas, open(os.path.join(ROOT, "project", "canvas.json"), "w"), indent=1, ensure_ascii=False)
    open(os.path.join(HERE, "preview.html"), "w").write(
        '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>GYLT canvas preview</title>' + FONT.replace("&amp;", "&") +
        '<style>body{margin:0;background:#bdbab2}</style></head><body>' + "".join(preview) + "</body></html>")
    print("built", len(built), "artboards ->", ROOT)

build()
