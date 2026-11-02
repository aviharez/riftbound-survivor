# Saves the cells of a workbench `join ... --as sheet` image of small pictures (icons, props) as PNGs.
# Small sheets are saved at 2x (the caption says "2x"): pass --scale 2. Caption 18 px, background #1f252c -> alpha 0.
#   python3 tools/icon_sheet.py <sheet.png> --cell 32 --scale 2 --out assets/ui/icons --names a,b,c [--palette N]
import argparse, os
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument("sheet")
ap.add_argument("--cell", type=int, default=32)
ap.add_argument("--scale", type=int, default=1)
ap.add_argument("--out", required=True)
ap.add_argument("--names", required=True)
ap.add_argument("--columns", type=int, default=0)
ap.add_argument("--palette", type=int, default=0)
a = ap.parse_args()
BG = (31, 37, 44)
im = Image.open(a.sheet).convert("RGB")
S, C = a.scale, a.cell
sheet = im.crop((0, 18, im.width, im.height))
names = a.names.split(",")
cols_n = a.columns or len(names)
assert sheet.width >= cols_n * C * S, (sheet.size, cols_n, C, S)
os.makedirs(a.out, exist_ok=True)
cols = set()
for i, n in enumerate(names):
    ox, oy = (i % cols_n) * C * S, (i // cols_n) * C * S
    out = Image.new("RGBA", (C, C), (0, 0, 0, 0))
    k = 0
    for y in range(C):
        for x in range(C):
            c = sheet.getpixel((ox + x * S, oy + y * S))
            if c != BG:
                out.putpixel((x, y), c + (255,))
                cols.add(c)
                k += 1
    assert k > 20, (n, k)
    if n != "_":
        out.save(os.path.join(a.out, n + ".png"))
print("colours", len(cols), "(expected %d)" % a.palette if a.palette else "")
if a.palette and "_" not in names:
    assert len(cols) == a.palette
