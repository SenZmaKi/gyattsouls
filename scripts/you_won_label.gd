extends Label
@onready var princess: CharacterBody2D = $"../../Princess"
@onready var timer: Timer = $Timer
@onready var player: CharacterBody2D = $"../../Player"

var start_time = 0

func _ready() -> void:
	hide()
	start_time = Time.get_ticks_msec()
	princess.is_saved.connect(show_score)


func show_score() -> void:
	Engine.time_scale = 0.5
	player.disable()

	var end_time = Time.get_ticks_msec()
	var duration_ms = end_time - start_time
	var duration_sec = duration_ms / 1000
	var min = int(duration_sec / 60)   
	var sec = int(duration_sec % 60)   
	var enemies_killed = 0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.state.is_dead:
			enemies_killed += 1
	var score = (enemies_killed * 100) - int(duration_sec)
	if score < 0:
		score = 0
	text = "You saved the baddie!!!" + "\nEnemies killed: " + str(enemies_killed) + \
	"\nTime taken: " + str(min) + "m " + str(sec) + "s" + "\nScore: " + str(score)
	show()
	timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
