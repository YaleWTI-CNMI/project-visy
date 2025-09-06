extends InteractionReceiver
class_name EdgeGrabber

var graph_root: Node3D
var is_grabbed: bool = false
var grab_offset: Vector3
var grabbing_controller: InteractionController

func _ready():
	set_process(true)

func _process(delta):
	# update graph position while grabbed, regardless of hover events
	if is_grabbed and grabbing_controller:
		_update_graph_position()

func interaction_event(event: InteractionController.Event):	
	match event.type:
		InteractionController.EventType.HOVER_START:
			print("[edge grabber] hover start")
		InteractionController.EventType.HOVER_END:
			print("[edge grabber] hover end")
		InteractionController.EventType.BUTTON_PRESS:
			print("[edge grabber] button press: ", event.button_name)
			if event.button_name == "grip_click" and not is_grabbed:
				_start_graph_grab(event.icontroller)
		InteractionController.EventType.BUTTON_RELEASE:
			print("[edge grabber] button release: ", event.button_name)
			if event.button_name == "grip_click" and is_grabbed:
				_end_graph_grab()

func _start_graph_grab(controller: InteractionController):
	if not graph_root:
		return
		
		
	print("[edge grabber] start graph grab")
	is_grabbed = true
	grabbing_controller = controller
	grab_offset = graph_root.global_position - controller.global_position
	
	# maybe change colors when is grabbed
	_highlight_all_edges(true)

func _end_graph_grab():
	print("[edge grabber] end graph grab")
	is_grabbed = false
	grabbing_controller = null
	
	_highlight_all_edges(false)

func _update_graph_position():
	if grabbing_controller and graph_root:
		graph_root.global_position = grabbing_controller.global_position + grab_offset

func _highlight_all_edges(highlight: bool):
	# maybe implement something like highlight or change colors
	pass
