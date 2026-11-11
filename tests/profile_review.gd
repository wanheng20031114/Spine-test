extends Node2D

const ARM := "Skeleton2D/Hips/Torso/ArmAim/"


func _ready() -> void:
	_capture.call_deferred()


func _pose(rig: Node2D, locomotion_name: String, locomotion_time: float, action_name: String, action_time: float, bow_equipped: bool) -> void:
	var locomotion: AnimationPlayer = rig.get_node("Locomotion")
	var actions: AnimationPlayer = rig.get_node("Actions")
	locomotion.play(locomotion_name)
	locomotion.seek(locomotion_time, true)
	locomotion.pause()
	actions.play(action_name)
	actions.seek(action_time, true)
	actions.pause()
	var hand: Node2D = rig.get_node(ARM + "NearUpper/NearLower/Hand")
	var bow: Node2D = hand.get_node("Bow")
	bow.visible = bow_equipped
	hand.get_node("Sword").visible = not bow_equipped
	var nock: Node2D = rig.get_node(ARM + "FarUpper/FarLower/Hand/StringNock")
	var point := bow.to_local(nock.global_position)
	bow.get_node("String").set_point_position(1, point)
	var arrow: Sprite2D = bow.get_node("NockedArrow")
	arrow.position = point + Vector2(0, -arrow.texture.get_height() * arrow.scale.y * .5)


func _capture() -> void:
	get_window().size = Vector2i(1440, 900)
	await get_tree().process_frame
	_pose($Idle, "idle", 0.0, "sword_idle", 0.0, false)
	_pose($Walk, "walk", .39, "sword_walk", .39, false)
	_pose($Windup, "idle", 0.0, "slash", .11, false)
	_pose($Strike, "idle", 0.0, "slash", .20, false)
	_pose($Bow, "idle", 0.0, "bow_draw", .8, true)
	_pose($MirrorBow, "idle", 0.0, "bow_draw", .8, true)
	if "--capture-profile-review" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.local/profile-review.png")
		print("PROFILE_REVIEW_CAPTURED")
		get_tree().quit()
