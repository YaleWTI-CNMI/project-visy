extends InteractionReceiver
class_name InteractionMover

signal released

var _icontroller: InteractionController

@export var remote_path: Node3D

func _ready() -> void:
	if not remote_path:
		remote_path = self

func acquire(icontroller: InteractionController):
	if not _icontroller:
		_icontroller = icontroller


func hit(icontroller: InteractionController, interaction_point: Vector3):
	pass

func release(icontroller: InteractionController):
	await released
	_icontroller = null
	pass

func _process(delta: float) -> void:
	if _icontroller:
		if _icontroller.controller.is_button_pressed("trigger_click"):
			remote_path.global_transform = _icontroller.get_aim_node().global_transform.scaled_local(remote_path.global_transform.basis.get_scale())
			
		else:
			released.emit()
