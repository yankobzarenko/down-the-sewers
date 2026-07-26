extends CharacterBody2D

var health = 3

@export var gravity = -9.8

func _ready() -> void:
	MetSys.register_storable_object(self)
	
func apply_knockback(enemy_velocity: Vector2, kb_force: float):
	var kb_direction = (enemy_velocity - velocity).normalized() * kb_force
	velocity = kb_direction
	velocity.y -= 250 # Optional vertical lift

func attackDetch():
	health -= 1
	apply_knockback(velocity, 300)
	$Sprite2D.get_material().set_shader_parameter("active", true)
	await get_tree().create_timer(0.7).timeout
	$Sprite2D.get_material().set_shader_parameter("active", false)
	if health <= 0:
		self.queue_free()
	
