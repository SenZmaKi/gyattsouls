extends CharacterBody2D

@onready var turn_area_2d: Area2D = $TurnArea2D
@onready var turn_collision_shape_2d: CollisionShape2D = $TurnArea2D/CollisionShape2D
@onready var can_hit_area_2d: Area2D = $CanHitArea2D
@onready var can_hit_collision_shape_2d: CollisionShape2D = $CanHitArea2D/CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var action_timer: Timer = $ActionTimer
@onready var left_detect_player_area_2d: Area2D = $LeftDetectPlayerArea2D
@onready var right_detect_player_area_2d: Area2D = $RightDetectPlayerArea2D
@onready var right_detect_player_collision_shape_2d: CollisionShape2D = $RightDetectPlayerArea2D/RightDetectPlayerCollisionShape2D
@onready var left_detect_player_collision_shape_2d: CollisionShape2D = $LeftDetectPlayerArea2D/LeftDetectPlayerCollisionShape2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimatedSprite2D/AnimationPlayer
@onready var health_bar: ProgressBar = $"HealthBar"

@export var SPEED = 3000.0
@export var SEE_PLAYER_INCREASE_SPEED_RATE = 1.25
@export var JUMP_VELOCITY = -400.0
@export var DAMAGE = 1
@export var MAX_HP = 5
@export var action_animations: Array[String] = ["attack", "block", "idle"]
@export var is_flyer = false

class State:
	var direction = 1
	var can_hit_player = false
	var health = 0
	var is_hurt = false
	var is_dead = false
	var action = ""
	

var state = State.new()
var rng = RandomNumberGenerator.new()

func disable() -> void:
	can_hit_collision_shape_2d.disabled = true
	turn_collision_shape_2d.disabled = true
	left_detect_player_collision_shape_2d.disabled = true
	right_detect_player_collision_shape_2d.disabled = true
	set_collision_layer_value(4, false)
	# set_collision_mask_value(2, false)
	# collision_shape_2d.disabled = true
	health_bar.hide()
	
func hurt(damage: int) -> void:
	if state.is_dead or state.action == "block":
		return
	var new_health = state.health - damage
	if new_health <= 0:
		state.health = 0
	else:
		state.health = new_health
	state.is_hurt = true
	action_timer.timeout.emit()
	animated_sprite_2d.play("hurt")
	print("health: ", state.health)
	health_bar.value = state.health
	
	
func _ready() -> void:
	add_to_group("enemy")
	animated_sprite_2d.play("walk")
	state.health = MAX_HP
	health_bar.max_value = MAX_HP
	health_bar.value = state.health
	
func _physics_process(delta: float) -> void:
	state_manager(delta)
	
func state_manager(delta: float) -> void:
	if not is_on_floor() and (not is_flyer or state.is_dead):
		if is_flyer:
			move_and_slide()
			print("falling flyer")
		velocity += get_gravity() * delta
	if state.is_dead or state.action or state.is_hurt:
		return
	check_can_hit_area()
	var should_turn = turn_area_2d.get_overlapping_areas() or turn_area_2d.get_overlapping_bodies()
	var speed = SPEED
	if left_detect_player_area_2d.get_overlapping_bodies():
		should_turn = state.direction == 1 
		speed = SPEED * SEE_PLAYER_INCREASE_SPEED_RATE
	elif right_detect_player_area_2d.get_overlapping_bodies():
		should_turn = state.direction == -1
		speed = SPEED * SEE_PLAYER_INCREASE_SPEED_RATE
	if should_turn:
		scale.x *= -1
		state.direction *= -1
		var left_buffer = left_detect_player_area_2d
		left_detect_player_area_2d = right_detect_player_area_2d
		right_detect_player_area_2d = left_buffer
	
	if state.can_hit_player and not (state.action or state.is_hurt):
		var num = rng.randi_range(0, len(action_animations) - 1)
		action_timer.start(rng.randf_range(0.5, 1.5))
		for action_num in range(len(action_animations)):
			if num == action_num:
				var action = action_animations[action_num]
				if action == "attack":
					animation_player.play(action)
				else:
					animated_sprite_2d.play(action)
				state.action = action
				return

	velocity.x = state.direction * speed * delta
	move_and_slide()
	
func check_can_hit_area() -> void:
	var bodies = can_hit_area_2d.get_overlapping_bodies()
	if bodies:
		state.can_hit_player = true
		return 
	state.can_hit_player = false
	state.action = ""
	state.is_hurt = false
	animated_sprite_2d.play("walk")

func _on_action_timer_timeout() -> void:
	state.action = ""


func _on_animated_sprite_2d_animation_finished() -> void:
	if state.is_hurt:
		print("is hurt and finished")
		state.is_hurt = false
		if state.health <= 0:
			state.is_dead = true
			print("dead enemy")
			disable()
			animated_sprite_2d.play("death")
		else:
			animated_sprite_2d.play("idle")
			action_timer.start(0.5)
			
	if state.is_dead:
		animated_sprite_2d.play("dead")
	
func _on_hurt_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	print("damaging player")
	if state.action == "attack":
		body.hurt(DAMAGE)
		
