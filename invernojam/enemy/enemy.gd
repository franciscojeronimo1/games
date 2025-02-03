extends CharacterBody2D
class_name Enemy

@export var knockback_speed:float = 300.0  
@export var speed = 0  # Velocidade do inimigo
@export var hp:int = 5
@onready var enemy: Enemy = $"."
var knockback_velocity = Vector2.ZERO
@onready var attack_area: Attack_player = $"../Player/attack_area"
@onready var animated: AnimatedSprite2D = $Animated

@onready var player: Player = $"../Player"

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		velocity.x -= speed * delta
		
	move_and_slide()


func _on_hp_area_entered(area: Area2D) -> void:
	_knockback()
	animated.play("take_dmg")
	hp -= attack_area.attack_dmg()
	if hp <= 0:
		enemy.queue_free()

func _knockback() -> void:
	var _direction: Vector2 = global_position.direction_to(player.global_position)
	velocity.x -= _direction.x * knockback_speed
	


func _on_dmg_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player.hp_do_player()
		print("player toumou dano")


func _on_hp_area_exited(area: Area2D) -> void:
	animated.play("idle")
