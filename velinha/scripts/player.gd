extends CharacterBody2D
class_name Player

@onready var player: Player = $"."
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@export var gravity = 800
@export var jump_speed = -225
@export var move_speed = 100
@onready var animation_player: AnimatedSprite2D = $Animated


var is_dead = false

func _physics_process(delta):
	if is_dead:
		return
	velaGrande()
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("ui_jump"):
		velocity.y = jump_speed
		animation_player.play("jumpPequena")  #
	move_and_slide()
	apply_push_force()

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

func apply_push_force():
	for objects in get_slide_collision_count():
		var collision = get_slide_collision(objects)
		if collision.get_collider() is Pushables:
			collision.get_collider().slide_object(-collision.get_normal())
			#animation_player.play("pushGrande")


func _on_tomar_dmg_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		die()
		
func die():
	if is_dead:
		return  # Evita chamar a morte mais de uma vez

	is_dead = true
	velocity = Vector2.ZERO  # Para o movimento
	audio_stream_player.play()
	animation_player.play("death")  # Toca a animação de morte
	point_light_2d.enabled = false
	await animation_player.animation_finished  # Espera a animação terminar
	get_tree().change_scene_to_file("res://mapa.tscn")
	
