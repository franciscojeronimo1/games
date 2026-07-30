extends CanvasLayer

signal upgrade_chosen(upgrade_id: String)

@onready var title: Label = $Panel/VBox/Title
@onready var portrait_slot: Control = $Panel/VBox/PortraitSlot
@onready var portrait: AnimatedSprite2D = $Panel/VBox/PortraitSlot/Portrait
@onready var panel: PanelContainer = $Panel
var buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if portrait_slot:
		portrait_slot.visible = false
	buttons = [
		$Panel/VBox/Options/Option1,
		$Panel/VBox/Options/Option2,
		$Panel/VBox/Options/Option3,
	]
	for i in buttons.size():
		buttons[i].pressed.connect(_on_option_pressed.bind(i))


func pick_upgrade(options: Array) -> String:
	visible = true
	_center_portrait()
	for i in buttons.size():
		if i < options.size():
			buttons[i].visible = true
			buttons[i].text = "%s\n%s" % [options[i]["title"], options[i]["desc"]]
			buttons[i].set_meta("upgrade_id", options[i]["id"])
		else:
			buttons[i].visible = false

	var chosen: String = await upgrade_chosen
	visible = false
	if portrait_slot:
		portrait_slot.visible = false
	return chosen


func set_title(text: String) -> void:
	if title:
		title.text = text
	else:
		await ready
		title.text = text


## Mostra o Duke animado acima do título (usado no evento dele).
func show_duke_portrait() -> void:
	if not is_node_ready():
		await ready
	portrait_slot.visible = true
	# Painel mais alto pra caber o personagem
	panel.offset_top = -320.0
	panel.offset_bottom = 220.0
	if portrait and portrait.sprite_frames and portrait.sprite_frames.has_animation("idle"):
		portrait.play("idle")
	_center_portrait()


func _center_portrait() -> void:
	if portrait == null or portrait_slot == null or not portrait_slot.visible:
		return
	# Largura fixa do painel (720); não depende de layout sob pause
	var slot_w: float = maxf(portrait_slot.size.x, panel.offset_right - panel.offset_left)
	portrait.position = Vector2(slot_w * 0.5, 95.0)


func _on_option_pressed(index: int) -> void:
	var button := buttons[index]
	if button.has_meta("upgrade_id"):
		upgrade_chosen.emit(str(button.get_meta("upgrade_id")))
