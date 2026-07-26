extends Area2D


@export var speed: float = 900.0
var direction: Vector2 = Vector2.ZERO
@export var dmg: int = 1

func _process(delta: float) -> void:
	position += direction * speed * delta

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	# A flecha aponta pra direita na sprite, então o ângulo do vetor gira ela certo
	rotation = direction.angle()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(dmg, global_position)
		queue_free()
