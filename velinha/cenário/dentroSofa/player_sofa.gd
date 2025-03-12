extends CharacterBody2D

@export var gravity = 800
@export var jump_speed = -300
@export var move_speed = 100
@onready var anim: AnimatedSprite2D = $Anim
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var is_dead = false

func _physics_process(delta):
	if is_dead:
		return
	velaMedia()
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("ui_jump"):
		velocity.y = jump_speed
		anim.play("jumpMedia")
	move_and_slide()

func velaMedia():
	var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_dir * move_speed
	if is_on_floor() and velocity.x == 0:
		anim.play("idleMedia")
	elif is_on_floor() and velocity.x != 0:
		anim.play("runMedia")
	if velocity.x > 0:
		anim.flip_h = false  # Virado para a direita
	elif velocity.x < 0:
		anim.flip_h = true


func _on_tomar_dmg_body_entered(body: Node2D) -> void:
	if body.is_in_group("Eneny"):
		die()



func die():
	if is_dead:
		return  # Evita chamar a morte mais de uma vez

	is_dead = true
	velocity = Vector2.ZERO  # Para o movimento
	audio_stream_player.play()
	anim.play("death")  # Toca a animação de morte
	point_light_2d.enabled = false
	await anim.animation_finished  # Espera a animação terminar
	get_tree().change_scene_to_file("res://cenário/dentroSofa/mapa_sofa.tscn")
