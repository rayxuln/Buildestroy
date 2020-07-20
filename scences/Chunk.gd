extends MeshInstance

var chunck_data

var block_material:SpatialMaterial = null
var block_data:Dictionary = {}

# multi-thread update mesh
var expect_thread_id = -1
var ready_mesh:ArrayMesh = null
var ready_mesh_thread_id:int = -1
var update_mesh_mutex:Mutex = Mutex.new()
var thread_id_cnt = 0
var threads:Array = []
var gc_threads_mutex:Mutex = Mutex.new()
var mesh_dirty_flag:bool = false

func _process(delta):
	if ready_mesh != null and mesh != ready_mesh:
		mesh = ready_mesh
		ready_mesh.surface_set_material(0, block_material)
		update_chunck_collision()
		ready_mesh = null
	
	if mesh_dirty_flag:
		mesh_dirty_flag = false
		update_chunck_mesh()

func _exit_tree():
	for t in threads:
		if t is Thread:
			t.wait_to_finish()
#------- Enums -------------

#------- Methods -------------
func init(mat:SpatialMaterial, bd:Dictionary, pos:Vector2, cd=null):
	name = BlockType.make_chunck_name(pos)
	transform.origin = Vector3(pos.x*BlockType.chunck_size.x, 0, pos.y*BlockType.chunck_size.z)
	
	block_material = mat
	block_data = bd
	
	if not cd:
		gen_chunck_data()
	else:
		chunck_data = cd
	
#	update_chunck_mesh()
	mesh_dirty_flag = true
	
	gc_threads()

func create_block(block_name, x, y, z):
	return {"name": block_name, "pos": Vector3(x, y, z), "chunck_pos": BlockType.convert_to_chunck_pos(global_transform.origin)}

func gen_chunck_data():
	chunck_data = [] # chunck_data[x][y][z]
	var chunck_size = BlockType.chunck_size
	
	for x in chunck_size.x:
		var chunck_data_x = []
		for y in chunck_size.y:
			var chunck_data_y = []
			for z in chunck_size.z:
				chunck_data_y.append(create_block("air", x, y, z))
			chunck_data_x.append(chunck_data_y)
		chunck_data.append(chunck_data_x)
	
	for x in chunck_size.x:
		for z in chunck_size.z:
			chunck_data[x][0][z] = create_block("stone", x, 0, z)
	
	for x in chunck_size.x:
		for z in chunck_size.z:
			chunck_data[x][1][z] = create_block("dirt", x, 1, z)
	
	chunck_data[4][2][11] = create_block("stone", 4, 2, 11) 

func add_cube_mesh(mesh_tool:SurfaceTool, trans:Transform, base_index, block_data, up=true, down=true, left=true, right=true, front=true, back=true):
	if not up and not down and not left and not right and not front and not back:
		return base_index
	
	var uvs = block_data["uvs"]
	var sf = uvs["scale_factor"]
	if up:#0
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["up"][0]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 1, 0)))
		
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["up"][1]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 1, 0)))
		
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["up"][2]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 1, 1)))
		
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["up"][3]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 1, 1)))
		
		mesh_tool.add_index(base_index+0)
		mesh_tool.add_index(base_index+1)
		mesh_tool.add_index(base_index+2)
		
		mesh_tool.add_index(base_index+0)
		mesh_tool.add_index(base_index+2)
		mesh_tool.add_index(base_index+3)
		
		base_index += 4
	if down:#4
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["down"][0]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 0, 0)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["down"][1]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 0, 0)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["down"][2]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 0, 1)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["down"][3]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 0, 1)))

		mesh_tool.add_index(base_index+2)
		mesh_tool.add_index(base_index+1)
		mesh_tool.add_index(base_index+0)

		mesh_tool.add_index(base_index+3)
		mesh_tool.add_index(base_index+2)
		mesh_tool.add_index(base_index+0)
		base_index += 4
	if left:#8
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["left"][0]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 0, 0)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["left"][1]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 1, 0)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["left"][2]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 1, 1)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["left"][3]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 0, 1)))

		mesh_tool.add_index(base_index+0)
		mesh_tool.add_index(base_index+1)
		mesh_tool.add_index(base_index+3)

		mesh_tool.add_index(base_index+1)
		mesh_tool.add_index(base_index+2)
		mesh_tool.add_index(base_index+3)

		base_index += 4
	if right:#12
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["right"][0]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 0, 0)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["right"][1]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 1, 0)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["right"][2]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 1, 1)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["right"][3]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 0, 1)))

		mesh_tool.add_index(base_index+3)
		mesh_tool.add_index(base_index+1)
		mesh_tool.add_index(base_index+0)

		mesh_tool.add_index(base_index+3)
		mesh_tool.add_index(base_index+2)
		mesh_tool.add_index(base_index+1)

		base_index += 4
	if front:#16
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["front"][0]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 0, 1)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["front"][1]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 1, 1)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["front"][2]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 1, 1)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["front"][3]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 0, 1)))

		mesh_tool.add_index(base_index+0)
		mesh_tool.add_index(base_index+1)
		mesh_tool.add_index(base_index+3)

		mesh_tool.add_index(base_index+1)
		mesh_tool.add_index(base_index+2)
		mesh_tool.add_index(base_index+3)

		base_index += 4
	if back:#20
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["back"][0]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 0, 0)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["back"][1]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(0, 1, 0)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["back"][2]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 1, 0)))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["back"][3]*sf)
		mesh_tool.add_vertex(trans.xform(Vector3(1, 0, 0)))

		mesh_tool.add_index(base_index+3)
		mesh_tool.add_index(base_index+1)
		mesh_tool.add_index(base_index+0)

		mesh_tool.add_index(base_index+3)
		mesh_tool.add_index(base_index+2)
		mesh_tool.add_index(base_index+1)
		
		base_index += 4
	return base_index


