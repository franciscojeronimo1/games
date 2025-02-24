extends Area2D

@onready var point_light_2d: PointLight2D = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		point_light_2d.enabled = true
		$"../AudioStreamPlayer2D".play()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		connect("input_event", _on_input_event)



func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		disconnect("input_event", _on_input_event)
		await get_tree().create_timer(3.0).timeout 
		point_light_2d.enabled = false
		$"../AudioStreamPlayer2D".play()
