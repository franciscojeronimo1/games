extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@export var item_name: String = "Coletavel"
var can_collect = false 


func _ready() -> void:
	input_event.connect(_on_input_event)

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and can_collect:
		collect_item()
		



func collect_item():
	print("Item coletado:", item_name)  # Aqui você pode adicionar o item ao inventário
	queue_free()  # Remove o item da cena


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # Certifique-se de que o player pertence ao grupo "player"
		can_collect = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		can_collect = false
