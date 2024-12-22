extends CharacterBody2D
class_name BaseCharacter


@export_category("Variables")
@export var _speed: float = 200.0
@export var _jump_velocity: float = -400.0

@export_category("Objects")
@export var _character_texture: CharacterTexture

func _physics_process(delta: float) -> void:
	_vertical_movement(delta)
	_horizontal_movement()
	move_and_slide()
	_character_texture.animate(velocity)

func _vertical_movement(delta: float ) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = _jump_velocity
		
		
func _horizontal_movement() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * _speed
		return
	velocity.x = move_toward(velocity.x, 0, _speed)
