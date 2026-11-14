extends Node2D

const ANIMATIONS := ["idle_sword", "walk_sword", "jump_sword", "slash", "idle_bow", "walk_bow", "jump_bow", "bow_draw", "bow_release", "bow_draw_up", "bow_release_up", "bow_draw_down", "bow_release_down"]
const ARROW := preload("res://assets/schoolgirl_profile/arrow.png")
var total_hits := 0
var total_damage := 0
var next_arrow := 0

@onready var actor: SpriteOperator = $Actor
@onready var inspector: Control = $HUD/Inspector
@onready var preview: AnimatedSprite2D = $HUD/Inspector/Preview
@onready var timeline: HSlider = $HUD/Inspector/Timeline
@onready var selector: OptionButton = $HUD/Inspector/Selector


func _ready() -> void:
	actor.arrow_requested.connect(_shoot)
	for target: TrainingTarget in get_tree().get_nodes_in_group("targets"):
		target.struck.connect(_on_hit)
	_select_animation(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_animation_lab"):
		_open_skeleton()
	elif event.is_action_pressed("toggle_parts"):
		_toggle_inspector()
	elif event.is_action_pressed("reset_lab"):
		_reset_lab()


func _process(_delta: float) -> void:
	$HUD/Weapon.text = "01 / 直剑" if actor.weapon == SpriteOperator.Weapon.SWORD else "02 / 弓"
	$HUD/State.text = ["待机 / 行走", "挥剑", "拉弓蓄力", "放箭 / 收势", "起跳准备", "落地缓冲"][actor.action]
	if not actor.is_on_floor() and actor.action == SpriteOperator.Action.READY:
		$HUD/State.text = "空中 / 跳跃"
	$HUD/Animation.text = "%s\nFRAME  %02d / %02d" % [actor.sprite.animation, actor.sprite.frame + 1, actor.sprite.sprite_frames.get_frame_count(actor.sprite.animation)]
	$HUD/Aim.text = "瞄准  " + ["上 ↗", "平 →", "下 ↘"][actor.aim_index] + ("  / 左向" if actor.facing < 0 else "  / 右向")
	$HUD/Charge.value = actor.charge * 100.0
	$HUD/Stats.text = "挥剑  %02d    放箭  %02d\n跳跃  %02d    命中  %02d\n累计伤害  %03d" % [actor.swing_count, actor.shot_count, actor.jump_count, total_hits, total_damage]
	$AimGuide.position = actor.global_position + Vector2(0, -148)
	$AimGuide.rotation = actor.aim_direction().angle()
	$AimGuide.visible = not inspector.visible and actor.weapon == SpriteOperator.Weapon.BOW
	if inspector.visible:
		timeline.set_value_no_signal(preview.frame)
		$HUD/Inspector/FrameLabel.text = "FRAME  %02d / 08    ·    %s" % [preview.frame + 1, preview.animation]
		$HUD/Inspector/Play.text = "暂停" if preview.is_playing() else "播放"


func _shoot(origin: Vector2, direction: Vector2, power: float) -> void:
	var arrow: TrainingArrow = $Arrows.get_child(next_arrow)
	arrow.launch(origin, direction, power, ARROW, 6.0)
	next_arrow = (next_arrow + 1) % $Arrows.get_child_count()


func _on_hit(damage: int, _source: String) -> void:
	total_hits += 1
	total_damage += damage


func _reset_lab() -> void:
	actor.reset()
	total_hits = 0
	total_damage = 0
	for arrow: TrainingArrow in $Arrows.get_children():
		arrow.deactivate()
	for target: TrainingTarget in get_tree().get_nodes_in_group("targets"):
		target.reset()


func _toggle_inspector() -> void:
	inspector.visible = not inspector.visible
	actor.cancel_action()
	actor.process_mode = Node.PROCESS_MODE_DISABLED if inspector.visible else Node.PROCESS_MODE_INHERIT
	actor.visible = not inspector.visible
	if inspector.visible:
		_select_animation(selector.selected)


func _select_animation(index: int) -> void:
	var animation: String = ANIMATIONS[index]
	preview.stop()
	preview.play(animation)
	timeline.max_value = 7
	$HUD/Inspector/Sheet.texture = (preview.sprite_frames.get_frame_texture(animation, 1) as AtlasTexture).atlas


func _toggle_preview() -> void:
	if preview.is_playing():
		preview.pause()
	else:
		if preview.frame == 7:
			preview.stop()
		preview.play()


func _scrub(frame: float) -> void:
	preview.pause()
	preview.frame = int(frame)


func _step() -> void:
	preview.pause()
	preview.frame = (preview.frame + 1) % 8


func _mirror_preview() -> void:
	preview.flip_h = not preview.flip_h


func _open_skeleton() -> void:
	actor.cancel_action()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
