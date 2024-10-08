extends CharacterBody2D
class_name BaseCharacter

var _jump_count: int = 0

var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export_category("Variables")
@export var _speed: float = 200.0
@export var _jump_velocity: float = -300.0

func _physics_process(_delta: float) -> void:
	_vertical_moviment(_delta)
	_horizontal_movement()
	move_and_slide()

func _vertical_moviment(_delta: float) -> void:
	# Add the gravity.
	if is_on_floor():
		_jump_count =0

	if not is_on_floor():
		velocity.y += _gravity * _delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and _jump_count < 2:
		_jump_count +=1
		velocity.y = _jump_velocity

func _horizontal_movement() -> void:
	var _direction := Input.get_axis("move_left", "move_right")
	if _direction:
		velocity.x = _direction * _speed
		return

	velocity.x = move_toward(velocity.x, 0, _speed)
