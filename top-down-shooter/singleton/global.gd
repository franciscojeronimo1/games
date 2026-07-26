extends Node

var player

var score: int = 0
var kills: int = 0
var survival_time: float = 0.0
var high_score: int = 0
var wave: int = 0

const SAVE_PATH := "user://save.cfg"


func _ready() -> void:
	_load_high_score()


func reset_run() -> void:
	score = 0
	kills = 0
	survival_time = 0.0
	wave = 0


func add_score(amount: int) -> void:
	score += amount


func register_kill() -> void:
	kills += 1
	add_score(50)


func tick_survival(delta: float) -> void:
	survival_time += delta
	# 1 ponto por segundo sobrevivido
	if int(survival_time) > int(survival_time - delta):
		add_score(1)


func finalize_run() -> Dictionary:
	var is_record := score > high_score
	if is_record:
		high_score = score
		_save_high_score()
	return {
		"score": score,
		"high_score": high_score,
		"is_record": is_record,
		"time": survival_time,
		"kills": kills,
		"wave": wave,
	}


func format_time(seconds: float) -> String:
	var total := int(seconds)
	var m := total / 60
	var s := total % 60
	return "%02d:%02d" % [m, s]


func _load_high_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = int(cfg.get_value("score", "high", 0))


func _save_high_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "high", high_score)
	cfg.save(SAVE_PATH)
