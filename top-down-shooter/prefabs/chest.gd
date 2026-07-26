extends Area2D

@export var heal_amount: int = 2
@export var bonus_xp: int = 3

var _opened := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	modulate = Color(1.0, 0.85, 0.2)


func _on_body_entered(body: Node2D) -> void:
	if _opened or not body.is_in_group("player"):
		return
	if body is Player:
		_opened = true
		await _open_chest(body as Player)
		queue_free()


func _open_chest(player: Player) -> void:
	# Baú NÃO abre tela de upgrade — só cura ou XP bônus
	if randf() < 0.55:
		player.hp = mini(player.hp + heal_amount, player.max_hp)
		Global.add_score(40)
	else:
		Global.add_score(60)
		await player.add_xp(bonus_xp)
