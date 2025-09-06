class_name InteractiveNode
extends InteractionReceiver

@export var node_id: String
@export var plot_id: int
@export var movable: bool = true
@export var original_color: Color
@export var original_scale: Vector3

var is_grabbed: bool = false
var grab_offset: Vector3
var grabbing_controller: InteractionController
var lock_button_name: String

signal node_moved(node_id: String, plot_id: int, new_position: Vector3)

var mesh_instance: MeshInstance3D
var label: Label3D

func _ready():
	# InteractionReceiver doesn't have _ready(), so don't call super
	lock_button_name = "grip_click"
	original_scale = scale

func setup_node(node_data: Dictionary, plot_id: int):
	print("[interactive node] setting up node with data: ", node_data)
	self.node_id = str(node_data.get('id', ''))
	self.plot_id = plot_id
	self.movable = node_data.get('movable', true)
	print("[interactive node] node id: ", self.node_id, " plot ID: ", self.plot_id, " movable: ", self.movable)
	
	# add collision body
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	var node_size = max(node_data.get('size', 1.0), 0.1)  # min size
	sphere_shape.radius = node_size * 0.05
	collision_shape.shape = sphere_shape
	add_child(collision_shape)
	
	#  mesh
	mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = max(node_size * 0.05, 0.01)  # min radius
	sphere.height = sphere.radius * 2
	
	print("[interactive node] creating sphere with radius: ", sphere.radius, " height: ", sphere.height)
	
	mesh_instance.mesh = sphere
	add_child(mesh_instance)
	
	# position
	var x = node_data.get('x', 0.0) * 0.1  
	var y = node_data.get('y', 0.0) * 0.1
	var z = node_data.get('z', 0.0) * 0.1
	position = Vector3(x, y, z)
	
	# material/color
	var material = StandardMaterial3D.new()
	var color_data = node_data.get('color', {'r': 0.5, 'g': 0.5, 'b': 1.0})
	original_color = Color(color_data.get('r', 0.5), color_data.get('g', 0.5), color_data.get('b', 1.0))
	material.albedo_color = original_color
	mesh_instance.material_override = material
	
	# label
	if node_data.has('label'):
		label = Label3D.new()
		label.text = str(node_data.get('label', ''))
		label.position = Vector3(0, sphere.radius + 0.05, 0)
		label.scale = Vector3(0.1, 0.1, 0.1)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)

func interaction_event(event: InteractionController.Event):
	if not movable:
		return
		
	match event.type:
		InteractionController.EventType.HOVER_START:
			_on_hover_start(event)
		InteractionController.EventType.HOVER_END:
			_on_hover_end(event)
		InteractionController.EventType.BUTTON_PRESS:
			_on_button_press(event)
		InteractionController.EventType.BUTTON_RELEASE:
			_on_button_release(event)
		InteractionController.EventType.HOVER:
			_on_hover(event)

func _on_hover_start(event: InteractionController.Event):
	if not is_grabbed:
		# lightened node
		scale = original_scale * 1.1
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			material.albedo_color = original_color.lightened(0.3)

func _on_hover_end(event: InteractionController.Event):
	if not is_grabbed:
		# back to normal 
		scale = original_scale
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			material.albedo_color = original_color

func _on_button_press(event: InteractionController.Event):
	if event.button_name == "grip_click" and not is_grabbed:
		_start_grab(event.icontroller)

func _on_button_release(event: InteractionController.Event):
	if event.button_name == "grip_click" and is_grabbed:
		_end_grab()

func _on_hover(event: InteractionController.Event):
	if is_grabbed and grabbing_controller:
		_update_grab_position()

func _start_grab(controller: InteractionController):
	is_grabbed = true
	grabbing_controller = controller
	grab_offset = global_position - controller.global_position
	
	# visualize grab
	scale = original_scale * 1.2
	var material = mesh_instance.material_override as StandardMaterial3D
	if material:
		material.albedo_color = Color.RED
	
	print("grabbed node with id: ", node_id)

func _end_grab():
	is_grabbed = false
	grabbing_controller = null
	
	# end grab visual
	scale = original_scale
	var material = mesh_instance.material_override as StandardMaterial3D
	if material:
		material.albedo_color = original_color
	
	# signal for position update
	node_moved.emit(node_id, plot_id, global_position)
	print("released node with id: ", node_id, " at position: ", global_position)

func _update_grab_position():
	if grabbing_controller:
		global_position = grabbing_controller.global_position + grab_offset
		node_moved.emit(node_id, plot_id, global_position)

func update_position_from_server(new_position: Vector3):
	if not is_grabbed:
		global_position = new_position
