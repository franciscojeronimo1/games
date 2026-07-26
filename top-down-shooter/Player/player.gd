extends CharacterBody2D
class_name Player

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label
@onready var hurt_area: Area2D = $Area2D

var game_over_scene = preload("res://ui/game_over.tscn")
var upgrade_pick_scene = preload("res://ui/upgrade_pick.tscn")
@export var bullet_sceme: PackedScene
var can_shoot: bool = true
@export var shoot_coldown: float = 0.55
@export var game_over_hold_time: float = 2.2
@export var knockback_force: float = 480.0
@export var enemy_knockback_force: float = 380.0
@export var knockback_decay: float = 1400.0
@export var hurt_invuln_time: float = 0.35
@export var attack_release_frame: int = 5
@export var upgrade_every_n_levels: int = 5
@export var base_xp_to_level: int = 3
@export var xp_growth_per_level: int = 1

@export var hp: int = 6
@export var max_hp: int = 6
@export var lvl: int = 1
@export var bullet_damage: int = 1

var current_xp: int = 0
var xp_to_next: int = 3
var _pending_upgrades: int = 0

var move_speed := 300.0
var move_direction := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var is_attacking := false
var is_hurt := false
var is_dead := false
var is_invulnerable := false
var is_choosing_upgrade := false

var has_double_shot := false
var has_reverse_shot := false
var has_pierce := false
var has_explosive := false
var has_magnet := false
var has_arrow_rain := false
var has_bomb := false

var magnet_radius: float = 48.0
var dash_cooldown: float = 1.1
var dash_force: float = 780.0
var dash_duration: float = 0.14
var _dash_cd_left: float = 0.0
var _is_dashing := false

var arrow_rain_cooldown: float = 7.0
var bomb_cooldown: float = 8.0
var _arrow_rain_cd_left: float = 0.0
var _bomb_cd_left: float = 0.0

@export var boss_buff_duration: float = 18.0
var _boss_buff_time: float = 0.0
var _boss_buff_active: bool = false
var _boss_speed_mult: float = 1.0
var _boss_firerate_mult: float = 1.0
var _boss_damage_bonus: int = 0
var _boss_magnet_bonus: float = 0.0
var _boss_dash_mult: float = 1.0


func _ready() -> void:
	Global.player = self
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("idle")
	xp_to_next = base_xp_to_level
	_refresh_lvl_label()


func _physics_process(delta: float) -> void:
	if is_dead or is_choosing_upgrade:
		return

	_dash_cd_left = maxf(0.0, _dash_cd_left - delta)
	_arrow_rain_cd_left = maxf(0.0, _arrow_rain_cd_left - delta)
	_bomb_cd_left = maxf(0.0, _bomb_cd_left - delta)
	_tick_boss_buff(delta)

	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if Input.is_action_just_pressed("dash") and _dash_cd_left <= 0.0 and not _is_dashing:
		_start_dash()

	if Input.is_action_just_pressed("ability_q") and has_arrow_rain and _arrow_rain_cd_left <= 0.0:
		_cast_arrow_rain()

	if Input.is_action_just_pressed("ability_e") and has_bomb and _bomb_cd_left <= 0.0:
		_cast_bomb()

	if _is_dashing:
		move_and_slide()
		return

	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		velocity = move_direction * _get_move_speed()

	var mouse_dir = get_global_mouse_position() - global_position
	_update_facing(mouse_dir)

	# Tiro automático sempre na direção do mouse
	if can_shoot and not _is_dashing and not is_hurt:
		_shoot(mouse_dir)

	_update_animation()
	move_and_slide()


func _start_dash() -> void:
	var dash_dir := move_direction
	if dash_dir == Vector2.ZERO:
		dash_dir = Vector2.RIGHT if not anim.flip_h else Vector2.LEFT
	_is_dashing = true
	is_invulnerable = true
	_dash_cd_left = dash_cooldown * _boss_dash_mult
	velocity = dash_dir.normalized() * dash_force * (1.2 if _boss_buff_active else 1.0)
	await get_tree().create_timer(dash_duration).timeout
	_is_dashing = false
	if not is_dead:
		is_invulnerable = false
		_check_ongoing_damage()


func _cast_arrow_rain() -> void:
	_arrow_rain_cd_left = arrow_rain_cooldown
	var center := get_global_mouse_position()
	for i in 10:
		var offset := Vector2(randf_range(-90, 90), randf_range(-90, 90))
		var bullet = bullet_sceme.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = center + offset + Vector2(0, -180)
		bullet.set_direction(Vector2.DOWN.rotated(randf_range(-0.2, 0.2)))
		if bullet.has_method("configure"):
			bullet.configure(_get_damage(), has_pierce, has_explosive)
		bullet.speed = 700.0


