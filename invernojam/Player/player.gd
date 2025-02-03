extends CharacterBody2D
class_name Player

const SPEED = 150.0
@onready var anim: AnimatedSprite2D = $Anim
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: Area2D = $attack_area
var is_attacking = false
@onready var collision_attack: CollisionShape2D = $attack_area/collision_attack
@export var player_hp = 10
@onready var player: Player = $"."
@export var knockback_speed:int = 250
@onready var enemy: Enemy = $"../enemy"


func _ready() -> void:
	player.collision_attack.disabled

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	animacao()
	input()
	move_and_slide()
	# Verifica a direção do movimento e ajusta a escala

			
func animacao():
	if not is_attacking:
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		if is_on_floor() and velocity.x == 0 and not is_attacking :
			anim.play("idle")
		elif is_on_floor() and velocity.x != 0 and not is_attacking:
			anim.play("run")
		if direction != 0:
			anim.flip_h = direction > 0
		if is_attacking:
			velocity.x = 0  
		if direction > 0:
			attack_area.rotation = -160
		elif direction < 0:
			attack_area.rotation = 0


func hp_do_player():
	_knockback()
	anim.play("hurt")
	player_hp -= 1
	if player_hp <= 0:
		player.queue_free()
		
func _knockback() -> void:
	var _direction: Vector2 = global_position.direction_to(enemy.global_position)
	velocity.x = _direction.x * knockback_speed
	velocity.y = -1 * knockback_speed


func input():
	if Input.is_action_just_pressed("MOUSE_BUTTON_LEFT") and not is_attacking:
			start_attack()
			
			
func start_attack():
	# Iniciar a animação de ataque
	is_attacking = true
	anim.play("attack")
	animation_player.play("attack")
	# Ativar a área de ataque
	attack_area.monitoring = true



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		is_attacking = false
