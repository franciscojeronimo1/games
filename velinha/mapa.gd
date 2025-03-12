extends Node2D


func _on_tp_sofa_body_entered(body: Node2D) -> void:
	if body.name == "player":
		get_tree().change_scene_to_file("res://cenário/dentroSofa/mapa_sofa.tscn")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().change_scene_to_file("res://interface/interface.tscn")
