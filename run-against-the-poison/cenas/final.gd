extends Control



func _on_restart_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/interface.tscn")


func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/creditos.tscn")
