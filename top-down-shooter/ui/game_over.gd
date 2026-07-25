extends CanvasLayer

@onready var dim: ColorRect = $Dim
@onready var label: Label = $Center/Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dim.modulate.a = 0.0
	label.modulate.a = 0.0


## Escurece a tela e faz o texto GAME OVER aparecer aos poucos.
func play_fade(fade_in_duration: float = 1.5) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim, "modulate:a", 1.0, fade_in_duration)
	tween.tween_property(label, "modulate:a", 1.0, fade_in_duration).set_delay(0.35)
	await tween.finished
