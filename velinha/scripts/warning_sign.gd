extends Node2D

@onready var texture: AnimatedSprite2D = $texture
@onready var area_sign: Area2D = $area_sign

const lines : Array[String] = [
	"thanks little one,",
	"I see that you still",
	"have a lot of time to live,",
	 "but if you keep walking around",
	"you will become small,",
	 "be careful!"
]

func _unhandled_input(event: InputEvent) -> void:
	if area_sign.get_overlapping_bodies().size() > 0:
		texture.show()
		if event.is_action_pressed("interact") && !DialogManager.is_message_active:
			DialogManager.start_message(global_position, lines)
	else:
		texture.hide()
		if DialogManager.dialog_box != null:
			DialogManager.dialog_box.queue_free()
			DialogManager.is_message_active = false


func _on_area_sign_body_entered(body: Node2D) -> void:
	if body.name == "player":
		texture.play("idleVeia")
