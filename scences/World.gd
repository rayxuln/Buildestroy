extends Spatial

export(Dictionary) var block_data:Dictionary
export(SpatialMaterial) var block_material:SpatialMaterial

var chunck_size = Vector3(16, 256, 16)
var chunck_data

func _ready():
	if block_material == null:
		block_material = SpatialMaterial.new()
	register_blocks()
	block_material.albedo_texture = gen_texutre()
	gen_chunck_data()
	
	var mesh:ArrayMesh = gen_mesh_from_chunck_data(chunck_data)
	$ChunkMeshInstance.mesh = mesh
	mesh.surface_set_material(0, block_material)
	$ChunkMeshInstance.transform.origin = Vector3(0, 0, 0)

#------- Enums -------------
enum BlockType{AIR, HALF_SOLID, SOLID}

#------- Methods -------------
func register_blocks():
	block_data["air"] = {"name": "air", "type": BlockType.AIR}
	
	var su = 1.0/6.0
	
	block_data["dirt"] = {
		"name": "dirt",
		"type": BlockType.SOLID,
		"tex": preload("res://aseprites/dirt_block_texture.png"),
		"uvs": {
				"offset": Vector2.ZERO,
				"scale_factor": Vector2(1, 1),
				"up": [Vector2(0, 0), Vector2(su*1, 0), Vector2(su*1, 1), Vector2(0, 1)],
				"down": [Vector2(su*1, 0), Vector2(su*2, 0), Vector2(su*2, 1), Vector2(su*1, 1)],
				"left": [Vector2(su*2, 1), Vector2(su*2, 0), Vector2(su*3, 0), Vector2(su*3, 1)],
				"right": [Vector2(su*3, 1), Vector2(su*3, 0), Vector2(su*4, 0), Vector2(su*4, 1)],
				"front": [Vector2(su*4, 1), Vector2(su*4, 0), Vector2(su*5, 0), Vector2(su*5, 1)],
				"back": [Vector2(su*5, 1), Vector2(su*5, 0), Vector2(su*6, 0), Vector2(su*6, 1)]
			}
		}

func create_block(block_name, x, y, z):
	return {name=block_name, pos=Vector3(x, y, z)}
	

func is_rect_overlap(r1:Rect2, r2:Rect2):
	return (is_in_range(r1.position.x, r2.position.x, r2.end.x, true) \
			or is_in_range(r1.end.x, r2.position.x, r2.end.x, true))  \
			and (is_in_range(r1.position.y, r2.position.y, r2.end.y, true)  \
			or is_in_range(r1.end.y, r2.position.y, r2.end.y, true))
			

func gen_texutre():
	var the_image = Image.new()
	the_image.create(2048, 2048, false, Image.FORMAT_RGBA8)
	
	the_image.fill(Color(0, 0, 0, 0))
	
	for bd in block_data.values():
		if bd.has("tex"):
			var tex:Texture = bd["tex"]
			bd["uvs"]["scale_factor"] = Vector2(tex.get_width()/2048.0, tex.get_height()/2048.0)
			
			the_image.blit_rect(tex.get_data(), Rect2(0, 0, tex.get_width(), tex.get_height()), Vector2.ZERO)
	
	var tex = ImageTexture.new()
	tex.create_from_image(the_image)
	tex.flags ^= Texture.FLAG_FILTER
	return tex

func gen_chunck_data():
	chunck_data = [] # chunck_data[x][y][z]
	
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
			chunck_data[x][0][z] = create_block("dirt", x, 0, z)

