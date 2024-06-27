extends CharacterBody2D
class_name Enemy

const _EXPLOSION: PackedScene = preload("res://effects/particles/explosion.tscn")

var _loading_dash: bool = false
var _is_dashing: bool = false
var _previous_character_position: Vector2

@export_category("Variables")

@export var _enemt_type: String = "chase"
@export var _move_speed: float = 192.0
@export var _dash_speed: float = 768.0

@export var _health: int = 12
@export var _demage: int = 3
@export var _invicibility_cooldown: float = 0.5

@export_category("Objects")
@export var _hitbox_area: Area2D
@export var _invincibility_timer : Timer
@export var _dash_wait_time: Timer
@export var _dash_timer: Timer
@export var _aux_animation: AnimationPlayer

func _physics_process(delta):
	if _loading_dash:
		return
	if global.player == null:
		print("Personagem nao encontrado!")
		return
		
	var _direction: Vector2 = global_position.direction_to(global.player.global_position)
	var _distance: float = global_position.distance_to(global.player.global_position)
	
	if _distance <= 16.0:
		#aplicar a lógica de ataque
		return
	
	match _enemt_type:
		"chase":
			_chase(_direction)
			
		"chase_and_dash":
			chase_and_dash(_direction)
				
	move_and_slide()
	
func _chase(_direction: Vector2):
	velocity = _direction * _move_speed


func chase_and_dash(_direction: Vector2) -> void:
	if not _is_dashing:
		velocity = _direction * _move_speed


	if _is_dashing:
		_direction = global_position.direction_to(_previous_character_position)
		velocity= _direction * _dash_speed

func update_health(_value: int):
	_health -= _value
	if _health <= 0:
		get_tree().call_group("player_camera", "shake", 10.0, 0.35)
		_spawn_explosion_particles()
		queue_free()
		return
		
		get_tree().call_group("player_camera", "shake", 5.0, 0.25)
	_aux_animation.play("hit")

func _spawn_explosion_particles():
	var _particles: CPUParticles2D = _EXPLOSION.instantiate()
	_particles.global_position = global_position
	_particles.emitting = true
	get_tree().root.call_deferred("add_child", _particles)

func _on_range_area_body_entered(body):
	if _enemt_type != "chase_and_dash":
		return
		
	if _is_dashing:
		return
	if body is Player:
		_previous_character_position = global.player.global_position
		_dash_wait_time.start()
		_loading_dash = true


func _on_dash_wait_time_timeout():
	_loading_dash = false
	_is_dashing = true
	_dash_timer.start()


func _on_dash_timer_timeout() -> void:
	_is_dashing = false


func _on_hitbox_area_body_entered(body):
	if body is Player:
		_hitbox_area.set_deferred("monitoring", false)
		_invincibility_timer.start(_invicibility_cooldown)
		body.update_health("damage",_demage)
		print("causar dano")


func _on_invencibility_timer_timeout():
		_hitbox_area.set_deferred("monitoring", true)
