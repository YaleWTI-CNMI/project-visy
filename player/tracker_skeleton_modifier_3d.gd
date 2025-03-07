@tool
extends SkeletonModifier3D


@export_group("Bones")
@export_enum(" ") var trigger_bone: String
@export_enum(" ") var grip_bone: String
@export_enum(" ") var ax_bone: String
@export_enum(" ") var by_bone: String
@export_enum(" ") var menu_bone: String
@export_enum(" ") var joystick_bone: String

func input_bindings(x):
	return {
		trigger_bone: "trigger",
		grip_bone: "grip",
		ax_bone: "ax_button",
		by_bone: "by_button",
		menu_bone: "menu_button",
		joystick_bone: "primary"
	}[x]

@export_group("")
@export var tracker: XRController3D
var _is_left_hand = false

func _ready():
	if tracker.get_tracker_hand() == XRPositionalTracker.TrackerHand.TRACKER_HAND_LEFT:
		_is_left_hand = true
	else:
		_is_left_hand = false

func _validate_property(property: Dictionary) -> void:
	if property.name in ["trigger_bone", "grip_bone", "ax_bone", "by_bone", "menu_bone", "joystick_bone"]:
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if !skeleton:
		return
	
	# Simple Buttons
	for button_bone_name in [ax_bone, by_bone, menu_bone]:
		if button_bone_name == null:
			push_error("Bones not assigned");
			break;
		var button_bone = skeleton.find_bone(button_bone_name)
		if button_bone == -1: continue
		
		var pose = skeleton.get_bone_global_pose(button_bone)
		pose.origin.y -= float(tracker.is_button_pressed(input_bindings(button_bone_name))) * 0.001
		skeleton.set_bone_global_pose(button_bone, pose)
	
	# Trigger
	var trigger_bone_id = skeleton.find_bone(trigger_bone)
	if trigger_bone_id == -1: return
	var pose = skeleton.get_bone_pose(trigger_bone_id)
	var value: float = tracker.get_float(input_bindings(trigger_bone))
	
	skeleton.set_bone_pose(
		trigger_bone_id, 
		pose.rotated_local(Vector3.DOWN, value * PI / 24).rotated_local(Vector3.RIGHT, value * PI / 12)
	)
	
	# Grip
	var grip_bone_id = skeleton.find_bone(grip_bone)
	if grip_bone_id == -1: return
	pose = skeleton.get_bone_pose(grip_bone_id)
	value = tracker.get_float(input_bindings(grip_bone))
	
	skeleton.set_bone_pose(
		grip_bone_id,
		pose.rotated_local(Vector3.DOWN, (1 if _is_left_hand else -1) * value * PI / 24)
	)
	
	#Joystick
	var joystick_bone_id = skeleton.find_bone(joystick_bone)
	if joystick_bone_id == -1: return
	pose = skeleton.get_bone_rest(joystick_bone_id)
	var value_vec: Vector2 = tracker.get_vector2(input_bindings(joystick_bone))
	
	skeleton.set_bone_pose(
		joystick_bone_id,
		pose
			.rotated_local(Vector3.DOWN, PI / 4 * (1 if _is_left_hand else 0))
			.rotated_local(Vector3.RIGHT, value_vec.y / 3)
			.rotated_local(Vector3.BACK,value_vec.x / 3)
	)
