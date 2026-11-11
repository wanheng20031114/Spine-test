extends Node

var failures: Array[String] = []
@onready var lab: Node2D = $FieldLab
@onready var actor: Operator = $FieldLab/Schoolgirl
@onready var target: TrainingTarget = $FieldLab/TargetNear


func _ready() -> void:
	get_window().size = Vector2i(1440,900)
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
	event.position = get_viewport().get_mouse_position()
	Input.parse_input_event(event)


func _run() -> void:
	await _frames(5)
	_check(lab.operator == actor and actor.visible and not $FieldLab/Operator.can_process(), "New schoolgirl is active by default; original character is disabled")
	_check(actor.is_on_floor(), "CharacterBody2D rests on native floor collider")
	_check(actor.get_node("Rig/Skeleton2D").get_bone_count() == 14, "All 14 native bones loaded")
	var initial_x := actor.position.x
	_key(KEY_D, true)
	await _frames(24)
	_key(KEY_D, false)
	await _frames(8)
	_check(actor.position.x > initial_x + 70, "D mapping moves character right")
	_key(KEY_A, true)
	await _frames(24)
	_key(KEY_A, false)
	await _frames(8)
	_check(absf(actor.position.x - initial_x) < 8, "A mapping moves character left symmetrically")
	actor.position = Vector2(680,658)
	_mouse(Vector2(780,542))
	await _frames(5)
	_attack(true)
	await _frames(2)
	_attack(false)
	await _frames(36)
	_check(target.hit_count == 1 and target.total_damage == 35, "Sword hits nearby target once per swing")
	_check(actor.action == Operator.Action.READY, "Sword recovery returns to ready")
	_check(lab.get_node("TargetFar").hit_count == 0, "Sword cannot hit distant target")
	_key(KEY_Q,true)
	_key(KEY_Q,false)
	await _frames(3)
	_check(actor.weapon == Operator.Weapon.BOW and actor.bow.visible and not actor.sword.visible, "Q switches sword to bow")
	actor.position = Vector2(410,658)
	_mouse(Vector2(780,538))
	await _frames(5)
	_attack(true)
	await _frames(58)
	_check(actor.action == Operator.Action.DRAW and actor.charge > .95, "Hold mouse charges bow to full without firing")
	_check(actor.shot_count == 0, "Holding does not release arrows early")
	_attack(false)
	await _frames(45)
	_check(actor.shot_count == 1 and target.hit_count == 2 and target.total_damage == 100, "Release fires charged arrow and applies 65 damage")
	_mouse(Vector2(160,538))
	await _frames(3)
	_attack(true)
	await _frames(15)
	_attack(false)
	await _frames(40)
	_check(lab.get_node("TargetLeft").hit_count == 1 and actor.facing == -1.0, "Mirrored bow aims and hits left target")
	_attack(true)
	await _frames(10)
	_key(KEY_Q,true)
	_key(KEY_Q,false)
	_attack(false)
	await _frames(5)
	_check(actor.weapon == Operator.Weapon.SWORD and actor.charge == 0.0 and actor.shot_count == 2, "Switching while drawing cancels without ghost arrow")
	_key(KEY_F1,true)
	_key(KEY_F1,false)
	await _frames(2)
	_check(actor.bones_visible, "F1 exposes rig guides")
	_key(KEY_TAB,true)
	_key(KEY_TAB,false)
	await _frames(2)
	_check(lab.atlas_panel.visible, "Tab opens parts atlas")
	var overlay_x := actor.position.x
	_key(KEY_D,true)
	_attack(true)
	await _frames(8)
	_key(KEY_D,false)
	_attack(false)
	_check(actor.position.x == overlay_x and actor.action == Operator.Action.READY, "Parts overlay blocks movement and combat")
	_key(KEY_TAB,true)
	_key(KEY_TAB,false)
	_key(KEY_Q,true)
	_key(KEY_Q,false)
	await _frames(3)
	_attack(true)
	await _frames(8)
	get_window().focus_exited.emit()
	_attack(false)
	await _frames(3)
	_check(actor.action == Operator.Action.READY and actor.charge == 0.0 and actor.shot_count == 2, "Losing focus cancels bow draw without firing")
	_key(KEY_R,true)
	_key(KEY_R,false)
	await _frames(3)
	_check(target.hit_count == 0 and lab.total_hits == 0 and actor.shot_count == 0, "R resets target telemetry and combat")
	for arrow: TrainingArrow in lab.get_node("Arrows").get_children():
		_check(not arrow.active, "Reset deactivates " + arrow.name)
	# Switch during a live draw: the hidden actor must stop processing input,
	# and releasing the button must not fire an arrow from either character.
	actor.position.x = 500
	_key(KEY_Q,true)
	_key(KEY_Q,false)
	await _frames(3)
	_attack(true)
	await _frames(8)
	_key(KEY_F2,true)
	_key(KEY_F2,false)
	_attack(false)
	await _frames(3)
	var original: Operator = $FieldLab/Operator
	_check(lab.operator == original and original.visible and not actor.visible, "F2 selects the original character")
	_check(original.position.x == 500 and original.weapon == Operator.Weapon.BOW, "Switch preserves position and equipped weapon")
	_check(not actor.can_process() and original.action == Operator.Action.READY and original.shot_count == 0, "Switch cancels draw without a ghost arrow or hidden actor updates")
	_check(original.bones_visible, "Rig guide preference survives character switch")
	_check(lab.get_node("HUD/AtlasPanel/Atlas").texture == original.parts_atlas, "Parts atlas follows the selected character")
	original.position = Vector2(680,658)
	_mouse(Vector2(780,542))
	_key(KEY_Q,true)
	_key(KEY_Q,false)
	await _frames(5)
	_attack(true)
	await _frames(2)
	_attack(false)
	await _frames(36)
	_check(target.hit_count == 1 and original.swing_count == 1, "Original character can still attack after switching")
	original.position = Vector2(410,658)
	_key(KEY_Q,true)
	_key(KEY_Q,false)
	await _frames(5)
	_attack(true)
	await _frames(58)
	_attack(false)
	await _frames(45)
	_check(target.total_damage == 100 and original.shot_count == 1, "Original character can still shoot its own arrow after switching")
	_check(lab.get_node("Arrows/Arrow03/Artwork").texture == original.projectile_texture, "Projectile pool uses the shooting character's texture")
	_key(KEY_TAB,true)
	_key(KEY_TAB,false)
	_key(KEY_F2,true)
	_key(KEY_F2,false)
	await _frames(3)
	_check(lab.operator == actor and lab.atlas_panel.visible and not actor.is_physics_processing(), "Switching in parts view updates character while keeping gameplay frozen")
	_check(lab.get_node("HUD/AtlasPanel/Atlas").texture == actor.parts_atlas, "Schoolgirl parts atlas is restored")
	_key(KEY_TAB,true)
	_key(KEY_TAB,false)
	lab.get_node("HUD/CharacterButton").pressed.emit()
	await _frames(3)
	_check(lab.operator == original and original.is_physics_processing(), "Native character button switches and resumes gameplay")
	lab._reset_lab()
	_check(original.shot_count == 0 and actor.shot_count == 0 and original.swing_count == 0, "Reset clears both characters' counters")
	if failures.is_empty():
		print("GAMEPLAY_TEST_OK")
	else:
		push_error("Gameplay failures: " + "; ".join(failures))
	get_tree().quit(0 if failures.is_empty() else 1)
