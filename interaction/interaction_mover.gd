extends InteractionReceiver
class_name InteractionMover


var lock_button_name = "trigger_click"

var _icontroller: InteractionController
var transform_offset: Transform3D
var manual_dist_offset: float = 0.0
var target_transform: Transform3D

@export var remote_path: Node3D
@export var bounds_path: Node


func _ready() -> void:
	if not remote_path:
		remote_path = self
		
	var parent = get_parent()
	self.top_level = true
	
	if not bounds_path:
		self.bounds_path = self.owner if self.owner and self.owner != get_tree().root else parent
	
	self.reparent.call_deferred(get_tree().root)
	

func interaction_event(event: InteractionController.Event):
	if _icontroller and event.icontroller != _icontroller:
		return
	
	match(event.type):
		InteractionController.EventType.HOVER_START:
			pass
		
		InteractionController.EventType.HOVER_END:
			if not _icontroller:
				self.scale = Vector3.ONE
			pass
		
		InteractionController.EventType.BUTTON_PRESS:
			if event.button_name == "trigger_click":
				_icontroller = event.icontroller
				transform_offset = _icontroller.global_transform \
											   .translated(remote_path.global_position - self.global_position) \
											   .affine_inverse() * \
									remote_path.global_transform
		
				manual_dist_offset = 0.0
				event.icontroller.grab_pointer(self, event.collision_info.hit_location)
			pass
		
		InteractionController.EventType.BUTTON_RELEASE:
			if _icontroller and event.button_name == "trigger_click":
				_icontroller.return_pointer()
				_icontroller = null
			pass
		
		InteractionController.EventType.HOVER:
			self.scale = lerp(self.scale, Vector3.ONE * 1.4,\
										 get_process_delta_time() * 50)
			pass
		
	
func _process(delta: float) -> void:
	if _icontroller:
		manual_dist_offset -= _icontroller.controller.get_vector2("primary").y * delta * 1.5
  		
		target_transform = _icontroller.global_transform \
				 						.translated(remote_path.global_position - self.global_position) \
							* transform_offset
		target_transform = target_transform \
							.translated((_icontroller.global_position - target_transform.origin).normalized() * manual_dist_offset)
		
		if _icontroller.controller.is_button_pressed("ax_button"):
			target_transform.origin = remote_path.global_transform.origin
			target_transform = target_transform \
								.looking_at(_icontroller.global_transform.origin, Vector3(0, 1, 0), true) \
								.scaled(remote_path.scale)
			target_transform.origin = remote_path.global_transform.origin


	if _icontroller or (target_transform and not target_transform.is_equal_approx(remote_path.global_transform)):
		remote_path.global_transform = lerp(remote_path.global_transform, \
											target_transform,\
							 				delta * 10)
		
	
	# Modify own transform
	if remote_path and bounds_path:
		var aabb = get_node_aabb(bounds_path)
		self.global_position = remote_path.global_position - Vector3(0, aabb.size.y, 0)
		var y = remote_path.global_transform.basis.get_euler().y
		
		self.global_transform.basis = Basis.from_euler(Vector3(0, y, 0))


func get_node_aabb(node : Node, exclude_top_level_scale: bool = true, exclude_paths: Array[Node] = [self]) -> AABB:
	var bounds : AABB = AABB()

	if node is not Node3D or node in exclude_paths:
		return AABB()
		
	# Do not include children that is queued for deletion
	if node.is_queued_for_deletion():
		return bounds

	# Get the aabb of the visual instance
	if node is VisualInstance3D:
		bounds = node.get_aabb();

	# Recurse through all children
	for child in node.get_children():
		var child_bounds : AABB = get_node_aabb(child, false)
		if bounds.size == Vector3.ZERO:
			bounds = child_bounds
		else:
			bounds = bounds.merge(child_bounds)

	if exclude_top_level_scale:
		bounds.size.x *= node.scale.x
		bounds.size.y *= node.scale.y
		bounds.size.z *= node.scale.z

	return bounds
