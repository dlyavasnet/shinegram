import math
import os
import random

OUT = os.path.dirname(os.path.abspath(__file__))

MONO = "'JetBrains Mono','SF Mono',Menlo,Consolas,'DejaVu Sans Mono',monospace"
BG = "#0b0a12"
PANEL = "#110f1c"
BAR = "#1a1729"
LAV = "#b9b8ff"
WHITE = "#f4f3ff"
DIM = "#6f6b8f"
GREEN = "#7dffb2"
PINK = "#ff8fc7"
GOLD = "#ffd36e"
CYAN = "#7fe3ff"

FONT = {
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    "N": ["10001", "11001", "10101", "10101", "10011", "10001", "10001"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "G": ["01111", "10000", "10000", "10111", "10001", "10001", "01111"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
}


def window(width, height, title, body, defs=""):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
<defs>
<linearGradient id="pixelGradient" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="560" y2="63">
<stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="{LAV}"/><stop offset="1" stop-color="#9d7bff"/>
</linearGradient>
<filter id="glow" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
{defs}
</defs>
<rect x="1" y="1" width="{width - 2}" height="{height - 2}" rx="14" fill="{PANEL}" stroke="#2a2640" stroke-width="2"/>
<path d="M1 15 a14 14 0 0 1 14 -14 h{width - 30} a14 14 0 0 1 14 14 v21 h-{width - 2} z" fill="{BAR}"/>
<circle cx="24" cy="19" r="6" fill="#ff5f57"/><circle cx="44" cy="19" r="6" fill="#febc2e"/><circle cx="64" cy="19" r="6" fill="#28c840"/>
<text x="{width / 2}" y="24" text-anchor="middle" font-family={repr(MONO)} font-size="13" fill="{DIM}">{title}</text>
{body}
</svg>
'''


def twinkles(width, height, top, count, seed):
    rnd = random.Random(seed)
    parts = []
    for _ in range(count):
        x = rnd.randint(8, width - 12)
        y = rnd.randint(top + 6, height - 10)
        size = rnd.choice([2, 2, 3, 4])
        color = rnd.choice([LAV, WHITE, "#9d7bff", CYAN])
        duration = round(rnd.uniform(1.6, 4.2), 2)
        delay = round(rnd.uniform(0, 4), 2)
        low = round(rnd.uniform(0.05, 0.25), 2)
        parts.append(f'<rect x="{x}" y="{y}" width="{size}" height="{size}" fill="{color}" opacity="{low}"><animate attributeName="opacity" values="{low};0.95;{low}" dur="{duration}s" begin="{delay}s" repeatCount="indefinite"/></rect>')
    return "\n".join(parts)


def pixel_star(cx, cy, cell, radius):
    parts = []
    for gy in range(-radius, radius + 1):
        for gx in range(-radius, radius + 1):
            nx = abs(gx) / radius
            ny = abs(gy) / radius
            value = math.sqrt(nx) + math.sqrt(ny)
            if value <= 1.0:
                distance = min(1.0, math.hypot(nx, ny))
                if distance < 0.18:
                    color = "#ffffff"
                elif distance < 0.4:
                    color = "#e6e5ff"
                elif distance < 0.65:
                    color = LAV
                else:
                    color = "#8f7dff"
                parts.append(f'<rect x="{cx + gx * cell}" y="{cy + gy * cell}" width="{cell}" height="{cell}" fill="{color}"/>')
    return "\n".join(parts)


def pixel_text(text, x, y, cell, gap):
    parts = []
    cursor = x
    for char in text:
        glyph = FONT[char]
        for row, line in enumerate(glyph):
            for col, bit in enumerate(line):
                if bit == "1":
                    parts.append(f'<rect x="{cursor + col * cell}" y="{y + row * cell}" width="{cell - 1}" height="{cell - 1}"/>')
        cursor += (len(glyph[0]) + gap) * cell
    return "\n".join(parts), cursor - x - gap * cell


def typed_line(index, x, y, text, delay, duration, chars_width, color=WHITE, size=15, extra=""):
    clip = f"clip{index}"
    width = max(1, int(chars_width))
    defs = f'<clipPath id="{clip}"><rect x="{x - 2}" y="{y - size}" width="0" height="{size + 8}"><animate attributeName="width" from="0" to="{width + 6}" begin="{delay}s" dur="{duration}s" fill="freeze"/></rect></clipPath>'
    body = f'<g clip-path="url(#{clip})"><text x="{x}" y="{y}" font-family={repr(MONO)} font-size="{size}" fill="{color}" xml:space="preserve">{text}</text>{extra}</g>'
    return defs, body


def banner():
    width, height = 920, 360
    defs = []
    body = [twinkles(width, height, 38, 70, 7)]

    d, b = typed_line(0, 30, 70, f'<tspan fill="{GREEN}">➜</tspan> <tspan fill="{CYAN}">~/shinegram</tspan> <tspan fill="{WHITE}">./shinegram --shine</tspan>', 0.3, 1.1, 330)
    defs.append(d)
    body.append(b)

    star = pixel_star(150, 196, 6, 15)
    body.append(f'<g opacity="0" filter="url(#glow)">{star}<animate attributeName="opacity" from="0" to="1" begin="1.5s" dur="0.6s" fill="freeze"/><animateTransform attributeName="transform" type="translate" values="0 0;0 -5;0 0" dur="4s" begin="2.1s" repeatCount="indefinite"/></g>')

    letters, text_width = pixel_text("SHINEGRAM", 0, 0, 9, 1)
    scale_x = 270
    body.append(f'<g opacity="0" transform="translate({scale_x} 138)" fill="url(#pixelGradient)" filter="url(#glow)">{letters}<animate attributeName="opacity" from="0" to="1" begin="1.8s" dur="0.5s" fill="freeze"/></g>')

    d, b = typed_line(1, scale_x, 238, "telegram for macOS · ghost mode · anti-delete", 2.4, 1.4, 470, LAV, 15)
    defs.append(d)
    body.append(b)

    d, b = typed_line(2, scale_x, 266, f'<tspan fill="{DIM}">status:</tspan> <tspan fill="{GREEN}">online</tspan> <tspan fill="{DIM}">→</tspan> <tspan fill="{PINK}">invisible</tspan> <tspan fill="{DIM}">// nobody sees you</tspan>', 4.1, 1.4, 500, WHITE, 15)
    defs.append(d)
    body.append(b)

    body.append(f'<text x="30" y="326" font-family={repr(MONO)} font-size="15" fill="{GREEN}" opacity="0">➜<animate attributeName="opacity" from="0" to="1" begin="5.6s" dur="0.1s" fill="freeze"/></text>')
    body.append(f'<rect x="50" y="313" width="9" height="17" fill="{WHITE}" opacity="0"><animate attributeName="opacity" values="1;1;0;0" keyTimes="0;0.5;0.5;1" dur="1s" begin="5.6s" repeatCount="indefinite"/></rect>')

    return window(width, height, "shinegram — zsh — 92×24", "\n".join(body), "\n".join(defs))


FEATURES = [
    ("ghost.read_receipts", "сообщения не помечаются прочитанными"),
    ("ghost.online", "никто не видит, что ты в сети"),
    ("ghost.typing", "без «печатает…» и «записывает»"),
    ("ghost.stories", "истории смотрятся анонимно"),
    ("ghost.voice", "голосовые и кружки не отмечаются"),
    ("ghost.send_scheduled", "пишешь в чат — он остаётся непрочитанным"),
    ("anti_delete", "удалённые сообщения остаются в чате"),
    ("edit_history", "все версии изменённых сообщений"),
    ("no_ads", "без спонсорских сообщений в каналах"),
    ("streamer_mode", "окна скрыты от записи и демонстрации"),
    ("ui.extras", "скрыть истории · секунды · копировать ID"),
    ("app_icons", "6 иконок: starlight, gold, ruby, emerald…"),
]


def features():
    width = 920
    line_height = 25
    top = 72
    height = top + line_height * (len(FEATURES) + 2) + 24
    defs = []
    body = [twinkles(width, height, 38, 26, 11)]
    d, b = typed_line(100, 30, top, f'<tspan fill="{GREEN}">➜</tspan> <tspan fill="{CYAN}">~</tspan> <tspan fill="{WHITE}">shinegram --features --verbose</tspan>', 0.2, 0.9, 360)
    defs.append(d)
    body.append(b)
    start = 1.3
    for i, (key, desc) in enumerate(FEATURES):
        y = top + line_height * (i + 1) + 6
        delay = start + i * 0.28
        text = f'<tspan fill="{DIM}">[</tspan><tspan fill="{GREEN}">✓</tspan><tspan fill="{DIM}">]</tspan> <tspan x="70" fill="{LAV}">{key}</tspan><tspan x="290" fill="{WHITE}">{desc}</tspan>'
        d, b = typed_line(101 + i, 30, y, text, delay, 0.35, 860, WHITE, 15)
        defs.append(d)
        body.append(b)
    end = start + len(FEATURES) * 0.28 + 0.4
    y = top + line_height * (len(FEATURES) + 1) + 14
    d, b = typed_line(200, 30, y, f'<tspan fill="{GOLD}">★</tspan> <tspan fill="{WHITE}">{len(FEATURES)} modules loaded</tspan> <tspan fill="{DIM}">·</tspan> <tspan fill="{GREEN}">ghost ready</tspan>', end, 0.6, 400)
    defs.append(d)
    body.append(b)
    return window(width, height, "shinegram --features", "\n".join(body), "\n".join(defs))


GHOST = [
    "....######....",
    "..##########..",
    ".############.",
    ".############.",
    "##..####..####",
    "##..####..####",
    "##############",
    "##############",
    "##############",
    "##############",
    "##############",
    "##############",
    "##.###..###.##",
    "#...#....#...#",
]


def ghost():
    cell = 10
    size = len(GHOST) * cell
    pad = 30
    width = size + pad * 2
    height = size + pad * 2 + 16
    body_parts = []
    eyes = []
    for row, line in enumerate(GHOST):
        for col, char in enumerate(line):
            x = pad + col * cell
            y = pad + row * cell
            if char == "#":
                body_parts.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}"/>')
            elif row in (4, 5) and col in (2, 3, 8, 9):
                eyes.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}"/>')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
<defs>
<linearGradient id="ghostGradient" gradientUnits="userSpaceOnUse" x1="0" y1="{pad}" x2="0" y2="{pad + size}"><stop offset="0" stop-color="#cfcaff"/><stop offset="1" stop-color="#8a6bff"/></linearGradient>
<filter id="ghostGlow" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
</defs>
<g>
<animateTransform attributeName="transform" type="translate" values="0 0;0 -8;0 0" dur="2.6s" repeatCount="indefinite"/>
<g fill="url(#ghostGradient)" filter="url(#ghostGlow)">
<animate attributeName="opacity" values="1;0.35;1" dur="5s" repeatCount="indefinite"/>
{"".join(body_parts)}
</g>
<g fill="{BG}">{"".join(eyes)}
<animate attributeName="opacity" values="1;1;0.1;1;1" keyTimes="0;0.9;0.93;0.96;1" dur="4s" repeatCount="indefinite"/>
</g>
</g>
<g fill="{LAV}" opacity="0.35">
<rect x="{pad + 2 * cell}" y="{height - 14}" width="{size - 4 * cell}" height="4"><animate attributeName="opacity" values="0.6;0.2;0.6" dur="2.6s" repeatCount="indefinite"/></rect>
</g>
</svg>
'''


def divider():
    width, height = 920, 24
    parts = []
    rnd = random.Random(3)
    x = 0
    while x < width:
        color = rnd.choice([LAV, "#9d7bff", "#2a2640", "#2a2640", CYAN, "#2a2640"])
        parts.append(f'<rect x="{x}" y="10" width="6" height="4" fill="{color}"/>')
        x += 10
    parts.append(f'<rect x="0" y="9" width="40" height="6" fill="{WHITE}" opacity="0.9"><animate attributeName="x" from="-40" to="{width}" dur="3.5s" repeatCount="indefinite"/></rect>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{"".join(parts)}</svg>\n'


for name, content in [("banner.svg", banner()), ("features.svg", features()), ("ghost.svg", ghost()), ("divider.svg", divider())]:
    with open(os.path.join(OUT, name), "w") as f:
        f.write(content)
print("ok")
