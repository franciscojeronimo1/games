extends Area2D

@export var speed: float = 900.0
@export var dmg: int = 1
@export var pierce: bool = false
@export var explosive: bool = false
@export var explosion_radius: float = 90.0

var direction: Vector2 = Vector2.ZERO
var _hit_enemies: Array = []


func _process(delta: float) -> void:
	position += direction * speed * delta


func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()


func configure(damage: int, can_pierce: bool, can_explode: bool) -> void:
	dmg = damage
	pierce = can_pierce
	explosive = can_explode
	if explosive:
		modulate = Color(1.0, 0.55, 0.2)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	if body in _hit_enemies:
		return

	_hit_enemies.append(body)
	if body.has_method("take_damage"):
		body.take_damage(dmg, global_position)

	if explosive:
		_explode()
		queue_free()
		return

	if pierce:
		return

	queue_free()


func _explode() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		if node in _hit_enemies:
			continue
		if global_position.distance_to(node.global_position) <= explosion_radius:
			if node.has_method("take_damage"):
				node.take_damage(dmg, global_position)
