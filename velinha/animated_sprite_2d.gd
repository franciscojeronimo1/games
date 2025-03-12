extends AnimatedSprite2D

@onready var npc_g_apagado: AnimatedSprite2D = $"."


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		npc_g_apagado.play("acesa")
	
