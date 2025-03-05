extends CharacterBody2D
class_name Pushables

const PUSH_SPEED = 300.0



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
		velocity.x = 0

func slide_object(direction):
	velocity.x = int(direction.x) * PUSH_SPEED
