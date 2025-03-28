@tool
extends Node3D

@export_tool_button("Reload Preview UI") var reload_preview_ui = on_reload_preview_ui 
	
func on_reload_preview_ui():
	ui_scene = ui_scene

@export var ui_scene: PackedScene:
	set(new_val):
		ui_scene = new_val
		if Engine.is_editor_hint():
			if ui_scene:
				set_content(ui_scene.instantiate())
			else:
				set_content(preload("res://ui/test_ui.tscn").instantiate())

@export var window_scale: float = 0.05:
	set(value):
		window_scale = value
		_update_window_size()


@export var size_2d: Vector2 = Vector2(500, 500):
	set(value):
		size_2d = value
		_update_window_size()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var subviewport: SubViewport = $MeshInstance3D/SubViewport
@onready var canvas: CanvasLayer = %CanvasLayer
@onready var interactionCollisionShape: CollisionShape3D = $InteractionReceiver/InteractionCollisionShape

var current_control: Control = null

var plane_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	if ui_scene:
		set_content(ui_scene.instantiate())

	_update_window_size()

func set_content(control: Control) -> void:
	if current_control != null:
		current_control.queue_free()
	
	current_control = control
	current_control.position = Vector2(0, 0)
	
	canvas.add_child(current_control)
	_update_window_size()

func _update_window_size() -> void:
	if not self.is_node_ready():
		return
		
	var mesh = mesh_instance.mesh as PlaneMesh
	var boxShape = interactionCollisionShape.shape as BoxShape3D
	
	subviewport.size = size_2d
	subviewport.size_2d_override = size_2d
	
	var plane_scale = window_scale / min(size_2d.x, size_2d.y)
	plane_size = size_2d * plane_scale
	
	mesh.size = plane_size
	mesh.request_update()
	
	boxShape.size = Vector3(plane_size.x, plane_size.y, 0.01)
