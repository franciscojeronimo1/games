extends CharacterBody2D



@export var speed: float = 200.0
@export var jump_velocity: float = -500.0

	


func _physics_process(delta):
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1

	velocity.x = direction.x * speed

	if is_on_floor():
		if Input.is_action_just_pressed("ui_select"):
			velocity.y = jump_velocity

	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	move_and_slide()




