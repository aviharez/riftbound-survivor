# Saves a PixelLab loose-sprite animation (animate_image -> workbench `join <job> --as sheet --columns N`)
# as one horizontal strip PNG. The saved workbench image is an 18 px caption above the sheet on solid
# #1f252c, which becomes alpha 0 (sprites only use alpha 0/255).
#   python3 tools/enemy_anim.py <sheet.png> <out.png> --cell 48 [--palette N] [--skip-first]
# A `join ... --as rows` sheet (one animation per row): <out> is a folder, --rows a,b,c names the rows
# ("_" skips one), and each row is written as <out>/<name>.png.
# --skip-first drops frame 0 (animate_image returns the input frame unchanged as frame 0).
import argparse
from PIL import Image

BG = (31, 37, 44)
CAPTION = 18

ap = argparse.ArgumentParser()
ap.add_argument("sheet")
ap.add_argument("out")
ap.add_argument("--cell", type=int, default=48)
ap.add_argument("--palette", type=int, default=0)
ap.add_argument("--skip-first", action="store_true")
ap.add_argument("--rows")
a = ap.parse_args()

im = Image.open(a.sheet).convert("RGB")
sheet = im.crop((0, CAPTION, im.width, im.height))
C = a.cell
cols = set()
px = sheet.load()


def strip(row, n):
    first = 1 if a.skip_first else 0
    res = Image.new("RGBA", ((n - first) * C, C), (0, 0, 0, 0))
    rp = res.load()
    for i in range(first, n):
        k = 0
        for y in range(C):
            for x in range(C):
                c = px[i * C + x, row * C + y]
                if c != BG:
                    rp[(i - first) * C + x, y] = (c[0], c[1], c[2], 255)
                    cols.add(c)
                    k += 1
        assert k > 60, ("frame almost empty", row, i, k)
    return res


assert sheet.width % C == 0 and sheet.height % C == 0, (sheet.size, C)
n = sheet.width // C
if a.rows:
    import os
    names = a.rows.split(",")
    assert sheet.height == C * len(names), (sheet.size, len(names))
    os.makedirs(a.out, exist_ok=True)
    for r, name in enumerate(names):
        if name != "_":
            strip(r, n).save(os.path.join(a.out, name + ".png"))
            print(f"{name}: frames={n - (1 if a.skip_first else 0)}")
else:
    assert sheet.height == C, (sheet.size, C)
    strip(0, n).save(a.out)
    print(f"{a.out}: frames={n - (1 if a.skip_first else 0)}")
print(f"colours={len(cols)}" + (f" (expected {a.palette})" if a.palette else ""))
if a.palette and "_" not in (a.rows or ""):
    assert len(cols) == a.palette, "colour count mismatch"
