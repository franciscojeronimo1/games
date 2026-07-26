extends CanvasLayer

@onready var dim: ColorRect = $Dim
@onready var label: Label = $Center/VBox/Label
@onready var stats: Label = $Center/VBox/Stats


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dim.modulate.a = 0.0
	label.modulate.a = 0.0
	stats.modulate.a = 0.0


func setup(result: Dictionary) -> void:
	var record_text := "NOVO RECORDE!" if result.get("is_record", false) else "Recorde: %d" % result.get("high_score", 0)
	stats.text = "Score: %d\n%s\nTempo: %s\nKills: %d  |  Wave: %d" % [
		result.get("score", 0),
		record_text,
		Global.format_time(result.get("time", 0.0)),
		result.get("kills", 0),
		result.get("wave", 0),
	]


func play_fade(fade_in_duration: float = 1.5) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim, "modulate:a", 1.0, fade_in_duration)
	tween.tween_property(label, "modulate:a", 1.0, fade_in_duration).set_delay(0.35)
	tween.tween_property(stats, "modulate:a", 1.0, fade_in_duration).set_delay(0.55)
	await tween.finished
