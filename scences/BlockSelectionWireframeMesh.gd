extends MeshInstance

func _ready():
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
	mesh = mesh_tool.commit()
	var mat = SpatialMaterial.new()
	mat.flags_unshaded = true
#	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	mat.params_line_width = 2
	mat.albedo_color = Color.black
	mesh.surface_set_material(0, mat)
