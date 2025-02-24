extends Node2D

@export var proxima_cena: String = "res://interface/final.tscn"




func _process(delta):
	if get_tree().get_nodes_in_group("coletavel").is_empty():
		mudar_de_cena()
	if Input.is_action_pressed("esc"):
		get_tree().change_scene_to_file("res://interface/interface.tscn")
func mudar_de_cena():
	await get_tree().create_timer(4).timeout  
	get_tree().change_scene_to_file(proxima_cena)
	



func _on_expressao_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		$expressao/Expressao1.visible = true


func _on_expressao_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		$expressao/Expressao1.visible = false


func _on_tarefa_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		$Tarefa/Papel.visible = true
		$Tarefa/ExpressaoRuivo3.visible = true

func _on_tarefa_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		$Tarefa/Papel.visible = false
		$Tarefa/ExpressaoRuivo3.visible = false
