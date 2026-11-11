extends Node

var failures: Array[String] = []
@onready var rig: Node2D = $Rig
@onready var locomotion: AnimationPlayer = $Rig/Locomotion
@onready var actions: AnimationPlayer = $Rig/Actions
const ARM := "Skeleton2D/Hips/Torso/ArmAim/"


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures.append(description)


func _sample(player: AnimationPlayer, animation_name: String, time: float) -> void:
	player.play(animation_name)
	player.seek(time, true)
	player.pause()


func _run() -> void:
	await get_tree().process_frame
	_sample(actions, "sword_idle", 0)
	var maximum_slide := 0.0
	var maximum_ground_error := 0.0
	for direction in [1.0, -1.0]:
		rig.scale.x = direction
		for side in ["Near", "Far"]:
			var sole: Marker2D = rig.get_node("Skeleton2D/Hips/" + side + "Thigh/Shin/Foot/Sole")
			var start_time := 0.0 if side == "Near" else .3
			var start_x := 0.0
			for frame in range(61):
				var t := start_time + .3 * frame / 60.0
				rig.position.x = direction * 160 * t
				_sample(locomotion, "walk", t)
				if frame == 0:
					start_x = sole.global_position.x
				maximum_slide = maxf(maximum_slide, absf(sole.global_position.x - start_x))
				maximum_ground_error = maxf(maximum_ground_error, absf(sole.global_position.y))
	_check(maximum_slide < .35, "Steady walk footplant drift below 0.35 px, both sides: %.4f" % maximum_slide)
	_check(maximum_ground_error < .35, "Supporting soles stay on the floor: %.4f" % maximum_ground_error)
	rig.position = Vector2.ZERO
	rig.scale.x = 1
	_sample(locomotion, "idle", 0)
	var upper: Bone2D = rig.get_node(ARM + "NearUpper")
	var lower: Bone2D = upper.get_node("NearLower")
	var hand: Bone2D = lower.get_node("Hand")
	var sword_art: Sprite2D = hand.get_node("Sword/Artwork")
	var sword_hand: Sprite2D = hand.get_node("Sword/GripHand")
	var max_grip_error := 0.0
	var max_wrist_angle := 0.0
	for frame in range(61):
		_sample(actions, "slash", .5 * frame / 60.0)
		# Independently measured image-space anchors, not scene marker positions.
		var handle := sword_art.to_global(Vector2(128, 1306))
		var palm := sword_hand.to_global(Vector2(692, 394))
		max_grip_error = maxf(max_grip_error, handle.distance_to(palm))
		max_wrist_angle = maxf(max_wrist_angle, absf(wrapf(hand.rotation - PI / 2, -PI, PI)))
	_check(max_grip_error < 1.5, "Painted sword handle stays inside painted palm throughout slash: %.3f px" % max_grip_error)
	_check(max_wrist_angle < deg_to_rad(65), "Sword wrist stays within 65 degrees of forearm axis: %.2f deg" % rad_to_deg(max_wrist_angle))
	var bow: Node2D = hand.get_node("Bow")
	var bow_art: Sprite2D = bow.get_node("Artwork")
	var bow_hand: Sprite2D = bow.get_node("GripHand")
	var nock: Marker2D = rig.get_node(ARM + "FarUpper/FarLower/Hand/StringNock")
	var pull: Sprite2D = rig.get_node(ARM + "FarUpper/FarLower/Hand/PullHand")
	var max_bow_grip_error := 0.0
	var max_nock_error := 0.0
	var max_arrow_height_error := 0.0
	for frame in range(49):
		_sample(actions, "bow_draw", .8 * frame / 48.0)
		var grip := bow_art.to_global(Vector2(292, 727))
		var palm := bow_hand.to_global(Vector2(646, 330))
		max_bow_grip_error = maxf(max_bow_grip_error, grip.distance_to(palm))
		var fingertip := pull.to_global(Vector2(1170, 304))
		max_nock_error = maxf(max_nock_error, fingertip.distance_to(nock.global_position))
		max_arrow_height_error = maxf(max_arrow_height_error, absf(bow.to_local(nock.global_position).y + 1))
	_check(max_bow_grip_error < 1.5, "Painted bow grip and palm remain aligned: %.3f px" % max_bow_grip_error)
	_check(max_nock_error < 1.5, "Bowstring nock stays at painted pulling fingertips: %.3f px" % max_nock_error)
	_check(max_arrow_height_error < .15, "Arrow remains level with the bow grip throughout the draw: %.3f px" % max_arrow_height_error)
	var hair: Polygon2D = $Rig/HairMesh
	_check(hair.get_bone_count() == 3 and hair.polygons.size() == 16, "Long hair uses one continuous native mesh with three bone influences")
	if failures.is_empty():
		print("PROFILE_POSE_TEST_OK")
	else:
		push_error("Profile pose failures: " + "; ".join(failures))
	get_tree().quit(0 if failures.is_empty() else 1)
