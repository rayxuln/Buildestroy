extends Object

class_name BlockType

enum {AIR, HALF_SOLID, SOLID}

const chunck_size = Vector3(16, 256, 16)

const CHUNCK_NAME_PREFIX = "chunck|"

static func make_chunck_name(chunck_pos:Vector2):
	chunck_pos = Vector2(ceil(chunck_pos.x), ceil(chunck_pos.y))
	return CHUNCK_NAME_PREFIX + str(chunck_pos)

static func convert_to_chunck_pos(pos:Vector3):
	return Vector2(floor(pos.x/chunck_size.x), floor(pos.z/chunck_size.z))

static func convert_to_world_pos(chunck_pos:Vector2):
	return Vector3(chunck_pos.x*chunck_size.x, 0, chunck_pos.y*chunck_size.z)
