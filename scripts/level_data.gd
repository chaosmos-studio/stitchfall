class_name PalewheelLevels
extends RefCounted

const FRAME: Array[Rect2] = [
	Rect2(110, 168, 1700, 30),
	Rect2(110, 898, 1700, 30),
	Rect2(110, 168, 30, 760),
	Rect2(1780, 168, 30, 760),
]


static func count() -> int:
	return 12


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
	}
	match index:
		0:
			base.merge({
				"name": "DOCK 01",
				"hint": "Run and jump. Turn gravity to clear the shaft.",
				"accent": Color("18c9df"),
				"walls": FRAME + [Rect2(810, 628, 34, 270), Rect2(1030, 478, 330, 28)],
				"checkpoint": Vector2(1180, 815),
				"shards": [Vector2(525, 760), Vector2(976, 370), Vector2(1488, 728)],
			}, true)
		1:
			base.merge({
				"name": "SENSOR ARRAY",
				"hint": "A turn changes the bridges and pauses the drone.",
				"accent": Color("f46b42"),
				"walls": FRAME + [Rect2(545, 680, 28, 218), Rect2(1170, 560, 28, 338)],
				"phase_walls": [Rect2(620, 568, 310, 26), Rect2(1250, 430, 260, 26)],
				"hazards": [Rect2(884, 870, 200, 28)],
				"checkpoint": Vector2(720, 815),
				"sentries": [{"from": Vector2(940, 320), "to": Vector2(1110, 320), "period": 3.4, "offset": 0.0}],
				"shards": [Vector2(425, 310), Vector2(1000, 490), Vector2(1500, 340)],
			}, true)
		2:
			base.merge({
				"name": "MASS TRANSFER",
				"hint": "Move the cargo onto its plate by turning gravity.",
				"accent": Color("e9ab34"),
				"crate": Vector2(488, 835),
				"pad": Vector2(764, 876),
				"walls": FRAME + [Rect2(1070, 548, 32, 350), Rect2(1290, 455, 270, 28)],
				"hazards": [Rect2(1110, 870, 145, 28)],
				"checkpoint": Vector2(940, 815),
				"sentries": [{"from": Vector2(1240, 675), "to": Vector2(1500, 675), "period": 3.1, "offset": 1.0}],
				"shards": [Vector2(590, 368), Vector2(1198, 392), Vector2(1580, 725)],
			}, true)
		3:
			base.merge({
				"name": "THE CORE",
				"hint": "Time each turn to pass the drones and restart the core.",
				"accent": Color("8e7ae8"),
				"walls": FRAME + [Rect2(610, 550, 32, 348), Rect2(975, 285, 32, 360), Rect2(1345, 540, 32, 358)],
				"phase_walls": [Rect2(675, 485, 260, 26), Rect2(1040, 712, 260, 26)],
				"hazards": [Rect2(745, 870, 130, 28), Rect2(1465, 870, 120, 28)],
				"checkpoint": Vector2(1130, 815),
				"sentries": [
					{"from": Vector2(650, 350), "to": Vector2(850, 350), "period": 2.7, "offset": 0.5},
					{"from": Vector2(1410, 365), "to": Vector2(1620, 365), "period": 3.3, "offset": 2.0},
				],
				"shards": [Vector2(405, 313), Vector2(1060, 354), Vector2(1580, 335)],
			}, true)
		4:
			base.merge({
				"name": "TIDE LOCK",
				"hint": "Floodwater slows your fall. Turn gravity through the pool.",
				"backdrop": 4,
				"environment": "water",
				"environment_zone": Rect2(660, 590, 680, 308),
				"walls": FRAME + [Rect2(610, 660, 34, 238), Rect2(1000, 510, 310, 28)],
				"checkpoint": Vector2(935, 815),
				"shards": [Vector2(420, 730), Vector2(870, 420), Vector2(1500, 690)],
			}, true)
		5:
			base.merge({
				"name": "PUMP GALLERY",
				"hint": "Use the flooded sluice to soften the descent.",
				"backdrop": 4,
				"environment": "water",
				"environment_zone": Rect2(595, 560, 320, 338),
				"walls": FRAME + [Rect2(570, 620, 32, 278), Rect2(1110, 585, 32, 313)],
				"phase_walls": [Rect2(670, 485, 245, 26)],
				"hazards": [Rect2(930, 870, 145, 28)],
				"checkpoint": Vector2(800, 815),
				"sentries": [{"from": Vector2(1210, 420), "to": Vector2(1480, 420), "period": 3.7, "offset": 0.4}],
				"shards": [Vector2(405, 430), Vector2(980, 350), Vector2(1570, 695)],
			}, true)
		6:
			base.merge({
				"name": "DUNE RELAY",
				"hint": "The sand wind pushes right. Turn with its momentum.",
				"backdrop": 5,
				"environment": "dunes",
				"environment_zone": Rect2(580, 280, 1030, 618),
				"walls": FRAME + [Rect2(535, 700, 32, 198), Rect2(900, 510, 315, 28)],
				"checkpoint": Vector2(1100, 815),
				"shards": [Vector2(360, 715), Vector2(815, 405), Vector2(1510, 710)],
			}, true)
		7:
			base.merge({
				"name": "SAND CHOKE",
				"hint": "Cross the sand wind, then switch the bridge.",
				"backdrop": 5,
				"environment": "dunes",
				"environment_zone": Rect2(590, 270, 1010, 628),
				"walls": FRAME + [Rect2(615, 610, 34, 288), Rect2(1180, 540, 34, 358)],
				"phase_walls": [Rect2(740, 445, 280, 26)],
				"hazards": [Rect2(940, 870, 155, 28)],
				"checkpoint": Vector2(850, 815),
				"sentries": [{"from": Vector2(1310, 355), "to": Vector2(1570, 355), "period": 3.2, "offset": 1.1}],
				"shards": [Vector2(400, 380), Vector2(1020, 375), Vector2(1570, 705)],
			}, true)
		8:
			base.merge({
				"name": "CANOPY BRIDGE",
				"hint": "The canopy draft lifts you under the bridge.",
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
				"name": "ROOT ENGINE",
				"hint": "Ride the canopy draft after setting the cargo plate.",
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
				"name": "ORBITAL RIM",
				"hint": "Outside the ring, each jump carries farther.",
				"backdrop": 7,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"walls": FRAME + [Rect2(650, 645, 34, 253), Rect2(1080, 470, 34, 428), Rect2(1370, 325, 260, 28)],
				"checkpoint": Vector2(890, 815),
				"shards": [Vector2(395, 505), Vector2(910, 405), Vector2(1510, 385)],
			}, true)
		11:
			base.merge({
				"name": "SOLAR SPAN",
				"hint": "Drift across the array. Shift to open the last bridge.",
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
	return base
