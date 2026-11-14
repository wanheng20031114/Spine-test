extends Node

var failures: Array[String] = []
@onready var lab: Node2D = $Lab
@onready var actor: SpriteOperator = $Lab/Actor


func _ready() -> void:
	get_window().size = Vector2i(1440, 900)
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures.append(description)


func _frames(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


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


func _run() -> void:
	await _frames(5)
	_check(actor.is_on_floor(), "Sprite character rests on native floor")
	_check(InputMap.action_has_event("jump", _key_event(KEY_SPACE)) and InputMap.action_has_event("switch_animation_lab", _key_event(KEY_F3)), "Space and F3 are native InputMap actions")
	var animations_valid := true
	for animation: String in lab.ANIMATIONS:
		animations_valid = animations_valid and actor.sprite.sprite_frames.get_frame_count(animation) == 8
	_check(animations_valid and lab.ANIMATIONS.size() == 13, "All 13 generated sequences load as eight-frame native animations")
	_key(KEY_D, true)
	await _frames(26)
	_key(KEY_D, false)
	await _frames(8)
	_check(actor.position.x > 465, "D moves sprite character right")
	_key(KEY_A, true)
	await _frames(26)
	_check(actor.sprite.animation == &"walk_sword" and actor.sprite.speed_scale < 0, "Backward movement reverses walking sequence")
	_key(KEY_A, false)
	await _frames(8)
	_key(KEY_SPACE, true)
	_key(KEY_SPACE, false)
	await _frames(24)
	_check(actor.position.y < 595 and not actor.is_on_floor() and actor.sprite.animation == &"jump_air_sword", "Space launches physical jump with airborne sword pose")
	_key(KEY_SPACE, true)
	_key(KEY_SPACE, false)
	await _frames(48)
	_check(actor.is_on_floor() and actor.jump_count == 1 and actor.action == SpriteOperator.Action.READY, "Jump lands and recovers; pressing Space in air cannot double-jump")
	actor.position = Vector2(753, 658)
	_mouse(Vector2(850, 520))
	await _frames(5)
	_attack(true)
	_attack(false)
	await actor.sprite.animation_finished
	_check($Lab/TargetNear.hit_count == 1 and $Lab/TargetNear.total_damage == 35, "Sword impact frames hit nearby target once per swing")
	_check($Lab/TargetLeft.hit_count == 0, "Sword cannot hit distant target")
	_attack(true)
	_attack(false)
	await _frames(45)
	_check($Lab/TargetNear.hit_count == 2 and actor.action == SpriteOperator.Action.READY, "A new click on the exact finishing frame restarts the attack cleanly")
	lab._reset_lab()
	_key(KEY_Q, true)
	_key(KEY_Q, false)
	await _frames(3)
	_check(actor.weapon == SpriteOperator.Weapon.BOW and actor.sprite.animation == &"idle_bow", "Q selects bow-specific idle")
	_key(KEY_D, true)
	await _frames(8)
	_check(actor.sprite.animation == &"walk_bow", "Bow has its own walking sprites")
	_key(KEY_D, false)
	await _frames(8)
	_key(KEY_SPACE, true)
	_key(KEY_SPACE, false)
	await _frames(20)
	_check(actor.sprite.animation == &"jump_air_bow", "Bow has its own airborne sprites")
	await _frames(52)
	actor.position = Vector2(410, 658)
	_mouse(Vector2(900, 510))
	await _frames(4)
	_attack(true)
	await _frames(27)
	var charge_before := actor.charge
	_mouse(Vector2(945, 220))
	await _frames(4)
	_check(actor.aim_index == 0 and actor.sprite.animation == &"bow_draw_up" and actor.charge >= charge_before, "Changing mouse aim switches to upward draw without resetting charge")
	_mouse(Vector2(610, 635))
	await _frames(4)
	_check(actor.aim_index == 2 and actor.sprite.animation == &"bow_draw_down", "Downward mouse aim selects downward drawing artwork")
	_mouse(Vector2(850, 510))
	await _frames(26)
	_check(actor.charge == 1.0 and actor.sprite.frame == 7 and actor.shot_count == 0, "Full draw holds its last frame without firing")
	_attack(false)
	await _frames(50)
	_check(actor.shot_count == 1 and $Lab/TargetNear.hit_count == 1, "Release frame spawns one horizontal arrow and hits target")
	_mouse(Vector2(945, 220))
	await _frames(3)
	_attack(true)
	await _frames(54)
	_attack(false)
	await _frames(50)
	_check($Lab/TargetHigh.hit_count == 1, "Upward arrow matches upper aim band and hits elevated target")
	_mouse(Vector2(610, 635))
	await _frames(3)
	_attack(true)
	await _frames(54)
	_attack(false)
	await _frames(50)
	_check($Lab/TargetLow.hit_count == 1, "Downward arrow matches lower aim band and hits low target")
	_mouse(Vector2(160, 510))
	await _frames(3)
	_attack(true)
	await _frames(54)
	_attack(false)
	await _frames(45)
	_check(actor.facing == -1 and $Lab/TargetLeft.hit_count == 1, "Mirroring preserves leftward projectile direction and target hits")
	var shots := actor.shot_count
	_attack(true)
	await _frames(10)
	_key(KEY_Q, true)
	_key(KEY_Q, false)
	_attack(false)
	await _frames(30)
	_check(actor.shot_count == shots and actor.weapon == SpriteOperator.Weapon.SWORD, "Switching equipment cancels charge without ghost arrow")
	_key(KEY_Q, true)
	_key(KEY_Q, false)
	_attack(true)
	await _frames(8)
	actor.get_window().focus_exited.emit()
	_attack(false)
	await _frames(25)
	_check(actor.shot_count == shots and actor.action == SpriteOperator.Action.READY, "Focus loss cancels pending draw")
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	await _frames(3)
	var before := actor.position
	_key(KEY_D, true)
	_attack(true)
	await _frames(15)
	_key(KEY_D, false)
	_attack(false)
	_check(lab.inspector.visible and actor.position == before and not actor.can_process(), "Frame inspector blocks gameplay inputs")
	lab.selector.select(11)
	lab.selector.item_selected.emit(11)
	lab.timeline.value = 5
	await _frames(2)
	_check(lab.preview.animation == &"bow_draw_down" and lab.preview.frame == 5 and not lab.preview.is_playing(), "Native selector and timeline allow paused inspection of a chosen frame")
	lab._step()
	lab._mirror_preview()
	_check(lab.preview.frame == 6 and lab.preview.flip_h, "Inspector supports frame stepping and mirror preview")
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	await _frames(3)
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _frames(4)
	_check(actor.can_process() and actor.shot_count == 0 and actor.jump_count == 0 and lab.total_hits == 0, "Closing inspector restores gameplay; R resets all telemetry")
	if failures.is_empty():
		print("SPRITE_GAMEPLAY_TEST_OK")
	else:
		push_error("Sprite failures: " + "; ".join(failures))
	get_tree().quit(0 if failures.is_empty() else 1)


func _key_event(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event
