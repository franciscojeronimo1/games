extends CharacterBody2D
class_name Player

signal health_change()
@export var hp:int = 100 :
	set(value):
		hp = value
@export var gravity = 800
@export var jump_speed = -300
@export var move_speed = 160
@export var animation_player: AnimatedSprite2D
@onready var audio: AudioStreamPlayer2D = $Audio


func _physics_process(delta: float) -> void:
	apply_push_force()
	if Input.is_action_just_pressed("ui_quit"):
		get_tree().change_scene_to_file("res://cenas/interface.tscn")
	# Movimento horizontal
	var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_dir * move_speed
	
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if is_on_floor() and Input.is_action_just_pressed("ui_jump"):
		velocity.y = jump_speed
		animation_player.play("jump")  # Animação de pulo
		
	if velocity.y > 0 and not is_on_floor():  # Apenas se estiver caindo
		animation_player.play("fall")
	# Retornando ao estado de "idle" ao tocar o chão
	if is_on_floor() and velocity.x == 0:
		animation_player.play("idle")
	elif is_on_floor() and velocity.x != 0:
		animation_player.play("run")
	if input_dir > 0:
		animation_player.scale.x = 1  # Normal (para a direita)
	elif input_dir < 0:
		animation_player.scale.x = -1  # Flipado (para a esquerda)

	move_and_slide()

func dead():
	hp -= 100

func heal():
	hp = 100
	audio.play()
func _on_timer_timeout() -> void:
	hp -= 10
	health_change.emit()
	if hp < 1:
		get_tree().change_scene_to_file("res://mapa/mapa.tscn")
	print(hp)
	
func apply_push_force():
	for objects in get_slide_collision_count():
		var collision = get_slide_collision(objects)
		if collision.get_collider() is Pushables:
			collision.get_collider().slide_object(-collision.get_normal())
