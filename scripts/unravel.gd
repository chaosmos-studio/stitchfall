class_name PalewheelUnravel
extends Node2D

const THREAD: Color = Color("f6e6c9")


func scatter(courier: PalewheelCourier) -> void:
	position = courier.position
	z_index = 8
	var source: Texture2D = courier.sprite.sprite_frames.get_frame_texture(courier.sprite.animation, courier.sprite.frame)
	var tile: Vector2 = source.get_size() / Vector2(3, 4)
	for row: int in range(4):
		for column: int in range(3):
			var piece: Sprite2D = Sprite2D.new()
			var crop: AtlasTexture = AtlasTexture.new()
			crop.atlas = source
			crop.region = Rect2(Vector2(column, row) * tile, tile)
			piece.texture = crop
			piece.scale = courier.sprite.scale
			piece.position = courier.sprite.position + (Vector2(column + 0.5, row + 0.5) * tile - source.get_size() * 0.5) * piece.scale
			piece.rotation = courier.sprite.rotation
			add_child(piece)
			var direction: Vector2 = Vector2(float(column - 1) * 41.0 + sin(float(row * 3 + column) * 2.0) * 16.0, -85.0 + float(row) * 12.0)
			var tween: Tween = create_tween().set_parallel(true)
			tween.tween_property(piece, "position", piece.position + direction, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(piece, "rotation", piece.rotation + float(column - 1) * 0.8 + float(row % 2) * 0.35, 0.62)
			tween.tween_property(piece, "modulate:a", 0.0, 0.62).set_delay(0.2)
	for index: int in range(11):
		var stitch: Line2D = Line2D.new()
		var angle: float = float(index) * TAU / 11.0
		stitch.width = 2.0
		stitch.default_color = THREAD
		stitch.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(angle) * (31.0 + float(index % 3) * 8.0)])
		add_child(stitch)
		var stitch_tween: Tween = create_tween().set_parallel(true)
		stitch_tween.tween_property(stitch, "position", Vector2.from_angle(angle) * 115.0, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		stitch_tween.tween_property(stitch, "modulate:a", 0.0, 0.62).set_delay(0.12)
