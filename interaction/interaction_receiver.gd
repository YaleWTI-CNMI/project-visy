extends Area3D
class_name InteractionReceiver

var _icontroller: InteractionController = null

signal button_pressed(icontroller: InteractionController, name: String)
signal button_released(icontroller: InteractionController, name: String)
signal hitted(icontroller: InteractionController, interaction_point: Vector3)

func _ready():
	self.collision_layer = (1<<8)
	self.collision_mask = (1<<8)
	pass

func acquire(icontroller: InteractionController):
	pass

func hit(icontroller: InteractionController, interaction_point: Vector3):
	pass

func release(icontroller: InteractionController):
	pass

func _process(delta: float) -> void:
	pass
