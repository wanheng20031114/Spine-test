extends Node2D

func _ready() -> void:
	get_window().size = Vector2i(1440, 900)
	var frames := [0, 2, 4, 4, 7, 7, 7, 2]
	for i in range(8):
		var sprite: AnimatedSprite2D = get_node("Pose" + str(i))
		sprite.pause()
		sprite.frame = frames[i]
	if "--capture-sprite-review" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.local/sprite-review.png")
		print("SPRITE_REVIEW_CAPTURED")
		get_tree().quit()
