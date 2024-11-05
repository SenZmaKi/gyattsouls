extends Label
@onready var player: CharacterBody2D = $"../../Player"
@onready var timer: Timer = $Timer


func _ready() -> void:
	hide()
	player.death.connect(on_death)

func on_death() -> void:
	show()
	timer.start()
	

func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
