extends CanvasLayer

const MAIN_MENU := "res://scenes/main_menu.tscn"
const ARENA := "res://scenes/arena.tscn"

@onready var dim: ColorRect = $Dim
@onready var label: Label = $Center/VBox/Label
@onready var stats: Label = $Center/VBox/Stats
@onready var menu_btn: Button = $Center/VBox/Buttons/MenuBtn
@onready var retry_btn: Button = $Center/VBox/Buttons/RetryBtn


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dim.modulate.a = 0.0
	label.modulate.a = 0.0
	stats.modulate.a = 0.0
	$Center/VBox/Buttons.modulate.a = 0.0
	UiTheme.apply_button(menu_btn, 22)
	UiTheme.apply_button(retry_btn, 22)
	UiTheme.apply_label(label, 72, UiTheme.ACCENT_RED, true)
	UiTheme.apply_label(stats, 26, UiTheme.TEXT_BODY, false)
	menu_btn.pressed.connect(_go_menu)
	retry_btn.pressed.connect(_retry)


func setup(result: Dictionary) -> void:
	var record_text := "NOVO RECORDE!" if result.get("is_record", false) else "Recorde: %d" % result.get("high_score", 0)
	var relic := str(result.get("relic", ""))
	var relic_line := ""
	if not relic.is_empty():
		relic_line = "\nRelíquia: %s" % Global.relic_title()
	stats.text = "Score: %d\n%s\nTempo: %s\nKills: %d  |  Wave: %d\nMoedas nesta run: +%d  |  Total: %d%s" % [
		result.get("score", 0),
		record_text,
		Global.format_time(result.get("time", 0.0)),
		result.get("kills", 0),
		result.get("wave", 0),
		result.get("run_coins", 0),
		result.get("coins", 0),
		relic_line,
	]


func play_fade(fade_in_duration: float = 1.5) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim, "modulate:a", 1.0, fade_in_duration)
	tween.tween_property(label, "modulate:a", 1.0, fade_in_duration).set_delay(0.35)
	tween.tween_property(stats, "modulate:a", 1.0, fade_in_duration).set_delay(0.55)
	tween.tween_property($Center/VBox/Buttons, "modulate:a", 1.0, fade_in_duration).set_delay(0.7)
	await tween.finished


func _go_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)


func _retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(ARENA)
