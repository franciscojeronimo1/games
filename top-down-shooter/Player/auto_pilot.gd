class_name AutoPilot
extends RefCounted

## Decide movimento, mira e skills do player em modo automático.

const PREFERRED_RANGE := 260.0
const MIN_SAFE_DIST := 200.0
const DANGER_RADIUS := 170.0
const PANIC_RADIUS := 120.0
const FLEE_BLEND_RADIUS := 240.0


static func think(player: Player) -> Dictionary:
	var result := {
		"move": Vector2.ZERO,
		"aim": Vector2.RIGHT,
		"shoot": false,
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

	for e in enemies:
		var d: float = player.global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e
		if d <= DANGER_RADIUS:
			near_count += 1

	var target := _pick_target(player, enemies)
	if target:
		result["aim"] = (target.global_position - player.global_position).normalized()
	elif closest:
		result["aim"] = (closest.global_position - player.global_position).normalized()
	else:
		result["aim"] = Vector2.RIGHT if not player.anim.flip_h else Vector2.LEFT

	# Fuga quando vários inimigos ou muito perto
	var flee_vec: Vector2 = _flee_vector(player, enemies)
	if flee_vec != Vector2.ZERO and (closest_dist < DANGER_RADIUS or near_count >= 2):
		result["move"] = flee_vec
		if closest_dist < PANIC_RADIUS or near_count >= 3:
			result["dash"] = true
			result["dash_dir"] = flee_vec
	elif target:
		result["move"] = _kite_move(player, target)
	elif closest and closest_dist < MIN_SAFE_DIST:
		var away: Vector2 = (player.global_position - closest.global_position).normalized()
		result["move"] = away if away != Vector2.ZERO else Vector2.UP
	else:
		var loot := _find_nearest_loot(player)
		if loot and (closest == null or closest_dist > DANGER_RADIUS + 40.0):
			var to_loot: Vector2 = loot.global_position - player.global_position
			result["move"] = to_loot.normalized()
			if closest:
				result["aim"] = (closest.global_position - player.global_position).normalized()
			else:
				result["aim"] = result["move"]

	# Atira se tem alvo e está na distância de combate (não só no desespero colado)
	if target and closest_dist < PREFERRED_RANGE + 120.0:
		result["shoot"] = true
	elif closest and closest_dist < PREFERRED_RANGE + 80.0:
		result["shoot"] = true

	if player.has_bomb and near_count >= 3:
		result["use_e"] = true

	if player.has_arrow_rain and target:
		var cluster := _count_near(target.global_position, enemies, 140.0)
		if cluster >= 3 or target.is_in_group("boss") or target.is_in_group("elites"):
			result["use_q"] = true
			result["q_center"] = target.global_position

	return result


static func _kite_move(player: Player, target: Node2D) -> Vector2:
	var to_target: Vector2 = target.global_position - player.global_position
	var dist: float = to_target.length()
	if dist < 0.001:
		return Vector2.RIGHT

	var dir: Vector2 = to_target / dist

	# Muito perto: só recua
	if dist < MIN_SAFE_DIST:
		return -dir

	# Zona ideal: orbita de lado (kite) sem se aproximar
	if dist <= PREFERRED_RANGE + 50.0:
		var strafe: Vector2 = dir.orthogonal()
		# Se ainda está um pouco perto do ideal, mistura recuo com strafe
		if dist < PREFERRED_RANGE - 20.0:
			return (-dir * 0.65 + strafe * 0.35).normalized()
		return strafe

	# Longe demais: aproxima só até a distância preferida, sem colar
	return dir * 0.55


static func _flee_vector(player: Player, enemies: Array) -> Vector2:
	var flee := Vector2.ZERO
	for e in enemies:
		var d: float = player.global_position.distance_to(e.global_position)
		if d > FLEE_BLEND_RADIUS or d < 1.0:
			continue
		var away: Vector2 = (player.global_position - e.global_position).normalized()
		var weight: float = 1.0 - (d / FLEE_BLEND_RADIUS)
		flee += away * weight

	if flee.length() < 0.01:
		return Vector2.ZERO
	return flee.normalized()


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
		# Prefere alvos que dá pra atirar sem encostar
		var score := 1000.0 - absf(d - PREFERRED_RANGE)
		if d < MIN_SAFE_DIST:
			score -= 400.0
		if e is Boss or e.is_in_group("boss"):
			score += 600.0
		elif e.is_in_group("elites"):
			score += 250.0
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
	# Só baús agora — XP vem automático na kill
	for node in player.get_tree().get_nodes_in_group("chest"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var d: float = player.global_position.distance_to(node.global_position)
		if d < best_d:
			best_d = d
			best = node
	return best
