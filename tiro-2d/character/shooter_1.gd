extends Node2D

@export var bullet_scene: PackedScene

var _is_shooting = false

func shoot():
	_is_shooting = true
	
func stop_shoot():
	_is_shooting = false
	
func shooting():
	var bullet = bullet_scene.instantiate()
	bullet.set_start_pos(global_position)
	bullet.rotation = rotation
	get_tree().root.add_child(bullet)
	#add_child(bullet)
	


func _on_timer_timeout() -> void:
	if _is_shooting:
		shooting()
