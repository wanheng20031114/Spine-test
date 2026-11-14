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


func _delay(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.local/sprite-" + name + ".png")


func _run() -> void:
	get_window().size = Vector2i(1440, 900)
	await get_tree().process_frame
	_mouse(Vector2(900, 510))
	await _delay(.4)
	await _save("idle")
	_key(KEY_D, true)
	await _delay(.45)
	await _save("walk")
	_key(KEY_SPACE, true)
	_key(KEY_SPACE, false)
	await _delay(.45)
	await _save("jump")
	await _delay(.2)
	_key(KEY_D, false)
	await _delay(.4)
	_key(KEY_D, true)
	await _delay(.95)
	_key(KEY_D, false)
	await _delay(.15)
	_attack(true)
	_attack(false)
	await _delay(.26)
	await _save("slash")
	await _delay(.4)
	_key(KEY_Q, true)
	_key(KEY_Q, false)
	_key(KEY_A, true)
	await _delay(2.1)
	_key(KEY_A, false)
	await _delay(.15)
	for entry: Array in [["bow-up", Vector2(945, 220)], ["bow-level", Vector2(850, 510)], ["bow-down", Vector2(610, 635)], ["bow-left", Vector2(160, 510)]]:
		_mouse(entry[1])
		await _delay(.08)
		_attack(true)
		await _delay(.87)
		await _save(entry[0])
		_attack(false)
		await _delay(.6)
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	await _delay(.15)
	$Lab.selector.select(11)
	$Lab.selector.item_selected.emit(11)
	await _delay(.9)
	await _save("inspector")
	print("SPRITE_MOTION_CAPTURED")
	get_tree().quit()