func gen_cube_mesh(block_data, up=true, down=true, left=true, right=true, front=true, back=true):
	var mesh_tool = SurfaceTool.new()
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uvs = block_data["uvs"]
	var sf = uvs["scale_factor"]
	var base_index = 0
	if up:#0
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["up"][0]*sf)
		mesh_tool.add_vertex(Vector3(0, 1, 0))
		
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["up"][1]*sf)
		mesh_tool.add_vertex(Vector3(1, 1, 0))
		
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["up"][2]*sf)
		mesh_tool.add_vertex(Vector3(1, 1, 1))
		
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["up"][3]*sf)
		mesh_tool.add_vertex(Vector3(0, 1, 1))
		
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
		mesh_tool.add_vertex(Vector3(0, 0, 0))
		
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["down"][1]*sf)
		mesh_tool.add_vertex(Vector3(1, 0, 0))
		
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["down"][2]*sf)
		mesh_tool.add_vertex(Vector3(1, 0, 1))
		
		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["down"][3]*sf)
		mesh_tool.add_vertex(Vector3(0, 0, 1))
		
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
		mesh_tool.add_vertex(Vector3(0, 0, 0))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["left"][1]*sf)
		mesh_tool.add_vertex(Vector3(0, 1, 0))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["left"][2]*sf)
		mesh_tool.add_vertex(Vector3(0, 1, 1))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["left"][3]*sf)
		mesh_tool.add_vertex(Vector3(0, 0, 1))

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
		mesh_tool.add_vertex(Vector3(1, 0, 0))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["right"][1]*sf)
		mesh_tool.add_vertex(Vector3(1, 1, 0))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["right"][2]*sf)
		mesh_tool.add_vertex(Vector3(1, 1, 1))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["right"][3]*sf)
		mesh_tool.add_vertex(Vector3(1, 0, 1))

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
		mesh_tool.add_vertex(Vector3(0, 0, 1))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["front"][1]*sf)
		mesh_tool.add_vertex(Vector3(0, 1, 1))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["front"][2]*sf)
		mesh_tool.add_vertex(Vector3(1, 1, 1))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["front"][3]*sf)
		mesh_tool.add_vertex(Vector3(1, 0, 1))

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
		mesh_tool.add_vertex(Vector3(0, 0, 0))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["back"][1]*sf)
		mesh_tool.add_vertex(Vector3(0, 1, 0))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["back"][2]*sf)
		mesh_tool.add_vertex(Vector3(1, 1, 0))

		mesh_tool.add_color(Color.white)
		mesh_tool.add_uv(uvs["offset"]+uvs["back"][3]*sf)
		mesh_tool.add_vertex(Vector3(1, 0, 0))

		mesh_tool.add_index(base_index+3)
		mesh_tool.add_index(base_index+1)
		mesh_tool.add_index(base_index+0)

		mesh_tool.add_index(base_index+3)
		mesh_tool.add_index(base_index+2)
		mesh_tool.add_index(base_index+1)
	return mesh_tool.commit()

func is_in_range(x, min_x, max_x, closed = false):
	if not closed:
		return x >= min_x and x < max_x
	return x >= min_x and x <= max_x

func chunck_data_get_block(x, y, z):
	if not is_in_range(x, 0,chunck_size.x) or not is_in_range(y, 0,chunck_size.y) or not is_in_range(z, 0,chunck_size.z):
		return null
	return chunck_data[x][y][z]

func is_not_solid_block(x, y, z):
	var res = chunck_data_get_block(x, y, z)
	if res == null:
		return true
	return block_data[res["name"]]["type"] != BlockType.SOLID

func gen_mesh_from_chunck_data(data):
	var mesh_tool = SurfaceTool.new()
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trans = Transform.IDENTITY
	for x in data.size():
		for y in data[x].size():
			for z in data[x][y].size():
				var block = chunck_data_get_block(x, y, z)
				if block != null and block["name"] != "air":
					trans.origin = Vector3(x, y, z)
					
					var block_mesh = gen_cube_mesh(block_data[block["name"]],
												is_not_solid_block(x, y+1, z),
												is_not_solid_block(x, y-1, z),
												is_not_solid_block(x-1, y, z),
												is_not_solid_block(x+1, y, z),
												is_not_solid_block(x, y, z+1),
												is_not_solid_block(x, y, z-1))
						
					mesh_tool.append_from(block_mesh, 0, trans)
	return mesh_tool.commit()
#------- RPCs -------------

#------- Signals -------------

