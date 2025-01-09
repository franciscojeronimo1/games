extends CharacterBody2D
class_name BaseCharacter


@export_category("Variables")
@export var _move_speed: float = 128.0
@export var dmg: int = 1
@export var _player_health: int = 5

@export_category("Objects")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	_move()
	_attack()
	_animate()
	
func _move() -> void:
	var _direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	
	velocity = _direction * _move_speed
	move_and_slide()
	
	
func _attack() -> void:
	if Input.is_action_just_pressed("left_attack"):
		animated_sprite_2d.play("attack_frente")
		set_physics_process(false)
		
	if Input.is_action_just_pressed("right_attack"):
		animated_sprite_2d.play("attack_area")
		set_physics_process(false)


func _animate() -> void:
	if velocity.x > 0:
		animated_sprite_2d.flip_h = false
		
	if velocity.x < 0:
		animated_sprite_2d.flip_h = true
	if velocity:
		animated_sprite_2d.play("run")


func _on_animated_sprite_2d_animation_finished() -> void:
	animated_sprite_2d.play("idle")
	set_physics_process(true)
	


func update_health(_damage: int) -> void:
	_player_health -= _damage
	if _player_health <= 0:
		print("player morreu")
		queue_free()
		return
	print("character perdeu " + str(_damage) + " pontos de vida. vida atual " + str(_player_health))
