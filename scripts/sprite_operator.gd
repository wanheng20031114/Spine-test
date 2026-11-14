class_name SpriteOperator
extends CharacterBody2D

signal arrow_requested(origin: Vector2, direction: Vector2, power: float)

enum Weapon { SWORD, BOW }
enum Action { READY, SLASH, DRAW, RELEASE, TAKEOFF, LAND }

const MOVE_SPEED := 165.0
const GRAVITY := 1250.0
const JUMP_SPEED := 470.0
const DRAW_DURATION := 0.8
const AIM_ANGLES := [-PI / 6, 0.0, PI / 6]
const AIM_SUFFIXES := ["_up", "", "_down"]
const SHOT_ORIGINS := [Vector2(-40, -255), Vector2(-45, -246), Vector2(-50, -251)]

var weapon := Weapon.SWORD
var action := Action.READY
var facing := 1.0
var aim_index := 1
var aim_target := Vector2(900, 510)
var charge := 0.0
var action_time := 0.0
var shot_power := 0.0
var shot_pending := false
var swing_count := 0
var shot_count := 0
var jump_count := 0
var hit_targets: Array[Area2D] = []

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var muzzle: Marker2D = $Visual/Muzzle
@onready var melee_pivot: Node2D = $MeleePivot
@onready var hitbox: Area2D = $MeleePivot/Hitbox


func _ready() -> void:
	get_window().focus_exited.connect(cancel_action)
	_play("idle_sword")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_target = get_canvas_transform().affine_inverse() * event.position
	elif event.is_action_pressed("jump"):
		if is_on_floor() and action == Action.READY:
			action = Action.TAKEOFF
			_play("jump_start_" + _weapon_name())
	elif event.is_action_pressed("switch_weapon"):
		if action == Action.TAKEOFF or action == Action.LAND:
			return
		cancel_action()
		weapon = Weapon.BOW if weapon == Weapon.SWORD else Weapon.SWORD
		_play("idle_" + _weapon_name())
	elif event.is_action_pressed("attack"):
		_begin_attack()
	elif event.is_action_released("attack") and action == Action.DRAW:
		shot_power = charge
		shot_pending = true
		action = Action.RELEASE
		_play("bow_release" + AIM_SUFFIXES[aim_index])


func _physics_process(delta: float) -> void:
	if action != Action.SLASH and action != Action.RELEASE:
		_update_aim()
	var movement := Input.get_axis("move_left", "move_right")
	var can_move := action == Action.READY or action == Action.TAKEOFF
	velocity.x = move_toward(velocity.x, movement * MOVE_SPEED if can_move else 0.0, 1700.0 * delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var was_grounded := is_on_floor()
	var previous_x := position.x
	move_and_slide()
	position.x = clampf(position.x, 80, 1090)
	var travel := (position.x - previous_x) / delta
	action_time += delta
	if not was_grounded and is_on_floor() and action == Action.READY:
		action = Action.LAND
		_play("jump_land_" + _weapon_name())
	if action == Action.READY:
		if not is_on_floor():
			sprite.animation = "jump_air_" + _weapon_name()
			sprite.pause()
			sprite.frame = 0 if velocity.y < -100 else (2 if velocity.y > 100 else 1)
		else:
			var walking := absf(travel) > 1.0
			_play(("walk_" if walking else "idle_") + _weapon_name())
			sprite.speed_scale = absf(travel) / MOVE_SPEED if walking else 1.0
			if walking and travel * facing < 0:
				sprite.speed_scale *= -1.0
	elif action == Action.DRAW:
		charge = minf(action_time / DRAW_DURATION, 1.0)
	elif action == Action.SLASH and sprite.frame >= 3 and sprite.frame <= 5:
		for area: Area2D in hitbox.get_overlapping_areas():
			if area is TrainingTarget and area not in hit_targets:
				hit_targets.append(area)
				area.hit(35, "逐帧剑击")


func _update_aim() -> void:
	var difference := aim_target - (global_position + Vector2(0, -148))
	if absf(difference.x) > 3:
		facing = 1.0 if difference.x >= 0 else -1.0
	var pitch := atan2(difference.y, maxf(absf(difference.x), 1.0))
	var next_aim := 0 if pitch < -PI / 12 else (2 if pitch > PI / 12 else 1)
	if next_aim != aim_index and action == Action.DRAW:
		# Preserve drawing progress when the mouse crosses an aiming band.
		var held_frame := sprite.frame
		var held_progress := sprite.frame_progress
		var was_playing := sprite.is_playing()
		sprite.play("bow_draw" + AIM_SUFFIXES[next_aim])
		sprite.set_frame_and_progress(held_frame, held_progress)
		if not was_playing:
			sprite.pause()
	aim_index = next_aim
	visual.scale = Vector2(facing * .6, .6)
	melee_pivot.scale.x = facing
	muzzle.position = SHOT_ORIGINS[aim_index]


func aim_direction() -> Vector2:
	var angle: float = AIM_ANGLES[aim_index]
	return Vector2(cos(angle) * facing, sin(angle))


func _begin_attack() -> void:
	if action != Action.READY or not is_on_floor():
		return
	velocity.x = 0.0
	action_time = 0.0
	if weapon == Weapon.SWORD:
		action = Action.SLASH
		swing_count += 1
		hit_targets.clear()
		_play("slash")
	else:
		action = Action.DRAW
		charge = 0.0
		_play("bow_draw" + AIM_SUFFIXES[aim_index])


func _on_frame_changed() -> void:
	if action == Action.RELEASE and sprite.frame == 1 and shot_pending:
		shot_pending = false
		shot_count += 1
		arrow_requested.emit(muzzle.global_position, aim_direction(), shot_power)
		charge = 0.0


func _on_animation_finished() -> void:
	if action == Action.TAKEOFF:
		velocity.y = -JUMP_SPEED
		jump_count += 1
		action = Action.READY
	elif action in [Action.SLASH, Action.RELEASE, Action.LAND]:
		action = Action.READY
		shot_pending = false


func _weapon_name() -> String:
	return "sword" if weapon == Weapon.SWORD else "bow"


func _play(animation: String) -> void:
	if sprite.animation != animation or not sprite.is_playing():
		sprite.speed_scale = 1.0
		sprite.stop()
		sprite.play(animation)


func cancel_action() -> void:
	action = Action.READY
	charge = 0.0
	action_time = 0.0
	shot_pending = false
	velocity.x = 0.0
	hit_targets.clear()
	sprite.stop()
	sprite.play("idle_" + _weapon_name())


func reset() -> void:
	weapon = Weapon.SWORD
	cancel_action()
	position = Vector2(410, 658)
	velocity = Vector2.ZERO
	facing = 1.0
	aim_index = 1
	aim_target = Vector2(900, 510)
	swing_count = 0
	shot_count = 0
	jump_count = 0
