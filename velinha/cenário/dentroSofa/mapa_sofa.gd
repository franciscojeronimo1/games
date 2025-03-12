extends Node2D



func _on_trocar_mapa_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_tree().change_scene_to_file("res://cenário/mapa_final.tscn")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().change_scene_to_file("res://interface/interface.tscn")
