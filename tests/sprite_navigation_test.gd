extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures += 1


func _frames(count: int) -> void:
	for _i in count:
		await physics_frame


func _f3() -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_F3
		event.pressed = pressed
		Input.parse_input_event(event)


func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await _frames(5)
	_f3()
	await scene_changed
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/sprite_lab.tscn", "F3 opens sprite lab from original main scene")
	_f3()
	await scene_changed
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/main.tscn", "F3 returns to original skeleton lab")
	current_scene.get_node("HUD/SpriteLabButton").pressed.emit()
	await scene_changed
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/sprite_lab.tscn", "Native main-scene button opens sprite lab")
	print("SPRITE_NAVIGATION_TEST_OK" if failures == 0 else "SPRITE_NAVIGATION_TEST_FAILED")
	quit(0 if failures == 0 else 1)
