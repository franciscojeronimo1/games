extends CharacterBody2D

class_name Enemy

@export var speed: float = 50  # Velocidade de movimento
@export var gravity: float = 800  # Gravidade
@export var detection_range: float = 200  # Distância para detectar o jogador
@onready var barata_sofa: CharacterBody2D = $"."
var morte = false

@export var _enemy_health: int = 5

var knockback_force := Vector2.ZERO
var knockback_timer := 0.0
const KNOCKBACK_DURATION := 0.2
@onready var player = get_parent().find_child("Player")  # Encontra o jogador na cena
@onready var sprite = $anim # Referência ao sprite do inimigo

func _physics_process(delta):
	if knockback_timer > 0:
		velocity = knockback_force
		knockback_timer -= delta
	else:
		follow_player()  # Persegue o player
	apply_gravity(delta)  # Aplica gravidade
	move_and_slide()  # Move o inimigo

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta  # Aplica gravidade

func follow_player():
	if player == null:
		return  # Evita erro se o player não existir
	var direction = (player.position - position).normalized()  # Direção até o player
	var distance = position.distance_to(player.position)  # Distância ao player
	if distance <= detection_range:
		velocity.x = direction.x * speed  # Move na direção do player
		sprite.flip_h = velocity.x > 0  # Vira o sprite conforme a direção
		sprite.play('run')
	else:
		velocity.x = 0  # Para quando está longe do player
		sprite.play('idle')
		
func update_health(_damage: int) -> void:
	apply_knockback(player.global_position, 100.0)
	sprite.play("hit")
	_enemy_health -= _damage
	morte = false
	if _enemy_health <= 0:
		apply_knockback(player.global_position, 500.0)
		print('inimigo morreu')
		sprite.play('dead_hit')
		morte = true
		await sprite.animation_finished
		queue_free()
		return
		
	print('Inimigo perdeu' + str(_damage) + "pontos vida atual " + str(_enemy_health) )
func apply_knockback(source_position: Vector2, force: float):
	var direction = (global_position - source_position).normalized()
	knockback_force = direction * force
	knockback_timer = KNOCKBACK_DURATION
