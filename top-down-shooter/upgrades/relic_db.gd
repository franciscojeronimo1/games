class_name RelicDB

const POOL := [
	{
		"id": "glass",
		"title": "Canhão de Vidro",
		"desc": "Só 3 de vida, mas dano dobrado",
	},
	{
		"id": "blood_rush",
		"title": "Fúria Sangrenta",
		"desc": "Inimigos +35% rápidos, orbs de XP valem o dobro (50%)",
	},
	{
		"id": "bounty",
		"title": "Caçador de Recompensas",
		"desc": "Inimigos +25% HP, kills valem muito mais",
	},
	{
		"id": "swift",
		"title": "Vento Ágil",
		"desc": "+80 velocidade, dash com CD menor",
	},
	{
		"id": "fortress",
		"title": "Fortaleza",
		"desc": "+3 vida, inimigos um pouco mais lentos",
	},
]


static func roll_three() -> Array:
	var options := POOL.duplicate()
	options.shuffle()
	return options.slice(0, mini(3, options.size()))


static func apply(player: Player, relic_id: String) -> void:
	Global.active_relic = relic_id
	match relic_id:
		"glass":
			player.max_hp = 3
			player.hp = 3
			player.bullet_damage = maxi(player.bullet_damage * 2, 2)
		"blood_rush":
			Global.enemy_speed_mult = 1.35
			Global.xp_double_chance = 0.5
		"bounty":
			Global.enemy_hp_mult = 1.25
			Global.kill_score_mult = 2.5
		"swift":
			player.move_speed += 80.0
			player.dash_cooldown = maxf(0.45, player.dash_cooldown * 0.65)
		"fortress":
			player.max_hp += 3
			player.hp = player.max_hp
			Global.enemy_speed_mult = 0.85
