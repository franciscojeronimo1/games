extends Label

class_name TextPopup

var _factor: float = 32.0

func update_text(_value: int) -> void:
	text = "-" + str(_value)

func _physics_process(_delta):
	position.y -= _delta * _factor

func _on_animation_finished(anim_name):
	queue_free()
