extends KinematicBody

export(float) var mouse_sensity = 1
const MOUSE_SENSITY_CORRECTION_FACTOR = 0.01
export(float) var mouse_max_rotate_x = 65
export(float) var mouse_min_rotate_x = -70
export(float) var move_speed = 2
export(float) var sprint_factor = 2
export(float) var sprint_camera_fov_factor = 1.14
export(float) var fly_speed = 1.5
export(bool) var enable = false

var velocity = Vector3.ZERO
var is_sprint = false
var normal_fov
var target_fov

var peer_id setget _on_peer_id_set, _on_peer_id_get
func _on_peer_id_set(v):
	peer_id = v
	name = "Player_" + str(v)
func _on_peer_id_get():
	return peer_id

func _ready():
	normal_fov = $Camera.fov
	target_fov = normal_fov

func _input(event):
	if not enable:
		return
	if event is InputEventMouseMotion:
		var input_vec = event.relative
		rotation_degrees.x += rad2deg(-input_vec.y * mouse_sensity * MOUSE_SENSITY_CORRECTION_FACTOR)
		rotation_degrees.x = clamp(rotation_degrees.x, mouse_min_rotate_x, mouse_max_rotate_x)

		rotation_degrees.y += rad2deg(-input_vec.x * mouse_sensity * MOUSE_SENSITY_CORRECTION_FACTOR)

func _process(delta):
	if not enable:
		return
	if Input.is_action_just_pressed("sprint"):
		is_sprint = true
		target_fov = normal_fov * sprint_camera_fov_factor
	
	if not Input.is_action_pressed("sprint") and not Input.is_action_pressed("move_up"):
		is_sprint = false
		target_fov = normal_fov
	
	$Camera.fov = lerp($Camera.fov, target_fov, 0.3)

func _physics_process(delta):
	if not enable:
		return
	var input_vec = Vector3.ZERO
	input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec.z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vec = input_vec.normalized()
	input_vec.y = Input.get_action_strength("fly_up") - Input.get_action_strength("fly_down")
	
	velocity = (transform.basis.x * input_vec.x + transform.basis.z * input_vec.z) * move_speed * (sprint_factor if is_sprint else 1) + Vector3.UP * input_vec.y * fly_speed
	move_and_slide(velocity, Vector3.UP)
	
#--------- Methods ------------------


#---------- RPC ---------------------
puppet func sync_transform(t):
	global_transform = t

#--------- Signals ------------------
func _on_SyncTimer_timeout():
	#if get_tree().get_network_unique_id() == peer_id:
	if is_network_master():
		rpc_unreliable("sync_transform", global_transform)
