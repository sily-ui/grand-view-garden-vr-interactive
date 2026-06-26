extends RefCounted
class_name NPCVisualBuilder

static func apply_to_npc(root: Node3D, character_name: String, palette: Dictionary = {}) -> Node3D:
	_clear_existing_visual(root)

	var visual := Node3D.new()
	visual.name = "ProceduralCharacterVisual"
	visual.visible = true
	root.add_child(visual)

	var robe_color: Color = palette.get("robe", _robe_color_for_name(character_name))
	var trim_color: Color = palette.get("trim", Color(0.86, 0.68, 0.28))
	var skin_color: Color = palette.get("skin", Color(0.86, 0.72, 0.58))
	var hair_color: Color = palette.get("hair", Color(0.08, 0.06, 0.045))
	var accent_color: Color = palette.get("accent", robe_color.lightened(0.18))

	var robe_material := _make_material(robe_color, 0.92)
	var trim_material := _make_material(trim_color, 0.78)
	var skin_material := _make_material(skin_color, 0.86)
	var hair_material := _make_material(hair_color, 0.9)
	var accent_material := _make_material(accent_color, 0.88)

	_add_cylinder(visual, "Robe", Vector3(0, 0.82, 0), 0.42, 1.45, robe_material, 18)
	_add_box(visual, "FrontPanel", Vector3(0, 0.84, -0.43), Vector3(0.22, 1.18, 0.025), accent_material)
	_add_box(visual, "WaistSash", Vector3(0, 1.04, -0.44), Vector3(0.72, 0.08, 0.035), trim_material)
	_add_sleeve(visual, "LeftSleeve", -0.48, robe_material)
	_add_sleeve(visual, "RightSleeve", 0.48, robe_material)
	_add_sphere(visual, "LeftHand", Vector3(-0.68, 0.86, -0.02), Vector3(0.13, 0.11, 0.13), skin_material, 10)
	_add_sphere(visual, "RightHand", Vector3(0.68, 0.86, -0.02), Vector3(0.13, 0.11, 0.13), skin_material, 10)
	_add_sphere(visual, "Head", Vector3(0, 1.73, 0), Vector3(0.31, 0.37, 0.31), skin_material, 18)
	_add_sphere(visual, "HairCap", Vector3(0, 1.88, -0.01), Vector3(0.32, 0.18, 0.32), hair_material, 14)
	_add_sphere(visual, "HairBun", Vector3(0, 2.08, 0.03), Vector3(0.15, 0.13, 0.15), hair_material, 12)
	_add_box(visual, "LeftEye", Vector3(-0.09, 1.75, -0.29), Vector3(0.045, 0.028, 0.018), hair_material)
	_add_box(visual, "RightEye", Vector3(0.09, 1.75, -0.29), Vector3(0.045, 0.028, 0.018), hair_material)
	_add_box(visual, "Mouth", Vector3(0, 1.63, -0.3), Vector3(0.11, 0.022, 0.018), _make_material(Color(0.42, 0.16, 0.14), 0.88))

	# 视觉创建成功后再隐藏占位体
	_hide_placeholder_mesh(root)

	return visual

static func apply_to_trigger(root: Node3D, character_name: String, offset: Vector3 = Vector3.ZERO) -> Node3D:
	var visual_anchor := Node3D.new()
	visual_anchor.name = "TriggerCharacterVisual"
	visual_anchor.position = offset
	root.add_child(visual_anchor)
	apply_to_npc(visual_anchor, character_name)
	return visual_anchor

static func _clear_existing_visual(root: Node3D) -> void:
	var existing := root.get_node_or_null("ProceduralCharacterVisual")
	if existing:
		existing.queue_free()

static func _hide_placeholder_mesh(root: Node3D) -> void:
	var body_mesh := root.get_node_or_null("BodyMesh") as MeshInstance3D
	if body_mesh:
		body_mesh.visible = false

static func _robe_color_for_name(character_name: String) -> Color:
	match character_name:
		"贾母":
			return Color(0.62, 0.42, 0.18)
		"王熙凤":
			return Color(0.72, 0.12, 0.12)
		"林黛玉":
			return Color(0.36, 0.58, 0.44)
		"贾宝玉":
			return Color(0.78, 0.42, 0.24)
		"妙玉":
			return Color(0.72, 0.72, 0.68)
		"李纨":
			return Color(0.50, 0.56, 0.38)
		"薛宝钗":
			return Color(0.68, 0.55, 0.32)
		"刘姥姥":
			return Color(0.36, 0.28, 0.18)
		"周瑞家", "引路仆妇":
			return Color(0.34, 0.38, 0.44)
		_:
			return Color(0.48, 0.38, 0.32)

static func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.vertex_color_use_as_albedo = false
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return material

static func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = position
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance

static func _add_cylinder(parent: Node3D, node_name: String, position: Vector3, radius: float, height: float, material: Material, radial_segments: int) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = position
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.82
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance

static func _add_sphere(parent: Node3D, node_name: String, position: Vector3, scale: Vector3, material: Material, segments: int) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = position
	mesh_instance.scale = scale
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = segments
	mesh.rings = max(6, floori(float(segments) / 2.0))
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance

static func _add_sleeve(parent: Node3D, node_name: String, side_offset: float, material: Material) -> void:
	var sleeve := _add_cylinder(parent, node_name, Vector3(side_offset, 1.08, 0), 0.13, 0.82, material, 12)
	sleeve.rotation_degrees.z = 18.0 * sign(side_offset)
	sleeve.rotation_degrees.x = 8.0