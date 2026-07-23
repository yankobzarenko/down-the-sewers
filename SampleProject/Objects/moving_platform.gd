extends Node2D

@export var offset: Vector2 = Vector2(64, 0)  # Movement offset
@export var duration: float = 5.0             # Total time for a full cycle

func _ready() -> void:
	start_tween()

func start_tween() -> void:
	# Get the starting position of the platform
	var start_pos: Vector2 = $AnimatableBody2D.position
	var end_pos: Vector2 = start_pos + offset

	# Create and configure the tween
	var tween = get_tree().create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_loops()  # Infinite loop

	# Move to end position
	tween.tween_property($AnimatableBody2D, "position", end_pos, duration / 2)
	# Move back to start position
	tween.tween_property($AnimatableBody2D, "position", start_pos, duration / 2)
