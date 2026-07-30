extends Area2D
## Rastro no chão: dano periódico em inimigos que pisam nele.

@export var lifetime: float = 3.0
@export var tick_interval: float = 0.4
@export var damage: int = 1

var _life_left: float = 3.0
var _tick_left: float = 0.0
var _inside: Array[Node2D] = []


func setup(dmg: int, life: float = 3.0) -> void:
	damage = maxi(1, dmg)
	lifetime = life
	_life_left = life
	_tick_left = 0.05


func _ready() -> void:
	z_index = -40
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	modulate = Color(0.35, 1.0, 0.45, 0.8)


func _process(delta: float) -> void:
	_life_left -= delta
	var fade := clampf(_life_left / lifetime, 0.0, 1.0)
	modulate.a = fade * 0.8
	scale = Vector2.ONE * (0.85 + (1.0 - fade) * 0.25)

	if _life_left <= 0.0:
		queue_free()
		return

	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left = tick_interval
		_damage_inside()


func _damage_inside() -> void:
	for i in range(_inside.size() - 1, -1, -1):
		var body := _inside[i]
		if not is_instance_valid(body):
			_inside.remove_at(i)
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	if body in _inside:
		return
	_inside.append(body)
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)


func _on_body_exited(body: Node2D) -> void:
	_inside.erase(body)
