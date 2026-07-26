extends Enemy
class_name Boss

@export var attack_range: float = 100.0
@export var attack_cooldown: float = 1.2
@export var attack_hit_frame_start: int = 4
@export var attack_hit_frame_end: int = 5

var is_attacking := false
var can_attack := true
var damage_dealt_this_attack := false


func _ready() -> void:
	super._ready()
	anim.animation_finished.connect(_on_animation_finished)
	anim.frame_changed.connect(_on_frame_changed)


func _chase_player(delta: float) -> void:
	if is_attacking:
		velocity = Vector2.ZERO
		return

	super._chase_player(delta)

	if can_attack and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= attack_range:
			_start_attack()


func _start_attack() -> void:
	if not is_instance_valid(player):
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

	var reach := attack_range * 1.25
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
