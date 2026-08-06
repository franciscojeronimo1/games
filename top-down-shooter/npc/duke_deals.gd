class_name DukeDeals

## Negócios estranhos do Duke — preços sobem a cada 20 níveis.

const POOL := [
	{
		"id": "power_pact",
		"title": "Pacto de Aço",
		"base_cost": 50,
		"weight": 6,
	},
	{
		"id": "all_or_nothing",
		"title": "Tudo ou Nada",
		"base_cost": 0,
		"weight": 5,
	},
	{
		"id": "blood_purse",
		"title": "Bolsa de Sangue",
		"base_cost": 0,
		"weight": 6,
	},
	{
		"id": "glass_edge",
		"title": "Lâmina de Vidro",
		"base_cost": 0,
		"weight": 5,
	},
	{
		"id": "pocket_heal",
		"title": "Poção Duvidosa",
		"base_cost": 25,
		"weight": 7,
	},
	{
		"id": "cursed_boots",
		"title": "Botas Amaldiçoadas",
		"base_cost": 0,
		"weight": 5,
	},
	{
		"id": "lucky_shot",
		"title": "Tiro da Sorte",
		"base_cost": 40,
		"weight": 6,
	},
	{
		"id": "poison_trail",
		"title": "Trilha Tóxica",
		"base_cost": 65,
		"weight": 1,
	},
	{
		"id": "fire_arrow",
		"title": "Ataque de Fogo",
		"base_cost": 55,
		"weight": 2,
	},
	{
		"id": "ice_arrow",
		"title": "Ataque de Gelo",
		"base_cost": 55,
		"weight": 2,
	},
	{
		"id": "fire_fuel",
		"title": "Óleo do Duke",
		"base_cost": 30,
		"weight": 3,
	},
]

const REFUSE := {
	"id": "refuse",
	"title": "Recusar",
	"desc": "“Sem negócio hoje, Duke.”",
	"cost": 0,
}


static func _player_lvl() -> int:
	if Global.player != null and is_instance_valid(Global.player):
		return maxi(1, int(Global.player.lvl))
	return maxi(1, Global.wave)


## A cada 20 lvls o preço sobe 50% (lvl 20 = 1.5x, 40 = 2x, 60 = 2.5x…)
static func price_mult() -> float:
	var milestones := maxi(0, int(_player_lvl() / 20))
	return 1.0 + float(milestones) * 0.5


static func scaled_cost(base_cost: int) -> int:
	if base_cost <= 0:
		return 0
	return maxi(base_cost, int(round(float(base_cost) * price_mult())))


static func scaled_coin_reward(base_reward: int) -> int:
	if base_reward <= 0:
		return 0
	return maxi(base_reward, int(round(float(base_reward) * price_mult())))


static func _base_cost_of(deal_id: String) -> int:
	for deal in POOL:
		if deal["id"] == deal_id:
			return int(deal.get("base_cost", 0))
	return 0


static func _build_deal(deal: Dictionary) -> Dictionary:
	var out := deal.duplicate()
	var cost := scaled_cost(int(deal.get("base_cost", 0)))
	var cid := SkillNames.char_id()
	out["cost"] = cost
	out["title"] = SkillNames.localize_duke_title(str(deal["id"]), str(deal.get("title", "")), cid)
	out["desc"] = _desc_for(str(deal["id"]), cost, cid)
	return out


static func _desc_for(deal_id: String, cost: int, character_id: String = "archer") -> String:
	var is_wizard := character_id == "wizard"
	match deal_id:
		"power_pact":
			return "%d moedas → +2 de dano nesta run" % cost
		"all_or_nothing":
			return "Aposta TODAS as moedas.\n50%: +4 dano\n50%: perde tudo"
		"blood_purse":
			return "-1 vida máx. → +%d moedas" % scaled_coin_reward(35)
		"glass_edge":
			return "+3 dano, mas -2 vida máx."
		"pocket_heal":
			return "%d moedas → cura 3 de vida" % cost
		"cursed_boots":
			return "+90 velocidade… e inimigos +20% rápidos"
		"lucky_shot":
			if is_wizard:
				return "%d moedas → +1 dano e +150 score" % cost
			return "%d moedas → +1 dano e +150 score" % cost
		"poison_trail":
			if is_wizard:
				return "%d moedas → círculo venenoso ao andar\n(raro)" % cost
			return "%d moedas → rastros venenosos ao andar\n(raro)" % cost
		"fire_arrow":
			if is_wizard:
				return "%d moedas → bola de fogo que queima\n(raro)" % cost
			return "%d moedas → flechas que queimam\n(raro)" % cost
		"ice_arrow":
			if is_wizard:
				return "%d moedas → bola de gelo (freia área)\n(raro)" % cost
			return "%d moedas → flechas de gelo (freia área)\n(raro)" % cost
		"fire_fuel":
			if is_wizard:
				return "%d moedas → +1 dano e +1s de queima\n(precisa bola de fogo)" % cost
			return "%d moedas → +1 dano e +1s de queima\n(precisa ataque de fogo)" % cost
		_:
			return ""


static func roll_three() -> Array:
	var pool: Array = []
	for deal in POOL:
		var built := _build_deal(deal)
		var cost: int = int(built.get("cost", 0))
		if deal["id"] == "all_or_nothing" and Global.coins <= 0:
			continue
		if cost > 0 and Global.coins < cost:
			continue
		if deal["id"] == "blood_purse" and Global.player != null and Global.player.max_hp <= 1:
			continue
		if deal["id"] == "poison_trail" and Global.player != null and Global.player.has_upgrade("foot_trail"):
			continue
		if deal["id"] == "fire_arrow" and Global.player != null and Global.player.arrow_element != "normal":
			continue
		if deal["id"] == "ice_arrow" and Global.player != null and Global.player.arrow_element != "normal":
			continue
		if deal["id"] == "fire_fuel" and (Global.player == null or Global.player.arrow_element != "fire"):
			continue
		pool.append(built)

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
	var cost := scaled_cost(_base_cost_of(deal_id))
	match deal_id:
		"refuse":
			return
		"power_pact":
			if Global.spend_coins(cost):
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
			Global.add_coins(scaled_coin_reward(35))
		"glass_edge":
			player.bullet_damage += 3
			player.max_hp = maxi(1, player.max_hp - 2)
			player.hp = mini(player.hp, player.max_hp)
		"pocket_heal":
			if Global.spend_coins(cost):
				player.hp = mini(player.hp + 3, player.max_hp)
		"cursed_boots":
			player.move_speed += 90.0
			Global.enemy_speed_mult *= 1.2
		"lucky_shot":
			if Global.spend_coins(cost):
				player.bullet_damage += 1
				Global.add_score(150)
		"poison_trail":
			if Global.spend_coins(cost):
				player.has_foot_trail = true
		"fire_arrow":
			if Global.spend_coins(cost):
				player.arrow_element = "fire"
		"ice_arrow":
			if Global.spend_coins(cost):
				player.arrow_element = "ice"
		"fire_fuel":
			if player.arrow_element == "fire" and Global.spend_coins(cost):
				player.burn_damage += 1
				player.burn_duration += 1.0
