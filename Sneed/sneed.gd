extends CharacterBody2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vision_ray: RayCast2D = $VisionRay 
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack: Sprite2D = $Attack

# --------------------
# CONFIG
# --------------------
@export var patrol_points: Array[Node2D] = []
@export var speed_walk: float = 1.7
@export var speed_run: float = 3.0
@export var attack_range: float = 2.0
@export var investigate_wait_time: float = 4.0
@export var patrol_wait_time: float = 3.0
@export var update_interval: float = 0.2
 
const VIEW_ANGLE: float = 190.0
const SMOOTHING_FACTOR = 0.2
 
# --------------------
# STATE MACHINE
# --------------------
enum State { IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, RETURN }
var state: State = State.IDLE
 
var patrol_index := 0
var patrol_timer := 0.0
var investigate_timer := 0.0
var investigate_position: Vector2
var return_position: Vector2
var target: Node2D
var update_timer := 0.0

# --------------------
# READY
# --------------------

func _ready() -> void:
	#init stuff
	MetSys.register_storable_object(self)
	print("Enemy initialized")
	velocity.y = 0
	#ai stuff
	target = PlayerManager.player
	_enter_state(State.IDLE if patrol_points.is_empty() else State.PATROL)

# --------------------
# MAIN LOOP
# --------------------
func _physics_process(delta: float) -> void:
	_update_path(delta)
 
	match state: # match is switch equivalent
		State.IDLE:        _state_idle()
		State.PATROL:      _state_patrol(delta)
		State.INVESTIGATE: _state_investigate(delta)
		State.CHASE:       _state_chase(delta)
		State.ATTACK:      _state_attack()
		State.RETURN:      _state_return(delta)
 
	_looking()
	handle_gravity(delta)
	move_and_slide()

# --------------------
# STATE HANDLERS
# --------------------
func _state_idle() -> void:
	if _can_see_player():
		_enter_state(State.CHASE)
 
func _state_patrol(delta: float) -> void:
	if agent.is_navigation_finished():
		if patrol_timer <= 0.0:
			patrol_timer = patrol_wait_time
			_stop_and_idle()
		else:
			patrol_timer -= delta
			if patrol_timer <= 0.0:
				_go_to_next_patrol_point()
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)
 
	if _can_see_player():
		_enter_state(State.CHASE)
 
func _state_investigate(delta: float) -> void:
	if agent.is_navigation_finished():
		if investigate_timer <= 0.0:
			investigate_timer = investigate_wait_time
			_stop_and_idle()
		else:
			investigate_timer -= delta
			if investigate_timer <= 0.0:
				_enter_state(State.RETURN)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)
 
	if _can_see_player():
		_enter_state(State.CHASE)
 
func _state_chase(delta: float) -> void:
	if not target:
		_enter_state(State.RETURN)
		return
 
	_walk_to(agent.get_next_path_position(), speed_run)
 
	if global_transform.origin.distance_to(target.global_transform.origin) < attack_range:
		_enter_state(State.ATTACK)
	elif not _can_see_player():
		investigate_position = target.global_transform.origin
		_enter_state(State.INVESTIGATE)
 
func _state_attack() -> void:
	velocity = Vector2.ZERO
	sprite.visible = false
	attack.visible = true
	anim.play("melee")
	await anim.animation_finished
	attack.visible = false
	sprite.visible = true
	# TODO: handle player capture
	_enter_state(State.CHASE)
 
func _state_return(delta: float) -> void:
	if agent.is_navigation_finished():
		_enter_state(State.PATROL)
	elif _can_see_player():
		_enter_state(State.CHASE)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)
 
# --------------------
# HELPERS
# --------------------
func _enter_state(new_state: State) -> void:
	state = new_state
	match state:
		State.PATROL:
			patrol_timer = 0
			_go_to_next_patrol_point()
		State.INVESTIGATE:
			investigate_timer = 0.0
			agent.set_target_position(investigate_position)
		State.CHASE, State.INVESTIGATE:
			return_position = global_transform.origin
 
func _update_agent_target() -> void:
	match state:
		State.PATROL:
			if patrol_points.size() > 0:
				agent.set_target_position(patrol_points[patrol_index].global_transform.origin)
		State.INVESTIGATE:
			agent.set_target_position(investigate_position)
		State.CHASE:
			if target:
				agent.set_target_position(target.global_transform.origin)
		State.RETURN:
			agent.set_target_position(return_position)
 
func _walk_to(next_pos: Vector2, speed: float) -> void:
	anim.play("Run")
	_move_towards(next_pos, speed)
 
func _stop_and_idle() -> void:
	velocity = Vector2.ZERO
	anim.play("Idle")
 
func _go_to_next_patrol_point() -> void:
	if patrol_points.size() != 0:
		patrol_index = ( patrol_index + 1 ) % patrol_points.size()
		agent.set_target_position(patrol_points[patrol_index].global_transform.origin)
 
func _move_towards(next_pos: Vector2, speed: float) -> void:
	var dir = (next_pos - global_transform.origin)
	dir.y = 0.0
	if  is_zero_approx( dir.length() ):
		velocity.x = lerp(velocity.x, 0.0, SMOOTHING_FACTOR)
		return
 
	dir = dir.normalized()
	var current_facing = -global_transform.x
	var new_dir = current_facing.slerp(dir, 0.12).normalized()
	look_at(global_transform.origin + new_dir)
 
	velocity.x = dir.x * speed
 
func _update_path(delta):
	update_timer -= delta
	if update_timer <= 0.0:
		_update_agent_target()
		update_timer = update_interval
 
 
# --------------------
# VISION
# --------------------
func _can_see_player() -> bool:
	return target and vision_ray.is_colliding() and vision_ray.get_collider() == target
 
func _looking() -> void:
	if not target:
		return
 
	if velocity.x > 1:
		self.flip_h = false
	elif velocity.x < -1:
		self.flip_h = true
		return
 
 
# --------------------
# SOUND
# --------------------
func hear_noise(pos: Vector2) -> void:
	if state not in [State.CHASE, State.ATTACK]:
		investigate_position = pos
		_enter_state(State.INVESTIGATE)

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity = get_gravity() * delta
