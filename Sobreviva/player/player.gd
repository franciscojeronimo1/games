extends CharacterBody2D
class_name Player

var _max_health: int

@export_category("Variables")
@export var _move_speed: float = 256.0
@export var _health: int = 20

@export_category("Objects")
@export var _dust: CPUParticles2D = null

func _ready():
	_max_health = _health
	global.player = self

func _physics_process(delta):
	_move()
	
func _move():
	var _direction: Vector2 = Input.get_vector(
		"move_left", "move_right",
		"move_up", "move_down"
	)
	
	velocity = _direction * _move_speed
	move_and_slide()
	
	if _direction:
		_dust.emitting = true
		return
	_dust.emitting = false

func update_health(_type: String, _value: int) -> void:
	match _type:
		"damage":
			_health -= _value
			if _health <= 0:
				# Ir para a tela das estatisticas
				queue_free()
			
		"health":
			_health += _value
			if _health > _max_health:
				_health = _max_health
				
func reset_health():
	print("Antiga Vida do personagem", str(_health))
	_health = _max_health
	print("Vida do personagem", str(_health))
