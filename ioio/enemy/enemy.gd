extends CharacterBody2D
class_name Enemy_base

var direction = Vector2(1,0)

@export_category("Variables")
@export var _enemy_health: int = 5
@export var speed:int = 100

func _ready():
	get_gravity()

func _physics_process(delta: float):
	velocity = direction * speed
	move_and_slide()

func update_health(_damage: int) -> void:
	_enemy_health -= _damage
	if _enemy_health <= 0:
		print("matou o inimigo")
		queue_free()
		return
	print("inimigo perdeu " + str(_damage) + " pontos de vida. vida atual " + str(_enemy_health))
