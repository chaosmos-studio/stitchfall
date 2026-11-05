class_name PalewheelLevels
extends RefCounted

const FRAME: Array[Rect2] = [
	Rect2(110, 168, 1700, 30),
	Rect2(110, 898, 1700, 30),
	Rect2(110, 168, 30, 760),
	Rect2(1780, 168, 30, 760),
]


static func count() -> int:
	return 26


static func wide_frame(width: float) -> Array[Rect2]:
	return [
		Rect2(110, 168, width - 220, 30),
		Rect2(110, 898, width - 220, 30),
		Rect2(110, 168, 30, 760),
		Rect2(width - 140, 168, 30, 760),
	]


static func get_level(index: int) -> Dictionary:
	var base: Dictionary = {
		"width": 1920.0,
		"backdrop": mini(index, 3),
		"environment": "",
		"environment_zone": Rect2(),
		"start": Vector2(270, 822),
		"exit": Vector2(1705, 815),
		"walls": FRAME.duplicate(),
		"phase_walls": [],
		"timed_gates": [],
		"gate_window": 2.2,
		"bloom_pads": [],
		"ferries": [],
		"mechanisms": [],
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
				"hint": "Shift wakes the cutter. Ride the hem under its pass.",
				"accent": Color("8e7ae8"),
				"width": 2600.0,
				"start": Vector2(310, 822),
				"exit": Vector2(2430, 815),
				"walls": wide_frame(2600) + [Rect2(1150, 525, 280, 30), Rect2(2020, 510, 270, 28)],
				"timed_gates": [Rect2(740, 198, 36, 700), Rect2(2250, 198, 36, 700)],
				"gate_window": 3.0,
				"phase_walls": [Rect2(845, 515, 220, 28)],
				"hazards": [Rect2(915, 870, 150, 28), Rect2(1760, 870, 170, 28)],
				"checkpoint": Vector2(1530, 810),
				"sentries": [{"from": Vector2(1150, 715), "to": Vector2(1290, 715), "period": 3.2, "offset": 0.4}],
				"ferries": [{"from": Vector2(1630, 735), "to": Vector2(1990, 560), "size": Vector2(210, 28), "period": 4.8}],
				"mechanisms": [{"kind": "cutter", "from": Vector2(1560, 580), "to": Vector2(1980, 580), "period": 3.6, "shift_armed": true}],
				"shards": [Vector2(475, 770), Vector2(1990, 485), Vector2(2350, 755)],
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
				"hint": "Catch the moving hem while the hanging weight rises.",
				"backdrop": 5,
				"width": 2500.0,
				"environment": "dunes",
				"environment_zone": Rect2(540, 280, 1560, 618),
				"exit": Vector2(2310, 815),
				"walls": wide_frame(2500) + [Rect2(605, 700, 38, 198), Rect2(1140, 560, 44, 338), Rect2(2030, 550, 230, 28)],
				"hazards": [Rect2(1590, 870, 325, 28)],
				"ferries": [{"from": Vector2(1490, 720), "to": Vector2(1870, 560), "size": Vector2(205, 28), "period": 4.2}],
				"mechanisms": [{"kind": "pulley", "from": Vector2(1770, 280), "to": Vector2(1770, 720), "anchor": Vector2(1770, 210), "period": 4.1}],
				"checkpoint": Vector2(1270, 815),
				"shards": [Vector2(400, 755), Vector2(890, 525), Vector2(1840, 490)],
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
				"hint": "The copper spring skips the lower canopy.",
				"backdrop": 6,
				"width": 2850.0,
				"environment": "forest",
				"environment_zone": Rect2(450, 340, 1120, 558),
				"bloom_pads": [Vector2(390, 870), Vector2(1780, 870)],
				"exit": Vector2(2650, 290),
				"walls": wide_frame(2850) + [Rect2(760, 620, 315, 30), Rect2(1320, 420, 285, 30), Rect2(2350, 390, 310, 30)],
				"hazards": [Rect2(2040, 870, 190, 28)],
				"ferries": [{"from": Vector2(1860, 660), "to": Vector2(2240, 440), "size": Vector2(220, 28), "period": 5.0}],
				"mechanisms": [{"kind": "spring", "from": Vector2(1130, 850)}],
				"checkpoint": Vector2(1510, 510),
				"shards": [Vector2(385, 755), Vector2(1450, 340), Vector2(2470, 315)],
			}, true)
		9:
			base.merge({
				"name": "Rootwork",
				"hint": "Seat the patch, then catch the bloom on the return.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(700, 340, 470, 558),
				"bloom_pads": [Vector2(610, 870)],
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
				"hint": "Catch the bloom on the first ledge to reach the stars.",
				"backdrop": 7,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"bloom_pads": [Vector2(735, 645)],
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
				"hint": "Shift starts the chain. Cross before the hanging weight falls.",
				"backdrop": 8,
				"width": 2800.0,
				"environment": "rain",
				"environment_zone": Rect2(430, 230, 2060, 668),
				"exit": Vector2(2600, 815),
				"walls": wide_frame(2800) + [Rect2(735, 640, 470, 28), Rect2(1240, 545, 245, 28), Rect2(2140, 500, 270, 28)],
				"timed_gates": [Rect2(1510, 198, 36, 700), Rect2(2420, 198, 36, 700)],
				"hazards": [Rect2(770, 870, 370, 28), Rect2(1850, 870, 220, 28)],
				"ferries": [{"from": Vector2(1700, 735), "to": Vector2(2150, 545), "size": Vector2(215, 28), "period": 5.2}],
				"mechanisms": [
					{"kind": "chain", "from": Vector2(1690, 600), "to": Vector2(2020, 600), "period": 4.6, "shift_armed": true},
					{"kind": "pulley", "from": Vector2(2290, 280), "to": Vector2(2290, 690), "anchor": Vector2(2290, 210), "period": 3.9},
				],
				"checkpoint": Vector2(1100, 565),
				"shards": [Vector2(410, 750), Vector2(965, 570), Vector2(2530, 755)],
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
				"hint": "Brake before the cutter reaches the safe strip.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"walls": FRAME + [Rect2(970, 580, 290, 28)],
				"hazards": [Rect2(710, 870, 220, 28), Rect2(1270, 870, 220, 28)],
				"checkpoint": Vector2(1090, 815),
				"mechanisms": [{"kind": "cutter", "from": Vector2(1050, 710), "to": Vector2(1400, 710), "period": 3.3}],
				"shards": [Vector2(430, 755), Vector2(1085, 755), Vector2(1630, 755)],
			}, true)
		15:
			base.merge({
				"name": "Cold Seam",
				"hint": "Bounce through the last seam before the chain wakes.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"start": Vector2(1640, 820),
				"exit": Vector2(300, 285),
				"walls": FRAME + [Rect2(1230, 570, 40, 328), Rect2(710, 630, 40, 268)],
				"phase_walls": [Rect2(950, 340, 40, 410)],
				"timed_gates": [Rect2(650, 198, 36, 700)],
				"gate_window": 1.7,
				"bloom_pads": [Vector2(1410, 870)],
				"hazards": [Rect2(1050, 870, 125, 28), Rect2(470, 870, 125, 28)],
				"checkpoint": Vector2(1040, 275),
				"sentries": [
					{"from": Vector2(780, 390), "to": Vector2(920, 390), "period": 3.4, "offset": 0.4},
					{"from": Vector2(1320, 680), "to": Vector2(1490, 680), "period": 2.9, "offset": 1.2},
				],
				"mechanisms": [
					{"kind": "spring", "from": Vector2(875, 850)},
					{"kind": "chain", "from": Vector2(790, 525), "to": Vector2(1110, 525), "period": 3.5, "shift_armed": true},
				],
				"shards": [Vector2(1510, 755), Vector2(1010, 475), Vector2(440, 285)],
				"shard_phases": [-1, 1, -1],
			}, true)
		16:
			base.merge({
				"name": "Threadfall",
				"hint": "Start at the high hem. Drop past the shelves, then turn the last fall.",
				"backdrop": 3,
				"start": Vector2(290, 275),
				"exit": Vector2(1610, 815),
				"walls": FRAME + [Rect2(280, 380, 300, 28), Rect2(810, 555, 305, 28), Rect2(1360, 705, 260, 28)],
				"checkpoint": Vector2(1010, 480),
				"shards": [Vector2(480, 300), Vector2(980, 485), Vector2(1480, 635)],
			}, true)
		17:
			base.merge({
				"name": "Backstitch",
				"hint": "The wall hides the button. Run past it on the ceiling, then come back.",
				"backdrop": 2,
				"start": Vector2(1595, 820),
				"exit": Vector2(1510, 285),
				"walls": FRAME + [Rect2(1180, 495, 42, 403), Rect2(670, 630, 42, 268), Rect2(850, 455, 235, 28)],
				"phase_walls": [Rect2(800, 305, 230, 28)],
				"checkpoint": Vector2(520, 285),
				"shards": [Vector2(1430, 755), Vector2(530, 750), Vector2(970, 275)],
			}, true)
		18:
			base.merge({
				"name": "Pond Stitch",
				"hint": "Sink for the low button. Turn the pull before you leave the water.",
				"backdrop": 4,
				"environment": "water",
				"environment_zone": Rect2(520, 500, 820, 398),
				"start": Vector2(310, 275),
				"exit": Vector2(1600, 815),
				"walls": FRAME + [Rect2(540, 420, 340, 28), Rect2(1240, 390, 42, 508)],
				"checkpoint": Vector2(1000, 765),
				"shards": [Vector2(460, 365), Vector2(930, 770), Vector2(1450, 280)],
			}, true)
		19:
			base.merge({
				"name": "Countercurrent",
				"hint": "Cross the pool against the pull. Catch the hem as it rises.",
				"backdrop": 4,
				"width": 2350.0,
				"environment": "water",
				"environment_zone": Rect2(625, 300, 1110, 598),
				"start": Vector2(2140, 820),
				"exit": Vector2(285, 285),
				"walls": wide_frame(2350) + [Rect2(1730, 570, 42, 328), Rect2(670, 480, 42, 418)],
				"ferries": [{"from": Vector2(1350, 730), "to": Vector2(1010, 390), "size": Vector2(210, 28), "period": 5.1}],
				"checkpoint": Vector2(1050, 825),
				"shards": [Vector2(1980, 750), Vector2(1250, 590), Vector2(440, 360)],
			}, true)
		20:
			base.merge({
				"name": "Kite Thread",
				"hint": "Let the warm gust carry you, then turn onto the upper ledge.",
				"backdrop": 5,
				"width": 2450.0,
				"environment": "dunes",
				"environment_zone": Rect2(425, 250, 1530, 648),
				"exit": Vector2(2220, 280),
				"walls": wide_frame(2450) + [Rect2(560, 700, 240, 28), Rect2(1130, 535, 300, 28), Rect2(1830, 385, 280, 28)],
				"bloom_pads": [Vector2(680, 870)],
				"checkpoint": Vector2(1350, 460),
				"shards": [Vector2(450, 750), Vector2(1230, 455), Vector2(2010, 310)],
			}, true)
		21:
			base.merge({
				"name": "Still Sand",
				"hint": "Move left against the gust. Shift to stop the cutter at the narrow hem.",
				"backdrop": 5,
				"environment": "dunes",
				"environment_zone": Rect2(430, 240, 1160, 658),
				"start": Vector2(1590, 265),
				"exit": Vector2(295, 815),
				"walls": FRAME + [Rect2(1220, 380, 290, 28), Rect2(730, 555, 305, 28)],
				"mechanisms": [{"kind": "cutter", "from": Vector2(690, 765), "to": Vector2(1050, 765), "period": 3.8, "shift_armed": true}],
				"checkpoint": Vector2(940, 480),
				"shards": [Vector2(1470, 275), Vector2(960, 485), Vector2(440, 755)],
			}, true)
		22:
			base.merge({
				"name": "Bloom Ladder",
				"hint": "Each flower lifts you one shelf. Turn at the top to reach the zipper.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(490, 290, 970, 608),
				"start": Vector2(940, 820),
				"exit": Vector2(300, 275),
				"walls": FRAME + [Rect2(520, 700, 280, 28), Rect2(1040, 525, 280, 28), Rect2(480, 355, 300, 28)],
				"bloom_pads": [Vector2(920, 870), Vector2(1160, 500)],
				"checkpoint": Vector2(1190, 460),
				"shards": [Vector2(1080, 765), Vector2(620, 625), Vector2(600, 280)],
			}, true)
		23:
			base.merge({
				"name": "Root Pocket",
				"hint": "The mint button hides below the root. Light the seam, then climb out.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(490, 290, 1000, 608),
				"start": Vector2(1590, 820),
				"exit": Vector2(335, 285),
				"walls": FRAME + [Rect2(1280, 585, 42, 313), Rect2(460, 500, 360, 28)],
				"phase_walls": [Rect2(900, 675, 350, 28)],
				"bloom_pads": [Vector2(650, 870)],
				"checkpoint": Vector2(1050, 775),
				"shards": [Vector2(1480, 755), Vector2(1040, 760), Vector2(565, 425)],
				"shard_phases": [-1, 1, -1],
			}, true)
		24:
			base.merge({
				"name": "Rain Reversal",
				"hint": "Cross the high seam before it closes. The storm pushes you back.",
				"backdrop": 8,
				"width": 2300.0,
				"environment": "rain",
				"environment_zone": Rect2(340, 210, 1650, 688),
				"start": Vector2(290, 275),
				"exit": Vector2(2060, 815),
				"walls": wide_frame(2300) + [Rect2(450, 400, 310, 28), Rect2(1250, 600, 290, 28)],
				"timed_gates": [Rect2(980, 198, 36, 700)],
				"gate_window": 2.5,
				"ferries": [{"from": Vector2(1580, 735), "to": Vector2(1830, 470), "size": Vector2(200, 28), "period": 4.7}],
				"checkpoint": Vector2(1380, 525),
				"shards": [Vector2(560, 325), Vector2(1130, 285), Vector2(1880, 745)],
			}, true)
		25:
			base.merge({
				"name": "Frost Brake",
				"hint": "Gather speed, then brake on the tiny dry patch before shifting up.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(600, 540, 1000, 358),
				"start": Vector2(1590, 820),
				"exit": Vector2(285, 280),
				"walls": FRAME + [Rect2(620, 545, 320, 28), Rect2(1100, 640, 235, 28)],
				"hazards": [Rect2(745, 870, 260, 28), Rect2(1170, 870, 170, 28)],
				"mechanisms": [{"kind": "cutter", "from": Vector2(970, 710), "to": Vector2(1250, 710), "period": 3.1}],
				"checkpoint": Vector2(1060, 470),
				"shards": [Vector2(1510, 750), Vector2(1090, 590), Vector2(480, 285)],
			}, true)
	return base
