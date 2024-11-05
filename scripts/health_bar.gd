extends ProgressBar
@onready var player: CharacterBody2D = $"../../Player"

func _ready() -> void:
	player.update_health.connect(on_update_health)
	player.death.connect(hide)
	max_value = player.MAX_HP
	value = player.state.health


func on_update_health(health: int) -> void:
	print("emitted")
	value = health
	
	
func _process(delta: float) -> void:
	pass
