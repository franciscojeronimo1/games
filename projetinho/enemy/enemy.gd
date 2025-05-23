extends CharacterBody2D

@onready var state_machine = $StateMachine
@onready var anim = $AnimationPlayer
@onready var player_detector = $Area2D
@export var speed := 40
var player_in_range := false

func _ready():
	state_machine.init(self)
	player_detector.body_entered.connect(_on_player_entered)
	player_detector.body_exited.connect(_on_player_exited)

func _physics_process(delta):
	state_machine.state_update(delta)

func play_animation(name: String):
	anim.play(name)

func change_state(new_state: String):
	state_machine.change_state(new_state)

func _on_player_entered(body):
	if body.name == "Player":
		 player_in_range = true
		change_state("attack")

func _on_player_exited(body):
	if body.name == "Player":
		player_in_range = false
		change_state("walk")
