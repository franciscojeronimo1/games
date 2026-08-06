extends CharacterBody2D
class_name Enemy

@export var move_speed: float = 100.0
@export var health: int = 1
@onready var anim: AnimatedSprite2D = $anim
@export var drop: PackedScene
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@export var xp_reward: int = 1
@export var coin_reward: int = 1
@export var deathParticle: PackedScene

var direction: Vector2 = Vector2.ZERO
var player = null
var original_color := Color.WHITE
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1000.0

var is_elite: bool = false
var _elite_pulse := 0.0

# Status: queimadura / gelo
var _burn_time: float = 0.0
var _burn_tick_left: float = 0.0
var _burn_damage: int = 0
var _burn_tick_interval: float = 0.5
var _slow_time: float = 0.0
var _slow_mult: float = 1.0
var _status_fx: GPUParticles2D


func make_elite() -> void:
	is_elite = true
	health = int(health * 3.0)
	move_speed *= 1.15
	scale *= 1.25
	xp_reward = maxi(xp_reward * 3, 3)
	coin_reward = maxi(coin_reward * 3, 3)
	original_color = Color(1.25, 1.05, 0.35)
	anim.modulate = original_color
	add_to_group("elites")


func _grant_rewards() -> void:
	var xp_amount := xp_reward
	var coin_amount := coin_reward
	if is_elite:
		Global.add_score(120)

	if is_instance_valid(Global.player):
		if Global.player.has_method("add_xp"):
			Global.player.add_xp(xp_amount)
		if "bonus_coins_per_kill" in Global.player:
			coin_amount += int(Global.player.bonus_coins_per_kill)
	Global.add_coins(coin_amount)


func _ready() -> void:
	player = Global.player
	if not is_elite:
		original_color = anim.modulate
		health = int(health * Global.enemy_hp_mult)
		move_speed *= Global.enemy_speed_mult
	_play_move_anim()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = Global.player

	_tick_status(delta)

	if is_elite:
		_elite_pulse += delta * 6.0
		if _burn_time <= 0.0 and _slow_time <= 0.0:
			anim.modulate = original_color * (1.0 + 0.15 * sin(_elite_pulse))

	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		_chase_player(delta)

	_update_flip()
	move_and_slide()


func _tick_status(delta: float) -> void:
	if _burn_time > 0.0:
		_burn_time -= delta
		_burn_tick_left -= delta
		if _burn_tick_left <= 0.0:
			_burn_tick_left = _burn_tick_interval
			if health > 0:
				health -= _burn_damage
				_pulse_burn_flash()
				if health <= 0:
					Global.register_kill(is_elite)
					call_deferred("_die")
					return
		if _burn_time <= 0.0 and _slow_time <= 0.0:
			_clear_status_fx()
			anim.modulate = original_color

	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow_mult = 1.0
			if _burn_time <= 0.0:
				_clear_status_fx()
				anim.modulate = original_color


func _status_speed_mult() -> float:
	if _slow_time > 0.0:
		return clampf(_slow_mult, 0.15, 1.0)
	return 1.0


func apply_burn(damage: int, duration: float, tick_interval: float = 0.5) -> void:
	if health <= 0:
		return
	_burn_damage = maxi(1, damage)
	_burn_tick_interval = maxf(0.2, tick_interval)
	_burn_time = maxf(_burn_time, duration)
	_burn_tick_left = minf(_burn_tick_left if _burn_tick_left > 0.0 else _burn_tick_interval, _burn_tick_interval)
	_ensure_status_fx(true)
	anim.modulate = Color(1.35, 0.55, 0.2)


func apply_slow(speed_mult: float, duration: float) -> void:
	if health <= 0:
		return
	_slow_mult = minf(_slow_mult if _slow_time > 0.0 else 1.0, clampf(speed_mult, 0.15, 1.0))
	_slow_time = maxf(_slow_time, duration)
	_ensure_status_fx(false)
	if _burn_time <= 0.0:
		anim.modulate = Color(0.55, 0.85, 1.35)


func _ensure_status_fx(is_fire: bool) -> void:
	if _status_fx == null or not is_instance_valid(_status_fx):
		_status_fx = GPUParticles2D.new()
		_status_fx.z_index = 5
		_status_fx.amount = 14
		_status_fx.lifetime = 0.45
		_status_fx.preprocess = 0.1
		_status_fx.explosiveness = 0.05
		_status_fx.local_coords = false
		add_child(_status_fx)
	_status_fx.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 10.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 40.0
	mat.initial_velocity_min = 12.0
	mat.initial_velocity_max = 36.0
	mat.gravity = Vector3(0, -20.0 if is_fire else 30.0, 0)
	mat.scale_min = 1.5
	mat.scale_max = 3.0
	if is_fire:
		mat.color = Color(1.0, 0.45, 0.1, 0.9)
	else:
		mat.color = Color(0.55, 0.9, 1.0, 0.85)
	_status_fx.process_material = mat


func _clear_status_fx() -> void:
	if _status_fx and is_instance_valid(_status_fx):
		_status_fx.emitting = false
		_status_fx.queue_free()
	_status_fx = null


func _pulse_burn_flash() -> void:
	anim.modulate = Color(1.6, 0.35, 0.1)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self) and _burn_time > 0.0:
		anim.modulate = Color(1.35, 0.55, 0.2)


func _chase_player(_delta: float) -> void:
	if player:
		direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed * _status_speed_mult()
		_play_move_anim()


func _update_flip() -> void:
	if direction.x != 0.0:
		anim.flip_h = direction.x < 0.0


func _play_move_anim() -> void:
	if anim.sprite_frames.has_animation("walk"):
		if anim.animation != "walk":
			anim.play("walk")
	elif anim.sprite_frames.has_animation("idle"):
		if anim.animation != "idle":
			anim.play("idle")
	elif anim.sprite_frames.has_animation("default_1"):
		if anim.animation != "default_1":
			anim.play("default_1")


func hit_flash():
	anim.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_instance_valid(self):
		return
	if _burn_time > 0.0:
		anim.modulate = Color(1.35, 0.55, 0.2)
	elif _slow_time > 0.0:
		anim.modulate = Color(0.55, 0.85, 1.35)
	else:
		anim.modulate = original_color


func apply_knockback(force: Vector2):
	knockback_velocity = force


func take_damage(amount: int, source_position: Vector2):
	if health <= 0:
		return

	health -= amount
	var knockback_dir = (global_position - source_position).normalized()
	apply_knockback(knockback_dir * 300)
	hit_flash()

	if health <= 0:
		Global.register_kill(is_elite)
		call_deferred("_die")


func drop_and_die():
	_die()


func _die():
	if not is_inside_tree():
		return
	_clear_status_fx()
	_grant_rewards()
	if deathParticle:
		var _particle = deathParticle.instantiate()
		_particle.position = global_position
		_particle.rotation = global_rotation
		_particle.emitting = true
		get_tree().current_scene.add_child(_particle)
	queue_free()


func killParticle():
	pass
