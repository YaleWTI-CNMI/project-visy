extends Area3D
class_name InteractionReceiver

func _init():
	self.collision_layer = (1<<8)
	self.collision_mask = (1<<8)
	pass

func interaction_event(event: InteractionController.Event):
	pass
