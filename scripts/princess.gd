extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
signal is_saved()

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
class State:
	var has_curtsied = false
	
var state = State.new()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()


func _on_detect_player_area_2d_body_entered(body: Node2D) -> void:
	if state.has_curtsied:
		return
	animated_sprite_2d.play("curtsy")
	state.has_curtsied = true


func _on_animated_sprite_2d_animation_finished() -> void:
		animated_sprite_2d.play("idle")
		is_saved.emit()
