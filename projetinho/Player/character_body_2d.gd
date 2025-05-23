extends CharacterBody2D

@export var gravity = 800
@export var jump_speed = -225
@export var move_speed = 100
@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $dmg/CollisionShape2D

var is_attacking = false

func _physics_process(delta):
	attacar()
	anim()
	quitar()
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("ui_jump"):
		velocity.y = jump_speed
		animation_player.play("jump") 
	move_and_slide()

func anim():
	if is_attacking:
		return 
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
		
func attacar():
	if Input.is_action_pressed("attack") and not is_attacking:
		collision_shape_2d.disabled = false
		is_attacking = true
		velocity.x = 0 
		animation_player.play("attack1")
		await animation_player.animation_finished
		collision_shape_2d.disabled = true
		is_attacking = false
		
	if Input.is_action_pressed("attack2") and not is_attacking:
		is_attacking = true
		velocity.x = 0 
		animation_player.play("attack2")
		await animation_player.animation_finished
		is_attacking = false
