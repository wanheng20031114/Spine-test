class_name TrainingArrow
extends Node2D

var active := false
var velocity := Vector2.ZERO
var remaining := 0.0
var damage := 0
@onready var sweep: RayCast2D = $Sweep
@onready var artwork: Sprite2D = $Artwork


func launch(origin: Vector2, direction: Vector2, power: float, texture: Texture2D, height: float) -> void:
	artwork.texture = texture
	artwork.scale = Vector2.ONE * (height / texture.get_height())
	artwork.position.y = -height * 0.5
	global_position = origin
	rotation = direction.angle()
	velocity = direction * lerpf(650.0, 1120.0, power)
	damage = roundi(lerpf(18.0, 65.0, power))
	remaining = 2.0
	active = true
	visible = true
	sweep.enabled = true


func deactivate() -> void:
	active = false
	visible = false
	sweep.enabled = false


func _physics_process(delta: float) -> void:
	if not active:
		return
	remaining -= delta
	if remaining <= 0.0:
		deactivate()
		return
	velocity.y += 130.0 * delta
	rotation = velocity.angle()
	# Sweep the full distance, including the tip. Fast arrows cannot tunnel.
	var tip_length := artwork.texture.get_width() * artwork.scale.x - 2.0
	sweep.target_position = to_local(global_position + velocity * delta + velocity.normalized() * tip_length)
	sweep.force_raycast_update()
	if sweep.is_colliding():
		var collider := sweep.get_collider()
		if collider is TrainingTarget:
			collider.hit(damage, "箭矢")
		deactivate()
		return
	global_position += velocity * delta
