extends CharacterBody2D
class_name Enemy

@export var move_speed: float = 100.0
@export var health: int = 5
@onready var anim: AnimatedSprite2D = $anim
@export var drop: PackedScene
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

var direction: Vector2 = Vector2.ZERO
var player = null
var original_color := Color.WHITE
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1000.0
@export var deathParticle: PackedScene


func spawn_enemy_item():
	var drop_instance = drop.instantiate()
	call_deferred("_add_drop", drop_instance)


func _add_drop(drop_instance):
	get_tree().current_scene.add_child(drop_instance)
	drop_instance.global_position = global_position


func _ready() -> void:
	player = Global.player
	original_color = anim.modulate
	_play_move_anim()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = Global.player

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
		Global.register_kill()
		call_deferred("_die")


func drop_and_die():
	_die()


func _die():
	if not is_inside_tree():
		return
	spawn_enemy_item()
	if deathParticle:
		var _particle = deathParticle.instantiate()
		_particle.position = global_position
		_particle.rotation = global_rotation
		_particle.emitting = true
		get_tree().current_scene.add_child(_particle)
	queue_free()


func killParticle():
	pass
