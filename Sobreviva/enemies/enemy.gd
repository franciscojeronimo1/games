extends CharacterBody2D
class_name Enemy

var _loading_dash: bool = false
var _is_dashing: bool = false
var _previous_character_position: Vector2

@export_category("Variables")
@export var _enemt_type: String = "chase"
@export var _move_speed: float = 192.0
@export var _dash_speed: float = 768.0

@export_category("Objects")
@export var _dash_wait_time: Timer
@export var _dash_timer: Timer

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
