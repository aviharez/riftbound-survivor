# Rebuilds a PixelLab sprite from the workbench 'inspect --scale 1' image saved in the tool-results folder:
# the image is a caption strip (18 px) above the 64x64 crop on a solid background colour, which becomes alpha 0.
# usage: python3 pl_extract.py <out_dir> dir=file [dir=file ...]
import sys, os
from PIL import Image
BG = (31, 37, 44)
out = sys.argv[1]
os.makedirs(out, exist_ok=True)
for arg in sys.argv[2:]:
    d, f = arg.split("=", 1)
    im = Image.open(f).convert("RGBA")
    assert im.size == (64, 82), (d, im.size)
    crop = im.crop((0, 18, 64, 82))
    px = crop.load()
    # background must be the solid key colour all around the border's empty corners
    assert px[0, 0][:3] == BG and px[63, 63][:3] == BG, (d, px[0, 0], px[63, 63])
    res = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    rp = res.load(); n = 0; cols = set()
    for y in range(64):
        for x in range(64):
            c = px[x, y]
            if c[:3] != BG:
                rp[x, y] = (c[0], c[1], c[2], 255); n += 1; cols.add(c[:3])
    res.save(os.path.join(out, d + ".png"))
    print(f"{d:11s} opaque={n} colours={len(cols)}")
