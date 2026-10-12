"""Replace U+2026 with three baseline periods built from the font's own period.

Japanese faces draw the ellipsis vertically centred ("···"), which reads as a
bug in Spanish UI text and in Flutter's TextOverflow.ellipsis.
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import Glyph, GlyphComponent

for path in sys.argv[1:]:
    font = TTFont(path)
    cmap = font.getBestCmap()
    period, ellipsis = cmap[0x2E], cmap.get(0x2026)
    if ellipsis is None:
        print(path, 'no ellipsis glyph'); continue
    glyf, hmtx = font['glyf'], font['hmtx']
    adv, lsb = hmtx[period]
    step = int(adv * 0.82)
    composite = Glyph()
    composite.numberOfContours = -1
    composite.components = []
    for i in range(3):
        c = GlyphComponent()
        c.glyphName = period
        c.x, c.y = i * step, 0
        c.flags = 0x2 | 0x4  # ARGS_ARE_XY_VALUES | ROUND_XY_TO_GRID
        composite.components.append(c)
    glyf[ellipsis] = composite
    composite.recalcBounds(glyf)
    hmtx[ellipsis] = (step * 2 + adv, lsb)
    font.save(path)
    print(path, 'ellipsis rebuilt from', period, 'adv', adv)
