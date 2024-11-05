extends Area2D
@onready var platform: AnimatableBody2D = $"../Platform"
@onready var invisible_boundary: Area2D = $"../InvisibleBoundary"
@onready var invisible_boundary_2: Area2D = $"../InvisibleBoundary2"



func _on_body_entered(body: Node2D) -> void:
	platform.queue_free()
	invisible_boundary.queue_free()
	invisible_boundary_2.queue_free()
	queue_free()
