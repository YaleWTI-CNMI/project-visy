class_name InteractionController
extends Node3D

@export var controller: XRController3D

var _current_receiver: InteractionReceiver
@onready var _attached_node: Node3D = $AimNode/AttachedNode
@onready var _aim_node: Node3D = $AimNode

@export var extent: float = 1.0:
	set(new_val):
		extent = new_val
		$RayCast3D.target_position = Vector3(0, 0, -new_val)
		_aim_node.position = Vector3(0, 0, -new_val)

func _ready() -> void:
	extent = extent
	
	controller.button_pressed.connect(_on_button_pressed)
	controller.button_released.connect(_on_button_released)
	
	detach_pointer()
	pass

func _process(delta: float) -> void:
	var collider = $RayCast3D.get_collider()
	if collider is InteractionReceiver and not controller.is_button_pressed("ax_button"):
		_current_receiver = collider as InteractionReceiver
		#_aim_node.global_position = $RayCast3D.get_collision_point()
	elif not controller.is_button_pressed("ax_button"):
		if _current_receiver:
			_current_receiver.on_release(self)
			_current_receiver = null
	
		
func _on_button_pressed(name):
	if name == "ax_button" and _current_receiver != null:
		_current_receiver.on_press(self, $RayCast3D.get_collision_point())
		
	
func _on_button_released(name):
	if name == "ax_button" and _current_receiver != null:
		_current_receiver.on_release(self)

func attach_pointer(new_parent: Node3D, global_offset: Vector3 = Vector3.ZERO):
	#_attached_node.top_level = false
	_attached_node.reparent(new_parent)
	_attached_node.global_position = global_offset

func detach_pointer():
	#_attached_node.top_level = true
	_attached_node.reparent(_aim_node)
	_attached_node.position = Vector3(0, 0, -extent)

func get_aim_node():
	return _aim_node
	
func get_attached_node():
	return _attached_node
