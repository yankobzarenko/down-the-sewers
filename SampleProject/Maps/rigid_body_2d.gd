extends RigidBody2D

@export var velocity = 10.0

var health = 3

func _ready() -> void:
	MetSys.register_storable_object(self)
	
func attackDetch():
	health -= 1
	$Sprite2D.get_material().set_shader_parameter("active", true)
	await get_tree().create_timer(0.7).timeout
	$Sprite2D.get_material().set_shader_parameter("active", false)
	if health <= 0:
		self.queue_free()
