extends Enemy
class_name Boss

@export var attack_range: float = 110.0
@export var attack_cooldown: float = 1.0
@export var attack_hit_frame_start: int = 4
@export var attack_hit_frame_end: int = 5
@export var triumph_xp: int = 8
@export var triumph_coins: int = 15
@export var dash_range_min: float = 160.0
@export var dash_range_max: float = 420.0
@export var dash_cooldown: float = 2.2
@export var dash_force: float = 900.0
@export var dash_duration: float = 0.22

var is_attacking := false
var can_attack := true
var damage_dealt_this_attack := false
var _dash_cd_left: float = 0.0
var _is_dashing := false


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	move_speed = maxf(move_speed, 160.0)
	anim.animation_finished.connect(_on_animation_finished)
	anim.frame_changed.connect(_on_frame_changed)


func _physics_process(delta: float) -> void:
	_dash_cd_left = maxf(0.0, _dash_cd_left - delta)
	if _is_dashing:
		_update_flip()
		move_and_slide()
		return
	super._physics_process(delta)


func _chase_player(delta: float) -> void:
	if is_attacking or _is_dashing:
		velocity = Vector2.ZERO
		return

	if not is_instance_valid(player):
		super._chase_player(delta)
		return

	var dist := global_position.distance_to(player.global_position)
	direction = global_position.direction_to(player.global_position)

	# Dash de investida quando o player está a média distância
	if can_attack and _dash_cd_left <= 0.0 and dist >= dash_range_min and dist <= dash_range_max:
		_start_dash()
		return

	super._chase_player(delta)

	if can_attack and dist <= attack_range:
		_start_attack()


func _start_dash() -> void:
	if not is_instance_valid(player):
		return

	_is_dashing = true
	can_attack = false
	_dash_cd_left = dash_cooldown
	direction = global_position.direction_to(player.global_position)
	_update_flip()
	velocity = direction * dash_force
	_play_move_anim()

	await get_tree().create_timer(dash_duration).timeout
	_is_dashing = false
	velocity = Vector2.ZERO

	# Se chegou perto no fim do dash, ataca na hora
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= attack_range * 1.4:
		_start_attack()
	else:
		await get_tree().create_timer(0.25).timeout
		can_attack = true


func _start_attack() -> void:
	if not is_instance_valid(player) or _is_dashing:
		return

	is_attacking = true
	can_attack = false
	damage_dealt_this_attack = false
	velocity = Vector2.ZERO

	direction = global_position.direction_to(player.global_position)
	_update_flip()

	if anim.sprite_frames.has_animation("attack1"):
		anim.play("attack1")
	else:
		_finish_attack()


func _on_frame_changed() -> void:
	if not is_attacking or anim.animation != "attack1":
		return
	if damage_dealt_this_attack:
		return
	if anim.frame < attack_hit_frame_start or anim.frame > attack_hit_frame_end:
		return

	_deal_attack_damage()


func _deal_attack_damage() -> void:
	if not is_instance_valid(player):
		return

	var reach := attack_range * 1.35
	if global_position.distance_to(player.global_position) > reach:
		return

	damage_dealt_this_attack = true
	if player.has_method("_take_damage_from"):
		player._take_damage_from(self)


func _on_animation_finished() -> void:
	if anim.animation == "attack1":
		_finish_attack()


func _finish_attack() -> void:
	is_attacking = false
	_play_move_anim()
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func _play_move_anim() -> void:
	if is_attacking:
		return
	super._play_move_anim()


func spawn_enemy_item():
	pass


func _grant_rewards() -> void:
	if is_instance_valid(Global.player) and Global.player.has_method("add_xp"):
		Global.player.add_xp(triumph_xp)
	Global.add_coins(triumph_coins)
	Global.add_score(500)


func _die():
	if not is_inside_tree():
		return

	if is_instance_valid(Global.player) and Global.player.has_method("apply_boss_triumph_buff"):
		Global.player.apply_boss_triumph_buff()

	_grant_rewards()
	if deathParticle:
		var _particle = deathParticle.instantiate()
		_particle.position = global_position
		_particle.rotation = global_rotation
		_particle.emitting = true
		get_tree().current_scene.add_child(_particle)

	queue_free()
