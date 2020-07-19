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

onready var anim_playback = $AnimationTree["parameters/playback"]	

func _ready():
	normal_fov = $Camera.fov
	target_fov = normal_fov
	
	var mesh_tool = SurfaceTool.new()
	mesh_tool.begin(Mesh.PRIMITIVE_LINES)
	mesh_tool.add_vertex(Vector3(0, 0, 0))#0
	mesh_tool.add_vertex(Vector3(1, 0, 0))#1
	mesh_tool.add_vertex(Vector3(1, 1, 0))#2
	mesh_tool.add_vertex(Vector3(0, 1, 0))#3
	mesh_tool.add_vertex(Vector3(0, 0, 1))#4
	mesh_tool.add_vertex(Vector3(1, 0, 1))#5
	mesh_tool.add_vertex(Vector3(1, 1, 1))#6
	mesh_tool.add_vertex(Vector3(0, 1, 1))#7
	#up
	mesh_tool.add_index(3);mesh_tool.add_index(7)
	mesh_tool.add_index(6);mesh_tool.add_index(2)
	#down
	mesh_tool.add_index(1);mesh_tool.add_index(5)
	mesh_tool.add_index(4);mesh_tool.add_index(0)
	#front
	mesh_tool.add_index(4);mesh_tool.add_index(5)
	mesh_tool.add_index(5);mesh_tool.add_index(6)
	mesh_tool.add_index(6);mesh_tool.add_index(7)
	mesh_tool.add_index(7);mesh_tool.add_index(4)
	#back
	mesh_tool.add_index(0);mesh_tool.add_index(1)
	mesh_tool.add_index(1);mesh_tool.add_index(2)
	mesh_tool.add_index(2);mesh_tool.add_index(3)
	mesh_tool.add_index(3);mesh_tool.add_index(0)
	$BlockSelectionWireframeMesh.mesh = mesh_tool.commit()
	var mat = SpatialMaterial.new()
	mat.flags_unshaded = true
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	mat.params_line_width = 2
	mat.albedo_color = Color.black
	$BlockSelectionWireframeMesh.mesh.surface_set_material(0, mat)
	
	$FirstPersonViewport.size = get_viewport().size

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
	
	if Input.is_action_just_pressed("destroy"):
		anim_playback.travel("hand_swing")
	
	if Input.is_action_just_pressed("build"):
		anim_playback.travel("hand_swing")
	
	$Cursor.position = get_viewport().size/2
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
	
	var space_state = get_world().direct_space_state
	var ray_from = $Camera.project_ray_origin($Cursor.global_position)
	var ray_to = ray_from+$Camera.project_ray_normal($Cursor.global_position) * 5
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
