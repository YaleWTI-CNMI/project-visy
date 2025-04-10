class_name InteractionController
extends Node3D

@export var controller: XRController3D

@onready var _attached_node: Node3D = $AimNode/AttachedNode
@onready var _aim_node: Node3D = $AimNode
@onready var _press_initial_location = Vector3.ZERO

# ---
	
enum EventType {
	HOVER_START,
	HOVER_END,
	HOVER,
	BUTTON_PRESS,
	BUTTON_RELEASE
}

class CollisionInfo:
	var hit_location: Vector3
	var collision_shape: CollisionShape3D

class Event:
	var icontroller: InteractionController
	var type: EventType
	var collision_info: CollisionInfo
	var button_name: String
	
# ---

var _current_receiver: InteractionReceiver
var _lock_button_name: String = ""
var _last_collision_info: CollisionInfo = CollisionInfo.new()

#var event = Event.new()

@export var extent: float = 1.0:
	set(new_val):
		extent = new_val
		
		if is_node_ready():
			$RayCast3D.target_position = Vector3(0, 0, -new_val)

func _ready() -> void:
	extent = extent
	
	controller.button_pressed.connect(_on_button_pressed)
	controller.button_released.connect(_on_button_released)
	
	_aim_node.position = Vector3(0, 0, -0.1)
	
	self.return_pointer()
	pass

func _process(delta: float) -> void:
	_target_switch_think() # Called when allowed to switch targets
	
	_current_receiver_think()

	
func _target_switch_think():
	var collider: CollisionObject3D = $RayCast3D.get_collider()
	
	if $RayCast3D.is_colliding():
		_last_collision_info.hit_location = $RayCast3D.get_collision_point()
		
		var shape_id = $RayCast3D.get_collider_shape()
		var shape_owner = collider.shape_find_owner(shape_id)
		_last_collision_info.collision_shape = collider.shape_owner_get_owner(shape_owner)
	
	if collider != _current_receiver \
		 and not _is_lock_button_held():
		if _current_receiver:
			_release_ireceiver()
			
		if collider is InteractionReceiver:
			_acquire_ireceiver(collider as InteractionReceiver)

func _current_receiver_think():
	var collision_point = $RayCast3D.get_collision_point()

	if _current_receiver:
		var event = Event.new()
		event.type = EventType.HOVER
		event.icontroller = self
		event.collision_info = _last_collision_info

		_current_receiver.interaction_event(event)



func _on_button_pressed(name):
	if _current_receiver:
		var event = Event.new()
		event.type = EventType.BUTTON_PRESS
		event.icontroller = self
		event.collision_info = _last_collision_info
		event.button_name = name
		
		_current_receiver.interaction_event(event)
	
func _on_button_released(name):
	if _current_receiver:
		var event = Event.new()
		event.type = EventType.BUTTON_RELEASE
		event.icontroller = self
		event.collision_info = _last_collision_info
		event.button_name = name
		
		_current_receiver.interaction_event(event)
	

func _acquire_ireceiver(ireceiver: InteractionReceiver):	
	var collision_point = $RayCast3D.get_collision_point()
	
	assert(_current_receiver == null, 
		"Current Receiver should be null before acquiring new ireceiver")
	
	_current_receiver = ireceiver
	if "lock_button_name" in ireceiver:
		_lock_button_name = ireceiver.lock_button_name
	
	var event = Event.new()
	event.type = EventType.HOVER_START
	event.icontroller = self
	event.collision_info = _last_collision_info

	_current_receiver.interaction_event(event)
	
	
func _release_ireceiver():
	assert(_current_receiver != null, "Current Receiver shouldn't be null")
	
	var event = Event.new()
	event.type = EventType.HOVER_END
	event.icontroller = self
	event.collision_info = _last_collision_info

	_current_receiver.interaction_event(event)

	_current_receiver = null
	_lock_button_name = ""
	
	self.return_pointer()

func grab_pointer(new_parent: Node3D, global_offset: Vector3 = Vector3.ZERO):
	_attached_node.reparent(new_parent)
	_attached_node.global_position = global_offset
	$RayCast3D.get_collider_shape()

func return_pointer():
	_attached_node.reparent(_aim_node)
	_attached_node.position = Vector3(0, 0, -extent)

func _is_lock_button_held():
	return _lock_button_name != "" and controller.is_button_pressed(_lock_button_name)

func get_aim_node():
	return _aim_node
	
func get_attached_node():
	return _attached_node
