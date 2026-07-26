extends CharacterBody2D
class_name Player

@onready var player: Player = $"."
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label
@onready var hurt_area: Area2D = $Area2D

var bonus_effect_scene = preload("res://Player/lvl_up.tscn")
var game_over_scene = preload("res://ui/game_over.tscn")
@export var bullet_sceme : PackedScene
var can_shoot: bool = true
@export var shoot_coldown : float = 2.0
@export var game_over_hold_time: float = 1.8
@export var knockback_force: float = 480.0
@export var enemy_knockback_force: float = 380.0
@export var knockback_decay: float = 1400.0
@export var hurt_invuln_time: float = 0.35
@export var attack_release_frame: int = 5
var upgrades = {
	1: {"shoot_coldown": 0.8},
	10: {"shoot_coldown": 0.5, "move_speed": 500.0},
	15: {"shoot_coldown": 0.3},
	20: {"shoot_coldown": 0.1, "move_speed": 700.0},
	30: {"move_speed": 900.0}
}

@export var hp : int = 10
@export var lvl: int = 1

var move_speed := 300.0
var move_direction := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var is_attacking := false
var is_hurt := false
var is_dead := false
var is_invulnerable := false


func _ready() -> void:
	Global.player = self
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("idle")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	bonusUP()
	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		velocity = move_direction * move_speed

	var mouse_dir = get_global_mouse_position() - global_position

	_update_facing(mouse_dir)

	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot(mouse_dir)

	_update_animation()
	move_and_slide()


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

	_spawn_bullet(direction)
	if lvl >= 15:
		_spawn_bullet(-direction)

	await get_tree().create_timer(shoot_coldown).timeout
	can_shoot = true


func _wait_for_attack_frame(target_frame: int) -> void:
	while is_attacking and anim.animation == "attack" and anim.frame < target_frame:
		await anim.frame_changed


func _spawn_bullet(direction: Vector2) -> void:
	var bullet_instance = bullet_sceme.instantiate()
	get_tree().current_scene.add_child(bullet_instance)
	bullet_instance.global_position = global_position + direction.normalized() * 24.0
	bullet_instance.set_direction(direction)


func _on_animation_finished() -> void:
	match anim.animation:
		"attack":
			is_attacking = false
		"hit":
			is_hurt = false


func bonusUP():
	if upgrades.has(lvl):
		for key in upgrades[lvl]:
			self.set(key, upgrades[lvl][key])


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_take_damage_from(body)


func _take_damage_from(enemy: Node2D) -> void:
	if is_dead or is_invulnerable:
		return

	hp -= 1
	print("perdeu " + str(hp))

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
	if is_dead:
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

	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	if anim.sprite_frames.has_animation("death") and anim.sprite_frames.get_frame_count("death") > 0:
		anim.play("death")
		await anim.animation_finished
	else:
		await get_tree().create_timer(0.6, true).timeout

	var overlay = game_over_scene.instantiate()
	get_tree().current_scene.add_child(overlay)
	await overlay.play_fade(1.4)

	await get_tree().create_timer(game_over_hold_time, true).timeout

	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("xpdropInicial"):
		lvl += 1
		label.text = "LVL: " + str(lvl)
		print(lvl)
