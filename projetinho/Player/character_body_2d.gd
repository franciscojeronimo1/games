extends CharacterBody2D

@export var gravity = 800
@export var jump_speed = -225
@export var move_speed = 100
@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	anim()
	quitar()
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("ui_jump"):
		velocity.y = jump_speed
		animation_player.play("jump") 
	move_and_slide()

func anim():
	var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_dir * move_speed
	if is_on_floor() and velocity.x == 0:
		animation_player.play("idle")
	elif is_on_floor() and velocity.x != 0:
		animation_player.play("run")
	if velocity.x > 0:
		animation_player.flip_h = false  # Virado para a direita
	elif velocity.x < 0:
		animation_player.flip_h = true
		
func quitar():
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
