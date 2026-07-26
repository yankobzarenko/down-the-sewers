extends CharacterBody2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: Area2D = $HitBox
@onready var attack_area: Area2D = $Attack
 
# --------------------
# CONFIG
# --------------------
@export var chase_speed: float = 150.0
@export var hover_amplitude: float = 12.0   # how far it bobs up/down while hovering
@export var hover_frequency: float = 1.5    # bob speed
@export var drift_radius: float = 40.0      # how far it wanders from spawn while idle
@export var drift_speed: float = 20.0
@export var contact_damage: int = 1
@export var give_up_distance: float = 220.0 # loses interest and returns if player gets this far away
@export var health: int = 3
 
const SMOOTHING_FACTOR = 0.08
 
# --------------------
# STATE MACHINE
# --------------------
enum State { HOVER, CHASE }
var state: State = State.HOVER
 
var target: Node2D
var spawn_position: Vector2
var drift_target: Vector2
var time_alive: float = 0.0
 
# --------------------
# READY
# --------------------
func _ready() -> void:
	MetSys.register_storable_object(self)
	target = PlayerManager.player
	if target:
		add_collision_exception_with(target)
		target.add_collision_exception_with(self)
	spawn_position = global_position
	_pick_new_drift_target()
 
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	attack_area.body_entered.connect(_on_attack_body_entered)
 
	_enter_state(State.HOVER)
 
# --------------------
# MAIN LOOP
# --------------------
func _physics_process(delta: float) -> void:
	time_alive += delta
 
	match state:
		State.HOVER: _state_hover(delta)
		State.CHASE: _state_chase(delta)
 
	move_and_slide()
 
# --------------------
# STATE HANDLERS
# --------------------
func _state_hover(delta: float) -> void:
	# Drift toward a wander point near spawn, close enough to keep looping
	if global_position.distance_to(drift_target) < 6.0:
		_pick_new_drift_target()
 
	var to_drift = global_position.direction_to(drift_target)
	var bob_offset = sin(time_alive * hover_frequency) * hover_amplitude * delta
 
	velocity = velocity.lerp(to_drift * drift_speed, SMOOTHING_FACTOR)
	velocity.y += bob_offset
	_face_direction(velocity)
 
func _state_chase(delta: float) -> void:
	if not target:
		_enter_state(State.HOVER)
		return
 
	if global_position.distance_to(target.global_position) > give_up_distance:
		_enter_state(State.HOVER)
		return
 
	var to_target = global_position.direction_to(target.global_position)
	var bob_offset = sin(time_alive * hover_frequency * 2.0) * (hover_amplitude * 0.5) * delta
 
	velocity = velocity.lerp(to_target * chase_speed, SMOOTHING_FACTOR)
	velocity.y += bob_offset
	_face_direction(velocity)
 
# --------------------
# HELPERS
# --------------------
func _enter_state(new_state: State) -> void:
	state = new_state
	match state:
		State.HOVER:
			anim.play("fly")
			_pick_new_drift_target()
		State.CHASE:
			anim.play("fly") # swap for a distinct "alert/chase" anim if you have one
 
func _pick_new_drift_target() -> void:
	var angle = randf() * TAU
	var dist = randf() * drift_radius
	drift_target = spawn_position + Vector2(cos(angle), sin(angle)) * dist
 
func _face_direction(dir: Vector2) -> void:
	if dir.x > 1.0:
		sprite.flip_h = false
	elif dir.x < -1.0:
		sprite.flip_h = true
 
# --------------------
# SIGNALS
# --------------------
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body == target:
		_enter_state(State.CHASE)
 
func _on_detection_area_body_exited(body: Node2D) -> void:
	# Don't immediately give up on exit — give_up_distance in _state_chase
	# handles the actual disengage so it doesn't flicker at the boundary.
	pass
 
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == target and body.has_method("take_damage"):
		body.take_damage(contact_damage)
 
# Attack is the enemy's own weapon hitbox — it damages the PLAYER on touch.
# No group needed: just confirm the body is the tracked target and has the method.
func _on_attack_body_entered(body: Node2D) -> void:
	if body == target and body.has_method("attackDetch"):
		body.attackDetch()
 
# --------------------
# DAMAGE
# --------------------
func attackDetch() -> void:
	health -= 1
	sprite.get_material().set_shader_parameter("active", true)
	await get_tree().create_timer(0.7).timeout
	sprite.get_material().set_shader_parameter("active", false)
	if health <= 0:
		self.queue_free()
