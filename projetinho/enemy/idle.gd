extends Node

func enter(enemy):
	enemy.velocity = Vector2.ZERO
	enemy.play_animation("idle")

func update(enemy, delta):
	# Transição automática para walk depois de 2 segundos
	await get_tree().create_timer(2).timeout
	if not enemy.player_in_range:
		enemy.change_state("walk")
