extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var character: CharacterBody2D = $"."

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const fall = Vector2(0,1)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	animacao()

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if direction != 0:
		animated_sprite_2d.flip_h = direction < 0
		
		
	move_and_slide()
func animacao():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animated_sprite_2d.play("jump")
		return
	if velocity.y > 0 and not is_on_floor():
		animated_sprite_2d.play("fall")
	if is_on_floor() and velocity.x == 0:
		animated_sprite_2d.play("idle")
	elif is_on_floor() and velocity.x != 0:
		animated_sprite_2d.play("run")
