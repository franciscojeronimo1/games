extends Node2D
@onready var player: Player = $player
@onready var spawn_timer: Timer = $spawn_timer

@export var enemy_scene: PackedScene
@export var spawn_margin := 200
@export var enemy_scene2: PackedScene
@export var enemy_scene3: PackedScene
@export var boss_scene: PackedScene
@export var boss_every_n_levels: int = 10
@export var first_boss_lvl: int = 10
@export var base_spawn_interval: float = 4.5
@export var min_spawn_interval: float = 2.2
@export var max_enemies_on_screen: int = 16
@export var max_pack_size: int = 4
@export var chest_interval: float = 28.0

var hud_scene = preload("res://ui/hud.tscn")
var chest_scene = preload("res://prefabs/chest.tscn")
var hud
var _chest_timer: float = 10.0
var _last_boss_lvl: int = 0


func _ready() -> void:
	Global.reset_run()
	hud = hud_scene.instantiate()
	add_child(hud)
	_update_hud()
	_sync_spawn_rate()
	await get_tree().process_frame
	if is_instance_valid(player):
		await player.offer_relic_choice()


func _process(delta: float) -> void:
	if not is_instance_valid(player) or player.is_dead or player.is_choosing_upgrade:
		return

	Global.tick_survival(delta)
	Global.wave = player.lvl
	_update_hud()
	_sync_spawn_rate()
	_try_spawn_boss_for_level()

	_chest_timer -= delta
	if _chest_timer <= 0.0:
		_chest_timer = chest_interval
		spawn_chest()


func _update_hud() -> void:
	if hud and is_instance_valid(player):
		hud.update_hud(player.hp, player.max_hp, player.lvl, player.get_ability_hud(), player.get_xp_hud())


func _player_lvl() -> int:
	if is_instance_valid(player):
		return maxi(1, player.lvl)
	return 1


func _alive_enemies() -> int:
	return get_tree().get_nodes_in_group("enemies").size()


func _sync_spawn_rate() -> void:
	var lvl := _player_lvl()
	# Quanto maior o nível, um pouco mais rápido — mas com piso
	spawn_timer.wait_time = maxf(min_spawn_interval, base_spawn_interval - (lvl - 1) * 0.12)


func _try_spawn_boss_for_level() -> void:
	if boss_scene == null:
		return
	var lvl := _player_lvl()
	if lvl < first_boss_lvl:
		return
	# Boss no lvl 10, 20, 30...
	if lvl % boss_every_n_levels != 0:
		return
	if lvl == _last_boss_lvl:
		return
	# Só spawna se ainda não tem boss vivo
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Boss:
			_last_boss_lvl = lvl
			return
	spawn_boss(lvl)


func spawn_enemy():
	if not is_instance_valid(player) or player.is_dead or player.is_choosing_upgrade:
		return

	var lvl := _player_lvl()
	Global.wave = lvl

	var alive := _alive_enemies()
	if alive >= max_enemies_on_screen:
		return

	var room := max_enemies_on_screen - alive
	# Pack cresce com o nível do player, com teto
	var pack_size := mini(room, 1 + int((lvl - 1) / 4))
	pack_size = clampi(pack_size, 1, max_pack_size)

	var hp_bonus := maxi(0, int((lvl - 1) * 0.35))
	var speed_mult := 1.0 + (lvl - 1) * 0.02

	for i in pack_size:
		var scene := _pick_enemy_scene(i)
		_spawn_scaled_enemy(scene, hp_bonus, speed_mult, false)

	# Elite ocasional a partir do lvl 4, se ainda couber
	if lvl >= 4 and lvl % 2 == 0 and _alive_enemies() < max_enemies_on_screen:
		var elite_scene := _pick_enemy_scene(lvl)
		_spawn_scaled_enemy(elite_scene, hp_bonus, speed_mult, true)

	_sync_spawn_rate()


func _pick_enemy_scene(seed_i: int = 0) -> PackedScene:
	var pool: Array[PackedScene] = []
	if enemy_scene:
		pool.append(enemy_scene)
	if enemy_scene2:
		pool.append(enemy_scene2)
	if enemy_scene3:
		pool.append(enemy_scene3)
	if pool.is_empty():
		return null
	return pool[seed_i % pool.size()]


func _spawn_scaled_enemy(scene: PackedScene, hp_bonus: int, speed_mult: float, elite: bool) -> void:
	if scene == null or not is_instance_valid(player):
		return
	if _alive_enemies() >= max_enemies_on_screen:
		return
	var enemy = scene.instantiate()
	add_child(enemy)
	enemy.global_position = calculate_spawn_position()
	enemy.player = player
	enemy.health += hp_bonus
	enemy.move_speed *= speed_mult
	if elite and enemy.has_method("make_elite"):
		enemy.make_elite()


func spawn_chest() -> void:
	if chest_scene == null or not is_instance_valid(player):
		return
	var chest = chest_scene.instantiate()
	add_child(chest)
	var angle := randf_range(0.0, TAU)
	var dist := randf_range(220.0, 380.0)
	chest.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * dist


func spawn_boss(at_lvl: int = -1) -> void:
	if boss_scene == null:
		return
	var lvl := at_lvl if at_lvl > 0 else _player_lvl()
	_last_boss_lvl = lvl
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = calculate_spawn_position()
	boss.player = player
	# Boss também escala um pouco com o nível
	boss.health = int(boss.health + (lvl - first_boss_lvl) * 4)
	boss.move_speed *= 1.0 + (lvl - first_boss_lvl) * 0.02
	Global.add_score(200 + lvl * 10)


func calculate_spawn_position() -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size
	var player_pos = player.global_position
	var spawn_distance := screen_size.length() / 2 + spawn_margin
	var angle := randf_range(0, TAU)
	return player_pos + Vector2.RIGHT.rotated(angle) * spawn_distance


func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