func _cast_bomb() -> void:
	_bomb_cd_left = bomb_cooldown
	var radius := 140.0
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		if global_position.distance_to(node.global_position) <= radius:
			if node.has_method("take_damage"):
				node.take_damage(_get_damage() * 3, global_position)
	# feedback visual simples
	modulate = Color(1.0, 0.7, 0.3)
	await get_tree().create_timer(0.12).timeout
	if not is_dead:
		modulate = Color.WHITE


func _update_facing(mouse_dir: Vector2) -> void:
	if mouse_dir.x != 0.0:
		anim.flip_h = mouse_dir.x < 0.0


func _update_animation() -> void:
	if is_attacking or is_hurt or is_dead:
		return

	if move_direction != Vector2.ZERO:
		if anim.animation != "run":
			anim.play("run")
	elif anim.animation != "idle":
		anim.play("idle")


func _shoot(direction: Vector2) -> void:
	can_shoot = false
	is_attacking = true
	anim.play("attack")

	await _wait_for_attack_frame(attack_release_frame)

	if is_dead or not is_attacking or anim.animation != "attack":
		can_shoot = true
		return

	_fire_projectiles(direction)

	await get_tree().create_timer(_get_shoot_cd()).timeout
	can_shoot = true


func _fire_projectiles(direction: Vector2) -> void:
	var dir := direction.normalized()
	# Sinergia: tiro duplo + traseiro = cruz completa
	if has_double_shot and has_reverse_shot:
		for angle_deg in [0.0, 90.0, 180.0, 270.0]:
			_spawn_bullet(dir.rotated(deg_to_rad(angle_deg)))
		return

	if has_double_shot:
		_spawn_bullet(dir.rotated(deg_to_rad(-12.0)))
		_spawn_bullet(dir.rotated(deg_to_rad(12.0)))
	else:
		_spawn_bullet(dir)

	if has_reverse_shot:
		_spawn_bullet(-dir)


func _wait_for_attack_frame(target_frame: int) -> void:
	while is_attacking and anim.animation == "attack" and anim.frame < target_frame:
		await anim.frame_changed


func _spawn_bullet(direction: Vector2) -> void:
	var bullet_instance = bullet_sceme.instantiate()
	get_tree().current_scene.add_child(bullet_instance)
	bullet_instance.global_position = global_position + direction.normalized() * 24.0
	bullet_instance.set_direction(direction)
	if bullet_instance.has_method("configure"):
		bullet_instance.configure(_get_damage(), has_pierce, has_explosive)


func _on_animation_finished() -> void:
	match anim.animation:
		"attack":
			is_attacking = false
		"hit":
			is_hurt = false


func has_upgrade(upgrade_id: String) -> bool:
	match upgrade_id:
		"double_shot":
			return has_double_shot
		"reverse_shot":
			return has_reverse_shot
		"pierce":
			return has_pierce
		"explosive":
			return has_explosive
		"magnet":
			return has_magnet
		"arrow_rain":
			return has_arrow_rain
		"bomb":
			return has_bomb
		_:
			return false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_take_damage_from(body)


func _take_damage_from(enemy: Node2D) -> void:
	if is_dead or is_invulnerable or is_choosing_upgrade or _is_dashing:
		return

	hp -= 1

	var knock_dir := (global_position - enemy.global_position).normalized()
	if knock_dir == Vector2.ZERO:
		knock_dir = Vector2.RIGHT.rotated(randf() * TAU)

	knockback_velocity = knock_dir * knockback_force

	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(-knock_dir * enemy_knockback_force)

	if hp <= 0:
		game_over()
		return

	_play_hit()
	_start_invulnerability()


func _start_invulnerability() -> void:
	is_invulnerable = true
	await get_tree().create_timer(hurt_invuln_time).timeout
	if is_dead or _is_dashing:
		return
	is_invulnerable = false
	_check_ongoing_damage()


func _check_ongoing_damage() -> void:
	for body in hurt_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			_take_damage_from(body)
			return


func _play_hit() -> void:
	if not anim.sprite_frames.has_animation("hit"):
		return
	is_hurt = true
	is_attacking = false
	anim.play("hit")


func game_over():
	is_dead = true
	can_shoot = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	is_attacking = false
	is_hurt = false

	var result := Global.finalize_run()

	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	if anim.sprite_frames.has_animation("death") and anim.sprite_frames.get_frame_count("death") > 0:
		anim.play("death")
		await anim.animation_finished
	else:
		await get_tree().create_timer(0.6, true).timeout

	var overlay = game_over_scene.instantiate()
	get_tree().current_scene.add_child(overlay)
	overlay.setup(result)
	await overlay.play_fade(1.4)

	await get_tree().create_timer(game_over_hold_time, true).timeout

	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	if area.is_in_group("xpdropInicial"):
		# Orbs dão pontos de XP, não 1 nível cada
		await add_xp(1)


