extends CharacterBody2D

@export var gravity = 800
@export var jump_speed = -200
@export var move_speed = 100
@onready var animation_player: AnimatedSprite2D = $Animated
@onready var timer: Timer = $Timer


func _physics_process(delta):
	velaGrande()
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("ui_jump"):
		velocity.y = jump_speed
		animation_player.play("jumpPequena")  # Animação de pulo
	move_and_slide()
	
func velaPequena():
	var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_dir * move_speed
	if is_on_floor() and velocity.x == 0:
		animation_player.play("idlePequena")
	elif is_on_floor() and velocity.x != 0:
		animation_player.play("runPequena")
	if velocity.x > 0:
		animation_player.flip_h = false  # Virado para a direita
	elif velocity.x < 0:
		animation_player.flip_h = true
		
func velaGrande():
	var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_dir * move_speed
	if is_on_floor() and velocity.x == 0:
		animation_player.play("idleGrande")
	elif is_on_floor() and velocity.x != 0:
		animation_player.play("runGrande")
	if velocity.x > 0:
		animation_player.flip_h = false  # Virado para a direita
	elif velocity.x < 0:
		animation_player.flip_h = true


func _on_timer_timeout() -> void:
	pass
