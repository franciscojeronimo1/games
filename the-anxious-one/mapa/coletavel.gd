extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@export var item_name: String = "Coletavel"
var can_collect = false 
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	add_to_group("coletavel")
	input_event.connect(_on_input_event)

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and can_collect:
		collect_item()
		



func collect_item():
	audio_stream_player_2d.play()
	await audio_stream_player_2d.finished
	queue_free()  # Remove o item da cena
	


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # Certifique-se de que o player pertence ao grupo "player"
		can_collect = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		can_collect = false
