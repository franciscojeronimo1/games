extends Control

const ARENA_SCENE := "res://scenes/arena.tscn"

@onready var play_btn: Button = $MenuHitboxes/Play
@onready var options_btn: Button = $MenuHitboxes/Options
@onready var credits_btn: Button = $MenuHitboxes/Credits
@onready var exit_btn: Button = $MenuHitboxes/Exit
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var character_panel: PanelContainer = $CharacterPanel
@onready var auto_check: CheckButton = $OptionsPanel/Margin/VBox/AutoMode
@onready var high_score_label: Label = $HighScore
@onready var char_title: Label = $CharacterPanel/Margin/VBox/CharTitle
@onready var char_desc: Label = $CharacterPanel/Margin/VBox/CharDesc
@onready var archer_btn: Button = $CharacterPanel/Margin/VBox/Choices/ArcherBtn
@onready var wizard_btn: Button = $CharacterPanel/Margin/VBox/Choices/WizardBtn
@onready var start_btn: Button = $CharacterPanel/Margin/VBox/StartBtn
@onready var back_char_btn: Button = $CharacterPanel/Margin/VBox/BackBtn
@onready var archer_preview: TextureRect = $CharacterPanel/Margin/VBox/Choices/ArcherBtn/VBox/Preview
@onready var wizard_preview: TextureRect = $CharacterPanel/Margin/VBox/Choices/WizardBtn/VBox/Preview

@export var show_hitbox_debug: bool = true

var _debug_style: StyleBoxFlat
var _empty_style: StyleBoxEmpty
var _buttons: Array[Button] = []
var _pending_character: String = "archer"


func _ready() -> void:
	_buttons = [play_btn, options_btn, credits_btn, exit_btn]
	_empty_style = StyleBoxEmpty.new()
	_debug_style = StyleBoxFlat.new()
	_debug_style.bg_color = Color(0.2, 1.0, 0.35, 0.25)
	_debug_style.set_border_width_all(2)
	_debug_style.border_color = Color(0.4, 1.0, 0.5, 0.9)

	play_btn.pressed.connect(_on_play)
	options_btn.pressed.connect(_on_options)
	credits_btn.pressed.connect(_on_credits)
	exit_btn.pressed.connect(_on_exit)
	$OptionsPanel/Margin/VBox/CloseOptions.pressed.connect(_close_panels)
	$CreditsPanel/Margin/VBox/CloseCredits.pressed.connect(_close_panels)

	archer_btn.pressed.connect(_select_character.bind("archer"))
	wizard_btn.pressed.connect(_select_character.bind("wizard"))
	start_btn.pressed.connect(_on_start_run)
	back_char_btn.pressed.connect(_close_panels)

	auto_check.button_pressed = Global.prefer_auto_mode
	auto_check.toggled.connect(_on_auto_toggled)

	options_panel.visible = false
	credits_panel.visible = false
	character_panel.visible = false
	high_score_label.text = "RECORDE  %d    |    MOEDAS  %d" % [Global.high_score, Global.coins]

	_pending_character = Global.selected_character
	_setup_character_previews()
	_refresh_character_ui()

	for btn in _buttons:
		btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))

	_apply_debug_visuals()


func _setup_character_previews() -> void:
	# Primeiro frame do idle do mago (22x28 numa sheet 66x28)
	var mage_tex := load("res://assets/mago/mago-idle-Sheet.png") as Texture2D
	if mage_tex and wizard_preview:
		var atlas := AtlasTexture.new()
		atlas.atlas = mage_tex
		atlas.region = Rect2(0, 0, 22, 28)
		wizard_preview.texture = atlas

	var archer_tex := load("res://assets/archer/MiniArcherMan_green.png") as Texture2D
	if archer_tex and archer_preview:
		var atlas := AtlasTexture.new()
		atlas.atlas = archer_tex
		atlas.region = Rect2(0, 0, 32, 32)
		archer_preview.texture = atlas


func _apply_debug_visuals() -> void:
	for btn in _buttons:
		var style: StyleBox = _debug_style if show_hitbox_debug else _empty_style
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", style)


func _on_btn_hover(btn: Button, entered: bool) -> void:
	btn.modulate = Color(1.35, 1.25, 0.85) if entered else Color.WHITE


func _on_play() -> void:
	credits_panel.visible = false
	options_panel.visible = false
	_pending_character = Global.selected_character
	_refresh_character_ui()
	character_panel.visible = true


func _on_options() -> void:
	credits_panel.visible = false
	character_panel.visible = false
	options_panel.visible = true


func _on_credits() -> void:
	options_panel.visible = false
	character_panel.visible = false
	credits_panel.visible = true


func _on_exit() -> void:
	get_tree().quit()


func _close_panels() -> void:
	options_panel.visible = false
	credits_panel.visible = false
	character_panel.visible = false


func _select_character(character_id: String) -> void:
	_pending_character = character_id
	_refresh_character_ui()


func _refresh_character_ui() -> void:
	var data: Dictionary = Global.CHARACTERS.get(_pending_character, Global.CHARACTERS["archer"])
	char_title.text = str(data.get("title", "Herói"))
	char_desc.text = str(data.get("desc", ""))
	archer_btn.modulate = Color(1.35, 1.2, 0.7) if _pending_character == "archer" else Color.WHITE
	wizard_btn.modulate = Color(1.2, 0.95, 1.4) if _pending_character == "wizard" else Color.WHITE


func _on_start_run() -> void:
	Global.set_selected_character(_pending_character)
	get_tree().change_scene_to_file(ARENA_SCENE)


func _on_auto_toggled(pressed: bool) -> void:
	Global.set_prefer_auto_mode(pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			show_hitbox_debug = not show_hitbox_debug
			_apply_debug_visuals()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		if options_panel.visible or credits_panel.visible or character_panel.visible:
			_close_panels()
			get_viewport().set_input_as_handled()
