extends CharacterBody2D
class_name Player

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label
@onready var hurt_area: Area2D = $Area2D

var game_over_scene = preload("res://ui/game_over.tscn")
var upgrade_pick_scene = preload("res://ui/upgrade_pick.tscn")
var foot_trail_scene = preload("res://prefabs/foot_trail.tscn")
var meteor_scene = preload("res://prefabs/meteoro.tscn")
@export var bullet_sceme: PackedScene
## "archer" | "wizard" — usado pra textos/ataques por personagem
@export var character_id: String = "archer"
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
var has_foot_trail := false
## "normal" | "fire" | "ice"
var arrow_element: String = "normal"
var burn_damage: int = 1
var burn_duration: float = 2.5
var burn_tick: float = 0.5
var ice_slow_mult: float = 0.45
var ice_slow_duration: float = 2.0
var ice_aura_radius: float = 95.0

var magnet_radius: float = 48.0
@export var trail_spacing: float = 42.0
@export var trail_lifetime: float = 3.0
var _last_trail_pos: Vector2 = Vector2.INF
var bonus_coins_per_kill: int = 0
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

## true = IA joga; false = você controla (WASD + mouse)
@export var auto_mode: bool = true
var _aim_dir: Vector2 = Vector2.RIGHT


func _ready() -> void:
	Global.player = self
	auto_mode = Global.prefer_auto_mode
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("idle")
	xp_to_next = base_xp_to_level
	_refresh_lvl_label()


func _unhandled_input(event: InputEvent) -> void:
	if is_dead or is_choosing_upgrade:
		return
	if event.is_action_pressed("toggle_auto"):
		auto_mode = not auto_mode
		get_viewport().set_input_as_handled()
		return
	# Skills manuais funcionam também no modo automático
	if event.is_action_pressed("ability_q"):
		if has_arrow_rain and _arrow_rain_cd_left <= 0.0:
			_cast_arrow_rain()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ability_e"):
		if has_bomb and _bomb_cd_left <= 0.0:
			_cast_bomb()
			get_viewport().set_input_as_handled()
		return


func _physics_process(delta: float) -> void:
	if is_dead or is_choosing_upgrade:
		return

	_dash_cd_left = maxf(0.0, _dash_cd_left - delta)
	_arrow_rain_cd_left = maxf(0.0, _arrow_rain_cd_left - delta)
	_bomb_cd_left = maxf(0.0, _bomb_cd_left - delta)
	_tick_boss_buff(delta)

	if auto_mode:
		_run_auto_pilot()
	else:
		_run_manual_control()

	if _is_dashing:
		move_and_slide()
		_try_drop_trail()
		return

	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		velocity = move_direction * _get_move_speed()

	_update_facing(_aim_dir)
	_update_animation()
	move_and_slide()
	_try_drop_trail()


func _try_drop_trail() -> void:
	if not has_foot_trail or is_dead:
		return
	if velocity.length() < 35.0:
		return
	if _last_trail_pos != Vector2.INF and global_position.distance_to(_last_trail_pos) < trail_spacing:
		return
	_last_trail_pos = global_position
	var trail = foot_trail_scene.instantiate()
	get_tree().current_scene.add_child(trail)
	# Um pouco abaixo do centro = “pés”
	trail.global_position = global_position + Vector2(0, 18)
	var dmg := maxi(1, int(ceili(float(_get_damage()) * 0.5)))
	if trail.has_method("setup"):
		trail.setup(dmg, trail_lifetime)


func _try_shoot() -> void:
	if can_shoot and not _is_dashing and not is_hurt and _aim_dir != Vector2.ZERO:
		_shoot(_aim_dir)


func _run_manual_control() -> void:
	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_aim_dir = get_global_mouse_position() - global_position

	# Manual: atira no clique / segurando o mouse
	if Input.is_action_pressed("shoot"):
		_try_shoot()

	if Input.is_action_just_pressed("dash") and _dash_cd_left <= 0.0 and not _is_dashing:
		_start_dash()

	# Q/E tratados em _unhandled_input (também no auto)


