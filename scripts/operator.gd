class_name Operator
extends CharacterBody2D

signal arrow_requested(origin: Vector2, direction: Vector2, power: float)
signal sword_swung

enum Weapon { SWORD, BOW }
enum Action { READY, SLASH, DRAW, RELEASE }

const MOVE_SPEED := 245.0
const DRAW_DURATION := 0.8
const GRAVITY := 1300.0
const SLASH_DURATION := 0.5

@export var display_name := "白发兽耳干员"
@export var parts_atlas: Texture2D = preload("res://assets/operator/parts_atlas.png")
@export var projectile_texture: Texture2D = preload("res://assets/operator/arrow.png")
@export_multiline var parts_legend := "01 头部  /  02 后发\n03 躯干  /  04 衣摆\n\n05–08 上臂 / 前臂\n09–12 大腿 / 靴子\n\n13 剑  /  14 弓\n15 箭矢  /  16 拉弦手"

var weapon := Weapon.SWORD
var action := Action.READY
var charge := 0.0
var facing := 1.0
var aim_direction := Vector2.RIGHT
var aim_target := Vector2.ZERO
var action_time := 0.0
var hit_applied := false
var swing_count := 0
var shot_count := 0
var bones_visible := false

@onready var rig: Node2D = $Rig
@onready var locomotion: AnimationPlayer = $Rig/Locomotion
@onready var actions: AnimationPlayer = $Rig/Actions
@onready var arm_aim: Bone2D = $Rig/Skeleton2D/Hips/Torso/ArmAim
@onready var sword: Node2D = $Rig/Skeleton2D/Hips/Torso/ArmAim/NearUpper/NearLower/Hand/Sword
@onready var bow: Node2D = $Rig/Skeleton2D/Hips/Torso/ArmAim/NearUpper/NearLower/Hand/Bow
@onready var string_line: Line2D = $Rig/Skeleton2D/Hips/Torso/ArmAim/NearUpper/NearLower/Hand/Bow/String
@onready var nocked_arrow: Sprite2D = $Rig/Skeleton2D/Hips/Torso/ArmAim/NearUpper/NearLower/Hand/Bow/NockedArrow
@onready var draw_hand: Marker2D = $Rig/Skeleton2D/Hips/Torso/ArmAim/FarUpper/FarLower/Hand
@onready var pull_hand: Sprite2D = $Rig/Skeleton2D/Hips/Torso/ArmAim/FarUpper/FarLower/Hand/PullHand
@onready var melee_aim: Node2D = $MeleeAim
@onready var hitbox: Area2D = $MeleeAim/Hitbox
@onready var slash: Polygon2D = $MeleeAim/Slash


func _ready() -> void:
	aim_target = global_position + Vector2(300, -122)
	_update_equipment()
	get_window().focus_exited.connect(_cancel_action)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_target = get_canvas_transform().affine_inverse() * event.position
	elif event.is_action_pressed("switch_weapon"):
		_switch_weapon()
	elif event.is_action_pressed("attack"):
		_begin_attack()
	elif event.is_action_released("attack") and action == Action.DRAW:
		_release_arrow()
	elif event.is_action_pressed("toggle_bones"):
		bones_visible = not bones_visible
		for guide: CanvasItem in get_tree().get_nodes_in_group("bone_guides"):
			guide.visible = bones_visible


func _physics_process(delta: float) -> void:
	var movement := Input.get_axis("move_left", "move_right")
	var speed_multiplier := 0.45 if action == Action.DRAW else 1.0
	if action == Action.SLASH:
		speed_multiplier = 0.28
	velocity.x = move_toward(velocity.x, movement * MOVE_SPEED * speed_multiplier, 1800.0 * delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()
	position.x = clampf(position.x, 78.0, 1040.0)
	if action != Action.SLASH:
		_update_aim()
	var walking := absf(velocity.x) > 10.0
	var locomotion_name := "walk" if walking else "idle"
	if locomotion.current_animation != locomotion_name:
		locomotion.play(locomotion_name, 0.12)
	locomotion.speed_scale = maxf(absf(velocity.x) / MOVE_SPEED, 0.5) if walking else 1.0
	action_time += delta
	match action:
		Action.READY:
			var pose := "sword_walk" if walking else "sword_idle"
			if weapon == Weapon.BOW:
				pose = "bow_ready"
			if actions.current_animation != pose:
				actions.play(pose, 0.10)
		Action.SLASH:
			var progress := action_time / SLASH_DURATION
			slash.modulate.a = sin(clampf((progress - 0.20) / 0.58, 0.0, 1.0) * PI) * 0.9
			slash.rotation = lerpf(-0.55, 0.55, progress)
			if action_time >= 0.18 and not hit_applied:
				hit_applied = true
				for target: Area2D in hitbox.get_overlapping_areas():
					(target as TrainingTarget).hit(35, "剑击")
			if action_time >= SLASH_DURATION:
				action = Action.READY
				slash.modulate.a = 0.0
		Action.DRAW:
			charge = minf(action_time / DRAW_DURATION, 1.0)
			actions.seek(charge * DRAW_DURATION, true)
		Action.RELEASE:
			if action_time >= 0.25:
				action = Action.READY


func _process(_delta: float) -> void:
	if weapon == Weapon.BOW:
		var nock := bow.to_local(draw_hand.global_position)
		string_line.set_point_position(1, nock)
		nocked_arrow.position = nock + Vector2(0, -6)
		nocked_arrow.visible = action != Action.RELEASE


func _update_aim() -> void:
	var cursor_delta := aim_target - (global_position + Vector2(0, -122))
	if cursor_delta.length_squared() < 16.0:
		return
	facing = 1.0 if cursor_delta.x >= 0.0 else -1.0
	var pitch := clampf(atan2(cursor_delta.y, absf(cursor_delta.x)), -1.15, 1.15)
	aim_direction = Vector2(cos(pitch) * facing, sin(pitch))
	rig.scale.x = facing
	arm_aim.rotation = pitch if weapon == Weapon.BOW else pitch * 0.45
	melee_aim.rotation = aim_direction.angle()


func _begin_attack() -> void:
	if action != Action.READY:
		return
	action_time = 0.0
	if weapon == Weapon.SWORD:
		action = Action.SLASH
		hit_applied = false
		swing_count += 1
		actions.play("slash", 0.04)
		sword_swung.emit()
	else:
		action = Action.DRAW
		charge = 0.0
		actions.play("bow_draw")
		actions.pause()
		actions.seek(0.0, true)


func _release_arrow() -> void:
	# Spawn at the actual nock so the hand, bowstring and projectile agree.
	arrow_requested.emit(draw_hand.global_position, aim_direction, charge)
	shot_count += 1
	action = Action.RELEASE
	action_time = 0.0
	charge = 0.0
	actions.play("bow_release")


func _switch_weapon() -> void:
	_cancel_action()
	weapon = Weapon.BOW if weapon == Weapon.SWORD else Weapon.SWORD
	_update_equipment()


func _cancel_action() -> void:
	action = Action.READY
	action_time = 0.0
	charge = 0.0
	slash.modulate.a = 0.0
	actions.stop()


func _update_equipment() -> void:
	sword.visible = weapon == Weapon.SWORD
	bow.visible = weapon == Weapon.BOW
	pull_hand.visible = weapon == Weapon.BOW


func reset() -> void:
	_cancel_action()
	position = Vector2(410, 658)
	velocity = Vector2.ZERO
	swing_count = 0
	shot_count = 0
	weapon = Weapon.SWORD
	_update_equipment()
