extends Node

var player

var score: int = 0
var kills: int = 0
var survival_time: float = 0.0
var high_score: int = 0
var wave: int = 0

## Moedas permanentes (não zera entre runs) — shop futuro
var coins: int = 0
## Moedas ganhas nesta run (só pra mostrar no game over)
var run_coins: int = 0

var active_relic: String = ""
var enemy_speed_mult: float = 1.0
var enemy_hp_mult: float = 1.0
var kill_score_mult: float = 1.0
var xp_double_chance: float = 0.0
var prefer_auto_mode: bool = true

const SAVE_PATH := "user://save.cfg"


func _ready() -> void:
	_load_save()


func reset_run() -> void:
	score = 0
	kills = 0
	survival_time = 0.0
	wave = 0
	run_coins = 0
	active_relic = ""
	enemy_speed_mult = 1.0
	enemy_hp_mult = 1.0
	kill_score_mult = 1.0
	xp_double_chance = 0.0


func add_score(amount: int) -> void:
	score += amount


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	run_coins += amount
	_save_data()


func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if coins < amount:
		return false
	coins -= amount
	_save_data()
	return true


func register_kill(is_elite: bool = false) -> void:
	kills += 1
	var points := int(50.0 * kill_score_mult)
	if is_elite:
		points *= 3
	add_score(points)


func tick_survival(delta: float) -> void:
	survival_time += delta
	if int(survival_time) > int(survival_time - delta):
		add_score(1)


func finalize_run() -> Dictionary:
	var is_record := score > high_score
	if is_record:
		high_score = score
	_save_data()
	return {
		"score": score,
		"high_score": high_score,
		"is_record": is_record,
		"time": survival_time,
		"kills": kills,
		"wave": wave,
		"relic": active_relic,
		"coins": coins,
		"run_coins": run_coins,
	}


func format_time(seconds: float) -> String:
	var total := int(seconds)
	var m := total / 60
	var s := total % 60
	return "%02d:%02d" % [m, s]


func relic_title() -> String:
	if active_relic.is_empty():
		return "-"
	for relic in RelicDB.POOL:
		if relic["id"] == active_relic:
			return relic["title"]
	return active_relic


func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = int(cfg.get_value("score", "high", 0))
		prefer_auto_mode = bool(cfg.get_value("settings", "auto_mode", true))
		coins = int(cfg.get_value("economy", "coins", 0))


func _save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("score", "high", high_score)
	cfg.set_value("settings", "auto_mode", prefer_auto_mode)
	cfg.set_value("economy", "coins", coins)
	cfg.save(SAVE_PATH)


func set_prefer_auto_mode(enabled: bool) -> void:
	prefer_auto_mode = enabled
	_save_data()
