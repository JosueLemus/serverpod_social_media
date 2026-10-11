"""Slice a 4x4 icon sheet by connected components, not by a fixed grid.

Usage: python3 -I slice_sheet.py <sheet.png> <out-dir> name1 ... name16  ("-" skips)

GPT draws the grid by eye, so a fixed 256px crop catches pieces of the
neighbouring glyph. Each component is assigned to the cell holding its
centroid; a cell's glyph is the union of its components, re-centred on a
cell-sized canvas at the sheet's own scale, so relative sizes survive.
"""
import os
import re
import subprocess
import sys
import tempfile

sheet, out, names = sys.argv[1], sys.argv[2], sys.argv[3:]
os.makedirs(out, exist_ok=True)
tmp = tempfile.mkdtemp()
mask = os.path.join(tmp, "mask.png")

# Black ink on transparent -> white ink on black mask.
subprocess.run(["magick", sheet, "-background", "white", "-alpha", "remove",
                "-alpha", "off", "-colorspace", "Gray", "-threshold", "60%",
                "-negate", mask], check=True)
w = int(subprocess.check_output(["magick", "identify", "-format", "%w", mask]))
cell = w // 4

cc = subprocess.run(
    ["magick", mask, "-define", "connected-components:verbose=true",
     "-define", "connected-components:area-threshold=12",
     "-connected-components", "8", "null:"],
    check=True, capture_output=True, text=True).stdout
pattern = re.compile(
    r"^\s*(\d+):\s+(\d+)x(\d+)\+(\d+)\+(\d+)\s+([\d.]+),([\d.]+)\s+(\d+)\s+(\S+)")
cells = {}
for line in cc.splitlines():
    m = pattern.match(line)
    if not m:
        continue
    _, bw, bh, bx, by, cx, cy, area, color = m.groups()
    if "255" not in color and "white" not in color:
        continue  # background component
    bw, bh, bx, by, area = map(int, (bw, bh, bx, by, area))
    cx, cy = float(cx), float(cy)
    if area < 12:
        continue
    key = (min(int(cy // cell), 3), min(int(cx // cell), 3))
    cells.setdefault(key, []).append((bx, by, bx + bw, by + bh, int(m.group(1))))

for i, name in enumerate(names):
    if name == "-":
        continue
    key = (i // 4, i % 4)
    comps = cells.get(key)
    if not comps:
        print(f"!! no glyph for {name} at {key}")
        continue
    x0 = min(c[0] for c in comps); y0 = min(c[1] for c in comps)
    x1 = max(c[2] for c in comps); y1 = max(c[3] for c in comps)
    glyph = os.path.join(tmp, "g.png")
    # The union box is tight around this cell's ink, so neighbours stay out.
    subprocess.run(
        ["magick", mask, "-crop", f"{x1 - x0}x{y1 - y0}+{x0}+{y0}", "+repage",
         "-background", "black", "-gravity", "center",
         "-extent", f"{cell}x{cell}", "-negate",
         "-filter", "Lanczos", "-resize", "512x512", "-threshold", "50%",
         glyph], check=True)
    svg = os.path.join(out, f"{name}.svg")
    pbm = subprocess.run(["magick", glyph, "pbm:-"], check=True,
                         capture_output=True).stdout
    subprocess.run(["potrace", "-s", "--flat", "-t", "12", "-a", "1.0",
                    "-O", "0.4", "-W", "512pt", "-H", "512pt", "-o", svg, "-"],
                   input=pbm, check=True)
    subprocess.run(["cp", glyph, os.path.join(out, f"{name}.preview.png")],
                   check=True)
print(f"sliced {sheet}: {len(cells)} cells found")
