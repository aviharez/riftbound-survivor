# Rebuilds PixelLab sprites from a workbench `join ... --as sheet` image saved in the tool-results folder.
# The saved image is an 18 px caption strip above the sheet (64x64 cells) on a solid #1f252c background,
# which becomes alpha 0. Sprites only use alpha 0/255.
#
# Rotations (one row of cells, one PNG per cell):
#   python3 tools/pixellab_sheet.py <sheet.png> <out_dir> --cells south,south-east,east,...  [--palette N]
# Animation (one row per direction, written as a horizontal strip <out_dir>/<dir>.png):
#   python3 tools/pixellab_sheet.py <sheet.png> <out_dir> --rows south,south-east,... --frames 6 [--palette N]
#   A row named "_" is skipped (e.g. a bad direction re-rolled later); --palette then cannot be checked.
# --palette N: the palette size the workbench reported for the sheet; the script checks it got exactly N colours.
import argparse, os
from PIL import Image

BG = (31, 37, 44)
CAPTION = 18
CELL = 64

ap = argparse.ArgumentParser()
ap.add_argument("sheet")
ap.add_argument("out")
ap.add_argument("--cells")
ap.add_argument("--rows")
ap.add_argument("--frames", type=int, default=0)
ap.add_argument("--palette", type=int, default=0)
# v3 custom animations are stored on a bigger canvas (64 px sprite -> 84 px): --cell 84 --offset 10,10
# reads 84 px cells and keeps the 64x64 window at that offset, so the feet line up with the template frames.
ap.add_argument("--cell", type=int, default=CELL)
ap.add_argument("--offset", default="0,0")
a = ap.parse_args()
OX, OY = (int(v) for v in a.offset.split(","))

im = Image.open(a.sheet).convert("RGB")
sheet = im.crop((0, CAPTION, im.width, im.height))
os.makedirs(a.out, exist_ok=True)
all_cols = set()


def keyed(box):
    src = sheet.crop(box)
    px = src.load()
    res = Image.new("RGBA", src.size, (0, 0, 0, 0))
    rp = res.load()
    n = 0
    for y in range(src.height):
        for x in range(src.width):
            c = px[x, y]
            if c != BG:
                rp[x, y] = (c[0], c[1], c[2], 255)
                n += 1
                all_cols.add(c)
    return res, n


if a.cells:
    names = a.cells.split(",")
    assert sheet.width == CELL * len(names) and sheet.height == CELL, (sheet.size, len(names))
    for i, name in enumerate(names):
        res, n = keyed((i * CELL, 0, (i + 1) * CELL, CELL))
        assert n > 200, (name, n)
        res.save(os.path.join(a.out, name + ".png"))
        print(f"{name:11s} opaque={n}")
else:
    rows = a.rows.split(",")
    f = a.frames
    # a joined sheet is as wide as its longest row (shorter rows are padded): only the first f cells are read
    C = a.cell
    assert sheet.width >= C * f and sheet.height == C * len(rows), (sheet.size, f, len(rows))
    for r, name in enumerate(rows):
        if name == "_":
            continue   # row not wanted (re-rolled separately)
        if C == CELL:
            res, n = keyed((0, r * C, f * C, (r + 1) * C))
        else:
            res = Image.new("RGBA", (f * CELL, CELL), (0, 0, 0, 0))
            n = 0
            for i in range(f):
                x0, y0 = i * C + OX, r * C + OY
                cut = sheet.crop((i * C, r * C, (i + 1) * C, (r + 1) * C))
                # anything outside the 64 px window would be lost: refuse instead of clipping silently
                full = sum(1 for y in range(C) for x in range(C) if cut.getpixel((x, y)) != BG)
                part, k = keyed((x0, y0, x0 + CELL, y0 + CELL))
                assert k == full, (name, i, "sprite pixels outside the 64 px window", full - k)
                res.paste(part, (i * CELL, 0))
                n += k
        assert n > 200 * f, (name, n)
        res.save(os.path.join(a.out, name + ".png"))
        print(f"{name:11s} frames={f} opaque={n}")

print(f"colours={len(all_cols)}" + (f" (expected {a.palette})" if a.palette else ""))
if a.palette:
    assert len(all_cols) == a.palette, "colour count mismatch: sheet scaled or keyed wrongly"
