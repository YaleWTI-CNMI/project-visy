extends Node3D

enum MarkShape {
	SQUARE,
	SQUARE_OUTLINE,
	CIRCLE,
	CIRCLE_OUTLINE,
	TRIANGLE,
	TRIANGLE_OUTLINE
}

var mark_shape_to_tex: Dictionary[MarkShape, String] = {
	SQUARE = "res://marks/billboard/square_mark.png",
	SQUARE_OUTLINE = "res://marks/billboard/square_outline_mark.png",
	CIRCLE = "res://marks/billboard/circle_mark.png",
	CIRCLE_OUTLINE = "res://marks/billboard/circle_outline_mark.png",
	TRIANGLE = "res://marks/billboard/triangle_mark.png",
	TRIANGLE_OUTLINE = "res://marks/billboard/triangle_outline_mark.png"
}

@onready var MMI: MultiMeshInstance3D = $MMI
@onready var shader_mat: ShaderMaterial = MMI.multimesh.mesh.surface_get_material(0)

func set_mark_shape(shape: MarkShape):
	shader_mat.set_shader_parameter("mark_texture", load(mark_shape_to_tex[shape]))

func set_global_size(size: float):
	shader_mat.set_shader_parameter("global_size", size)
