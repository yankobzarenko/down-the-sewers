extends CharacterBody2D

@onready var vision: RayCast2D = $RayCast2D


var target

func _ready() -> void:
	target = PlayerManager.player

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity = get_gravity() * delta
