extends Node2D
@onready var player: Player = $player
@onready var spawn_timer: Timer = $spawn_timer

@export var enemy_scene: PackedScene
@export var spawn_margin := 200
@export var enemy_scene2: PackedScene
@export var boss_scene: PackedScene
@export var boss_spawn_lvl: int = 12
@export var boss_spawn_time: float = 90.0
@export var min_spawn_interval: float = 1.2

var hud_scene = preload("res://ui/hud.tscn")
var hud
var boss_spawned := false


func _ready() -> void:
	Global.reset_run()
	hud = hud_scene.instantiate()
	add_child(hud)
	_update_hud()


func _process(delta: float) -> void:
	if not is_instance_valid(player) or player.is_dead:
		return

	Global.tick_survival(delta)
	_update_hud()

	if boss_spawned or boss_scene == null:
		return

	if player.lvl >= boss_spawn_lvl or Global.survival_time >= boss_spawn_time:
		spawn_boss()


func _update_hud() -> void:
	if hud and is_instance_valid(player):
		hud.update_hud(player.hp, player.max_hp, player.lvl)


func spawn_enemy():
	Global.wave += 1
	var wave := Global.wave

	var pack_size := 2 + int(wave / 3)
	var hp_bonus := int(wave * 0.6)
	var speed_mult := 1.0 + wave * 0.04

	for i in pack_size:
		var scene: PackedScene = enemy_scene if (i % 2 == 0) else enemy_scene2
		_spawn_scaled_enemy(scene, hp_bonus, speed_mult)

	# Waves ficam mais frequentes com o tempo
	spawn_timer.wait_time = maxf(min_spawn_interval, 5.0 - wave * 0.15)


func _spawn_scaled_enemy(scene: PackedScene, hp_bonus: int, speed_mult: float) -> void:
	if scene == null or not is_instance_valid(player):
		return
	var enemy = scene.instantiate()
	add_child(enemy)
	enemy.global_position = calculate_spawn_position()
	enemy.player = player
	enemy.health += hp_bonus
	enemy.move_speed *= speed_mult


func spawn_boss():
	boss_spawned = true
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = calculate_spawn_position()
	boss.player = player
	Global.add_score(200)


func calculate_spawn_position() -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size
	var player_pos = player.global_position
	var spawn_distance := screen_size.length() / 2 + spawn_margin
	var angle := randf_range(0, TAU)
	return player_pos + Vector2.RIGHT.rotated(angle) * spawn_distance


func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
