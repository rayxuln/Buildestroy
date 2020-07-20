extends KinematicBody

export(float) var mouse_sensity = 0.7
const MOUSE_SENSITY_CORRECTION_FACTOR = 0.01
export(float) var mouse_max_rotate_x = 65
export(float) var mouse_min_rotate_x = -90
export(float) var move_speed = 3.5
export(float) var sprint_factor = 1.5
export(float) var sprint_camera_fov_factor = 1.14
export(float) var jump_speed = 8.3
export(bool) var enable = false
export(float) var dead_y = -30

var velocity = Vector3.ZERO
var gravity = -0.49
var is_sprint = false
var normal_fov
var target_fov

var peer_id setget _on_peer_id_set, _on_peer_id_get
func _on_peer_id_set(v):
	peer_id = v
	name = "Player_" + str(v)
func _on_peer_id_get():
	return peer_id

onready var anim_playback = $AnimationTree["parameters/playback"]	
onready var world_camera = $Body/HeadJoint/Camera
onready var first_person_view_camera = $Body/HeadJoint/FirstPersonViewport/Camera

onready var head_joint = $Body/HeadJoint

onready var first_person_viewport = $Body/HeadJoint/FirstPersonViewport

func _ready():
	normal_fov = world_camera.fov
	target_fov = normal_fov
	
	first_person_viewport.size = get_viewport().size
	first_person_viewport.world = get_viewport().world

func _input(event):
	if not enable:
		return
	if event is InputEventMouseMotion:
		var input_vec = event.relative
		head_joint.rotation_degrees.x += rad2deg(-input_vec.y * mouse_sensity * MOUSE_SENSITY_CORRECTION_FACTOR)
		head_joint.rotation_degrees.x = clamp(head_joint.rotation_degrees.x, mouse_min_rotate_x, mouse_max_rotate_x)

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
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed
	
	if Input.is_action_just_pressed("destroy"):
		anim_playback.travel("hand_swing")
	
	if Input.is_action_just_pressed("build"):
		anim_playback.travel("hand_swing")
	
	$Cursor.position = get_viewport().size/2
	world_camera.fov = lerp(world_camera.fov, target_fov, 0.3)
	
	first_person_view_camera.global_transform = world_camera.global_transform

func _physics_process(delta):
	if not enable:
		return
	var input_vec = Vector3.ZERO
	input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec.z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vec = input_vec.normalized()
	
	var velocity_xz = (transform.basis.x * input_vec.x + transform.basis.z * input_vec.z) * move_speed * (sprint_factor if is_sprint else 1)
	velocity.x = velocity_xz.x
	velocity.z = velocity_xz.z
	
	velocity.y += gravity
	
	velocity = move_and_slide(velocity, Vector3.UP)
	if global_transform.origin.y < 0:
		velocity.y = 0
		global_transform.origin.y = 0
	
	var space_state = get_world().direct_space_state
	var ray_from = world_camera.project_ray_origin($Cursor.global_position)
	var ray_to = ray_from+world_camera.project_ray_normal($Cursor.global_position) * 5
	var ray_cast_res:Dictionary = space_state.intersect_ray(ray_from, ray_to, [self])
	
	$BlockSelectionWireframeMesh.visible = false
	if not ray_cast_res.empty():
		var cpos = ray_cast_res.position
		var cnor = ray_cast_res.normal
		
		var block = get_parent().get_block_by_world_position_and_face_normal(cpos, cnor)
		
		if block and get_parent().block_data[block.name].type == get_parent().BlockType.SOLID:
			$BlockSelectionWireframeMesh.global_transform = Transform.IDENTITY
			$BlockSelectionWireframeMesh.global_transform.origin = block.pos
			$BlockSelectionWireframeMesh.visible = true
			
			if Input.is_action_just_pressed("destroy"):
				get_parent().destroy_block(block.pos)
			
			if Input.is_action_just_pressed("build"):
				get_parent().build_block(block.pos+cnor, "stone")

	
#--------- Methods ------------------


#---------- RPC ---------------------
puppet func sync_transform(t):
	global_transform = t

#--------- Signals ------------------
func _on_SyncTimer_timeout():
	#if get_tree().get_network_unique_id() == peer_id:
	if is_network_master():
		rpc_unreliable("sync_transform", global_transform)