func _run_auto_pilot() -> void:
	var decision: Dictionary = AutoPilot.think(self)
	move_direction = decision.get("move", Vector2.ZERO)
	var aim: Vector2 = decision.get("aim", Vector2.RIGHT)
	if aim != Vector2.ZERO:
		_aim_dir = aim

	# Auto: IA decide quando atirar
	if decision.get("shoot", false):
		_try_shoot()

	if decision.get("dash", false) and _dash_cd_left <= 0.0 and not _is_dashing:
		var dash_dir: Vector2 = decision.get("dash_dir", move_direction)
		_start_dash(dash_dir)

	if decision.get("use_e", false) and has_bomb and _bomb_cd_left <= 0.0:
		_cast_bomb()

	if decision.get("use_q", false) and has_arrow_rain and _arrow_rain_cd_left <= 0.0:
		_cast_arrow_rain(decision.get("q_center", global_position))


func _start_dash(forced_dir: Vector2 = Vector2.ZERO) -> void:
	var dash_dir := forced_dir
	if dash_dir == Vector2.ZERO:
		dash_dir = move_direction
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


func _cast_arrow_rain(center: Vector2 = Vector2.INF) -> void:
	_arrow_rain_cd_left = arrow_rain_cooldown
	if character_id == "wizard":
		_cast_meteor_strike(center)
		return

	if center == Vector2.INF:
		center = get_global_mouse_position()
	for i in 10:
		var offset := Vector2(randf_range(-90, 90), randf_range(-90, 90))
		var bullet = bullet_sceme.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = center + offset + Vector2(0, -180)
		bullet.set_direction(Vector2.DOWN.rotated(randf_range(-0.2, 0.2)))
		if bullet.has_method("configure"):
			bullet.configure(_get_damage(), has_pierce, has_explosive, _arrow_extras())
		bullet.speed = 700.0


## Mago [Q]: meteoros caem de cima nos inimigos e explodem em área.
func _cast_meteor_strike(center: Vector2 = Vector2.INF) -> void:
	if center == Vector2.INF:
		center = _pick_meteor_focus()

	var impact_damage := maxi(18, _get_damage() * 10)
	var radius := 250.0
	# 3 meteoros no cluster — um no centro e dois perto
	var offsets: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(randf_range(-70, -30), randf_range(-40, 40)),
		Vector2(randf_range(30, 70), randf_range(-40, 40)),
	]
	for i in offsets.size():
		var meteor = meteor_scene.instantiate()
		get_tree().current_scene.add_child(meteor)
		var impact: Vector2 = center + offsets[i]
		if meteor.has_method("setup"):
			meteor.setup(impact, impact_damage, radius, 480.0 + i * 40.0)
			meteor.burn_damage = maxi(1, burn_damage)
			meteor.burn_duration = maxf(1.5, burn_duration * 0.7)


func _pick_meteor_focus() -> Vector2:
	# Mira no pack mais denso; senão no aim / mouse
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best_pos := global_position + _aim_dir.normalized() * 220.0
	var best_score := -1
	for e in enemies:
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var pos: Vector2 = e.global_position
		var score := 0
		for other in enemies:
			if not is_instance_valid(other) or not (other is Node2D):
				continue
			if pos.distance_to(other.global_position) <= 160.0:
				score += 1
		if score > best_score:
			best_score = score
			best_pos = pos
	if best_score <= 0 and not auto_mode:
		return get_global_mouse_position()
	return best_pos


func _cast_bomb() -> void:
	_bomb_cd_left = bomb_cooldown
	var radius := 160.0
	var damage := maxi(3, _get_damage() * 3)

	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		if global_position.distance_to(node.global_position) <= radius:
			if node.has_method("take_damage"):
				node.take_damage(damage, global_position)
			if node.has_method("apply_knockback"):
				var push: Vector2 = (node.global_position - global_position).normalized()
				if push == Vector2.ZERO:
					push = Vector2.RIGHT
				node.apply_knockback(push * 520.0)

	_spawn_bomb_vfx(radius)


