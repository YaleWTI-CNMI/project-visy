@tool
extends Node3D

@export_tool_button("Reload Preview UI") var reload_preview_ui = on_reload_preview_ui 
	
func on_reload_preview_ui():
	if ui_scene != null:
		set_content_scene(ui_scene)
	else:
		set_content_scene(preload("res://ui/test_ui.tscn"))

@export var ui_scene: PackedScene

@export var window_scale: float = 0.05:
	set(val):
		window_scale = val
		_update_window_size()

@export var size_2d: Vector2 = Vector2(500, 500):
	set(val):
		size_2d = val
		_update_window_size()

@onready var mesh_instance: MeshInstance3D
@onready var subviewport: SubViewport
@onready var canvas: CanvasLayer
@onready var interactionCollisionShape: CollisionShape3D

var current_control: Control = null

var plane_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	mesh_instance = $MeshInstance
	subviewport = $MeshInstance/SubViewport
	canvas = %CanvasLayer
	interactionCollisionShape = $InteractionReceiver/InteractionCollisionShape
	
	if ui_scene:
		set_content_scene(ui_scene)

func set_content_scene(scene: PackedScene) -> void:
	set_content(scene.instantiate())

func set_content(control: Control) -> void:
	if not is_inside_tree():
		return
	
	if current_control != null:
		current_control.queue_free()
	
	if control == null:
		return

	current_control = control
	canvas.add_child(current_control)
	
	size_2d = current_control.custom_minimum_size
	_update_window_size()


func _update_window_size() -> void:
	if not current_control:
		return
	
	var mesh = mesh_instance.mesh as PlaneMesh
	var boxShape = interactionCollisionShape.shape as BoxShape3D
	
	subviewport.size = size_2d
	subviewport.size_2d_override = size_2d
	
	var plane_scale = window_scale / min(size_2d.x, size_2d.y)
	plane_size = size_2d * plane_scale
	
	mesh.size = plane_size
	mesh.request_update()
	
	current_control.position = Vector2(0, 0)
	current_control.size = size_2d
	
	boxShape.size = Vector3(plane_size.x, plane_size.y, 0.01)
