extends CanvasLayer

signal upgrade_chosen(upgrade_id: String)

@onready var title: Label = $Panel/VBox/Title
var buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	buttons = [
		$Panel/VBox/Options/Option1,
		$Panel/VBox/Options/Option2,
		$Panel/VBox/Options/Option3,
	]
	for i in buttons.size():
		buttons[i].pressed.connect(_on_option_pressed.bind(i))


func pick_upgrade(options: Array) -> String:
	visible = true
	for i in buttons.size():
		if i < options.size():
			buttons[i].visible = true
			buttons[i].text = "%s\n%s" % [options[i]["title"], options[i]["desc"]]
			buttons[i].set_meta("upgrade_id", options[i]["id"])
		else:
			buttons[i].visible = false

	var chosen: String = await upgrade_chosen
	visible = false
	return chosen


func _on_option_pressed(index: int) -> void:
	var button := buttons[index]
	if button.has_meta("upgrade_id"):
		upgrade_chosen.emit(str(button.get_meta("upgrade_id")))
