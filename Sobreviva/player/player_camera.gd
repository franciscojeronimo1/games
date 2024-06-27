extends Camera2D
class_name  PlayerCamera

var _current_length: float
var _current_strength: float

func shake(_strength: float, _length: float) -> void:
	if _current_length != 0:
		return
	
	_current_length = _length
	_current_strength = _strength
	
	while _current_length >0:
		offset = Vector2 (
			randf_range(- _current_strength, + _current_strength),
			randf_range(- _current_strength, + _current_strength)
		)
		
		_current_length -= get_process_delta_time()
		await get_tree().physics_frame


	offset = Vector2.ZERO
	_current_strength = 0
	_current_length = 0