func is_valid_position_in_chunck(pos:Vector3):
	var chunck_size = BlockType.chunck_size
	return RaiixMathUtil.is_in_range(pos.x, 0,chunck_size.x) and RaiixMathUtil.is_in_range(pos.y, 0,chunck_size.y) and RaiixMathUtil.is_in_range(pos.z, 0,chunck_size.z)

func chunck_data_get_block(x:int, y:int, z:int):
	if not is_valid_position_in_chunck(Vector3(x, y, z)):
		return null
	return chunck_data[x][y][z]

func is_not_solid_block(x, y, z):
	var res = chunck_data_get_block(x, y, z)
	if res == null:
		return true
	return block_data[res["name"]]["type"] != BlockType.SOLID

func gen_mesh_from_chunck_data():
	var chunck_size = BlockType.chunck_size
	var mesh_tool = SurfaceTool.new()
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trans = Transform.IDENTITY
	var base_index = 0
	for x in chunck_size.x:
		for y in chunck_size.y:
			for z in chunck_size.z:
				var block = chunck_data_get_block(x, y, z)
				if block != null and block["name"] != "air":
					trans.origin = Vector3(x, y, z)
					base_index = add_cube_mesh(mesh_tool, trans, base_index, block_data[block["name"]],
																		is_not_solid_block(x, y+1, z),
																		is_not_solid_block(x, y-1, z),
																		is_not_solid_block(x-1, y, z),
																		is_not_solid_block(x+1, y, z),
																		is_not_solid_block(x, y, z+1),
																		is_not_solid_block(x, y, z-1))
					
					
	mesh_tool.generate_normals()
	return mesh_tool.commit()

func update_chunck_mesh():
	update_mesh_mutex.lock()
	ready_mesh = null
	update_mesh_mutex.unlock()
	var t = Thread.new()
	t.start(self, "_thread_update_chunck_mesh", [OS.get_ticks_msec(), t])
	
	gc_threads_mutex.lock()
	threads.append(t)
	gc_threads_mutex.unlock()

func _thread_update_chunck_mesh(args):
	var mesh:ArrayMesh = gen_mesh_from_chunck_data()
	if ready_mesh_thread_id < args[0]:
		update_mesh_mutex.lock()
		ready_mesh_thread_id = args[0]
		ready_mesh = mesh
		update_mesh_mutex.unlock()
	
	gc_threads_mutex.lock()
	var id = threads.find(args[1])
	if id >= 0:
		threads[id] = null
	gc_threads_mutex.unlock()
	

func update_chunck_collision():
	var shape = mesh.create_trimesh_shape()
	if shape == null:
		print("generate chunck collision fail!")
		return
	
	var chunck_collision = get_node_or_null("ChunckStaticBody/Shape")
	if chunck_collision:
		chunck_collision.shape = shape
	else:
		var static_body = StaticBody.new()
		static_body.name = "ChunckStaticBody"
		
		var collision_shape = CollisionShape.new()
		static_body.add_child(collision_shape)
		collision_shape.name = "Shape"
		collision_shape.shape = shape
		
		add_child(static_body)
	

func set_block(pos_in_chunck:Vector3, block_name):
	if not is_valid_position_in_chunck(pos_in_chunck):
		return
	chunck_data[pos_in_chunck.x][pos_in_chunck.y][pos_in_chunck.z] = create_block(block_name, pos_in_chunck.x, pos_in_chunck.y, pos_in_chunck.z)
	
#	update_chunck_mesh()
	mesh_dirty_flag = true

func destroy_block(pos_in_chunck:Vector3):
	set_block(pos_in_chunck, "air")

func build_block(pos_in_chunck:Vector3, block_name):
	set_block(pos_in_chunck, block_name)

func get_block_by_world_position_and_face_normal(pos:Vector3, nor:Vector3):
	pos -= nor * 0.01
	return chunck_data_get_block(pos.x, pos.y, pos.z)

func gc_threads():
	while true:
		gc_threads_mutex.lock()
		if not threads.empty():
			var new_threads = []
			for t in threads:
				if t:
					new_threads.append(t)
			threads = new_threads
		gc_threads_mutex.unlock()
		yield(get_tree().create_timer(10), "timeout")
#------- RPCs -------------

#------- Signals -------------

	
	
