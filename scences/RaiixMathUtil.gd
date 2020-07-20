extends Object

class_name RaiixMathUtil

static func is_in_range(x, min_x, max_x, closed = false):
	if not closed:
		return x >= min_x and x < max_x
	return x >= min_x and x <= max_x

static func is_rect_overlap(r1:Rect2, r2:Rect2):
	return (is_in_range(r1.position.x, r2.position.x, r2.end.x, true) \
			or is_in_range(r1.end.x, r2.position.x, r2.end.x, true))  \
			and (is_in_range(r1.position.y, r2.position.y, r2.end.y, true)  \
			or is_in_range(r1.end.y, r2.position.y, r2.end.y, true))
			
