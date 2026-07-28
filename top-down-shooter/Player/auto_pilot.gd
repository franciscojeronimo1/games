class_name AutoPilot
extends RefCounted

## Decide movimento, mira e skills do player em modo automático.


static func think(player: Player) -> Dictionary:
	var result := {
		"move": Vector2.ZERO,
		"aim": Vector2.RIGHT,
		"dash": false,
		"dash_dir": Vector2.ZERO,
		"use_q": false,
		"use_e": false,
		"q_center": Vector2.ZERO,
	}

	var enemies := _alive_enemies(player)
	var closest: Node2D = null
	var closest_dist := INF
	var near_count := 0
	var danger_radius := 110.0
	var fight_radius := 220.0

	for e in enemies:
		var d: float = player.global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e
		if d <= danger_radius:
			near_count += 1

	# Alvo: boss > elite > mais perto
	var target := _pick_target(player, enemies)
	if target:
		result["aim"] = (target.global_position - player.global_position).normalized()
	elif closest:
		result["aim"] = (closest.global_position - player.global_position).normalized()
	else:
		result["aim"] = Vector2.RIGHT if not player.anim.flip_h else Vector2.LEFT

	# Perigo: afasta e dash
	if closest and closest_dist < danger_radius:
		var away: Vector2 = (player.global_position - closest.global_position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT.rotated(randf() * TAU)
		result["move"] = away
		if closest_dist < 80.0 or near_count >= 3:
			result["dash"] = true
			result["dash_dir"] = away
	elif target:
		var to_target: Vector2 = target.global_position - player.global_position
		var dist: float = to_target.length()
		var preferred := 160.0
		if dist > preferred + 40.0:
			result["move"] = to_target.normalized()
		elif dist < preferred - 30.0:
			result["move"] = -to_target.normalized()
		else:
			# Strafe pra não ficar parado
			result["move"] = to_target.normalized().orthogonal()
	else:
		# Sem inimigo: busca XP / baú
		var loot := _find_nearest_loot(player)
		if loot:
			result["move"] = (loot.global_position - player.global_position).normalized()
			result["aim"] = result["move"]

	# Skills
	if player.has_bomb and near_count >= 3:
		result["use_e"] = true

	if player.has_arrow_rain and target:
		var cluster := _count_near(target.global_position, enemies, 140.0)
		if cluster >= 3 or target.is_in_group("boss") or target.is_in_group("elites"):
			result["use_q"] = true
			result["q_center"] = target.global_position

	return result


static func _alive_enemies(player: Player) -> Array:
	var list: Array = []
	for node in player.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node is Node2D:
			list.append(node)
	return list


static func _pick_target(player: Player, enemies: Array) -> Node2D:
	var best: Node2D = null
	var best_score := -INF
	for e in enemies:
		var d: float = player.global_position.distance_to(e.global_position)
		var score := 1000.0 - d
		if e is Boss or e.is_in_group("boss"):
			score += 800.0
		elif e.is_in_group("elites"):
			score += 350.0
		if score > best_score:
			best_score = score
			best = e
	return best


static func _count_near(origin: Vector2, enemies: Array, radius: float) -> int:
	var n := 0
	for e in enemies:
		if origin.distance_to(e.global_position) <= radius:
			n += 1
	return n


static func _find_nearest_loot(player: Player) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for group_name in ["xpdropInicial", "chest"]:
		for node in player.get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node) or not (node is Node2D):
				continue
			var d: float = player.global_position.distance_to(node.global_position)
			if d < best_d:
				best_d = d
				best = node
	return best
