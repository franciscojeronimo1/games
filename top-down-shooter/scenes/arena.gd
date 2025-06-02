extends Node2D
@onready var player: Player = $player

@export var enemy_scene : PackedScene
@export var spawn_margin := 200
@export var enemy_scene2 : PackedScene

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = calculate_spawn_position()
	enemy.player = player
	
	var enemy2 = enemy_scene2.instantiate()
	add_child(enemy2)
	enemy2.global_position = calculate_spawn_position()
	enemy2.player = player
	
func calculate_spawn_position() -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size
	var player_pos = player.global_position
	
	var spawn_distance := screen_size.length() / 2 + spawn_margin
	
	var angle := randf_range(0, TAU)
	var spawn_pos = player_pos + Vector2.RIGHT.rotated(angle) * spawn_distance
	
	return spawn_pos

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
