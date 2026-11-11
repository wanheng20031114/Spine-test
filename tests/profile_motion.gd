extends Node


func _ready() -> void:
	_run.call_deferred()


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _mouse(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	Input.parse_input_event(event)


func _attack(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.local/profile-" + name + ".png")


func _run() -> void:
	get_window().size = Vector2i(1440, 900)
	await get_tree().process_frame
	_mouse(Vector2(780, 534))
	await get_tree().create_timer(.5).timeout
	await _save("idle")
	_key(KEY_D, true)
	await get_tree().create_timer(.7).timeout
	await _save("walk")
	await get_tree().create_timer(.95).timeout
	_key(KEY_D, false)
	await get_tree().create_timer(.15).timeout
	_attack(true)
	await get_tree().create_timer(.2).timeout
	await _save("slash")
	_attack(false)
	await get_tree().create_timer(.4).timeout
	_key(KEY_Q, true)
	_key(KEY_Q, false)
	await get_tree().create_timer(.3).timeout
	_attack(true)
	await get_tree().create_timer(.85).timeout
	await _save("bow")
	_attack(false)
	await get_tree().create_timer(.5).timeout
	_mouse(Vector2(160, 534))
	_key(KEY_A, true)
	await get_tree().create_timer(.8).timeout
	_key(KEY_A, false)
	await get_tree().create_timer(.2).timeout
	_attack(true)
	await get_tree().create_timer(.85).timeout
	await _save("bow-left")
	_attack(false)
	await get_tree().create_timer(.6).timeout
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	await get_tree().create_timer(.2).timeout
	await _save("parts")
	await get_tree().create_timer(.6).timeout
	print("PROFILE_MOTION_CAPTURED")
	get_tree().quit()
