class_name PalewheelLevels
extends RefCounted

const FRAME: Array[Rect2] = [
	Rect2(110, 168, 1700, 30),
	Rect2(110, 898, 1700, 30),
	Rect2(110, 168, 30, 760),
	Rect2(1780, 168, 30, 760),
]


static func count() -> int:
	return 16


static func get_level(index: int) -> Dictionary:
	var base: Dictionary = {
		"backdrop": mini(index, 3),
		"environment": "",
		"environment_zone": Rect2(),
		"start": Vector2(270, 822),
		"exit": Vector2(1705, 815),
		"walls": FRAME.duplicate(),
		"phase_walls": [],
		"hazards": [],
		"crate": Vector2.ZERO,
		"pad": Vector2.ZERO,
		"checkpoint": Vector2.ZERO,
		"sentries": [],
		"shards": [],
		"shard_phases": [],
	}
	match index:
		0:
			base.merge({
				"name": "The First Stitch",
				"hint": "The high hem blocks the floor. Shift twice and run along the ceiling.",
				"accent": Color("18c9df"),
				"walls": FRAME + [Rect2(770, 600, 42, 298), Rect2(1170, 675, 42, 223)],
				"checkpoint": Vector2(1050, 260),
				"shards": [Vector2(445, 770), Vector2(965, 270), Vector2(1500, 750)],
			}, true)
		1:
			base.merge({
				"name": "Reverse Hem",
				"hint": "Turn the room over. The zipper waits at the far end of the ceiling.",
				"accent": Color("f46b42"),
				"start": Vector2(1630, 820),
				"exit": Vector2(310, 278),
				"walls": FRAME + [Rect2(1110, 540, 44, 358), Rect2(680, 635, 40, 263)],
				"checkpoint": Vector2(1030, 265),
				"shards": [Vector2(1490, 755), Vector2(930, 280), Vector2(490, 275)],
			}, true)
		2:
			base.merge({
				"name": "Loose Bridge",
				"hint": "The mint button needs a lit seam. Shift toward the wall and climb.",
				"accent": Color("e9ab34"),
				"walls": FRAME + [Rect2(780, 535, 40, 363), Rect2(1400, 665, 42, 233)],
				"phase_walls": [Rect2(1180, 360, 38, 420)],
				"checkpoint": Vector2(930, 275),
				"shards": [Vector2(460, 775), Vector2(1125, 485), Vector2(1570, 760)],
				"shard_phases": [-1, 1, -1],
			}, true)
		3:
			base.merge({
				"name": "Needle Clock",
				"hint": "Shift to still the moth. Cross its track before the wings wake.",
				"accent": Color("8e7ae8"),
				"start": Vector2(310, 822),
				"exit": Vector2(1610, 815),
				"walls": FRAME + [Rect2(740, 645, 32, 253), Rect2(1150, 525, 280, 30)],
				"phase_walls": [Rect2(845, 515, 220, 28)],
				"hazards": [Rect2(915, 870, 150, 28)],
				"checkpoint": Vector2(815, 265),
				"sentries": [{"from": Vector2(1150, 715), "to": Vector2(1290, 715), "period": 3.2, "offset": 0.4}],
				"shards": [Vector2(475, 770), Vector2(980, 630), Vector2(1440, 660)],
			}, true)
		4:
			base.merge({
				"name": "The Weighted Patch",
				"hint": "Push the patch into the corner, then turn the pull upward.",
				"crate": Vector2(470, 835),
				"pad": Vector2(1025, 225),
				"walls": FRAME + [Rect2(1060, 560, 44, 338), Rect2(1380, 640, 38, 258)],
				"checkpoint": Vector2(970, 805),
				"shards": [Vector2(380, 755), Vector2(930, 285), Vector2(1530, 750)],
			}, true)
		5:
			base.merge({
				"name": "Blue Thread",
				"hint": "The flooded cloth slows your fall. Turn upward inside the pool.",
				"backdrop": 4,
				"environment": "water",
				"environment_zone": Rect2(570, 540, 770, 358),
				"exit": Vector2(1640, 295),
				"walls": FRAME + [Rect2(710, 555, 40, 343), Rect2(1305, 450, 34, 448)],
				"checkpoint": Vector2(1020, 790),
				"shards": [Vector2(425, 760), Vector2(925, 700), Vector2(1450, 295)],
			}, true)
		6:
			base.merge({
				"name": "Sand Drift",
				"hint": "The gust carries you right. Turn the pull before the second dune.",
				"backdrop": 5,
				"environment": "dunes",
				"environment_zone": Rect2(540, 280, 930, 618),
				"walls": FRAME + [Rect2(605, 700, 38, 198), Rect2(1140, 560, 44, 338)],
				"checkpoint": Vector2(1010, 265),
				"shards": [Vector2(400, 755), Vector2(890, 525), Vector2(1510, 745)],
			}, true)
		7:
			base.merge({
				"name": "Against the Grain",
				"hint": "Travel left into the wind. A lit seam wakes the mint button.",
				"backdrop": 5,
				"environment": "dunes",
				"environment_zone": Rect2(510, 260, 1010, 638),
				"start": Vector2(1620, 820),
				"exit": Vector2(300, 815),
				"walls": FRAME + [Rect2(1180, 645, 38, 253), Rect2(710, 590, 38, 308)],
				"phase_walls": [Rect2(915, 410, 280, 28)],
				"checkpoint": Vector2(1060, 265),
				"shards": [Vector2(1500, 755), Vector2(1015, 280), Vector2(480, 745)],
				"shard_phases": [-1, 1, -1],
			}, true)
		8:
			base.merge({
				"name": "Green Canopy",
				"hint": "A canopy draft lifts you under the bridge.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(725, 390, 485, 508),
				"walls": FRAME + [Rect2(700, 650, 34, 248), Rect2(1170, 585, 34, 313)],
				"phase_walls": [Rect2(770, 535, 290, 26)],
				"checkpoint": Vector2(1030, 815),
				"shards": [Vector2(410, 710), Vector2(915, 405), Vector2(1540, 685)],
			}, true)
		9:
			base.merge({
				"name": "Rootwork",
				"hint": "Set the weighted patch, then ride the canopy draft.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(1050, 370, 590, 528),
				"crate": Vector2(460, 835),
				"pad": Vector2(760, 876),
				"walls": FRAME + [Rect2(1060, 565, 34, 333), Rect2(1340, 470, 265, 28)],
				"phase_walls": [Rect2(1125, 675, 220, 26)],
				"checkpoint": Vector2(980, 815),
				"sentries": [{"from": Vector2(1370, 345), "to": Vector2(1610, 345), "period": 2.8, "offset": 0.8}],
				"shards": [Vector2(565, 405), Vector2(1195, 370), Vector2(1580, 715)],
			}, true)
		10:
			base.merge({
				"name": "Night Quilt",
				"hint": "In the night cloth, each jump carries farther.",
				"backdrop": 7,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"walls": FRAME + [Rect2(650, 645, 34, 253), Rect2(1080, 470, 34, 428), Rect2(1370, 325, 260, 28)],
				"checkpoint": Vector2(890, 815),
				"shards": [Vector2(395, 505), Vector2(910, 405), Vector2(1510, 385)],
			}, true)
		11:
			base.merge({
				"name": "Moon Hem",
				"hint": "Drift across the quilt. Shift to sew the bridge.",
				"backdrop": 7,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"walls": FRAME + [Rect2(600, 575, 34, 323), Rect2(1050, 615, 34, 283), Rect2(1430, 490, 34, 408)],
				"phase_walls": [Rect2(695, 420, 280, 26), Rect2(1150, 350, 230, 26)],
				"hazards": [Rect2(750, 870, 155, 28), Rect2(1215, 870, 125, 28)],
				"checkpoint": Vector2(980, 815),
				"sentries": [{"from": Vector2(1200, 290), "to": Vector2(1560, 290), "period": 4.2, "offset": 1.0}],
				"shards": [Vector2(400, 310), Vector2(880, 345), Vector2(1570, 360)],
			}, true)
		12:
			base.merge({
				"name": "Rainline",
				"hint": "The gust changes direction. Shift when the rain leans.",
				"backdrop": 8,
				"environment": "rain",
				"environment_zone": Rect2(420, 220, 1120, 678),
				"walls": FRAME + [Rect2(700, 590, 34, 308), Rect2(1110, 475, 285, 28)],
				"checkpoint": Vector2(935, 815),
				"shards": [Vector2(390, 680), Vector2(885, 425), Vector2(1500, 705)],
			}, true)
		13:
			base.merge({
				"name": "Storm Stitch",
				"hint": "Use the gust to reach the bridge, then shift to hold it.",
				"backdrop": 8,
				"environment": "rain",
				"environment_zone": Rect2(480, 205, 1150, 693),
				"walls": FRAME + [Rect2(575, 650, 34, 248), Rect2(1260, 525, 34, 373)],
				"phase_walls": [Rect2(730, 500, 330, 26)],
				"hazards": [Rect2(1010, 870, 140, 28)],
				"checkpoint": Vector2(810, 815),
				"sentries": [{"from": Vector2(1360, 370), "to": Vector2(1580, 370), "period": 3.0, "offset": 0.6}],
				"shards": [Vector2(390, 405), Vector2(910, 385), Vector2(1560, 680)],
			}, true)
		14:
			base.merge({
				"name": "Frostline",
				"hint": "The snow keeps your momentum. Brake before the needles.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"walls": FRAME + [Rect2(660, 630, 34, 268), Rect2(1050, 535, 290, 28)],
				"hazards": [Rect2(790, 870, 120, 28)],
				"checkpoint": Vector2(1040, 815),
				"shards": [Vector2(370, 520), Vector2(945, 460), Vector2(1530, 720)],
			}, true)
		15:
			base.merge({
				"name": "The Last Seam",
				"hint": "Carry momentum, cross the moths, and close the final seam.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"walls": FRAME + [Rect2(590, 640, 34, 258), Rect2(1130, 570, 34, 328), Rect2(1410, 380, 230, 28)],
				"phase_walls": [Rect2(680, 510, 300, 26), Rect2(1190, 405, 220, 26)],
				"hazards": [Rect2(815, 870, 145, 28), Rect2(1220, 870, 125, 28)],
				"checkpoint": Vector2(1080, 815),
				"sentries": [
					{"from": Vector2(720, 340), "to": Vector2(975, 340), "period": 3.4, "offset": 0.4},
					{"from": Vector2(1420, 310), "to": Vector2(1640, 310), "period": 2.9, "offset": 1.2},
				],
				"shards": [Vector2(380, 375), Vector2(1035, 355), Vector2(1590, 310)],
			}, true)
	return base
