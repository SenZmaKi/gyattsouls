extends CharacterBody2D


const RUN_SPEED = 7000.0
const ROLL_SPEED = 5000.0
const JUMP_VELOCITY = -325.0
const DAMAGE = 1
const MAX_HP = 10
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var standing_collision_shape_2d: CollisionShape2D = $StandingCollisionShape2D
@onready var crouching_collision_shape_2d: CollisionShape2D = $CrouchingCollisionShape2D
@onready var uncrouch_area_2d: Area2D = $UncrouchArea2D
@onready var uncrouch_collision_shape_2d: CollisionShape2D = $UncrouchArea2D/CollisionShape2D
@onready var sword_hit_collision_shape_2d: CollisionShape2D = $SwordHitArea2D/CollisionShape2D
@onready var sword_hit_area_2d: Area2D = $SwordHitArea2D
@onready var animation_player: AnimationPlayer = $AnimatedSprite2D/AnimationPlayer
signal update_health(health: int)
signal death()

func _ready() -> void:
	uncrouch_collision_shape_2d.disabled = true

func _physics_process(delta: float) -> void:
	state_manager(delta)
	

class State:
	var is_rolling = false
	var is_crouching = false
	var is_crouch_transitioning = false
	var is_facing_right = true
	var is_attacking = false
	var was_attack_1 = false
	var is_hurt = false
	var health = MAX_HP
	var is_dead = false
	var is_disabled = false
	

var state = State.new()

func hurt(damage: int) -> void:
	print("got hurt")	
	if state.is_rolling or state.is_dead:
		return
	state.is_hurt = true
	animation_player.play("flash")
	var new_health = state.health - damage
	if new_health < 0:
		state.health = 0
	else:
		state.health = new_health
	update_health.emit(state.health)

	
func disable() -> void:
	if not state.is_dead:
		animated_sprite_2d.play("idle")
	state.is_disabled = true
	standing_collision_shape_2d.disabled = true
	crouching_collision_shape_2d.disabled = true
	uncrouch_collision_shape_2d.disabled = true
	sword_hit_collision_shape_2d.disabled = true	
	set_collision_layer_value(2, false)
	
func can_uncrouch() -> bool:
	# <= 1 since one of the bodies is CharacterBody2Da
	var can = not (uncrouch_area_2d.get_overlapping_bodies() or uncrouch_area_2d.get_overlapping_areas())
	return can

	
func state_manager(delta: float) -> void:
	crouching_collision_shape_2d.disabled = true
	standing_collision_shape_2d.disabled = false
	

	if not is_on_floor():
		velocity += get_gravity() * delta
	if state.is_crouch_transitioning or state.is_attacking or state.is_dead or state.is_disabled:
			return
			
	if state.is_rolling or state.is_crouching:
		crouching_collision_shape_2d.disabled = false
		standing_collision_shape_2d.disabled = true
		
		
	if state.is_rolling:
		crouching_collision_shape_2d.disabled = false
		standing_collision_shape_2d.disabled = true
		var direction = 1 if state.is_facing_right else -1
		velocity.x = direction * ROLL_SPEED * delta
		move_and_slide()
		return
	
	if is_on_floor() and can_uncrouch():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
		if Input.is_action_just_pressed("crouch"):
			state.is_crouch_transitioning = true
			if state.is_crouching:
				animated_sprite_2d.play_backwards("crouch_transition")
			else:
				animated_sprite_2d.play("crouch_transition")
			return
		if Input.is_action_just_pressed("attack"):
			state.is_attacking = true
			if state.was_attack_1:
				animation_player.play("attack_2")
			else:
				animation_player.play("attack_1")
			return
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * RUN_SPEED * delta

	if direction != 0:
		if state.is_facing_right and direction == -1:
			state.is_facing_right = false
			scale.x *= -1
		elif not state.is_facing_right and direction == 1:
			state.is_facing_right = true
			scale.x *= -1
	if is_on_floor():
		if Input.is_action_just_pressed("roll"):
			set_collision_layer_value(2, false)
			set_collision_mask_value(4, false)
			state.is_rolling = true
			animated_sprite_2d.play("roll")
			uncrouch_collision_shape_2d.disabled = false
		elif direction == 0:
			if state.is_crouching:
				animated_sprite_2d.play("crouch_idle")
			else:
				animated_sprite_2d.play("idle")
		else:
			if state.is_crouching:
				animated_sprite_2d.play("crouch_walk")
			else:
				animated_sprite_2d.play("run")
	else:
		if velocity.y <= 0:
			animated_sprite_2d.play("jump")
		else:
			animated_sprite_2d.play("fall")		
	move_and_slide()

func _on_animated_sprite_2d_animation_finished() -> void:
	print("finished animated sprite")
	if state.is_rolling:
		state.is_rolling = false
		set_collision_layer_value(2, true)
		set_collision_mask_value(4, true)
		if can_uncrouch():
			uncrouch_collision_shape_2d.disabled = false
		else:
			state.is_crouching = true
	if state.is_crouch_transitioning:
		state.is_crouch_transitioning = false
		state.is_crouching = not state.is_crouching
		uncrouch_collision_shape_2d.disabled = not uncrouch_collision_shape_2d.disabled
	if state.is_hurt:
		state.is_hurt = false
	if state.is_attacking:
		state.is_attacking = false
		state.was_attack_1 = not state.was_attack_1
		

func _on_sword_hit_area_2d_body_entered(body: Node2D) -> void:
	body.hurt(DAMAGE)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "flash":
		state.is_hurt = false
		if state.health <= 0:
			state.is_dead = true
			animated_sprite_2d.play("death")
			Engine.time_scale = 0.5
			death.emit()
			disable()
		return
	if state.is_attacking:
		state.is_attacking = false
		state.was_attack_1 = anim_name == "attack_1"
