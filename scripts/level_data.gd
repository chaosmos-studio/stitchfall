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
				"shards": [Vector2(445, 820), Vector2(965, 270), Vector2(1500, 750)],
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
				"hint": "Ride the gust over two dunes.",
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
				"hint": "The canopy lifts you. Catch the high ledge before it lets go.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(450, 340, 790, 558),
				"exit": Vector2(1620, 290),
				"walls": FRAME + [Rect2(760, 620, 315, 30), Rect2(1320, 420, 285, 30)],
				"checkpoint": Vector2(975, 550),
				"shards": [Vector2(385, 755), Vector2(840, 520), Vector2(1440, 290)],
			}, true)
		9:
			base.merge({
				"name": "Rootwork",
				"hint": "Push the patch left to the root. Ride the lift back across.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(700, 340, 470, 558),
				"start": Vector2(1650, 820),
				"exit": Vector2(310, 285),
				"crate": Vector2(1510, 835),
				"pad": Vector2(1300, 876),
				"walls": FRAME + [Rect2(1220, 680, 42, 218), Rect2(600, 420, 310, 30)],
				"checkpoint": Vector2(1080, 510),
				"shards": [Vector2(1530, 755), Vector2(970, 470), Vector2(470, 290)],
			}, true)
		10:
			base.merge({
				"name": "Night Quilt",
				"hint": "Low gravity carries a jump across three stepping ledges.",
				"backdrop": 7,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"exit": Vector2(1650, 285),
				"walls": FRAME + [Rect2(520, 670, 290, 28), Rect2(925, 515, 280, 28), Rect2(1335, 365, 285, 28)],
				"checkpoint": Vector2(1030, 440),
				"shards": [Vector2(420, 765), Vector2(1045, 445), Vector2(1480, 290)],
			}, true)
		11:
			base.merge({
				"name": "Moon Hem",
				"hint": "Descend through the quilt. Light the seam at the middle ledge.",
				"backdrop": 7,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"start": Vector2(1650, 268),
				"exit": Vector2(310, 815),
				"walls": FRAME + [Rect2(1260, 390, 290, 28), Rect2(815, 540, 270, 28), Rect2(420, 680, 260, 28)],
				"phase_walls": [Rect2(1040, 365, 35, 300)],
				"hazards": [Rect2(700, 870, 175, 28)],
				"checkpoint": Vector2(885, 480),
				"shards": [Vector2(1490, 270), Vector2(1010, 465), Vector2(510, 745)],
				"shard_phases": [-1, 1, -1],
			}, true)
		12:
			base.merge({
				"name": "Rainline",
				"hint": "Shift above the tear. Let the gust carry you.",
				"backdrop": 8,
				"environment": "rain",
				"environment_zone": Rect2(430, 230, 1090, 668),
				"walls": FRAME + [Rect2(735, 640, 470, 28), Rect2(1240, 545, 245, 28)],
				"hazards": [Rect2(770, 870, 370, 28)],
				"checkpoint": Vector2(1100, 565),
				"shards": [Vector2(410, 750), Vector2(965, 570), Vector2(1500, 760)],
			}, true)
		13:
			base.merge({
				"name": "Storm Stitch",
				"hint": "Travel against the storm. The mint button wakes on a wall turn.",
				"backdrop": 8,
				"environment": "rain",
				"environment_zone": Rect2(470, 215, 1130, 683),
				"start": Vector2(1630, 820),
				"exit": Vector2(315, 285),
				"walls": FRAME + [Rect2(1250, 595, 40, 303), Rect2(630, 540, 40, 358)],
				"phase_walls": [Rect2(975, 350, 36, 390)],
				"hazards": [Rect2(760, 870, 120, 28)],
				"checkpoint": Vector2(1090, 275),
				"sentries": [{"from": Vector2(710, 370), "to": Vector2(900, 370), "period": 3.2, "offset": 0.6}],
				"shards": [Vector2(1500, 755), Vector2(1030, 470), Vector2(470, 285)],
				"shard_phases": [-1, 1, -1],
			}, true)
		14:
			base.merge({
				"name": "Frostline",
				"hint": "The frost keeps your speed. Land in the safe strip and brake.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"walls": FRAME + [Rect2(970, 580, 290, 28)],
				"hazards": [Rect2(710, 870, 220, 28), Rect2(1270, 870, 220, 28)],
				"checkpoint": Vector2(1090, 815),
				"shards": [Vector2(430, 755), Vector2(1085, 755), Vector2(1630, 755)],
			}, true)
		15:
			base.merge({
				"name": "The Last Seam",
				"hint": "Cross the frozen cloth, light the middle seam, and evade the moths.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"start": Vector2(1640, 820),
				"exit": Vector2(300, 285),
				"walls": FRAME + [Rect2(1230, 570, 40, 328), Rect2(710, 630, 40, 268)],
				"phase_walls": [Rect2(950, 340, 40, 410)],
				"hazards": [Rect2(1050, 870, 125, 28), Rect2(470, 870, 125, 28)],
				"checkpoint": Vector2(1040, 275),
				"sentries": [
					{"from": Vector2(780, 390), "to": Vector2(920, 390), "period": 3.4, "offset": 0.4},
					{"from": Vector2(1320, 680), "to": Vector2(1490, 680), "period": 2.9, "offset": 1.2},
				],
				"shards": [Vector2(1510, 755), Vector2(1010, 475), Vector2(440, 285)],
				"shard_phases": [-1, 1, -1],
			}, true)
	return base
