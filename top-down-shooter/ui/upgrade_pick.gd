extends CanvasLayer

signal upgrade_chosen(upgrade_id: String)

@onready var title: Label = $Panel/VBox/Title
@onready var subtitle: Label = $Panel/VBox/Subtitle
@onready var portrait_slot: Control = $Panel/VBox/PortraitSlot
@onready var portrait: AnimatedSprite2D = $Panel/VBox/PortraitSlot/Portrait
@onready var panel: PanelContainer = $Panel
@onready var options_row: HBoxContainer = $Panel/VBox/Options
@onready var dim: ColorRect = $Dim

var buttons: Array[Button] = []
var _card_titles: Array[Label] = []
var _card_descs: Array[Label] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if portrait_slot:
		portrait_slot.visible = false

	UiTheme.apply_panel(panel)
	UiTheme.apply_label(title, 46, UiTheme.TEXT_TITLE, true)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	UiTheme.apply_label(subtitle, 22, UiTheme.TEXT_MUTED, false)

	buttons = [
		$Panel/VBox/Options/Card1/VBox/Button,
		$Panel/VBox/Options/Card2/VBox/Button,
		$Panel/VBox/Options/Card3/VBox/Button,
	]
	_card_titles = [
		$Panel/VBox/Options/Card1/VBox/Title,
		$Panel/VBox/Options/Card2/VBox/Title,
		$Panel/VBox/Options/Card3/VBox/Title,
	]
	_card_descs = [
		$Panel/VBox/Options/Card1/VBox/Desc,
		$Panel/VBox/Options/Card2/VBox/Desc,
		$Panel/VBox/Options/Card3/VBox/Desc,
	]

	for i in buttons.size():
		UiTheme.apply_button(buttons[i], 22)
		buttons[i].custom_minimum_size.y = 52
		buttons[i].pressed.connect(_on_option_pressed.bind(i))
		UiTheme.apply_label(_card_titles[i], 30, UiTheme.TEXT_TITLE, true)
		UiTheme.apply_label(_card_descs[i], 22, UiTheme.TEXT_BODY, false)
		var card: PanelContainer = options_row.get_child(i)
		UiTheme.apply_panel(card)


func pick_upgrade(options: Array) -> String:
	visible = true
	_center_portrait()
	_play_open_anim()

	for i in buttons.size():
		var card: Control = options_row.get_child(i)
		if i < options.size():
			card.visible = true
			buttons[i].visible = true
			_card_titles[i].text = str(options[i].get("title", ""))
			_card_descs[i].text = str(options[i].get("desc", ""))
			buttons[i].set_meta("upgrade_id", options[i]["id"])
			buttons[i].text = "ESCOLHER"
		else:
			card.visible = false

	var chosen: String = await upgrade_chosen
	visible = false
	if portrait_slot:
		portrait_slot.visible = false
	# Restaura tamanho padrão do painel (level-up)
	panel.offset_left = -480.0
	panel.offset_right = 480.0
	panel.offset_top = -280.0
	panel.offset_bottom = 280.0
	return chosen


func set_title(text: String) -> void:
	if not is_node_ready():
		await ready
	title.text = text
	if text.begins_with("DUKE"):
		subtitle.text = "Escolha com cuidado… ou recuse."
	elif text.begins_with("RELÍQUIA"):
		subtitle.text = "Essa escolha vale a run inteira."
	else:
		subtitle.text = "Escolha 1 poder para continuar."


func show_duke_portrait() -> void:
	if not is_node_ready():
		await ready
	portrait_slot.visible = true
	panel.offset_top = -340.0
	panel.offset_bottom = 260.0
	if portrait and portrait.sprite_frames and portrait.sprite_frames.has_animation("idle"):
		portrait.play("idle")
	_center_portrait()


func _center_portrait() -> void:
	if portrait == null or portrait_slot == null or not portrait_slot.visible:
		return
	var slot_w: float = maxf(portrait_slot.size.x, panel.offset_right - panel.offset_left)
	portrait.position = Vector2(slot_w * 0.5, 95.0)


func _play_open_anim() -> void:
	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim, "modulate:a", 1.0, 0.18)
	tween.tween_property(panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_option_pressed(index: int) -> void:
	var button := buttons[index]
	if button.has_meta("upgrade_id"):
		upgrade_chosen.emit(str(button.get_meta("upgrade_id")))
