extends CharacterBody2D
class_name Pushables

const PUSH_SPEED = 10.0



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
func slide_object(direction):
	velocity.x = int(direction.x) * PUSH_SPEED
	move_and_slide()
