extends Node2D
class_name WaveManager

const _GREEN_ENEMY: PackedScene = preload("res://enemies/enemy_green.tscn")
const _YELLOW_ENEMY: PackedScene = preload("res://enemies/enemy_yellow.tscn")
const _PURPLE_ENEMY: PackedScene = preload("res://enemies/enemy_purple.tscn")

var _waves_dict: Dictionary = {
	1:{
		"wave_time": 20,
		"wave_spawn_cooldown": 4,
		"wave_amount": 1,
		"spots_amount": [3,6],
		"wave_difficulty": "easy"
	},
	
	2:{
		"wave_time": 25,
		"wave_spawn_cooldown": 5,
		"wave_amount": 2,
		"spots_amount": [2,4],
		"wave_difficulty": "easy"
	},
	
	3:{
		"wave_time": 30,
		"wave_spawn_cooldown": 6,
		"wave_amount": 3,
		"spots_amount": [4,5],
		"wave_difficulty": "easy"
	},
	
	4:{
		"wave_time": 30,
		"wave_spawn_cooldown": 6,
		"wave_amount": 4,
		"spots_amount": [2,5],
		"wave_difficulty": "easy"
	},
}

var _current_wave: int = 1

@export_category("Objects")
@export var _wave_timer: Timer
@export var _wave_spawner_timer: Timer
@onready var interface = $Interface

func _ready():
	_wave_spawner_timer.start(_waves_dict[_current_wave]["wave_spawn_cooldown"])
	_wave_timer.start(_waves_dict[_current_wave]["wave_time"])
	_spawn_enemies()

func _on_wave_timer_timeout():
	_current_wave += 1
	if _current_wave > 10:
		print("Você venceu")
		return
	_wave_timer.start(_waves_dict[_current_wave]["wave_time"])

func _on_wave_spawn_cooldown_timeout() -> void:
	_spawn_enemies()
	_wave_spawner_timer.start(_waves_dict[_current_wave]["wave_spawn_cooldown"])

func _spawn_enemies() -> void:
	var _amount: int = _waves_dict[_current_wave]["wave_amount"]
	var _spots: Array[Node2D] = []
	
	for _child in get_children():
		if not _child is Timer:
			_spots.append(_child)
			
	var _spawn_spots: Array = []
	for _i in range(_amount):
		var _index: int = randi() % _spots.size()
		var _selected_spot: Node2D = _spots[_index]
		_spawn_spots.append(_selected_spot)
		_spots.remove_at(_index)
		
	for _spot in _spawn_spots:
		var _children: Array = []
		var _selected_children: Array = []
		
		for _child in _spot.get_children():
			_children.append(_child)
		
		var _amount_list: Array = _waves_dict[_current_wave]["spots_amount"]
		var _selected_amount: int = randi_range(_amount_list[0], _amount_list[1])
		for _i in range(_selected_amount):
			var _index: int = randi() % _children.size()
			var _selected_spot: Node2D = _children[_index]
			_selected_children.append(_selected_spot)
			_children.remove_at(_index)
			
		for _spawner in _selected_children:
			_spawn_enemy(_spawner)

func _spawn_enemy(_spawner: Node2D):
	var _enemy: Enemy = null
	var _randf: float = randf()
	var _difficulty: String = _waves_dict[_current_wave]["wave_difficulty"]
	match _difficulty:
		"easy":
			_enemy = _GREEN_ENEMY.instantiate()
		"easy_to_medium":
			if _randf <= 0.7:
				_enemy = _GREEN_ENEMY.instantiate()
			else:
				_enemy = _YELLOW_ENEMY.instantiate()
		"medium":
			if _randf <= 0.5:
				_enemy = _GREEN_ENEMY.instantiate()
			else:
				_enemy = _YELLOW_ENEMY.instantiate()
		"medium_to_hard":
			if _randf <= 0.4:
				_enemy = _GREEN_ENEMY.instantiate()
			elif _randf > 0.4 and _randf <= 0.9:
				_enemy = _YELLOW_ENEMY.instantiate()
			else:
				_enemy = _PURPLE_ENEMY.instantiate()
		"hard":
			if _randf <= 0.2:
				_enemy = _GREEN_ENEMY.instantiate()
			elif _randf > 0.2 and _randf <= 0.8:
				_enemy = _YELLOW_ENEMY.instantiate()
			else:
				_enemy = _PURPLE_ENEMY.instantiate()
				
	_enemy.global_position = _spawner.global_position
	get_parent().call_deferred("add_child", _enemy)

func _on_current_time_timer_timeout():
	interface.update_wave_and_time_label(_current_wave, _wave_timer.time_left)
