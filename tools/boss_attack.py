# Saves v3 custom character animations whose directions came back on different canvases (84 / 88 px)
# as uniform 96 px strips with the 64 px sprite window at (16, 16), so every direction lines up with the
# 64 px rotations and walk frames (the game anchors a bigger frame by its centre window).
# Input: workbench `join character:<id>:<dir>:<anim> ... --as rows` (rows padded to the biggest canvas,
# centred horizontally, on the bottom edge), saved with an 18 px caption on solid #1f252c.
#   python3 tools/boss_attack.py <sheet.png> <out_dir> --rows south,east,... --sizes 84,88,... --frames 8 [--palette N]
# --sizes = each direction's native canvas from the animate_character receipt.
import argparse, os
from PIL import Image

BG = (31, 37, 44)
CAPTION = 18
OUT = 96
WIN = 64

ap = argparse.ArgumentParser()
ap.add_argument("sheet")
ap.add_argument("out")
ap.add_argument("--rows", required=True)
ap.add_argument("--sizes", required=True)
ap.add_argument("--frames", type=int, default=8)
ap.add_argument("--palette", type=int, default=0)
a = ap.parse_args()

rows = a.rows.split(",")
sizes = [int(v) for v in a.sizes.split(",")]
assert len(rows) == len(sizes)
im = Image.open(a.sheet).convert("RGB")
sheet = im.crop((0, CAPTION, im.width, im.height))
C = max(sizes)
assert sheet.height == C * len(rows) and sheet.width >= C * a.frames, (sheet.size, C)
px = sheet.load()
os.makedirs(a.out, exist_ok=True)
cols = set()
for r, (name, c) in enumerate(zip(rows, sizes)):
    # where the native canvas sits in the padded cell, and its 64 px window inside it
    ox, oy = (C - c) // 2, C - c
    wx, wy = ox + (c - WIN) // 2, oy + (c - WIN) // 2
    dx, dy = (OUT - WIN) // 2 - wx, (OUT - WIN) // 2 - wy
    res = Image.new("RGBA", (a.frames * OUT, OUT), (0, 0, 0, 0))
    rp = res.load()
    lost = 0
    for f in range(a.frames):
        for y in range(C):
            for x in range(C):
                col = px[f * C + x, r * C + y]
                if col == BG:
                    continue
                tx, ty = x + dx, y + dy
                if 0 <= tx < OUT and 0 <= ty < OUT:
                    rp[f * OUT + tx, ty] = (col[0], col[1], col[2], 255)
                    cols.add(col)
                else:
                    lost += 1
    assert lost == 0, (name, "pixels outside the 96 px frame", lost)
    res.save(os.path.join(a.out, name + ".png"))
    print(f"{name:11s} canvas={c} shift={dx},{dy}")
print(f"colours={len(cols)}" + (f" (expected {a.palette})" if a.palette else ""))
if a.palette:
    assert len(cols) == a.palette, "colour count mismatch"
