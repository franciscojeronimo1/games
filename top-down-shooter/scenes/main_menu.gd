extends Control

const ARENA_SCENE := "res://scenes/arena.tscn"

@onready var play_btn: Button = $MenuHitboxes/Play
@onready var options_btn: Button = $MenuHitboxes/Options
@onready var credits_btn: Button = $MenuHitboxes/Credits
@onready var exit_btn: Button = $MenuHitboxes/Exit
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var auto_check: CheckButton = $OptionsPanel/Margin/VBox/AutoMode
@onready var high_score_label: Label = $HighScore


func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	options_btn.pressed.connect(_on_options)
	credits_btn.pressed.connect(_on_credits)
	exit_btn.pressed.connect(_on_exit)
	$OptionsPanel/Margin/VBox/CloseOptions.pressed.connect(_close_panels)
	$CreditsPanel/Margin/VBox/CloseCredits.pressed.connect(_close_panels)

	auto_check.button_pressed = Global.prefer_auto_mode
	auto_check.toggled.connect(_on_auto_toggled)

	options_panel.visible = false
	credits_panel.visible = false
	high_score_label.text = "RECORDE  %d" % Global.high_score

	for btn in [play_btn, options_btn, credits_btn, exit_btn]:
		btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))


func _on_btn_hover(btn: Button, entered: bool) -> void:
	btn.modulate = Color(1.35, 1.25, 0.85) if entered else Color.WHITE


func _on_play() -> void:
	get_tree().change_scene_to_file(ARENA_SCENE)


func _on_options() -> void:
	credits_panel.visible = false
	options_panel.visible = true


func _on_credits() -> void:
	options_panel.visible = false
	credits_panel.visible = true


func _on_exit() -> void:
	get_tree().quit()


func _close_panels() -> void:
	options_panel.visible = false
	credits_panel.visible = false


func _on_auto_toggled(pressed: bool) -> void:
	Global.set_prefer_auto_mode(pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if options_panel.visible or credits_panel.visible:
			_close_panels()
			get_viewport().set_input_as_handled()
