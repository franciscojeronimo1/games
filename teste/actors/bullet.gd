extends Area2D

var speed: float = 1200.0
var max_distance: float = 1800.0
var _bullet_distance: float = 0.0
var start_pos: Vector2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var distance = speed * delta
	var motion = Vector2.RIGHT.rotated(rotation) * speed * delta
	
	
	global_position += motion
	
	_bullet_distance += distance
	if _bullet_distance > max_distance:
		queue_free()
		
func set_start_pos(pos: Vector2):
	global_position = pos
