extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine = animation_tree['parameters/playback']

const melee_attacks = ['attack_1', "attack_2", "attack_3"]
const range_attacks = ["jump_up", 'throw']

func _ready():
	state_machine.travel("attack_1")

func melee_attack():
	state_machine.travel(melee_attacks.pick_random())

func range_attck():
	state_machine.travel(range_attacks.pick_random())
