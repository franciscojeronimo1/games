extends Node2D
class_name BaseWeapon

var _is_attacking: bool = false

@export_category("Variables")
@export var _attack_damage: int
@export var _attack_cooldown: float

@export_category("Objects")
@export var _attack_timer: Timer
@export var _detection_area: Area2D
@export var animation: AnimationPlayer

func _on_detection_area_body_entered(body) -> void:
	if _is_attacking:
		return
		
	if body is Enemy:
		_detection_area.set_deferred("monitoring", false)
		_attack_timer.start(_attack_cooldown)
		animation.play("att")
		_is_attacking = true
		
		


func _on_attack_timer_timeout() -> void:
	_is_attacking = false
	_detection_area.set_deferred("monitoring", true)


func _on_attack_area_body_entered(body):
	if body is Enemy:
		body.update_health(_attack_damage)
