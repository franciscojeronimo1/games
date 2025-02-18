extends Node2D



var is_on = true
@onready var point_light_2d: PointLight2D = $PointLight2D

func _ready():
	toggle_light()
func _physics_process(delta: float) -> void:
	pass

func toggle_light():
	while true:
		is_on = !is_on
		point_light_2d.enabled = is_on
		await get_tree().create_timer(3.0).timeout  # Espera 1 segundo e repete

#func _on_ligar_luz_body_entered(body: Node2D) -> void:
	#if body.name == "Player":
	#	point_light_2d.enabled = true