func add_xp(amount: int = 1) -> void:
	if amount <= 0 or is_dead:
		return

	# Relíquia de XP: chance de dobrar o valor do orb
	if Global.xp_double_chance > 0.0 and randf() < Global.xp_double_chance:
		amount *= 2

	current_xp += amount
	Global.add_score(8 * amount)

	var upgrades_due := 0
	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		lvl += 1
		Global.add_score(25)
		xp_to_next = base_xp_to_level + (lvl - 1) * xp_growth_per_level
		if upgrade_every_n_levels > 0 and lvl % upgrade_every_n_levels == 0:
			upgrades_due += 1

	_refresh_lvl_label()

	if upgrades_due > 0:
		_pending_upgrades += upgrades_due
		if not is_choosing_upgrade:
			await _process_upgrade_queue()


func _process_upgrade_queue() -> void:
	while _pending_upgrades > 0 and not is_dead:
		_pending_upgrades -= 1
		await offer_upgrade_choice()


func offer_upgrade_choice() -> void:
	if is_dead:
		return
	if is_choosing_upgrade:
		return

	var options := UpgradeDB.roll_three(self)
	if options.is_empty():
		return

	is_choosing_upgrade = true
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	var pick = upgrade_pick_scene.instantiate()
	get_tree().current_scene.add_child(pick)
	var queue_hint := ""
	if _pending_upgrades > 0:
		queue_hint = "  (+%d na fila)" % _pending_upgrades
	if pick.has_method("set_title"):
		pick.set_title("LEVEL UP — escolha 1%s" % queue_hint)
	var chosen_id: String = await pick.pick_upgrade(options)
	UpgradeDB.apply(self, chosen_id)
	pick.queue_free()

	is_choosing_upgrade = false
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_INHERIT


func offer_relic_choice() -> void:
	if is_dead or is_choosing_upgrade:
		return

	is_choosing_upgrade = true
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	var pick = upgrade_pick_scene.instantiate()
	get_tree().current_scene.add_child(pick)
	if pick.has_method("set_title"):
		pick.set_title("RELÍQUIA DA RUN — escolha 1")
	var chosen_id: String = await pick.pick_upgrade(RelicDB.roll_three())
	RelicDB.apply(self, chosen_id)
	pick.queue_free()

	is_choosing_upgrade = false
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_INHERIT


func _refresh_lvl_label() -> void:
	label.text = "LVL: %d (%d/%d)" % [lvl, current_xp, xp_to_next]


func get_xp_hud() -> Dictionary:
	return {
		"current": current_xp,
		"next": xp_to_next,
	}


func _get_move_speed() -> float:
	return move_speed * _boss_speed_mult


func _get_shoot_cd() -> float:
	return maxf(0.1, shoot_coldown * _boss_firerate_mult)


func _get_damage() -> int:
	return bullet_damage + _boss_damage_bonus


func get_magnet_radius() -> float:
	return magnet_radius + _boss_magnet_bonus


## Buff temporário ao matar o boss (não é upgrade permanente).
func apply_boss_triumph_buff(duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = boss_buff_duration

	_boss_buff_active = true
	_boss_buff_time = duration
	_boss_speed_mult = 1.5
	_boss_firerate_mult = 0.5
	_boss_damage_bonus = 2
	_boss_magnet_bonus = 180.0
	_boss_dash_mult = 0.55

	hp = mini(hp + 2, max_hp)
	is_invulnerable = true
	Global.add_score(350)

	# I-frame curto no começo do buff
	await get_tree().create_timer(1.0).timeout
	if not is_dead and not _is_dashing:
		is_invulnerable = false


func _tick_boss_buff(delta: float) -> void:
	if not _boss_buff_active:
		return

	_boss_buff_time -= delta
	var pulse := 1.0 + 0.1 * sin(Time.get_ticks_msec() * 0.012)
	modulate = Color(1.25, 0.95, 0.45) * pulse

	if _boss_buff_time <= 0.0:
		_clear_boss_buff()


func _clear_boss_buff() -> void:
	_boss_buff_active = false
	_boss_buff_time = 0.0
	_boss_speed_mult = 1.0
	_boss_firerate_mult = 1.0
	_boss_damage_bonus = 0
	_boss_magnet_bonus = 0.0
	_boss_dash_mult = 1.0
	modulate = Color.WHITE


func get_ability_hud() -> Dictionary:
	return {
		"dash": _dash_cd_left,
		"dash_max": dash_cooldown * _boss_dash_mult,
		"rain": _arrow_rain_cd_left if has_arrow_rain else -1.0,
		"rain_max": arrow_rain_cooldown,
		"bomb": _bomb_cd_left if has_bomb else -1.0,
		"bomb_max": bomb_cooldown,
		"synergy": _synergy_text(),
		"boss_buff": _boss_buff_time if _boss_buff_active else 0.0,
	}


func _synergy_text() -> String:
	var parts: PackedStringArray = []
	if has_double_shot and has_reverse_shot:
		parts.append("CRUZ")
	if has_pierce and has_explosive:
		parts.append("CADEIA")
	if has_magnet:
		parts.append("IMA")
	return " + ".join(parts)
