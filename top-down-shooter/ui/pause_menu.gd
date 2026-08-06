extends CanvasLayer

const MAIN_MENU := "res://scenes/main_menu.tscn"
const ARENA := "res://scenes/arena.tscn"

@onready var panel: PanelContainer = $Panel
@onready var title: Label = $Panel/VBox/Title
@onready var hint: Label = $Panel/VBox/Hint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	UiTheme.apply_panel(panel)
	UiTheme.apply_label(title, 44, UiTheme.TEXT_TITLE, true)
	UiTheme.apply_label(hint, 20, UiTheme.TEXT_MUTED, false)
	for btn_path in ["ResumeBtn", "RestartBtn", "MenuBtn"]:
		var btn: Button = $Panel/VBox.get_node(btn_path)
		UiTheme.apply_button(btn, 22)
	$Panel/VBox/ResumeBtn.pressed.connect(_on_resume)
	$Panel/VBox/RestartBtn.pressed.connect(_on_restart)
	$Panel/VBox/MenuBtn.pressed.connect(_on_menu)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if Global.player != null and is_instance_valid(Global.player):
		if Global.player.is_dead or Global.player.is_choosing_upgrade:
			return
	toggle()
	get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		_on_resume()
	else:
		_open()


func _open() -> void:
	visible = true
	get_tree().paused = true
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.94, 0.94)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_resume() -> void:
	visible = false
	get_tree().paused = false


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(ARENA)


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
