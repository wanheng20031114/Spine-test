extends Node2D

var next_arrow := 0
var total_hits := 0
var total_damage := 0
var character_index := 1
@onready var characters: Array[Operator] = [$Operator, $Schoolgirl]
@onready var operator: Operator = $Schoolgirl
@onready var arrows: Node2D = $Arrows
@onready var weapon_label: Label = $HUD/Weapon
@onready var state_label: Label = $HUD/State
@onready var charge_bar: ProgressBar = $HUD/Charge
@onready var charge_label: Label = $HUD/ChargeLabel
@onready var stats: Label = $HUD/Stats
@onready var hint: Label = $HUD/Hint
@onready var atlas_panel: Control = $HUD/AtlasPanel
@onready var reticle: Node2D = $Reticle


func _ready() -> void:
	for character: Operator in characters:
		character.arrow_requested.connect(_shoot)
	for target: TrainingTarget in get_tree().get_nodes_in_group("targets"):
		target.struck.connect(_on_hit)
	_update_character_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_lab"):
		_reset_lab()
	elif event.is_action_pressed("toggle_parts"):
		_toggle_parts()
	elif event.is_action_pressed("switch_character"):
		_switch_character()


func _process(_delta: float) -> void:
	var sword_equipped := operator.weapon == Operator.Weapon.SWORD
	weapon_label.text = "01  /  战术直剑" if sword_equipped else "02  /  复合弓"
	var states := ["待机 / 行走", "挥剑", "拉弓蓄力", "放箭"]
	state_label.text = states[operator.action]
	charge_bar.value = operator.charge * 100.0
	charge_label.text = "蓄力  %03d%%" % roundi(operator.charge * 100.0)
	stats.text = "挥剑次数    %02d\n射箭次数    %02d\n命中次数    %02d\n累计伤害    %03d" % [operator.swing_count, operator.shot_count, total_hits, total_damage]
	hint.text = "靠近训练靶，单击左键挥剑" if sword_equipped else "按住左键拉弓，松开射箭"
	reticle.global_position = get_global_mouse_position()
	reticle.modulate = Color(0.44, 0.95, 0.88, 0.9) if sword_equipped else Color(1.0, 0.76, 0.34, 0.9)
	reticle.visible = not atlas_panel.visible and reticle.position.x < 1110.0 and reticle.position.y > 145.0 and reticle.position.y < 720.0


func _shoot(origin: Vector2, direction: Vector2, power: float) -> void:
	# Projectile instances are authored in main.tscn; reuse the fixed pool.
	var arrow := arrows.get_child(next_arrow) as TrainingArrow
	arrow.launch(origin, direction, power, operator.projectile_texture)
	next_arrow = (next_arrow + 1) % arrows.get_child_count()


func _on_hit(damage: int, _source: String) -> void:
	total_hits += 1
	total_damage += damage


func _reset_lab() -> void:
	for character: Operator in characters:
		character.reset()
	total_hits = 0
	total_damage = 0
	for arrow: TrainingArrow in arrows.get_children():
		arrow.deactivate()
	for target: TrainingTarget in get_tree().get_nodes_in_group("targets"):
		target.reset()


func _toggle_parts() -> void:
	atlas_panel.visible = not atlas_panel.visible
	operator._cancel_action()
	operator.set_process_unhandled_input(not atlas_panel.visible)
	operator.set_physics_process(not atlas_panel.visible)
	operator.velocity = Vector2.ZERO


func _switch_character() -> void:
	var previous := operator
	previous._cancel_action()
	character_index = (character_index + 1) % characters.size()
	operator = characters[character_index]
	operator.position = previous.position
	operator.velocity = Vector2.ZERO
	operator.aim_target = previous.aim_target
	operator.facing = previous.facing
	operator.weapon = previous.weapon
	operator.bones_visible = previous.bones_visible
	operator._cancel_action()
	operator._update_equipment()
	# Both characters are authored in the scene. Disabled CollisionObject2Ds
	# use native DISABLE_MODE_REMOVE, so the hidden actor leaves the physics world.
	previous.visible = false
	previous.process_mode = Node.PROCESS_MODE_DISABLED
	operator.visible = true
	operator.process_mode = Node.PROCESS_MODE_INHERIT
	operator.set_process_unhandled_input(not atlas_panel.visible)
	operator.set_physics_process(not atlas_panel.visible)
	_update_character_ui()


func _update_character_ui() -> void:
	$HUD/CharacterButton.text = operator.display_name + "  / F2"
	$HUD/Subtitle.text = operator.display_name + " · 分件骨骼动作试验场"
	$HUD/AtlasPanel/Atlas.texture = operator.parts_atlas
	$HUD/AtlasPanel/AtlasTitle.text = operator.display_name + "  /  PARTS ATLAS"
	$HUD/AtlasPanel/AtlasLegend.text = operator.parts_legend
