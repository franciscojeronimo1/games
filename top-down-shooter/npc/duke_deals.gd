class_name DukeDeals

## Negócios estranhos do Duke — flavor > balance.

const POOL := [
	{
		"id": "power_pact",
		"title": "Pacto de Aço",
		"desc": "50 moedas → +2 de dano nesta run",
		"cost": 50,
		"weight": 6,
	},
	{
		"id": "all_or_nothing",
		"title": "Tudo ou Nada",
		"desc": "Aposta TODAS as moedas.\n50%: +4 dano\n50%: perde tudo",
		"cost": 0,
		"weight": 5,
	},
	{
		"id": "blood_purse",
		"title": "Bolsa de Sangue",
		"desc": "-1 vida máx. → +35 moedas",
		"cost": 0,
		"weight": 6,
	},
	{
		"id": "glass_edge",
		"title": "Lâmina de Vidro",
		"desc": "+3 dano, mas -2 vida máx.",
		"cost": 0,
		"weight": 5,
	},
	{
		"id": "pocket_heal",
		"title": "Poção Duvidosa",
		"desc": "25 moedas → cura 3 de vida",
		"cost": 25,
		"weight": 7,
	},
	{
		"id": "cursed_boots",
		"title": "Botas Amaldiçoadas",
		"desc": "+90 velocidade… e inimigos +20% rápidos",
		"cost": 0,
		"weight": 5,
	},
	{
		"id": "lucky_shot",
		"title": "Tiro da Sorte",
		"desc": "40 moedas → +1 dano e +150 score",
		"cost": 40,
		"weight": 6,
	},
	{
		"id": "poison_trail",
		"title": "Trilha Tóxica",
		"desc": "65 moedas → rastros venenosos ao andar\n(raro)",
		"cost": 65,
		"weight": 1,
	},
]

const REFUSE := {
	"id": "refuse",
	"title": "Recusar",
	"desc": "“Sem negócio hoje, Duke.”",
	"cost": 0,
}


static func roll_three() -> Array:
	var pool: Array = []
	for deal in POOL:
		var cost: int = int(deal.get("cost", 0))
		if deal["id"] == "all_or_nothing" and Global.coins <= 0:
			continue
		if cost > 0 and Global.coins < cost:
			continue
		if deal["id"] == "blood_purse" and Global.player != null and Global.player.max_hp <= 1:
			continue
		if deal["id"] == "poison_trail" and Global.player != null and Global.player.has_upgrade("foot_trail"):
			continue
		pool.append(deal)

	var picks: Array = []
	for _i in 2:
		if pool.is_empty():
			break
		var chosen: Dictionary = _weighted_pick(pool)
		picks.append(chosen)
		pool.erase(chosen)
	picks.append(REFUSE)
	return picks


static func _weighted_pick(pool: Array) -> Dictionary:
	var total := 0
	for item in pool:
		total += int(item.get("weight", 5))
	var roll := randi_range(1, maxi(1, total))
	var acc := 0
	for item in pool:
		acc += int(item.get("weight", 5))
		if roll <= acc:
			return item
	return pool[pool.size() - 1]


static func apply(player: Player, deal_id: String) -> void:
	match deal_id:
		"refuse":
			return
		"power_pact":
			if Global.spend_coins(50):
				player.bullet_damage += 2
		"all_or_nothing":
			var stake: int = Global.coins
			if stake <= 0:
				return
			if not Global.spend_coins(stake):
				return
			if randf() < 0.5:
				player.bullet_damage += 4
		"blood_purse":
			if player.max_hp <= 1:
				return
			player.max_hp -= 1
			player.hp = mini(player.hp, player.max_hp)
			Global.add_coins(35)
		"glass_edge":
			player.bullet_damage += 3
			player.max_hp = maxi(1, player.max_hp - 2)
			player.hp = mini(player.hp, player.max_hp)
		"pocket_heal":
			if Global.spend_coins(25):
				player.hp = mini(player.hp + 3, player.max_hp)
		"cursed_boots":
			player.move_speed += 90.0
			Global.enemy_speed_mult *= 1.2
		"lucky_shot":
			if Global.spend_coins(40):
				player.bullet_damage += 1
				Global.add_score(150)
		"poison_trail":
			if Global.spend_coins(65):
				player.has_foot_trail = true
