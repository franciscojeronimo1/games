extends CharacterBody2D
class_name Enemy_base

var direction = Vector2(0, 1)


@onready var top_point = $TopPoint.global_position.y
@onready var botton_point = $BottonPoint.global_position.y

@export_category("Variables")
@export var _enemy_health: int = 5
@export var speed:int = 100

func _ready():
	get_gravity()



func _physics_process(delta: float):
	velocity = direction * speed
	move_and_slide()
	if is_on_wall():
		direction = -direction  # Inverte a direção
	# Verifica se atingiu os limites
	if global_position.y <= top_point:
		direction = Vector2(0, 1)  # Muda para baixo
	elif global_position.y >= botton_point:
		direction = Vector2(0, -1)  # Muda para cima
func _process(delta):
	position += direction * speed * delta
# Confinar o movimento no mapa (exemplo: 800x600)
	position.x = clamp(position.x, 0, 454)
	position.y = clamp(position.y, 0, 175)
	
func update_health(_damage: int) -> void:
	_enemy_health -= _damage
	if _enemy_health <= 0:
		print("matou o inimigo")
		queue_free()
		return
	print("inimigo perdeu " + str(_damage) + " pontos de vida. vida atual " + str(_enemy_health))
