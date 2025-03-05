extends Node2D


func _on_tp_sofa_body_entered(body: Node2D) -> void:
	get_tree().change_scene_to_file("res://cenário/dentroSofa/mapa_sofa.tscn")
