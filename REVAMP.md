# Stitchfall revamp

The plan for 1.2.0: make the rooms as good as the menus. Controls stay swipes (Shravan, 2026-11-09).

## What is wrong now

Seen on a 20:9 phone, one room from every chapter (2026-11-09):

1. **The backdrop is a blurry slice.** `world_view.gd` stretches each 1672 by 941 painting over a fixed 2580 by 1440, but the camera only sees the room, about the middle 47% of the width and 40% of the height. So every room shows a magnified, empty middle of its painting, and the painting's details sit off screen.
2. **The first six chapters share one backdrop.** Plain Linen, Loose Pins, Unpinned, Lit Seams, Needle Moths and Weighted Patch all use `linen_landscape.png`, so thirty rooms look the same.
3. **Ledges and walls are flat rectangles.** A tinted felt texture inside an ink outline reads as a placeholder next to the painted art.
4. **The zipper exit is a teal box.**
5. **Needles are thin and small** (drawn at 0.3), so a hazard is hard to read at phone size.
6. **Floors are only the frame's edge.** Nothing grows on them, nothing settles on them, and the runner seems to stand on a line.
7. **Little reacts.** A landing, a turn of the room and a button make small effects, and a prank springs without a beat of surprise.
8. **The room's name is tiny and pale** at the top of the screen.
9. **Swipes can feel unsure.** A slide must travel 64 pixels before it means anything, with no sign it was read.

## What changes

Art (Codex, prompts below) and code (here), in this order:

1. Backdrops fitted to what the camera sees, and a painting for each of the first six chapters.
2. Felt ledges with stitched, padded edges, tinted per chapter, with a soft shadow.
3. A real zipper pocket for the exit that unzips and glows when every button is in.
4. Bolder needles, and sewing buttons drawn from art.
5. An embroidered grass fringe on floors and ledge tops.
6. Feel: a landing puff of fluff, a squash and stretch on jump and land, a sway of the whole room as it turns, a ring and a pop for each button, a beat of surprise when a prank springs.
7. Swipes: a thread drawn from where the finger landed while it slides, so the player sees the move being read, and a shorter travel to start a run.
8. The room's name as a sewn label that stays readable.

## Art prompts for Codex

Paste one block per Codex task. They share the setup and the style.

### Setup (put at the top of every prompt)

> You are making image assets for Stitchfall, a Godot game, in the repo at
> `/home/seeker/Work/Weekend-Projects/Games/prototypes/stitchfall` (GitHub `chaosmos-studio/stitchfall`).
> Work in a separate git worktree so the main checkout is untouched:
> `git -C /home/seeker/Work/Weekend-Projects/Games/prototypes/stitchfall worktree add ../stitchfall-revamp-art -b sg/revamp-art main`
> (if the worktree already exists, use it and stay on `sg/revamp-art`).
> Save every file at exactly the path given, inside that worktree. Make one commit per file, with a one-line
> message like `Add the Loose Pins backdrop`. Push the branch with `git push -u origin sg/revamp-art`.
> Do not edit any code, scenes, `.import` files or other assets, do not open a pull request and do not merge.
> When done, list each file with its pixel size and whether it has transparency.
>
> Style for everything: a photograph of a hand-sewn textile diorama, the same look as
> `assets/art/cloth_night.webp`, `assets/art/linen_landscape.png` and `assets/art/props/pincushion.png` in the
> repo (open them first). Real linen and wool felt with visible weave, cream running stitches, small embroidered
> details, soft even daylight from the top left, muted warm colours. No text, no letters, no people, no
> characters, no border or frame, no vignette.

### 1. Six chapter backdrops

> Paint six backdrops, each 1672 by 941 pixels, opaque PNG:
>
> - `assets/art/backdrops/linen.png`, Plain Linen: a calm sunny meadow sampler, cream sky, sage and wheat hills,
>   a few embroidered daisies.
> - `assets/art/backdrops/pins.png`, Loose Pins: a sewing table turned landscape, low hills of red and coral
>   pincushions in the distance, thread spools like little towers, a few pearl-headed pins standing in the grass
>   like fence posts. Warm reds and cream.
> - `assets/art/backdrops/unpinned.png`, Unpinned: a windy hillside under a pale blue-grey sky, loose fabric
>   patches lifting in the wind like kites, grasses bent one way.
> - `assets/art/backdrops/seams.png`, Lit Seams: dusk over rolling teal hills, seams of warm amber light stitched
>   across the hills like lit paths, a few felt lanterns.
> - `assets/art/backdrops/moths.png`, Needle Moths: a twilight garden in lavender and dusty rose, pale moonflowers,
>   a crescent felt moon, soft dotted flight paths in thread.
> - `assets/art/backdrops/patch.png`, Weighted Patch: patchwork farmland of quilted fields in ochre, rust and olive,
>   round wool bales, a stitched fence.
>
> They sit behind a platformer room that fills most of the picture, with ledges and the runner in front. So keep
> the middle calm and low in contrast (sky, soft distant hills), put the richest detail in the bottom fifth and the
> corners, and keep anything that matters inside the middle 80% of the height (wide phones crop the top and
> bottom). The six must look like one set with each other and with `cloth_night.webp`.

### 2. Felt ledge

> Make `assets/art/props/felt_ledge.png`, 1024 by 192 pixels, PNG with a transparent background: one horizontal
> strip of padded wool felt, like a sewn quilt binding, 140 pixels tall, centred top to bottom, with rounded ends.
> A cream running stitch runs 16 pixels inside its whole edge. The felt is a light neutral cream-grey, so the game
> can tint it any colour, softly lit from the top left with a slightly puffy edge. The middle part, from x 256 to
> x 768, must tile seamlessly left to right (check by placing two copies side by side). No shadow under it.

### 3. Zipper pocket exit

> Make two PNGs, each 512 by 704 pixels with a transparent background, framed identically so one can fade into the
> other:
>
> - `assets/art/props/pocket_closed.png`: an upright felt pocket in deep teal with a stitched cream edge, a brass
>   zipper running down its middle from top to bottom, closed, its pull tab hanging at the bottom with a small
>   rust-red thread tassel.
> - `assets/art/props/pocket_open.png`: the same pocket, the zipper pulled to the top and the two sides parted
>   into an opening, warm golden light glowing from inside.

### 4. Sewing buttons

> Make `assets/art/props/buttons.png`, 1024 by 256 pixels, PNG with a transparent background: four round sewing
> buttons in a row, each centred in its own 256 by 256 cell and about 200 pixels across: gold, coral, sage and
> cream. Each has four holes with cream thread crossed through them, a raised rim and a soft glossy highlight.

### 5. Grass fringe

> Make `assets/art/props/grass_fringe.png`, 1024 by 128 pixels, PNG with a transparent background: an embroidered
> fringe of grass blades, tiny clover leaves and a few small daisies, standing up from the bottom edge, about 70
> pixels tall at most, in muted sage green with cream highlights. It must tile seamlessly left to right.
