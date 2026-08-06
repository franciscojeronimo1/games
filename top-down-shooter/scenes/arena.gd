extends Node2D
var player: Player
@onready var spawn_timer: Timer = $spawn_timer

@export var enemy_scene: PackedScene
@export var spawn_margin := 200
@export var enemy_scene2: PackedScene
@export var enemy_scene3: PackedScene
@export var boss_scene: PackedScene
@export var boss_every_n_levels: int = 10
@export var first_boss_lvl: int = 10
## A partir deste nível: bosses mais rápidos e vários na arena
@export var late_game_boss_lvl: int = 20
@export var late_boss_every_n_levels: int = 5
@export var late_boss_interval: float = 42.0
@export var max_bosses_early: int = 1
@export var max_bosses_late: int = 3
@export var base_spawn_interval: float = 4.5
@export var min_spawn_interval: float = 2.2
@export var max_enemies_on_screen: int = 16
@export var max_pack_size: int = 4
@export var chest_interval: float = 28.0
## 0 = mapa infinito (recomendado pra survivor). >0 = raio máx. a partir do spawn.
@export var arena_radius: float = 0.0
## Primeira aparição do Duke (segundos após começar a run)
@export var duke_first_delay: float = 50.0
## Intervalo entre chances do Duke
@export var duke_interval: float = 90.0
## Chance de ele realmente aparecer quando o timer dispara
@export var duke_chance: float = 0.55

var hud_scene = preload("res://ui/hud.tscn")
var chest_scene = preload("res://prefabs/chest.tscn")
var duke_scene = preload("res://npc/duke.tscn")
var pause_menu_scene = preload("res://ui/pause_menu.tscn")
var hud
var _chest_timer: float = 10.0
var _duke_timer: float = 50.0
var _duke_active: bool = false
var _last_boss_lvl: int = 0
var _extra_boss_timer: float = 0.0
var _arena_origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	Global.reset_run()
	_spawn_selected_player()
	_duke_timer = duke_first_delay
	if is_instance_valid(player):
		_arena_origin = player.global_position
	hud = hud_scene.instantiate()
	add_child(hud)
	add_child(pause_menu_scene.instantiate())
	_update_hud()
	_sync_spawn_rate()
	await get_tree().process_frame
	if is_instance_valid(player):
		await player.offer_relic_choice()


func _spawn_selected_player() -> void:
	var spawn_pos := Vector2(868, 538)
	var old := get_node_or_null("player")
	if old:
		spawn_pos = old.position
		remove_child(old)
		old.free()

	var scene := Global.get_player_scene()
	if scene == null:
		scene = load("res://Player/player.tscn") as PackedScene
	player = scene.instantiate() as Player
	player.name = "player"
	player.position = spawn_pos
	add_child(player)
	# Mantém o player perto do início da árvore (atrás de HUD etc. ainda não adicionados)
	move_child(player, 0)


func _process(delta: float) -> void:
	if not is_instance_valid(player) or player.is_dead or player.is_choosing_upgrade:
		return

	_clamp_player_to_arena()
	Global.tick_survival(delta)
	Global.wave = player.lvl
	_update_hud()
	_sync_spawn_rate()
	_try_spawn_boss_for_level()
	_try_extra_boss_spawn(delta)

	_chest_timer -= delta
	if _chest_timer <= 0.0:
		_chest_timer = chest_interval
		spawn_chest()

	_duke_timer -= delta
	if _duke_timer <= 0.0:
		_duke_timer = duke_interval
		if not _duke_active and randf() <= duke_chance:
			spawn_duke()


func _clamp_player_to_arena() -> void:
	if arena_radius <= 0.0 or not is_instance_valid(player):
		return
	var offset := player.global_position - _arena_origin
	if offset.length() > arena_radius:
		player.global_position = _arena_origin + offset.limit_length(arena_radius)



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


func _alive_bosses() -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and (node is Boss or node.is_in_group("boss")):
			n += 1
	return n


func _max_bosses_allowed() -> int:
	if _player_lvl() >= late_game_boss_lvl:
		# A cada 10 lvls depois do 20, sobe o teto (max 4)
		var bonus := int((_player_lvl() - late_game_boss_lvl) / 10)
		return mini(4, max_bosses_late + bonus)
	return max_bosses_early


func _boss_milestone_step() -> int:
	if _player_lvl() >= late_game_boss_lvl:
		return maxi(1, late_boss_every_n_levels)
	return maxi(1, boss_every_n_levels)


func _try_spawn_boss_for_level() -> void:
	if boss_scene == null:
		return
	var lvl := _player_lvl()
	if lvl < first_boss_lvl:
		return

	var step := _boss_milestone_step()
	if lvl % step != 0:
		return
	if lvl == _last_boss_lvl:
		return

	if _alive_bosses() >= _max_bosses_allowed():
		# Marca o marco pra não spammar; o timer de late game ainda pode completar o teto
		_last_boss_lvl = lvl
		return

	spawn_boss(lvl)


## Depois do lvl 20: bosses extras por tempo, além dos marcos de nível.
func _try_extra_boss_spawn(delta: float) -> void:
	if boss_scene == null:
		return
	var lvl := _player_lvl()
	if lvl < late_game_boss_lvl:
		_extra_boss_timer = late_boss_interval
		return

	_extra_boss_timer -= delta
	if _extra_boss_timer > 0.0:
		return

	# Intervalo encolhe conforme o nível sobe
	var next_cd := maxf(18.0, late_boss_interval - float(lvl - late_game_boss_lvl) * 1.2)
	_extra_boss_timer = next_cd

	if _alive_bosses() >= _max_bosses_allowed():
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
	# A cada 20 níveis: +1 vida nos bichos (lvl 20, 40, 60...)
	hp_bonus += _milestone_enemy_hp(lvl)
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


func spawn_duke() -> void:
	if duke_scene == null or not is_instance_valid(player) or player.is_dead:
		return
	if _duke_active or player.is_choosing_upgrade:
		return
	_duke_active = true
	var duke = duke_scene.instantiate()
	add_child(duke)
	var angle := randf_range(0.0, TAU)
	duke.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * 200.0
	duke.tree_exited.connect(func() -> void:
		_duke_active = false
	)


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
	# A cada 20 níveis: +10 vida no boss
	boss.health += _milestone_boss_hp(lvl)
	boss.move_speed *= 1.0 + (lvl - first_boss_lvl) * 0.02
	Global.add_score(200 + lvl * 10)


## Marcos de dificuldade: a cada 20 lvls.
func _milestone_enemy_hp(lvl: int) -> int:
	return maxi(0, int(lvl / 20)) * 1


func _milestone_boss_hp(lvl: int) -> int:
	return maxi(0, int(lvl / 20)) * 10


func calculate_spawn_position() -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size
	var player_pos = player.global_position
	var spawn_distance := screen_size.length() / 2 + spawn_margin
	var angle := randf_range(0, TAU)
	return player_pos + Vector2.RIGHT.rotated(angle) * spawn_distance


func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
