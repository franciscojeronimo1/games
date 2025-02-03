extends Node2D

@export var enemy_scene: PackedScene
@onready var spawn_point: Marker2D = $spawn_points
@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer
