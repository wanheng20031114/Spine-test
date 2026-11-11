class_name TrainingTarget
extends Area2D

signal struck(damage: int, source: String)
var total_damage := 0
var hit_count := 0
var flash_time := 0.0
@onready var plate: Polygon2D = $Plate
@onready var readout: Label = $Readout
@onready var impact: Line2D = $Impact


func hit(damage: int, source: String) -> void:
	total_damage += damage
	hit_count += 1
	flash_time = 0.36
	readout.text = "%s  −%d" % [source, damage]
	struck.emit(damage, source)


func reset() -> void:
	total_damage = 0
	hit_count = 0
	flash_time = 0.0
	readout.text = "训练靶"


func _process(delta: float) -> void:
	flash_time = maxf(0.0, flash_time - delta)
	var flash := flash_time / 0.36
	plate.color = Color(0.12, 0.22, 0.27).lerp(Color(0.6, 1.0, 0.91), flash)
	impact.modulate.a = flash
	readout.modulate = Color(0.45, 0.65, 0.69).lerp(Color(0.7, 1.0, 0.87), flash)
