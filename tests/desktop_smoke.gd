extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var client = root.get_node("WSClient")
	client.set_process(false)
	var scene = load("res://intro_scene_debug.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	client.feed_packet('{"type":"CONNECTED","data":{}}\n')
	var data := {
		"id": 1, "mods": {"frame": {"value": 62, "definition": {"type": "continuous", "range": [5, 150], "step": 1}}},
		"result": {"type": "builder", "xlim": [-1, 1], "ylim": [-1, 1], "zlim": [-1, 1], "objects": {
			"101": {"type": "point_set", "vrid": 101, "x": [0.0], "y": [0.0], "z": [0.0],
			"xlim": [-1, 1], "ylim": [-1, 1], "zlim": [-1, 1], "color": {"r": 1, "g": 0, "b": 0}, "size": 0.03}}}}
	var payload := JSON.stringify({"type": "PLOT_ADDED", "data": data}) + "\n"
	client.feed_packet(payload.substr(0, 50))
	check(scene.plots.is_empty(), "Partial messages must not render")
	client.feed_packet(payload.substr(50))
	await process_frame
	check(scene.plots.size() == 1, "Expected one displayed plot")
	check(scene.plots[1].get_parent() == scene.world, "Plot must belong to the displayed viewport")
	check(scene.get_node("Layout/Split/Inspector/ModsPanel").rows[1]["frame"].slider.value == 62, "Slider must start at Python's value")
	client.feed_packet(payload)
	check(scene.plots.size() == 1, "Replay must not duplicate plots")
	var point_set = get_nodes_in_group("desktop_point_sets")[0]
	var screen: Vector2 = scene.camera.unproject_position(point_set.global_position)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = screen
	scene.camera.handle_input(press)
	press.pressed = false
	scene.camera.handle_input(press)
	check(client.queue.size() == 1, "Desktop click should queue a selection")
	if not client.queue.is_empty():
		check(JSON.parse_string(client.queue.pop_front()).data.args.index == 0, "Selection must keep the original point index")
	press.pressed = true
	scene.camera.handle_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = screen + Vector2(20, 0)
	motion.relative = Vector2(20, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	var previous_yaw: float = scene.camera.yaw
	scene.camera.handle_input(motion)
	press.pressed = false
	press.position = motion.position
	scene.camera.handle_input(press)
	check(scene.camera.yaw != previous_yaw, "Dragging must orbit the camera")
	check(client.queue.is_empty(), "Dragging must not send a point selection")
	var scroll := InputEventMouseButton.new()
	scroll.button_index = MOUSE_BUTTON_WHEEL_UP
	scroll.pressed = true
	var previous_size: float = scene.camera.size
	scene.camera.handle_input(scroll)
	check(scene.camera.size < previous_size, "Scrolling must zoom")
	data.id = 2
	data.mods = {}
	data.result.objects["101"].x = [0.0, 0.5]
	data.result.objects["101"].y = [0.0, 0.5]
	data.result.objects["101"].z = [0.0, 0.5]
	data.result.note = "large message ".repeat(12000)
	payload = JSON.stringify({"type": "PLOT_ADDED", "data": data}) + "\n"
	for offset in range(0, payload.length(), 65536):
		client.feed_packet(payload.substr(offset, 65536))
	await process_frame
	check(scene.plots.size() == 2, "Large messages must be reassembled")
	check(point_set.get_node("MultiMeshInstance").multimesh.instance_count == 1, "Point sets must not share mutable MultiMeshes")
	client.feed_packet('{"type":"PLOT_REMOVED","data":{"id":1}}\n{"type":"PLOT_REMOVED","data":{"id":2}}\n')
	await process_frame
	check(scene.plots.is_empty(), "Clear must remove every plot")
	check(scene.get_node("Layout/Split/Inspector/ModsPanel").rows.is_empty(), "Clear must remove inspector rows")
	print("VISY_DESKTOP_SMOKE: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
