# Character sprites

One folder per character id (`astra`, `lyra`, `kael`, `nym`, and `boss` for the
Corrupted Guardian), each with 8 direction PNGs named:

south.png, south-east.png, east.png, north-east.png,
north.png, north-west.png, west.png, south-west.png

`CharacterArt` loads them automatically; when a folder is missing the game draws
the coloured placeholder instead. Sprites come from PixelLab (64x64 chibi heroes,
64x64 boss, low top-down view).
