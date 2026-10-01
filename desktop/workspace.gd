extends Control

@onready var world: Node3D = %World
@onready var camera: Camera3D = %Camera3D
@onready var status: Label = %Status
var plots: Dictionary = {}
const UI_SCALES := [1.0, 1.25, 1.5]
var preferences := ConfigFile.new()

func _ready() -> void:
	preferences.load("user://desktop.cfg")
	var scale_index := clampi(int(preferences.get_value("display", "ui_scale", 1)), 0, 2)
	%UIScale.select(scale_index)
	get_window().content_scale_factor = UI_SCALES[scale_index]
	%UIScale.item_selected.connect(_set_ui_scale)
	WSClient.connected.connect(func(): status.text = "Connected · send a plot from the VISYB shell")
	WSClient.disconnected.connect(_disconnected)
	WSClient.plot_added.connect(_add_plot)
	WSClient.plot_updated.connect(_update_plot)
	WSClient.plot_removed.connect(_remove_plot)
	%View.gui_input.connect(camera.handle_input)
	%Reset.pressed.connect(_reset_camera)
	camera.point_selected.connect(func(index): status.text = "Selected point %d · waiting for Python…" % index)

func _set_ui_scale(index: int) -> void:
	get_window().content_scale_factor = UI_SCALES[index]
	preferences.set_value("display", "ui_scale", index)
	preferences.save("user://desktop.cfg")

func _add_plot(data: Dictionary) -> void:
	var id := int(data.id)
	if plots.has(id):
		_update_plot(data)
		return
	var type: String = data.result.type
	if type not in ["builder", "scatter", "model3d", "heatmap", "volume", "graph"]:
		status.text = "Unsupported plot type: " + type
		return
	var scene: PackedScene = load("res://plot_types/%s/plot.tscn" % type)
	var plot: Node3D = scene.instantiate()
	world.add_child(plot)
	plot.set_meta("id", id)
	plot.add_to_group("plots")
	# Existing scenes are scaled for hand-held VR. Use readable desktop sizes.
	plot.scale = Vector3.ONE if type != "model3d" else Vector3.ONE * 6.0
	plot.position = Vector3((plots.size() % 3) * 2.6, -(plots.size() / 3) * 2.6, 0)
	for child in plot.get_children():
		if child is InteractionReceiver:
			child.hide()
	plots[id] = plot
	plot.update_data(data)
	_style_plot(plot, type)
	_fit_camera()
	status.text = "Received %s · %d plot(s)" % [type, plots.size()]
	print("VISY_RENDERED id=%d type=%s" % [id, type])

func _update_plot(data: Dictionary) -> void:
	var id := int(data.id)
	if plots.has(id):
		plots[id].update_data(data)
		_style_plot(plots[id], data.result.type)
		status.text = "Updated plot %d" % id
		print("VISY_UPDATED id=%d" % id)

func _style_plot(plot: Node3D, type: String) -> void:
	if type == "builder":
		plot.get_node("MeshInstance3D").hide()
	for point_set in plot.find_children("*", "Node3D", true, false):
		if point_set.is_in_group("desktop_point_sets"):
			var mesh: Mesh = point_set.get_node("MultiMeshInstance").multimesh.mesh
			mesh.surface_get_material(0).set_shader_parameter("global_size", 1.0)

func _remove_plot(data: Dictionary) -> void:
	var id := int(data.id)
	if plots.has(id):
		plots[id].queue_free()
		plots.erase(id)
	status.text = "Connected · %d plot(s)" % plots.size()
	if plots.is_empty():
		camera.reset_view()

func _disconnected(_code: int) -> void:
	for plot in plots.values():
		plot.queue_free()
	plots.clear()
	status.text = "Waiting for Python · run python -m visyb"

func _reset_camera() -> void:
	camera.reset_view()
	_fit_camera()

func _fit_camera() -> void:
	if plots.size() > 1:
		var columns := mini(plots.size(), 3)
		var rows := ceili(plots.size() / 3.0)
		camera.target = Vector3(2.6 * (columns - 1) / 2.0, -2.6 * (rows - 1) / 2.0, 0)
		camera.size = maxf(4.5 if columns == 2 else 6.5, rows * 2.6 + 0.5)
		camera._update_transform()
