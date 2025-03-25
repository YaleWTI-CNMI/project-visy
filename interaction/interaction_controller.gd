class_name InteractionController
extends Node3D

@export var controller: XRController3D

@export_category("Tuning")
@export var min_drag_start_distance = 0.07 # 7cm by default


@export_category("Appearance")
@onready var _attached_node: Node3D = $AimNode/AttachedNode
@onready var _aim_node: Node3D = $AimNode
@onready var _press_initial_location = Vector3.ZERO

# ---

var _current_receiver: InteractionReceiver

@export var extent: float = 1.0:
	set(new_val):
		extent = new_val
		$RayCast3D.target_position = Vector3(0, 0, -new_val)
		_aim_node.position = Vector3(0, 0, -new_val)

func _ready() -> void:
	extent = extent
	
	controller.button_pressed.connect(_on_button_pressed)
	controller.button_released.connect(_on_button_released)
	
	return_pointer()
	pass

func is_acquire_button_pressed():
	controller.is_button_pressed("grip_click")
	return

func _process(delta: float) -> void:
	_target_switch_think() # Called when allowed to switch targets
	
	_current_receiver_think()
	
func _target_switch_think():
	var collider = $RayCast3D.get_collider()
	var collision_point = $RayCast3D.get_collision_point()
	
	if _current_receiver != collider and not is_acquire_button_pressed():
		_release_ireceiver()
	elif collider is InteractionReceiver and is_acquire_button_pressed():
		_acquire_ireceiver(collider as InteractionReceiver)

func _current_receiver_think():
	var collision_point = $RayCast3D.get_collision_point()

	if _current_receiver:
		_current_receiver.hit(self, collision_point)

func _on_button_pressed(name):
	if name == "grip_click" and _current_receiver != null:
		_current_receiver.on_acquire(self)
	
func _on_button_released(name):
	if name == "grip_click" and _current_receiver != null:
		_current_receiver.on_release(self)

func _acquire_ireceiver(ireceiver: InteractionReceiver):
	assert(_current_receiver == null, 
		"Current Receiver should be null before acquiring new ireceiver")
	
	_current_receiver = ireceiver
	_current_receiver.acquire(self)
	
	
func _release_ireceiver():
	assert(_current_receiver != null, "Current Receiver shouldn't be null")
	
	_current_receiver.release(self)
	_current_receiver = null
	
	self.return_pointer()

func grab_pointer(new_parent: Node3D, global_offset: Vector3 = Vector3.ZERO):
	_attached_node.reparent(new_parent)
	_attached_node.global_position = global_offset

func return_pointer():
	_attached_node.reparent(_aim_node)
	_attached_node.position = Vector3(0, 0, -extent)

func get_aim_node():
	return _aim_node
	
func get_attached_node():
	return _attached_node
