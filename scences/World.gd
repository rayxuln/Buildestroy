extends Spatial

export(Dictionary) var block_data:Dictionary
export(SpatialMaterial) var block_material:SpatialMaterial

export(int) var view_distance = 4

var game_system:Node = null


func _ready():
	if block_material == null:
		block_material = SpatialMaterial.new()
		
	register_blocks()
	block_material.albedo_texture = gen_texutre()
	
	if get_tree().is_network_server():
		load_chunck(Vector2.ZERO)

	
func _process(delta):
	if not get_tree().is_network_server():
		return
	if game_system:
		var player = game_system.the_player
		if player:
			var player_pos = player.global_transform.origin
			var chunck_pos = Vector2(floor(player_pos.x/BlockType.chunck_size.x), floor(player_pos.z/BlockType.chunck_size.z))
			chunck_pos -= Vector2(view_distance/2, view_distance/2)
			for offset_x in view_distance:
				for offset_y in view_distance:
					var offset = Vector2(offset_x, offset_y)
					var pos = chunck_pos + offset
					var chunck_name = BlockType.make_chunck_name(pos)
					if not has_node(chunck_name):
						#load_chunck(pos)
						rpc("load_chunck", pos)
#------- Enums -------------

#------- Methods -------------
func remote_init_chuncks(id):
	var chunck_pos_list = []
	var chuncks = get_tree().get_nodes_in_group("chunck")
	for c in chuncks:
		chunck_pos_list.append([BlockType.convert_to_chunck_pos(c.global_transform.origin), null])
	rpc_id(id, "_init_chuncks", chunck_pos_list)

func gen_normal_solid_cube_block_uvs_data():
	var su = 1.0/6.0
	return {
				"offset": Vector2.ZERO,
				"scale_factor": Vector2(1, 1),
				"up": [Vector2(0, 0), Vector2(su*1, 0), Vector2(su*1, 1), Vector2(0, 1)],
				"down": [Vector2(su*1, 0), Vector2(su*2, 0), Vector2(su*2, 1), Vector2(su*1, 1)],
				"left": [Vector2(su*2, 1), Vector2(su*2, 0), Vector2(su*3, 0), Vector2(su*3, 1)],
				"right": [Vector2(su*3, 1), Vector2(su*3, 0), Vector2(su*4, 0), Vector2(su*4, 1)],
				"front": [Vector2(su*4, 1), Vector2(su*4, 0), Vector2(su*5, 0), Vector2(su*5, 1)],
				"back": [Vector2(su*5, 1), Vector2(su*5, 0), Vector2(su*6, 0), Vector2(su*6, 1)]
			}

func register_blocks():
	block_data["air"] = {"name": "air", "type": BlockType.AIR}
	
	block_data["dirt"] = {
		"name": "dirt",
		"type": BlockType.SOLID,
		"tex": preload("res://aseprites/dirt_block_texture.png"),
		"uvs": gen_normal_solid_cube_block_uvs_data()
		}
	
	block_data["stone"] = {
		"name": "stone",
		"type": BlockType.SOLID,
		"tex": preload("res://aseprites/stone_block_texture.png"),
		"uvs": gen_normal_solid_cube_block_uvs_data()
		}

func gen_texutre():
	var USED = 1
	var UNUSED = 0
	
	var the_image = Image.new()
	var image_size = Vector2(2048, 2048)
	the_image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	
	var tex_size = Vector2(6, 1)
	var face_tex_size = Vector2(16, 16)
	var unit_size = tex_size*face_tex_size
	var units_num = Vector2(floor(image_size.x/unit_size.x), floor(image_size.y/unit_size.y))
	
	var units_used = []
	units_used.resize(units_num.x)
	for x in units_num.x:
		var row = []
		row.resize(units_num.y)
		for y in units_num.y:
			row[y] = UNUSED
		units_used[x] = row
	
	the_image.fill(Color(0, 0, 0, 0))
	
	for bd in block_data.values():
		if bd.has("tex"):
			var tex:Texture = bd["tex"]
			var tw = tex.get_width()
			var th = tex.get_height()
			bd["uvs"]["scale_factor"] = Vector2(tw/image_size.x, th/image_size.y)
			
			# calc how many space it needs
			var ts = Vector2(ceil(tw/unit_size.x), ceil(th/unit_size.y))
#			print(bd["name"], " ts:", ts)
			
			# get available position
			var tpos = Vector2.ZERO # in unit
			var found_tpos = false
			for x in units_num.x:
				for y in units_num.y:
					if units_used[x][y] == UNUSED:
						var available = true
						# try to put it in
						for tx in ts.x:
							for ty in ts.y:
#								print(bd["name"], " tx:", tx, " ty:", ty)
								if not RaiixMathUtil.is_in_range(x+tx, 0, units_num.x) or not RaiixMathUtil.is_in_range(y+ty, 0, units_num.y) or units_used[x+tx][y+ty] == USED:
									available = false
									break
						if not available:
							continue
						found_tpos = true
						units_used[x][y] = USED
						tpos = Vector2(x, y)
						break
				if found_tpos:
					break
			if not found_tpos:
				print("Can't found a place for tex:" + bd["name"])
				continue
			
#			print("gen tex for " + bd["name"] + " at ", tpos)
			
			# calc uv pos
			bd["uvs"]["offset"] = Vector2((tpos.x * unit_size.x)/image_size.x, (tpos.y * unit_size.y)/image_size.y)
			
			the_image.blit_rect(tex.get_data(), Rect2(0, 0, tw, th), tpos * unit_size)
	
	var tex = ImageTexture.new()
	tex.create_from_image(the_image)
	tex.flags = Texture.FLAG_REPEAT
	return tex

func destroy_block(pos:Vector3):
	#set_block(pos, "air")
	rpc("set_block", pos, "air")

func build_block(pos:Vector3, block_name):
	#set_block(pos, block_name)
	rpc("set_block", pos, block_name)

func get_block_by_world_position_and_face_normal(pos:Vector3, nor:Vector3):
	var chunck_pos = BlockType.convert_to_chunck_pos(pos)
	var chunck = get_node_or_null(BlockType.make_chunck_name(chunck_pos))
	if chunck:
		return chunck.get_block_by_world_position_and_face_normal(pos-chunck.global_transform.origin, nor)
	return null
	
#------- RPCs -------------
remote func _init_chuncks(chunck_pos_list:Array):
	for p in chunck_pos_list:
		load_chunck(p[0], p[1])

remotesync func load_chunck(chunck_pos:Vector2, chunck_data=null):
	var chunck = preload("res://scences/Chunk.gd").new()
	add_child(chunck)
	chunck.add_to_group("chunck")
	chunck.init(block_material, block_data, chunck_pos, chunck_data)

remotesync func set_block(pos:Vector3, block_name):
	var chunck_pos = BlockType.convert_to_chunck_pos(pos)
	var chunck = get_node_or_null(BlockType.make_chunck_name(chunck_pos))
	if chunck:
		chunck.set_block(pos-chunck.global_transform.origin, block_name)
#------- Signals -------------

