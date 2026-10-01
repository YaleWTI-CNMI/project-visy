extends Camera3D

signal point_selected(index: int)
var target := Vector3.ZERO
var yaw := 0.45
var pitch := 0.25
var _pressed := false
var _dragged := false
var _press_position := Vector2.ZERO

func _ready() -> void:
	reset_view()

func reset_view() -> void:
	target = Vector3.ZERO
	yaw = 0.45
	pitch = 0.25
	size = 3.0
	_update_transform()

func _update_transform() -> void:
	position = target + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 10.0
	look_at(target)

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			size = maxf(0.1, size * 0.9)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			size = minf(100.0, size * 1.1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressed = true
				_dragged = false
				_press_position = event.position
			else:
				if _pressed and not _dragged and not event.shift_pressed:
					pick_point(event.position)
				_pressed = false
	elif event is InputEventMouseMotion and _pressed:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_pressed = false
			return
		if event.position.distance_to(_press_position) > 5.0:
			_dragged = true
		if _dragged:
			if event.shift_pressed:
				target += (-basis.x * event.relative.x + basis.y * event.relative.y) * size / get_viewport().size.y
			else:
				yaw -= event.relative.x * 0.008
				pitch = clampf(pitch + event.relative.y * 0.008, -1.4, 1.4)
			_update_transform()
	elif event is InputEventMagnifyGesture:
		size = clampf(size / event.factor, 0.1, 100.0)

func pick_point(screen_position: Vector2) -> void:
	var best_distance := 10.0
	var best_set: Node3D
	var best_index := -1
	for point_set in get_tree().get_nodes_in_group("desktop_point_sets"):
		var instances: MultiMesh = point_set.get_node("MultiMeshInstance").multimesh
		for i in range(instances.instance_count):
			var world: Vector3 = point_set.to_global(instances.get_instance_transform(i).origin)
			if is_position_behind(world):
				continue
			var distance := unproject_position(world).distance_to(screen_position)
			if distance < best_distance:
				best_distance = distance
				best_set = point_set
				best_index = i
	if best_set:
		WSClient.queue_vrid_call(best_set.vrid, {"action": "point_pressed", "index": best_index})
		point_selected.emit(best_index)
