extends Node

var states = {}
var current_state: String
var enemy: CharacterBody2D = null



func init(e):
	enemy = e
	for child in get_children():
		states[child.name.to_lower()] = child
	change_state("idle")

func change_state(new_state: String):
	if not states.has(new_state):
		push_error("Estado não encontrado: %s" % new_state)
		return

	if current_state == new_state:
		return

	current_state = new_state
	states[current_state].enter(enemy)

func state_update(delta):
	if current_state and states.has(current_state):
		states[current_state].update(enemy, delta)
