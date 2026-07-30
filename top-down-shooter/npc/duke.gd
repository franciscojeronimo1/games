extends CharacterBody2D
## Evento raro: Duke aparece, pausa a run e oferece um negócio estranho.

var upgrade_pick_scene = preload("res://ui/upgrade_pick.tscn")

@export var open_delay: float = 0.7
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	if anim:
		anim.play("idle")
	# Espera um frame pra estar na cena, depois abre o negócio
	await get_tree().create_timer(open_delay).timeout
	await _open_deal()
	queue_free()


func _open_deal() -> void:
	var player: Player = Global.player
	if player == null or not is_instance_valid(player) or player.is_dead:
		return

	# Não empilha com level-up / relíquia
	while player.is_choosing_upgrade and not player.is_dead:
		await get_tree().process_frame

	if player.is_dead:
		return

	var options := DukeDeals.roll_three()
	if options.is_empty():
		return

	player.is_choosing_upgrade = true
	get_tree().paused = true
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	process_mode = Node.PROCESS_MODE_ALWAYS

	var pick = upgrade_pick_scene.instantiate()
	get_tree().current_scene.add_child(pick)
	if pick.has_method("show_duke_portrait"):
		pick.show_duke_portrait()
	if pick.has_method("set_title"):
		pick.set_title("DUKE — \"Tenho um negócio pra você…\"")
	# Sprite no mundo fica atrás do dim — esconde pra não competir
	if anim:
		anim.visible = false
	var chosen_id: String = await pick.pick_upgrade(options)
	DukeDeals.apply(player, chosen_id)
	pick.queue_free()

	player.is_choosing_upgrade = false
	get_tree().paused = false
	player.process_mode = Node.PROCESS_MODE_INHERIT
	process_mode = Node.PROCESS_MODE_INHERIT