func _spawn_bomb_vfx(radius: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	# Anel de choque expansivo
	var ring := Polygon2D.new()
	ring.z_index = 20
	ring.color = Color(1.0, 0.85, 0.25, 0.75)
	var pts := PackedVector2Array()
	for i in 24:
		var a := float(i) * TAU / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 18.0)
	ring.polygon = pts
	ring.global_position = global_position
	scene.add_child(ring)

	var tween := scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * (radius / 18.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(ring.queue_free)

	# Partículas da explosão
	var burst := GPUParticles2D.new()
	burst.z_index = 21
	burst.global_position = global_position
	burst.amount = 36
	burst.lifetime = 0.4
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 8.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 90.0
	mat.initial_velocity_max = 260.0
	mat.gravity = Vector3(0, 180, 0)
	mat.scale_min = 2.0
	mat.scale_max = 4.5
	mat.color = Color(1.0, 0.7, 0.2, 1.0)
	burst.process_material = mat
	scene.add_child(burst)
	burst.get_tree().create_timer(0.7, true).timeout.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)

	# Flash no player
	modulate = Color(1.4, 1.1, 0.5)
	await get_tree().create_timer(0.12).timeout
	if not is_dead:
		modulate = Color.WHITE


func _update_facing(aim_dir: Vector2) -> void:
	if aim_dir.x != 0.0:
		anim.flip_h = aim_dir.x < 0.0


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
	var goal := target_frame
	if anim.sprite_frames and anim.sprite_frames.has_animation("attack"):
		var last := anim.sprite_frames.get_frame_count("attack") - 1
		goal = clampi(target_frame, 0, maxi(0, last))
	while is_attacking and anim.animation == "attack" and anim.frame < goal:
		await anim.frame_changed


func _spawn_bullet(direction: Vector2) -> void:
	if bullet_sceme == null:
		return
	var bullet_instance = bullet_sceme.instantiate()
	get_tree().current_scene.add_child(bullet_instance)
	var muzzle := 28.0 if character_id == "wizard" else 24.0
	bullet_instance.global_position = global_position + direction.normalized() * muzzle
	bullet_instance.set_direction(direction)
	if bullet_instance.has_method("configure"):
		bullet_instance.configure(_get_damage(), has_pierce, has_explosive, _arrow_extras())


func _arrow_extras() -> Dictionary:
	return {
		"element": arrow_element,
		"burn_damage": burn_damage,
		"burn_duration": burn_duration,
		"burn_tick": burn_tick,
		"ice_slow_mult": ice_slow_mult,
		"ice_slow_duration": ice_slow_duration,
		"ice_aura_radius": ice_aura_radius,
	}


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
		"foot_trail":
			return has_foot_trail
		"fire_arrow":
			return arrow_element == "fire"
		"ice_arrow":
			return arrow_element == "ice"
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

	# Espera um pouco e volta sozinho pro menu (botões também funcionam)
	await get_tree().create_timer(game_over_hold_time, true).timeout
	if not is_inside_tree():
		return
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_area_2d_area_entered(area: Area2D) -> void:
	# Orbs de XP antigos não são mais usados; mantém só pra itens especiais futuros
	if is_dead:
		return
	if area.is_in_group("xpdropInicial"):
		area.queue_free()


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
		"q_name": SkillNames.ability_q_name(character_id),
		"e_name": SkillNames.ability_e_name(character_id),
		"synergy": _synergy_text(),
		"boss_buff": _boss_buff_time if _boss_buff_active else 0.0,
		"auto_mode": auto_mode,
	}


func _synergy_text() -> String:
	var parts: PackedStringArray = []
	if has_double_shot and has_reverse_shot:
		parts.append(SkillNames.synergy_label("cross", character_id))
	if has_pierce and has_explosive:
		parts.append(SkillNames.synergy_label("chain", character_id))
	if has_magnet:
		parts.append(SkillNames.synergy_label("coins", character_id))
	if has_foot_trail:
		parts.append(SkillNames.synergy_label("trail", character_id))
	if arrow_element == "fire":
		parts.append(SkillNames.synergy_label("fire", character_id))
	elif arrow_element == "ice":
		parts.append(SkillNames.synergy_label("ice", character_id))
	return " + ".join(parts)
