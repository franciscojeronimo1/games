extends Area2D

@export var pull_speed: float = 420.0


func _physics_process(delta: float) -> void:
	var p = Global.player
	if p == null or not is_instance_valid(p):
		return
	if not ("magnet_radius" in p):
		return
	var radius: float = p.magnet_radius
	if p.has_method("get_magnet_radius"):
		radius = p.get_magnet_radius()
	if radius <= 0.0:
		return
	if global_position.distance_to(p.global_position) <= radius:
		global_position = global_position.move_toward(p.global_position, pull_speed * delta)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		await get_tree().create_timer(0.05).timeout
		queue_free()
