# Character illustrations (provided by Syifa)

Large anime illustrations shown on the Characters page portrait (and later the codex / victory screen).
The game uses `assets/illustrations/<character id>.png` automatically when the file exists; otherwise it shows
the pixel sprite scaled up. Ids: astra, lyra, kael, nym, selene, noah, raika, vesper, wren, sera, celeste, runa, lumi.

Spec (one image per character):
- PNG with a transparent background (no scenery, no frame, no text or logo).
- 768 x 1024 px (3:4 portrait). The game scales it to the portrait height, so keep the same size for everyone.
- Pose: standing, full body or knees-up, body turned slightly towards the left of the image (the portrait sits on
  the right side of the screen and should look into the screen). Head in the top quarter, the bottom edge of the
  image is the floor (the character stands on a glowing disc drawn by the game).
- Same outfit, hair and colours as the in-game sprite (`assets/characters/<id>/south.png`), cute anime style.
- Leave a little space on the sides for weapons / staves; nothing important closer than ~20 px to the edges.
- Make sure the design does not resemble a known game / anime character.
