extends Node2D
@onready var player: Player = $player

@export var enemy_scene: PackedScene
@export var spawn_margin := 200
@export var enemy_scene2: PackedScene
@export var boss_scene: PackedScene
@export var boss_spawn_lvl: int = 10
@export var boss_spawn_time: float = 45.0

var boss_spawned := false
var elapsed_time := 0.0


func _process(delta: float) -> void:
	if boss_spawned or boss_scene == null or not is_instance_valid(player):
		return

	elapsed_time += delta
	if player.lvl >= boss_spawn_lvl or elapsed_time >= boss_spawn_time:
		spawn_boss()


func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = calculate_spawn_position()
	enemy.player = player

	var enemy2 = enemy_scene2.instantiate()
	add_child(enemy2)
	enemy2.global_position = calculate_spawn_position()
	enemy2.player = player


func spawn_boss():
	boss_spawned = true
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = calculate_spawn_position()
	boss.player = player


func calculate_spawn_position() -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size
	var player_pos = player.global_position

	var spawn_distance := screen_size.length() / 2 + spawn_margin

	var angle := randf_range(0, TAU)
	var spawn_pos = player_pos + Vector2.RIGHT.rotated(angle) * spawn_distance

	return spawn_pos


func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
