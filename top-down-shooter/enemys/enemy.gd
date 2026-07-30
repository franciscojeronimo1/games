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

	if is_elite:
		_elite_pulse += delta * 6.0
		anim.modulate = original_color * (1.0 + 0.15 * sin(_elite_pulse))

	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		_chase_player(delta)

	_update_flip()
	move_and_slide()


func _chase_player(_delta: float) -> void:
	if player:
		direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed
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
