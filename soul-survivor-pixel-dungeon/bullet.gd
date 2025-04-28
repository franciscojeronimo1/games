extends Area2D

@export var speed := 500
var direction := Vector2.ZERO

func _physics_process(delta):
	position += direction * speed * delta
	if not get_viewport_rect().has_point(global_position):
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		body.take_damage(1)
		queue_free()
