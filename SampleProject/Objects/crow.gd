extends Area2D

@export var speed := 350.0
@export var steer_force := 50.0

var velocity := Vector2.ZERO
var acceleration := Vector2.ZERO
var target: Node2D
var exploded := false

func start(_transform: Transform2D, _target: Node2D):
	global_transform = _transform
	rotation += randf_range(-0.09, 0.09)
	velocity = transform.x * speed
	target = _target

func seek() -> Vector2:
	if !is_instance_valid(target):
		return Vector2.ZERO

	var desired = (target.global_position - global_position).normalized() * speed
	var steer = desired - velocity

	if steer.length() > 0:
		steer = steer.normalized() * steer_force

	return steer

func _physics_process(delta):
	acceleration = seek()

	velocity += acceleration * delta
	velocity = velocity.limit_length(speed)

	if velocity.length() > 0.1:
		rotation = velocity.angle()

	global_position += velocity * delta

func _on_body_entered(body):
	explode()

func _on_lifetime_timeout():
	explode()

func explode():
	if exploded:
		return

	exploded = true
	monitoring = false
	set_physics_process(false)

	$Particles2D.emitting = false
	$AnimationPlayer.play("explode")

	await $AnimationPlayer.animation_finished
	queue_free()


func _on_timer_timeout() -> void:
	pass # Replace with function body.
