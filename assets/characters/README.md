# Character sprites

One folder per character id (13 heroes, plus `boss` for the Corrupted Guardian), each with 8 direction PNGs:

south.png, south-east.png, east.png, north-east.png,
north.png, north-west.png, west.png, south-west.png

and two animation folders with the same 8 file names, each a horizontal strip of 64x64 frames:

- `walk/<direction>.png`: 6 frames (PixelLab template `walking-6-frames`), played at `GameData.CHARACTER_WALK_FPS`
- `idle/<direction>.png`: 4 frames (template `breathing-idle`), played at `GameData.CHARACTER_IDLE_FPS`

`CharacterArt` loads them automatically. A missing animation strip falls back to the static sprite with the
procedural bob; a missing character folder falls back to the coloured placeholder.

All heroes are PixelLab v3 characters (64x64, low top-down, cute chibi; alpha 0/255 only), made on Syifa's
PixelLab account. How they are pulled out of PixelLab (the workspace cannot download PixelLab URLs):

- rotations: `pixelart_workbench join character:<id>:south character:<id>:south-east ... --as sheet --columns 8`,
  then `python3 tools/pixellab_sheet.py <saved image> assets/characters/<hero> --cells south,south-east,... --palette N`
- animations: `pixelart_workbench join character:<id>:south:walk ... (8 directions) --as rows`,
  then `python3 tools/pixellab_sheet.py <saved image> assets/characters/<hero>/walk --rows south,... --frames 6 --palette N`
- a direction re-rolled with a v3 custom animation is stored on an 84 px canvas: `--cell 84 --offset 10,10`.

N is the palette size the workbench reports; the script checks it rebuilt exactly that many colours.
Template animations sometimes lose a detail on one direction (Astra's hood): look at every sheet and re-roll
that direction (a v3 custom animation keeps the look better).

Every new design is checked against well-known game / anime characters before it goes in (a first Nym came
out too close to a Genshin Impact character and was thrown away).
