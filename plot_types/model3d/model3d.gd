extends Node3D

@onready var mesh_inst: MeshInstance3D = $MeshInstance3D

func update_data(data: Dictionary) -> void:
	var model_mesh: Mesh = ObjParse.load_obj_from_buffer(data.result.data, {})
	if model_mesh == null or model_mesh.get_surface_count() == 0:
		push_error("VISY: received an empty molecular mesh")
		return
	mesh_inst.mesh = model_mesh
	$Label3D.text = data.result.get("caption", "")
	$Label3D.position = Vector3(0, -0.2, 0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if data.result.has("color"):
		var color: Dictionary = data.result.color
		material.albedo_color = Color(color.r, color.g, color.b)
	mesh_inst.material_override = material
	var bounds := model_mesh.get_aabb()
	var extent := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if extent > 0:
		var factor := 0.3 / extent
		mesh_inst.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * factor), -bounds.get_center() * factor)
