extends Area3D
class_name InteractionReceiver

@export var hey: String
var _icontroller: InteractionController = null

func _ready():
	self.collision_layer = (1<<8)
	self.collision_mask = (1<<8)
	
	pass

func on_press(icontroller: InteractionController, collision_point: Vector3):
	if _icontroller == null:
		_icontroller = icontroller
		_icontroller.attach_pointer(self, collision_point)


func on_release(icontroller: InteractionController):
	if _icontroller == icontroller:
		_icontroller.detach_pointer()
		_icontroller = null

func _process(delta: float) -> void:
	if _icontroller != null:
		owner.global_position = lerp(
			self.global_position,
			_icontroller.get_aim_node().global_position - _icontroller.get_attached_node().position,
			 delta * 15)
