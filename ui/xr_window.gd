extends Node3D

@export var basic_resolution: int = 3840
@export var window_size: Vector2 = Vector2(25.0/100, 40.0/100):
	set(value):
		window_size = value
		_update_window_size()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var subviewport: SubViewport = $MeshInstance3D/SubViewport
@onready var canvas: CanvasLayer = $MeshInstance3D/SubViewport/CanvasLayer
@onready var initial_control = get_node_or_null("InitialContent")

var current_control: Control = null

func _ready() -> void:
	if initial_control != null:
		initial_control.get_parent().remove_child(initial_control)
		set_content(initial_control)

	_update_window_size()

func set_content(control: Control) -> void:
	if current_control != null:
		current_control.queue_free()
	
	current_control = control
	current_control.position = Vector2(0, 0)
	
	canvas.add_child(current_control)
	_update_window_size()

func _update_window_size() -> void:
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = window_size
	plane_mesh.material = StandardMaterial3D.new()
	plane_mesh.material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA_SCISSOR
	plane_mesh.material.albedo_texture = subviewport.get_texture()
	plane_mesh.request_update()
	
	var canvas_size = basic_resolution * window_size
	
	subviewport.size = canvas_size
	mesh_instance.mesh = plane_mesh
	
	if current_control != null:
		current_control.set_size(canvas_size)
