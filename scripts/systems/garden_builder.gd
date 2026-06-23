@tool
extends Node3D
class_name GardenBuilder

## 大观园场景构建器
## 程序化生成围墙、水系、新增院落、地形、外围建筑
## 在 main.gd _ready() 中实例化挂载

# ============================================================
# 材质缓存
# ============================================================
var mat_wall: StandardMaterial3D         # 青砖墙
var mat_wall_top: StandardMaterial3D     # 墙顶瓦
var mat_wood_red: StandardMaterial3D     # 红木柱
var mat_roof: StandardMaterial3D         # 灰瓦屋顶
var mat_water: StandardMaterial3D        # 水面
var mat_dirt: StandardMaterial3D         # 泥土/田地
var mat_stone: StandardMaterial3D        # 石料
var mat_brick: StandardMaterial3D        # 地砖
var mat_creek_bank: StandardMaterial3D   # 溪岸
var mat_farmland: StandardMaterial3D     # 农田
var mat_white_wall: StandardMaterial3D   # 白墙
var mat_gold: StandardMaterial3D         # 金字
var mat_shop_wall: StandardMaterial3D    # 街巷铺面墙
var mat_cloth: StandardMaterial3D        # 幌子/布棚
var mat_road_dust: StandardMaterial3D    # 街道路面

func _ready() -> void:
	if Engine.is_editor_hint():
		_build_all_immediate()
		return
	if name == "EditorGardenPreview":
		queue_free()
		return

	# 延迟一帧，让其他系统先初始化
	await get_tree().process_frame
	_clear_generated_children()
	_init_materials()
	_build_rongfu_forecourt()
	await get_tree().process_frame
	_build_perimeter_wall()
	await get_tree().process_frame
	_build_main_gate()
	await get_tree().process_frame
	_build_entrance_rockery()
	_build_qinfang_creek()
	await get_tree().process_frame
	_build_qinfang_bridge()
	_build_boat_dock()
	await get_tree().process_frame
	_build_mountain_terrain()
	await get_tree().process_frame
	_build_west_courtyards()
	await get_tree().process_frame
	_build_east_courtyards()
	await get_tree().process_frame
	_build_core_courtyard_optimization()
	await get_tree().process_frame
	_build_outer_buildings()
	# 稻香村菜畦在 _build_west_courtyards 中已构建
	_print_build_summary()

func _build_all_immediate() -> void:
	_clear_generated_children()
	_init_materials()
	_build_rongfu_forecourt()
	_build_perimeter_wall()
	_build_main_gate()
	_build_entrance_rockery()
	_build_qinfang_creek()
	_build_qinfang_bridge()
	_build_boat_dock()
	_build_mountain_terrain()
	_build_west_courtyards()
	_build_east_courtyards()
	_build_core_courtyard_optimization()
	_build_outer_buildings()

func _clear_generated_children() -> void:
	for child in get_children():
		if Engine.is_editor_hint():
			child.free()
		else:
			child.queue_free()

# ============================================================
# 材质初始化
# ============================================================
func _init_materials() -> void:
	# 青砖墙 — 灰青色
	mat_wall = StandardMaterial3D.new()
	mat_wall.albedo_color = Color(0.45, 0.42, 0.38)
	mat_wall.roughness = 0.85
	# 墙顶瓦 — 深灰
	mat_wall_top = StandardMaterial3D.new()
	mat_wall_top.albedo_color = Color(0.25, 0.23, 0.2)
	mat_wall_top.roughness = 0.7
	# 红木柱
	mat_wood_red = StandardMaterial3D.new()
	mat_wood_red.albedo_color = Color(0.6, 0.15, 0.08)
	mat_wood_red.roughness = 0.6
	# 灰瓦屋顶
	mat_roof = StandardMaterial3D.new()
	mat_roof.albedo_color = Color(0.35, 0.32, 0.28)
	mat_roof.roughness = 0.65
	# 水面 — 半透明青绿
	mat_water = StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.2, 0.5, 0.45, 0.6)
	mat_water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_water.roughness = 0.1
	mat_water.metallic = 0.3
	# 泥土
	mat_dirt = StandardMaterial3D.new()
	mat_dirt.albedo_color = Color(0.45, 0.35, 0.2)
	mat_dirt.roughness = 0.95
	# 石料
	mat_stone = StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.55, 0.52, 0.48)
	mat_stone.roughness = 0.8
	# 地砖 — 青灰色
	mat_brick = StandardMaterial3D.new()
	mat_brick.albedo_color = Color(0.38, 0.36, 0.32)
	mat_brick.roughness = 0.9
	# 溪岸
	mat_creek_bank = StandardMaterial3D.new()
	mat_creek_bank.albedo_color = Color(0.35, 0.32, 0.25)
	mat_creek_bank.roughness = 0.9
	# 农田 — 黄绿
	mat_farmland = StandardMaterial3D.new()
	mat_farmland.albedo_color = Color(0.45, 0.55, 0.2)
	mat_farmland.roughness = 0.95
	# 大观园外围白墙
	mat_white_wall = StandardMaterial3D.new()
	mat_white_wall.albedo_color = Color(0.88, 0.86, 0.78)
	mat_white_wall.roughness = 0.9
	# 匾额和门楣金色
	mat_gold = StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.86, 0.68, 0.22)
	mat_gold.roughness = 0.35
	mat_gold.emission_enabled = true
	mat_gold.emission = Color(0.45, 0.32, 0.08)
	mat_gold.emission_energy_multiplier = 0.25
	# 宁荣街铺面墙：比园墙更暗，降低“突然冒出一座园子”的割裂感
	mat_shop_wall = StandardMaterial3D.new()
	mat_shop_wall.albedo_color = Color(0.58, 0.50, 0.40)
	mat_shop_wall.roughness = 0.9
	# 幌子、布棚、行李担子
	mat_cloth = StandardMaterial3D.new()
	mat_cloth.albedo_color = Color(0.62, 0.20, 0.12)
	mat_cloth.roughness = 0.8
	# 园外土石街面
	mat_road_dust = StandardMaterial3D.new()
	mat_road_dust.albedo_color = Color(0.46, 0.40, 0.31)
	mat_road_dust.roughness = 0.96

# ============================================================
# 辅助：创建带碰撞的静态 Box 节点
# ============================================================
func _make_box(parent: Node3D, name_s: String, pos: Vector3, size: Vector3,
		material: StandardMaterial3D, add_collision: bool = true) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = name_s
	sb.position = pos
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sb.add_child(mi)
	if add_collision:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		sb.add_child(col)
	parent.add_child(sb)
	return sb

func _make_mesh(parent: Node3D, name_s: String, pos: Vector3, size: Vector3,
		material: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_s
	mi.position = pos
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = material
	parent.add_child(mi)
	return mi

func _make_cylinder(parent: Node3D, name_s: String, pos: Vector3,
		radius: float, height: float, material: StandardMaterial3D,
		add_collision: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_s
	mi.position = pos
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mi.mesh = cyl
	mi.material_override = material
	if add_collision:
		var sb := StaticBody3D.new()
		sb.name = name_s + "_Col"
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		col.shape = shape
		sb.add_child(col)
		sb.position = pos
		parent.add_child(sb)
	parent.add_child(mi)
	return mi

func _make_label(parent: Node3D, name_s: String, text: String, pos: Vector3,
		font_size: int = 28, pixel_size: float = 0.012, rot_y: float = 0.0) -> Label3D:
	var label := Label3D.new()
	label.name = name_s
	label.text = text
	label.position = pos
	label.rotation.y = rot_y
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = Color(0.88, 0.72, 0.24, 1)
	label.outline_size = 7
	label.outline_modulate = Color(0.05, 0.03, 0.01, 1)
	label.double_sided = true
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
	return label

func _make_wall_segment(parent: Node3D, name_s: String, from_pos: Vector3, to_pos: Vector3,
		height: float, thickness: float, material: StandardMaterial3D) -> StaticBody3D:
	var mid: Vector3 = (from_pos + to_pos) / 2.0
	var diff: Vector3 = to_pos - from_pos
	var wall: StaticBody3D = _make_box(parent, name_s, Vector3(mid.x, height / 2.0, mid.z),
		Vector3(thickness, height, diff.length()), material, true)
	wall.rotation.y = atan2(diff.x, diff.z)
	return wall

func _make_wall_cap_segment(parent: Node3D, name_s: String, from_pos: Vector3, to_pos: Vector3,
		height: float, thickness: float, material: StandardMaterial3D) -> MeshInstance3D:
	var mid: Vector3 = (from_pos + to_pos) / 2.0
	var diff: Vector3 = to_pos - from_pos
	var cap: MeshInstance3D = _make_mesh(parent, name_s, Vector3(mid.x, height, mid.z),
		Vector3(thickness + 0.35, 0.28, diff.length() + 0.35), material)
	cap.rotation.y = atan2(diff.x, diff.z)
	return cap

func _make_gable_roof(parent: Node3D, name_s: String, pos: Vector3,
		width: float, length: float, height: float, material: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_s
	mi.position = pos
	var vertices: Array[Vector3] = [
		Vector3(-width / 2.0, 0, -length / 2.0),
		Vector3(0, height, -length / 2.0),
		Vector3(width / 2.0, 0, -length / 2.0),
		Vector3(-width / 2.0, 0, length / 2.0),
		Vector3(0, height, length / 2.0),
		Vector3(width / 2.0, 0, length / 2.0),
	]
	var indices: Array[int] = [
		0, 3, 4, 0, 4, 1,
		1, 4, 5, 1, 5, 2,
		0, 1, 2,
		3, 5, 4,
		0, 2, 5, 0, 5, 3,
	]
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in indices:
		surface_tool.add_vertex(vertices[index])
	surface_tool.generate_normals()
	mi.mesh = surface_tool.commit()
	mi.material_override = material
	parent.add_child(mi)
	return mi

# ============================================================
# 1. 围墙系统 — 闭合白墙灰瓦高墙，设置正门、后门、侧门三处出入口
# ============================================================
func _build_perimeter_wall() -> void:
	var wall_root := Node3D.new()
	wall_root.name = "PerimeterWall"
	add_child(wall_root)

	var wall_h := 6.0    # 墙高
	var wall_t := 1.2    # 墙厚
	var cap_h := 0.3     # 墙帽高度

	# 场地范围: X ∈ [-60, 60], Z ∈ [-65, 55]
	var x_min := -60.0
	var x_max := 60.0
	var z_min := -65.0
	var z_max := 55.0

	# 北墙 (z = z_max)
	_make_box(wall_root, "Wall_North", Vector3(0, wall_h / 2.0, z_max),
		Vector3(x_max - x_min, wall_h, wall_t), mat_white_wall)
	_make_mesh(wall_root, "Wall_North_Cap", Vector3(0, wall_h + cap_h / 2.0, z_max),
		Vector3(x_max - x_min + 0.4, cap_h, wall_t + 0.4), mat_wall_top)

	# 南侧主正门墙 — 八字展开，正中留门楼和照壁空间
	var gate_half_w: float = 9.0
	var left_inner := Vector3(-gate_half_w, 0, z_min + 1.8)
	var left_outer := Vector3(-24.0, 0, z_min - 4.0)
	var right_inner := Vector3(gate_half_w, 0, z_min + 1.8)
	var right_outer := Vector3(24.0, 0, z_min - 4.0)
	_make_wall_segment(wall_root, "Wall_South_Bazi_L", left_outer, left_inner, wall_h, wall_t, mat_wall)
	_make_wall_segment(wall_root, "Wall_South_Bazi_R", right_inner, right_outer, wall_h, wall_t, mat_wall)
	_make_wall_cap_segment(wall_root, "Wall_South_Bazi_Cap_L", left_outer, left_inner, wall_h + cap_h / 2.0, wall_t, mat_wall_top)
	_make_wall_cap_segment(wall_root, "Wall_South_Bazi_Cap_R", right_inner, right_outer, wall_h + cap_h / 2.0, wall_t, mat_wall_top)
	_make_wall_segment(wall_root, "Wall_South_Left", Vector3(x_min, 0, z_min), left_outer, wall_h, wall_t, mat_wall)
	_make_wall_segment(wall_root, "Wall_South_Right", right_outer, Vector3(x_max, 0, z_min), wall_h, wall_t, mat_wall)
	_make_wall_cap_segment(wall_root, "Wall_South_Cap_L", Vector3(x_min, 0, z_min), left_outer, wall_h + cap_h / 2.0, wall_t, mat_wall_top)
	_make_wall_cap_segment(wall_root, "Wall_South_Cap_R", right_outer, Vector3(x_max, 0, z_min), wall_h + cap_h / 2.0, wall_t, mat_wall_top)

	# 东墙 (x = x_max)
	_make_box(wall_root, "Wall_East", Vector3(x_max, wall_h / 2.0, 0),
		Vector3(wall_t, wall_h, z_max - z_min), mat_white_wall)
	_make_mesh(wall_root, "Wall_East_Cap", Vector3(x_max, wall_h + cap_h / 2.0, 0),
		Vector3(wall_t + 0.4, cap_h, z_max - z_min + 0.4), mat_wall_top)

	# 西墙 (x = x_min)
	_make_box(wall_root, "Wall_West", Vector3(x_min, wall_h / 2.0, 0),
		Vector3(wall_t, wall_h, z_max - z_min), mat_white_wall)
	_make_mesh(wall_root, "Wall_West_Cap", Vector3(x_min, wall_h + cap_h / 2.0, 0),
		Vector3(wall_t + 0.4, cap_h, z_max - z_min + 0.4), mat_wall_top)

	# 内侧巡逻道 — 四面各铺一条 2m 宽地砖
	_make_mesh(wall_root, "Path_N", Vector3(0, 0.01, z_max - 2),
		Vector3(x_max - x_min - 4, 0.02, 3), mat_brick)
	_make_mesh(wall_root, "Path_S", Vector3(0, 0.01, z_min + 2),
		Vector3(x_max - x_min - 4, 0.02, 3), mat_brick)
	_make_mesh(wall_root, "Path_E", Vector3(x_max - 2, 0.01, 0),
		Vector3(3, 0.02, z_max - z_min - 4), mat_brick)
	_make_mesh(wall_root, "Path_W", Vector3(x_min + 2, 0.01, 0),
		Vector3(3, 0.02, z_max - z_min - 4), mat_brick)

	_build_perimeter_gatehouse(wall_root, "BackGate_North", Vector3(0, 0, z_max - 0.72), PI, "后 门", false)
	_build_perimeter_gatehouse(wall_root, "ServiceGate_East", Vector3(x_max - 0.72, 0, -20), -PI / 2.0, "侧 门", false)
	_build_wall_corner_towers(wall_root, x_min, x_max, z_min, z_max)
	_build_inner_boundary_reinforcement(wall_root, x_min, x_max, z_min, z_max)

func _build_wall_corner_towers(parent: Node3D, x_min: float, x_max: float, z_min: float, z_max: float) -> void:
	var corners: Array[Vector3] = [
		Vector3(x_min, 0, z_min), Vector3(x_max, 0, z_min),
		Vector3(x_min, 0, z_max), Vector3(x_max, 0, z_max),
	]
	for index: int in range(corners.size()):
		var tower := Node3D.new()
		tower.name = "CornerWatchTower_%d" % index
		tower.position = corners[index]
		parent.add_child(tower)
		_make_box(tower, "TowerBase", Vector3(0, 2.9, 0), Vector3(5.2, 5.8, 5.2), mat_white_wall, true)
		_make_mesh(tower, "TowerTileCap", Vector3(0, 6.05, 0), Vector3(5.8, 0.35, 5.8), mat_wall_top)
		_make_gable_roof(tower, "TowerRoof", Vector3(0, 6.25, 0), 6.5, 6.5, 1.0, mat_roof)

func _build_inner_boundary_reinforcement(parent: Node3D, x_min: float, x_max: float, _z_min: float, z_max: float) -> void:
	var low_h := 1.2
	var low_t := 0.55
	_make_box(parent, "EastPlayableBoundary", Vector3(x_max - 4.2, low_h / 2.0, 6),
		Vector3(low_t, low_h, 86), mat_white_wall, true)
	_make_mesh(parent, "EastPlayableBoundaryCap", Vector3(x_max - 4.2, low_h + 0.12, 6),
		Vector3(low_t + 0.25, 0.22, 86.3), mat_wall_top)
	_make_box(parent, "WestPlayableBoundary", Vector3(x_min + 4.2, low_h / 2.0, 6),
		Vector3(low_t, low_h, 86), mat_white_wall, true)
	_make_mesh(parent, "WestPlayableBoundaryCap", Vector3(x_min + 4.2, low_h + 0.12, 6),
		Vector3(low_t + 0.25, 0.22, 86.3), mat_wall_top)
	_make_box(parent, "NorthPlayableBoundary", Vector3(0, low_h / 2.0, z_max - 4.2),
		Vector3(98, low_h, low_t), mat_white_wall, true)
	_make_mesh(parent, "NorthPlayableBoundaryCap", Vector3(0, low_h + 0.12, z_max - 4.2),
		Vector3(98.3, 0.22, low_t + 0.25), mat_wall_top)

func _build_perimeter_gatehouse(parent: Node3D, name_s: String, pos: Vector3, rot_y: float,
		label_text: String, open_passage: bool) -> void:
	var gate := Node3D.new()
	gate.name = name_s
	gate.position = pos
	gate.rotation.y = rot_y
	parent.add_child(gate)

	var wall_h := 4.8
	var gap := 4.2
	_make_box(gate, "GateWall_L", Vector3(-4.1, wall_h / 2.0, 0), Vector3(2.6, wall_h, 1.0), mat_white_wall, true)
	_make_box(gate, "GateWall_R", Vector3(4.1, wall_h / 2.0, 0), Vector3(2.6, wall_h, 1.0), mat_white_wall, true)
	_make_box(gate, "GateLintel", Vector3(0, wall_h - 0.35, 0), Vector3(gap + 4.0, 0.7, 1.1), mat_white_wall, true)
	_make_mesh(gate, "GateTileCap", Vector3(0, wall_h + 0.2, 0), Vector3(gap + 4.8, 0.3, 1.45), mat_wall_top)
	_make_gable_roof(gate, "GatehouseRoof", Vector3(0, wall_h + 0.35, 0), gap + 5.2, 2.8, 0.65, mat_roof)
	if not open_passage:
		_make_box(gate, "ClosedDoor_L", Vector3(-1.05, 1.65, 0.08), Vector3(2.05, 3.3, 0.22), mat_wood_red, true)
		_make_box(gate, "ClosedDoor_R", Vector3(1.05, 1.65, 0.08), Vector3(2.05, 3.3, 0.22), mat_wood_red, true)
	var label := Label3D.new()
	label.name = "GatehousePlaque"
	label.text = label_text
	label.position = Vector3(0, 3.85, -0.62)
	label.font_size = 36
	label.pixel_size = 0.012
	label.modulate = Color(0.9, 0.72, 0.22)
	label.outline_size = 6
	label.outline_modulate = Color(0.05, 0.03, 0.01)
	label.double_sided = true
	gate.add_child(label)

# ============================================================
# 2. 正门 — 五间大门楼
# ============================================================
func _build_main_gate() -> void:
	var gate_root := Node3D.new()
	gate_root.name = "MainGate"
	gate_root.position = Vector3(0, 0, -65)
	add_child(gate_root)

	var pillar_h: float = 6.2
	var gate_w: float = 17.5
	var gate_depth: float = 4.8

	_make_box(gate_root, "OuterStoneRoad", Vector3(0, 0.035, -9.5), Vector3(15.0, 0.07, 17.0), mat_brick, true)
	_make_box(gate_root, "GateHallFloor", Vector3(0, 0.055, 0.2), Vector3(18.5, 0.11, 6.2), mat_stone, true)
	_make_box(gate_root, "InnerStoneRoad", Vector3(0, 0.035, 8.8), Vector3(12.0, 0.07, 12.0), mat_brick, true)
	for step_index in range(3):
		var step_z: float = -4.9 - float(step_index) * 0.75
		var step_y: float = 0.11 + float(step_index) * 0.13
		_make_box(gate_root, "BluestoneStep_%d" % step_index, Vector3(0, step_y, step_z), Vector3(16.5 - float(step_index) * 1.3, 0.22, 0.8), mat_stone, true)
	_make_box(gate_root, "HighThreshold", Vector3(0, 0.24, -2.35), Vector3(12.2, 0.28, 0.55), mat_stone, false)

	_make_box(gate_root, "GateBaseWall_L", Vector3(-7.25, 2.45, 0), Vector3(3.0, 4.9, gate_depth), mat_wall, true)
	_make_box(gate_root, "GateBaseWall_R", Vector3(7.25, 2.45, 0), Vector3(3.0, 4.9, gate_depth), mat_wall, true)
	_make_box(gate_root, "GateSidePier_L", Vector3(-3.2, 2.45, 0), Vector3(0.65, 4.9, gate_depth), mat_wall, true)
	_make_box(gate_root, "GateSidePier_R", Vector3(3.2, 2.45, 0), Vector3(0.65, 4.9, gate_depth), mat_wall, true)
	_make_box(gate_root, "GateLintel", Vector3(0, 5.15, 0), Vector3(gate_w, 0.9, gate_depth), mat_wall, true)

	var pillar_positions: Array[Vector3] = [
		Vector3(-8.9, pillar_h / 2.0, -2.0), Vector3(-3.8, pillar_h / 2.0, -2.0), Vector3(3.8, pillar_h / 2.0, -2.0), Vector3(8.9, pillar_h / 2.0, -2.0),
		Vector3(-8.9, pillar_h / 2.0, 2.0), Vector3(-3.8, pillar_h / 2.0, 2.0), Vector3(3.8, pillar_h / 2.0, 2.0), Vector3(8.9, pillar_h / 2.0, 2.0)
	]
	for i in range(pillar_positions.size()):
		_make_cylinder(gate_root, "GatePillar_%d" % i, pillar_positions[i], 0.22, pillar_h, mat_wood_red, false)

	_make_box(gate_root, "FrontBeam", Vector3(0, 5.8, -2.3), Vector3(gate_w + 1.2, 0.35, 0.35), mat_wood_red, false)
	_make_box(gate_root, "BackBeam", Vector3(0, 5.8, 2.3), Vector3(gate_w + 1.2, 0.35, 0.35), mat_wood_red, false)
	_make_gable_roof(gate_root, "GateMainRoof", Vector3(0, 6.55, 0), gate_w + 4.2, gate_depth + 3.2, 1.45, mat_roof)
	_make_box(gate_root, "RoofShadow", Vector3(0, 5.95, 0), Vector3(gate_w + 4.8, 0.18, gate_depth + 3.8), mat_wall_top, false)
	_make_box(gate_root, "FrontEave", Vector3(0, 5.78, -4.0), Vector3(gate_w + 5.2, 0.24, 0.45), mat_wall_top, false)
	_make_box(gate_root, "BackEave", Vector3(0, 5.78, 4.0), Vector3(gate_w + 5.2, 0.24, 0.45), mat_wall_top, false)

	var door_defs: Array[Array] = [["Door_L", -1.35, -1.0], ["Door_R", 1.35, 1.0], ["SideDoor_L", -5.35, -1.0], ["SideDoor_R", 5.35, 1.0]]
	for door_def: Array in door_defs:
		var door_name: String = door_def[0]
		var door_x: float = door_def[1]
		var door_side: float = door_def[2]
		var door_width: float = 2.5 if door_name.begins_with("Door") else 1.75
		var door_height: float = 4.55 if door_name.begins_with("Door") else 3.5
		var door: StaticBody3D = _make_box(gate_root, door_name, Vector3(door_x, door_height / 2.0 + 0.2, -2.25), Vector3(door_width, door_height, 0.28), mat_wood_red, true)
		door.set_meta("closed_rotation_y", 0.0)
		door.set_meta("open_rotation_y", deg_to_rad(70.0) * door_side)
		_make_box(gate_root, "%s_BronzeKnob" % door_name, Vector3(door_x - door_side * door_width * 0.24, 2.45, -2.43), Vector3(0.14, 0.14, 0.12), mat_gold, false)

	# 门匾
	var plaque_mi := MeshInstance3D.new()
	plaque_mi.name = "GatePlaque"
	plaque_mi.position = Vector3(0, 5.85, -4.1)
	var plaque_mesh := BoxMesh.new()
	plaque_mesh.size = Vector3(6.5, 1.1, 0.15)
	plaque_mi.mesh = plaque_mesh
	var plaque_mat := StandardMaterial3D.new()
	plaque_mat.albedo_color = Color(0.15, 0.08, 0.03)
	plaque_mi.material_override = plaque_mat
	gate_root.add_child(plaque_mi)

	# 匾额文字 (Label3D)
	var label := Label3D.new()
	label.name = "GateLabel"
	label.text = "大 观 园"
	label.position = Vector3(0, 5.85, -4.28)
	label.font_size = 60
	label.pixel_size = 0.011
	label.modulate = Color(0.85, 0.7, 0.2)
	label.outline_size = 10
	label.outline_modulate = Color(0.05, 0.025, 0.01, 1)
	label.double_sided = true
	label.no_depth_test = true
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.rotation.y = PI
	gate_root.add_child(label)
	_start_gate_auto_open(gate_root)

	_build_gate_screen_wall(gate_root)
	_build_gate_ceremonial_objects(gate_root)
	_build_simple_house(gate_root, "Gatehouse_L", Vector3(-14.0, 0, -1.0), 5.8, 3.4, 4.8)
	_build_simple_house(gate_root, "Gatehouse_R", Vector3(14.0, 0, -1.0), 5.8, 3.4, 4.8)

func _build_gate_screen_wall(gate_root: Node3D) -> void:
	var screen := Node3D.new()
	screen.name = "EntranceScreenWall"
	screen.position = Vector3(0, 0, 7.0)
	gate_root.add_child(screen)
	_make_box(screen, "ScreenWallBody_L", Vector3(-3.7, 2.25, 0), Vector3(3.1, 4.5, 0.65), mat_wall, true)
	_make_box(screen, "ScreenWallBody_R", Vector3(3.7, 2.25, 0), Vector3(3.1, 4.5, 0.65), mat_wall, true)
	_make_box(screen, "ScreenWhiteInset", Vector3(0, 2.35, -0.38), Vector3(8.8, 3.1, 0.16), mat_white_wall, false)
	_make_box(screen, "ScreenCarvedPanel", Vector3(0, 2.35, -0.5), Vector3(6.8, 2.2, 0.14), mat_stone, false)
	_make_box(screen, "ScreenLotusRelief", Vector3(0, 2.35, -0.62), Vector3(3.8, 0.75, 0.12), mat_gold, false)
	_make_box(screen, "ScreenBase_L", Vector3(-3.7, 0.22, 0), Vector3(3.1, 0.44, 1.1), mat_stone, true)
	_make_box(screen, "ScreenBase_R", Vector3(3.7, 0.22, 0), Vector3(3.1, 0.44, 1.1), mat_stone, true)
	_make_box(screen, "ScreenTileCap", Vector3(0, 4.7, 0), Vector3(11.6, 0.36, 1.25), mat_wall_top, false)
	_make_gable_roof(screen, "ScreenRoof", Vector3(0, 4.9, 0), 12.4, 1.8, 0.55, mat_roof)
	_make_box(gate_root, "ScreenLeftBypass", Vector3(-8.8, 0.035, 7.0), Vector3(4.2, 0.07, 5.5), mat_brick, true)
	_make_box(gate_root, "ScreenRightBypass", Vector3(8.8, 0.035, 7.0), Vector3(4.2, 0.07, 5.5), mat_brick, true)
	_make_label(screen, "ScreenWallTitle", "照 壁", Vector3(0, 3.85, -0.72), 34, 0.011, PI)
	_make_label(screen, "ScreenWallGuide", "请从左右石路绕行入园", Vector3(0, 1.35, -0.76), 22, 0.01, PI)
	_make_label(gate_root, "LeftBypassGuide", "左绕入园", Vector3(-8.8, 0.55, 3.8), 22, 0.011, PI)
	_make_label(gate_root, "RightBypassGuide", "右绕入园", Vector3(8.8, 0.55, 3.8), 22, 0.011, PI)

func _build_gate_ceremonial_objects(gate_root: Node3D) -> void:
	for side in [-1, 1]:
		var side_suffix: String = "L" if side < 0 else "R"
		_build_stone_lion(gate_root, "StoneLion_%s" % side_suffix, Vector3(float(side) * 8.8, 0, -6.1))
		_build_stone_horse(gate_root, "StoneHorse_%s" % side_suffix, Vector3(float(side) * 12.2, 0, -9.2), deg_to_rad(-8.0 * float(side)))
		_build_gate_stone_lantern(gate_root, "GateLantern_%s" % side_suffix, Vector3(float(side) * 6.0, 0, -7.2))
		_build_hitching_post(gate_root, Vector3(float(side) * 13.8, 0, -5.8))
		_make_box(gate_root, "MountingStone_%s" % side_suffix, Vector3(float(side) * 5.2, 0.38, -6.2), Vector3(1.5, 0.76, 1.7), mat_stone, true)
		_build_gate_bamboo_cluster(gate_root, Vector3(float(side) * 17.0, 0, 1.0))
		_build_shrub_group(gate_root, Vector3(float(side) * 16.2, 0, -5.8))
	_build_horse_yard_fence(gate_root)

func _build_stone_lion(parent: Node3D, name_s: String, pos: Vector3) -> void:
	var lion := StaticBody3D.new()
	lion.name = name_s
	lion.position = pos
	parent.add_child(lion)
	_make_box(lion, "Pedestal", Vector3(0, 0.35, 0), Vector3(1.8, 0.7, 1.8), mat_stone, true)
	_make_box(lion, "Body", Vector3(0, 1.35, 0), Vector3(1.25, 1.35, 1.05), mat_stone, false)
	_make_box(lion, "Head", Vector3(0, 2.25, -0.15), Vector3(0.95, 0.9, 0.85), mat_stone, false)
	_make_box(lion, "Mane", Vector3(0, 2.1, 0.35), Vector3(1.15, 0.7, 0.55), mat_wall_top, false)
	_make_box(lion, "ChestRelief", Vector3(0, 1.45, -0.6), Vector3(0.75, 0.45, 0.16), mat_gold, false)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 2.8, 1.8)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 1.4, 0)
	lion.add_child(col)

func _build_stone_horse(parent: Node3D, name_s: String, pos: Vector3, rot_y: float) -> void:
	var horse := Node3D.new()
	horse.name = name_s
	horse.position = pos
	horse.rotation.y = rot_y
	parent.add_child(horse)
	_make_box(horse, "Pedestal", Vector3(0, 0.28, 0), Vector3(2.6, 0.56, 1.4), mat_stone, true)
	_make_box(horse, "Body", Vector3(0, 1.25, 0), Vector3(1.9, 0.8, 0.62), mat_stone, false)
	_make_box(horse, "Neck", Vector3(0.86, 1.7, 0), Vector3(0.35, 0.85, 0.35), mat_stone, false)
	_make_box(horse, "Head", Vector3(1.16, 2.05, 0), Vector3(0.58, 0.45, 0.4), mat_stone, false)
	for x_pos in [-0.68, 0.68]:
		for z_pos in [-0.22, 0.22]:
			_make_box(horse, "Leg_%s_%s" % [str(x_pos), str(z_pos)], Vector3(x_pos, 0.72, z_pos), Vector3(0.18, 0.9, 0.18), mat_stone, false)

func _build_gate_stone_lantern(parent: Node3D, name_s: String, pos: Vector3) -> void:
	var lantern := Node3D.new()
	lantern.name = name_s
	lantern.position = pos
	parent.add_child(lantern)
	_make_cylinder(lantern, "Base", Vector3(0, 0.35, 0), 0.28, 0.7, mat_stone, true)
	_make_cylinder(lantern, "Post", Vector3(0, 1.05, 0), 0.16, 0.9, mat_stone, false)
	_make_box(lantern, "LampBox", Vector3(0, 1.65, 0), Vector3(0.78, 0.58, 0.78), mat_stone, false)
	_make_box(lantern, "WarmGlow", Vector3(0, 1.65, -0.41), Vector3(0.42, 0.3, 0.08), mat_gold, false)
	_make_gable_roof(lantern, "LanternRoof", Vector3(0, 2.05, 0), 1.1, 1.1, 0.32, mat_roof)

func _build_gate_bamboo_cluster(parent: Node3D, pos: Vector3) -> void:
	var bamboo := Node3D.new()
	bamboo.name = "GateBambooCluster"
	bamboo.position = pos
	parent.add_child(bamboo)
	for i in range(7):
		var x_pos: float = -0.9 + float(i % 3) * 0.85
		var z_pos: float = -0.6 + float(i / 3.0) * 0.65
		_make_cylinder(bamboo, "BambooStem_%d" % i, Vector3(x_pos, 1.85, z_pos), 0.045, 3.7, mat_wood_red, false)
		_make_box(bamboo, "BambooLeaf_%d" % i, Vector3(x_pos + 0.22, 3.55, z_pos), Vector3(0.65, 0.32, 0.42), mat_farmland, false)

func _build_horse_yard_fence(parent: Node3D) -> void:
	var fence := Node3D.new()
	fence.name = "HorseDismountYardFence"
	parent.add_child(fence)
	var fence_points: Array[Vector3] = [Vector3(-16.0, 0, -12.2), Vector3(-8.5, 0, -12.2), Vector3(8.5, 0, -12.2), Vector3(16.0, 0, -12.2)]
	for i in range(fence_points.size()):
		_make_cylinder(fence, "FencePost_%d" % i, fence_points[i] + Vector3(0, 0.55, 0), 0.08, 1.1, mat_wood_red, false)
	_make_box(fence, "FenceRail_L", Vector3(-12.25, 0.85, -12.2), Vector3(7.3, 0.1, 0.12), mat_wood_red, false)
	_make_box(fence, "FenceRail_R", Vector3(12.25, 0.85, -12.2), Vector3(7.3, 0.1, 0.12), mat_wood_red, false)
	_make_box(fence, "DismountYardGround", Vector3(0, 0.025, -11.8), Vector3(36.0, 0.05, 4.8), mat_dirt, true)

func _start_gate_auto_open(gate_root: Node3D) -> void:
	var timer := Timer.new()
	timer.name = "AutoOpenTimer"
	timer.wait_time = 0.25
	timer.autostart = true
	timer.timeout.connect(_update_gate_auto_open.bind(gate_root))
	gate_root.add_child(timer)

func _update_gate_auto_open(gate_root: Node3D) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return
	var distance := gate_root.global_position.distance_to(player.global_position)
	var should_open := distance <= 5.5
	if gate_root.get_meta("is_open", false) == should_open:
		return
	gate_root.set_meta("is_open", should_open)
	if should_open:
		var audio_sys: Node = get_tree().get_first_node_in_group("audio_system")
		if audio_sys and audio_sys.has_method("play_sfx"):
			audio_sys.play_sfx("gate_open")
	var tween := create_tween()
	tween.set_parallel(true)
	var door_names: Array[String] = ["Door_L", "Door_R", "SideDoor_L", "SideDoor_R"]
	for door_name: String in door_names:
		var door := gate_root.get_node_or_null(door_name) as Node3D
		if not door:
			continue
		_set_gate_door_collision(door, not should_open)
		var target: float = door.get_meta("open_rotation_y", 0.0) if should_open else door.get_meta("closed_rotation_y", 0.0)
		tween.tween_property(door, "rotation:y", target, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_gate_door_collision(door: Node3D, enabled: bool) -> void:
	for child in door.get_children():
		if child is CollisionShape3D:
			child.disabled = not enabled

# ============================================================
# 3. 正门内假山 — "曲径通幽"
# ============================================================
func _build_entrance_rockery() -> void:
	var rock_root := Node3D.new()
	rock_root.name = "EntranceRockery"
	rock_root.position = Vector3(0, 0, -55)
	add_child(rock_root)

	# 随机堆放的假山石块
	var rock_positions: Array[Vector3] = [
		Vector3(0, 1.5, 0), Vector3(-2.5, 2.2, 1), Vector3(2, 1.8, -0.5),
		Vector3(-1, 3.0, -1), Vector3(1.5, 2.8, 1.5), Vector3(-3, 1.2, -2),
		Vector3(3, 1.0, 2), Vector3(0, 3.5, 0.5), Vector3(-2, 0.8, 3),
		Vector3(2.5, 1.5, -2.5)
	]
	var rock_sizes: Array[Vector3] = [
		Vector3(3, 3, 2.5), Vector3(2.5, 4.4, 2), Vector3(2, 3.6, 3),
		Vector3(2, 6, 2.5), Vector3(2.5, 5.6, 2), Vector3(3.5, 2.4, 3),
		Vector3(2.5, 2, 2), Vector3(2, 7, 3), Vector3(3, 1.6, 2.5),
		Vector3(2, 3, 2)
	]
	for i in range(rock_positions.size()):
		var r_mi := MeshInstance3D.new()
		r_mi.name = "Rock_%d" % i
		r_mi.position = rock_positions[i]
		var r_mesh := BoxMesh.new()
		r_mesh.size = rock_sizes[i]
		r_mi.mesh = r_mesh
		r_mi.material_override = mat_stone
		rock_root.add_child(r_mi)

	# 石刻路标
	var path_label := Label3D.new()
	path_label.name = "PathSign"
	path_label.text = "曲径通幽"
	path_label.position = Vector3(0, 5.5, 2)
	path_label.font_size = 36
	path_label.modulate = Color(0.75, 0.65, 0.35)
	rock_root.add_child(path_label)

# ============================================================
# 5. 沁芳溪 — 贯穿全园南北的水系
# ============================================================
func _build_qinfang_creek() -> void:
	var creek_root := Node3D.new()
	creek_root.name = "QinfangCreek"
	add_child(creek_root)

	var creek_w := 5.0
	var creek_y := 0.05
	# 溪流主干 — 南北贯穿，略带弯曲 (分段)
	var seg_positions: Array[Vector3] = [
		Vector3(0, creek_y, -42), Vector3(1, creek_y, -25),
		Vector3(-1, creek_y, -10), Vector3(0, creek_y, 10),
		Vector3(1, creek_y, 30), Vector3(0, creek_y, 48),
	]
	var seg_sizes: Array[Vector3] = [
		Vector3(creek_w, 0.1, 12), Vector3(creek_w, 0.1, 18),
		Vector3(creek_w, 0.1, 20), Vector3(creek_w, 0.1, 20),
		Vector3(creek_w, 0.1, 20), Vector3(creek_w + 6, 0.1, 16),
	]
	for i in range(seg_positions.size()):
		_make_mesh(creek_root, "CreekSeg_%d" % i, seg_positions[i], seg_sizes[i], mat_water)

	# 溪岸 — 两侧土岸
	for i in range(seg_positions.size()):
		var s_pos: Vector3 = seg_positions[i]
		var s_size: Vector3 = seg_sizes[i]
		_make_mesh(creek_root, "Bank_L_%d" % i, Vector3(s_pos.x - s_size.x / 2.0 - 1.0, 0.02, s_pos.z),
			Vector3(2, 0.04, s_size.z), mat_creek_bank)
		_make_mesh(creek_root, "Bank_R_%d" % i, Vector3(s_pos.x + s_size.x / 2.0 + 1.0, 0.02, s_pos.z),
			Vector3(2, 0.04, s_size.z), mat_creek_bank)

	_make_label(creek_root, "CreekNameLabel", "沁芳溪", Vector3(-5.2, 1.15, -38.0), 24, 0.011, PI + deg_to_rad(10.0))
	_make_label(creek_root, "CreekHintLabel", "水道从园中穿行，请沿中轴石桥过溪", Vector3(5.2, 1.0, -34.0), 18, 0.01, PI + deg_to_rad(-12.0))

# ============================================================
# 6. 沁芳亭石桥 — 横跨沁芳溪
# ============================================================
func _build_qinfang_bridge() -> void:
	var bridge := Node3D.new()
	bridge.name = "QinfangBridge"
	bridge.position = Vector3(0, 0, -10)
	add_child(bridge)
	# 堤道宽度与桥面一致，避免视觉断口
	_make_box(bridge, "SouthStoneCauseway", Vector3(0, 0.07, -16.5), Vector3(8.0, 0.14, 12.0), mat_stone, true)
	_make_box(bridge, "NorthStoneCauseway", Vector3(0, 0.07, 12.0), Vector3(8.0, 0.14, 14.0), mat_stone, true)

	# 桥面 — 厚实连续，避免断桥感
	_make_box(bridge, "Deck", Vector3(0, 0.8, 0), Vector3(8.0, 0.5, 5.2), mat_stone, true)
	_make_box(bridge, "SouthApproachRamp", Vector3(0, 0.5, -3.4), Vector3(8.0, 0.42, 3.0), mat_stone, true)
	_make_box(bridge, "NorthApproachRamp", Vector3(0, 0.5, 3.4), Vector3(8.0, 0.42, 3.0), mat_stone, true)
	_make_box(bridge, "SouthLanding", Vector3(0, 0.12, -5.4), Vector3(8.0, 0.24, 2.0), mat_stone, true)
	_make_box(bridge, "NorthLanding", Vector3(0, 0.12, 5.4), Vector3(8.0, 0.24, 2.0), mat_stone, true)
	# 额外填充：确保堤道与桥面之间无缝衔接
	_make_box(bridge, "SouthBridgeFill", Vector3(0, 0.15, -8.0), Vector3(8.0, 0.3, 5.0), mat_stone, true)
	_make_box(bridge, "NorthBridgeFill", Vector3(0, 0.15, 8.0), Vector3(8.0, 0.3, 5.0), mat_stone, true)
	# 桥栏杆
	for side in [-1, 1]:
		for i in range(4):
			var x := -3 + i * 2
			_make_cylinder(bridge, "RailPost_%d_%d" % [side, i],
				Vector3(x, 1.5, side * 1.8), 0.08, 1.4, mat_stone, false)
		_make_box(bridge, "RailBar_%d" % side, Vector3(0, 1.8, side * 1.8),
			Vector3(8, 0.1, 0.1), mat_stone, false)

	# 桥头亭 (沁芳亭)
	var pavilion := Node3D.new()
	pavilion.name = "QinfangPavilion"
	pavilion.position = Vector3(-7, 0, 0)
	bridge.add_child(pavilion)
	_make_cylinder(pavilion, "P1", Vector3(-1.5, 2, -1.5), 0.15, 4, mat_wood_red)
	_make_cylinder(pavilion, "P2", Vector3(1.5, 2, -1.5), 0.15, 4, mat_wood_red)
	_make_cylinder(pavilion, "P3", Vector3(-1.5, 2, 1.5), 0.15, 4, mat_wood_red)
	_make_cylinder(pavilion, "P4", Vector3(1.5, 2, 1.5), 0.15, 4, mat_wood_red)
	_make_box(pavilion, "PRoof", Vector3(0, 4.5, 0), Vector3(4.5, 0.4, 4.5), mat_roof)

	# 亭名
	var label := Label3D.new()
	label.name = "BridgeLabel"
	label.text = "沁芳亭"
	label.position = Vector3(-7, 5.5, 0)
	label.rotation.y = PI
	label.font_size = 30
	label.modulate = Color(0.8, 0.65, 0.25)
	bridge.add_child(label)
	_make_label(bridge, "BridgeWayfindingLabel", "从此石桥入园", Vector3(0, 1.55, -7.2), 22, 0.01, PI)

# ============================================================
# 7. 游船码头
# ============================================================
func _build_boat_dock() -> void:
	var dock := Node3D.new()
	dock.name = "BoatDock"
	dock.position = Vector3(0, 0, 42)
	add_child(dock)

	# 木栈桥
	_make_box(dock, "DockPlank", Vector3(0, 0.3, -3), Vector3(6, 0.15, 6), mat_wood_red, true)
	# 栏杆
	for side in [-1, 1]:
		for i in range(3):
			_make_cylinder(dock, "DockRail_%d_%d" % [side, i],
				Vector3(side * 2.5, 1.0, -4.5 + i * 2), 0.05, 1.5, mat_wood_red, false)
	# 小船 (简单矩形)
	var boat_mi := MeshInstance3D.new()
	boat_mi.name = "Boat"
	boat_mi.position = Vector3(4, 0.2, -5)
	var boat_mesh := BoxMesh.new()
	boat_mesh.size = Vector3(3, 0.8, 6)
	boat_mi.mesh = boat_mesh
	var boat_mat := StandardMaterial3D.new()
	boat_mat.albedo_color = Color(0.4, 0.25, 0.1)
	boat_mi.material_override = boat_mat
	dock.add_child(boat_mi)

# ============================================================
# 8. 北侧主山 + 西北/东北山坡
# ============================================================
func _build_mountain_terrain() -> void:
	var mt_root := Node3D.new()
	mt_root.name = "MountainTerrain"
	add_child(mt_root)

	# 北侧主山脊 (用多个重叠 Box 模拟山体)
	var peak_positions: Array[Vector3] = [
		Vector3(0, 4, 50), Vector3(-15, 3, 48), Vector3(15, 3.5, 48),
		Vector3(-30, 2, 52), Vector3(30, 2.5, 52), Vector3(-45, 1.5, 50),
		Vector3(45, 1.5, 50),
	]
	var peak_sizes: Array[Vector3] = [
		Vector3(40, 8, 20), Vector3(20, 6, 15), Vector3(20, 7, 15),
		Vector3(18, 4, 12), Vector3(18, 5, 12), Vector3(15, 3, 10),
		Vector3(15, 3, 10),
	]
	for i in range(peak_positions.size()):
		var mi := MeshInstance3D.new()
		mi.name = "Peak_%d" % i
		mi.position = peak_positions[i]
		var mesh := BoxMesh.new()
		mesh.size = peak_sizes[i]
		mi.mesh = mesh
		mi.material_override = mat_dirt
		mt_root.add_child(mi)

	# 山坡绿植覆盖 (简单绿色小丘)
	var hill_positions: Array[Vector3] = [
		Vector3(-25, 1, 42), Vector3(25, 1, 42),
		Vector3(-40, 0.5, 44), Vector3(40, 0.5, 44),
	]
	var hill_sizes: Array[Vector3] = [
		Vector3(12, 2, 10), Vector3(12, 2, 10),
		Vector3(10, 1, 8), Vector3(10, 1, 8),
	]
	var hill_mat := StandardMaterial3D.new()
	hill_mat.albedo_color = Color(0.3, 0.45, 0.15)
	hill_mat.roughness = 0.95
	for i in range(hill_positions.size()):
		var mi := MeshInstance3D.new()
		mi.name = "Hill_%d" % i
		mi.position = hill_positions[i]
		var mesh := BoxMesh.new()
		mesh.size = hill_sizes[i]
		mi.mesh = mesh
		mi.material_override = hill_mat
		mt_root.add_child(mi)

# ============================================================
# 9. 西片区院落群 (潇湘馆已存在, 新增: 秋爽斋、紫菱洲、完善稻香村菜畦)
# ============================================================
func _build_west_courtyards() -> void:
	var west_root := Node3D.new()
	west_root.name = "WestCourtyards"
	add_child(west_root)

	# --- 秋爽斋 (探春居所) ---
	_build_courtyard(west_root, "QiushuangZhai", Vector3(-40, 0, -5),
		"秋爽斋", "探春", Color(0.5, 0.3, 0.1))

	# --- 紫菱洲 (迎春居所) — 沁芳溪西侧临水洲岛 ---
	_build_courtyard(west_root, "Zilingzhou", Vector3(-25, 0, 20),
		"紫菱洲", "迎春", Color(0.45, 0.35, 0.5))

	# 紫菱洲临水码头
	_make_box(west_root, "ZilingDock", Vector3(-20, 0.3, 20),
		Vector3(4, 0.15, 5), mat_wood_red, true)

	# --- 稻香村菜畦 (李纨居所旁) ---
	_build_farm_plots(west_root, Vector3(-25, 0, -25))

	# --- 蘅芜苑院墙完善 (已存在，补围墙) ---
	_build_courtyard_wall(west_root, "HengwuWall", Vector3(25, 0, -15), 18, 16)

	# 西片区连接游廊 (潇湘馆 → 秋爽斋 → 紫菱洲)
	# === 连通性修复: WestCorridor起点延伸至西侧主干道(WestBluestone Z=10) ===
	_build_corridor(west_root, "WestCorridor",
		Vector3(-37, 0, 10), Vector3(-32, 0, -5), 3.0)
	_build_corridor(west_root, "WestCorridor2",
		Vector3(-32, 0, -5), Vector3(-27, 0, 20), 3.0)
	# === 连通性修复: 潇湘馆南花门入户石板小径 ===
	_make_mesh(west_root, "XiaoxiangApproachPath",
		Vector3(-35, 0.14, 16), Vector3(3.0, 0.06, 12), mat_stone)

# ============================================================
# 10. 东片区院落群 (怡红院已存在, 新增: 缀锦阁, 完善栊翠庵)
# ============================================================
func _build_east_courtyards() -> void:
	var east_root := Node3D.new()
	east_root.name = "EastCourtyards"
	add_child(east_root)

	# --- 缀锦阁 (公共宴会建筑) ---
	_build_courtyard(east_root, "Zhuijinge", Vector3(40, 0, 25),
		"缀锦阁", "", Color(0.55, 0.35, 0.15))

	# --- 栊翠庵禅院围合完善 (已存在建筑，补围墙和庭院) ---
	_build_courtyard_wall(east_root, "LongcuiWall", Vector3(0, 0, 40), 16, 14)
	# 禅院小径
	_make_mesh(east_root, "LongcuiPath", Vector3(0, 0.02, 35),
		Vector3(2, 0.04, 10), mat_stone)

	# 东片区连接游廊 (怡红院花门 → 缀锦阁西月洞门)
	_build_corridor(east_root, "EastCorridor",
		Vector3(35, 0, 21), Vector3(29, 0, 25), 3.0)
	# === 连通性修复: 打通东片区断路 (EastLakeVeranda终点→EastCorridor起点) ===
	_build_corridor(east_root, "EastLinkVeranda",
		Vector3(31, 0, 18), Vector3(35, 0, 21), 3.0)

# ============================================================
# 11. 外围建筑
# ============================================================
func _build_outer_buildings() -> void:
	var outer := Node3D.new()
	outer.name = "OuterBuildings"
	add_child(outer)

	_build_outer_street_market(outer)

	# --- 南侧贾府民居 (围墙外) ---
	for i in range(5):
		var x := -20 + i * 10
		_build_simple_house(outer, "FolkHouse_%d" % i, Vector3(x, 0, -75), 8, 4, 6)

	# --- 东侧府邸建筑 ---
	for i in range(3):
		var z := -10 + i * 15
		_build_simple_house(outer, "EastManor_%d" % i, Vector3(75, 0, z), 12, 5, 10)

	# --- 西侧府邸建筑 ---
	for i in range(3):
		var z := -10 + i * 15
		_build_simple_house(outer, "WestManor_%d" % i, Vector3(-75, 0, z), 12, 5, 10)

	# --- 北侧山林农田 ---
	var farm_mat := StandardMaterial3D.new()
	farm_mat.albedo_color = Color(0.5, 0.6, 0.25)
	farm_mat.roughness = 0.95
	for i in range(6):
		var x := -40 + i * 16
		_make_mesh(outer, "NorthFarm_%d" % i, Vector3(x, 0.02, 65),
			Vector3(14, 0.04, 10), farm_mat)

func _build_outer_street_market(parent: Node3D) -> void:
	var street := Node3D.new()
	street.name = "NingrongStreetMarket"
	parent.add_child(street)

	_make_box(street, "NingrongMainStreet", Vector3(0, 0.018, -107.0), Vector3(94.0, 0.04, 12.0), mat_road_dust, true)
	_make_box(street, "GardenApproachCauseway", Vector3(0, 0.02, -95.0), Vector3(11.0, 0.04, 26.0), mat_stone, true)
	_make_box(street, "StreetDustWest", Vector3(-55.0, 0.012, -101.5), Vector3(20.0, 0.025, 22.0), mat_road_dust, true)
	_make_box(street, "StreetDustEast", Vector3(55.0, 0.012, -101.5), Vector3(20.0, 0.025, 22.0), mat_road_dust, true)

	var shop_specs: Array[Dictionary] = [
		{"name": "TeaShop", "label": "茶肆", "pos": Vector3(-42, 0, -113), "w": 10.0, "d": 6.0, "rot": 0.0},
		{"name": "SilkShop", "label": "绸缎", "pos": Vector3(-27, 0, -113), "w": 11.0, "d": 6.5, "rot": 0.0},
		{"name": "BookShop", "label": "书坊", "pos": Vector3(-12, 0, -113), "w": 9.0, "d": 5.8, "rot": 0.0},
		{"name": "WineShop", "label": "酒旗", "pos": Vector3(14, 0, -113), "w": 9.5, "d": 6.0, "rot": 0.0},
		{"name": "PorcelainShop", "label": "瓷器", "pos": Vector3(29, 0, -113), "w": 10.5, "d": 6.2, "rot": 0.0},
		{"name": "GrainShop", "label": "米铺", "pos": Vector3(44, 0, -113), "w": 10.0, "d": 6.0, "rot": 0.0},
		{"name": "WestVendorRow", "label": "杂货", "pos": Vector3(-55, 0, -100), "w": 8.0, "d": 5.0, "rot": PI / 2.0},
		{"name": "EastVendorRow", "label": "果品", "pos": Vector3(55, 0, -100), "w": 8.0, "d": 5.0, "rot": -PI / 2.0},
	]
	for spec: Dictionary in shop_specs:
		_build_market_shop(street, String(spec["name"]), String(spec["label"]), spec["pos"], spec["w"], spec["d"], spec["rot"])

	for i in range(7):
		var x_pos := -36.0 + float(i) * 12.0
		_build_market_stall(street, "StreetStall_%d" % i, Vector3(x_pos, 0, -101.0 + float(i % 2) * 2.0))

	_build_carriage(street, "StreetCarriageWestbound", Vector3(-22.0, 0.0, -105.0), deg_to_rad(4.0))
	_build_carriage(street, "StreetCarriageEastbound", Vector3(32.0, 0.0, -108.0), deg_to_rad(184.0))
	_build_horse(street, "StreetHorseWest", Vector3(-17.0, 0.0, -105.0), deg_to_rad(88.0))
	_build_horse(street, "StreetHorseEast", Vector3(27.0, 0.0, -108.0), deg_to_rad(-92.0))
	for i in range(10):
		var px := -45.0 + float(i) * 10.0
		var pz := -103.0 + float(i % 3) * 2.2
		_build_street_figure(street, "StreetFigure_%d" % i, Vector3(px, 0, pz), deg_to_rad(80.0 + float(i % 2) * 180.0))
	_build_porter_pair(street, Vector3(-6.0, 0.0, -104.0))
	_build_porter_pair(street, Vector3(48.0, 0.0, -105.5))
	_build_street_banner(street, "NingrongStreetSign", "宁 荣 街", Vector3(0, 3.2, -101.0), 0.0)

func _build_market_shop(parent: Node3D, name_s: String, label_text: String, pos: Vector3,
		w: float, d: float, rot_y: float) -> void:
	var shop := Node3D.new()
	shop.name = name_s
	shop.position = pos
	shop.rotation.y = rot_y
	parent.add_child(shop)

	_make_box(shop, "Wall", Vector3(0, 2.05, 0), Vector3(w, 4.1, d), mat_shop_wall, true)
	_make_gable_roof(shop, "Roof", Vector3(0, 4.25, 0), w + 1.5, d + 1.2, 0.85, mat_roof)
	_make_box(shop, "ShopFront", Vector3(0, 1.75, d / 2.0 + 0.06), Vector3(w - 1.2, 2.1, 0.16), mat_wood_red, false)
	_make_box(shop, "Counter", Vector3(0, 0.85, d / 2.0 + 0.45), Vector3(w - 2.0, 0.7, 0.85), mat_wood_red, false)
	_make_box(shop, "Awning", Vector3(0, 3.15, d / 2.0 + 0.65), Vector3(w + 0.7, 0.14, 1.45), mat_cloth, false)
	for side in [-1.0, 1.0]:
		var side_name := "L" if side < 0.0 else "R"
		_make_cylinder(shop, "AwningPole_%s" % side_name, Vector3(side * (w / 2.0 - 0.55), 1.6, d / 2.0 + 1.0), 0.06, 3.0, mat_wood_red, false)
	_make_label(shop, "ShopSign", label_text, Vector3(0, 3.55, d / 2.0 + 0.22), 24, 0.01, PI)
	_build_street_banner(shop, "ShopBanner", label_text, Vector3(w / 2.0 - 0.75, 2.35, d / 2.0 + 0.95), PI)

func _build_market_stall(parent: Node3D, name_s: String, pos: Vector3) -> void:
	var stall := Node3D.new()
	stall.name = name_s
	stall.position = pos
	parent.add_child(stall)
	_make_box(stall, "Table", Vector3(0, 0.65, 0), Vector3(3.2, 0.35, 1.4), mat_wood_red, false)
	_make_box(stall, "Canopy", Vector3(0, 2.15, 0), Vector3(3.8, 0.16, 2.0), mat_cloth, false)
	for x_pos in [-1.55, 1.55]:
		for z_pos in [-0.65, 0.65]:
			_make_cylinder(stall, "Pole_%s_%s" % [str(x_pos), str(z_pos)], Vector3(x_pos, 1.15, z_pos), 0.045, 2.2, mat_wood_red, false)
	for i in range(4):
		_make_box(stall, "Goods_%d" % i, Vector3(-1.15 + float(i) * 0.75, 1.0, -0.15 + float(i % 2) * 0.35), Vector3(0.48, 0.32, 0.36), mat_farmland if i % 2 == 0 else mat_gold, false)

func _build_street_figure(parent: Node3D, name_s: String, pos: Vector3, rot_y: float) -> void:
	var figure := Node3D.new()
	figure.name = name_s
	figure.position = pos
	figure.rotation.y = rot_y
	parent.add_child(figure)
	_make_cylinder(figure, "Body", Vector3(0, 0.95, 0), 0.22, 1.25, mat_cloth, false)
	_make_cylinder(figure, "Head", Vector3(0, 1.72, 0), 0.18, 0.25, mat_stone, false)
	_make_box(figure, "Sleeve_L", Vector3(-0.28, 1.12, 0), Vector3(0.16, 0.6, 0.16), mat_cloth, false)
	_make_box(figure, "Sleeve_R", Vector3(0.28, 1.12, 0), Vector3(0.16, 0.6, 0.16), mat_cloth, false)

func _build_porter_pair(parent: Node3D, pos: Vector3) -> void:
	var porter := Node3D.new()
	porter.name = "PorterPair"
	porter.position = pos
	parent.add_child(porter)
	_build_street_figure(porter, "PorterFront", Vector3(-0.7, 0, 0), PI / 2.0)
	_build_street_figure(porter, "PorterBack", Vector3(0.7, 0, 0), PI / 2.0)
	_make_box(porter, "ShoulderPole", Vector3(0, 1.55, 0), Vector3(2.3, 0.08, 0.08), mat_wood_red, false)
	_make_box(porter, "Basket_L", Vector3(-1.35, 0.95, 0), Vector3(0.55, 0.55, 0.55), mat_dirt, false)
	_make_box(porter, "Basket_R", Vector3(1.35, 0.95, 0), Vector3(0.55, 0.55, 0.55), mat_dirt, false)

func _build_street_banner(parent: Node3D, name_s: String, text: String, pos: Vector3, rot_y: float) -> void:
	var banner := Node3D.new()
	banner.name = name_s
	banner.position = pos
	banner.rotation.y = rot_y
	parent.add_child(banner)
	_make_cylinder(banner, "Pole", Vector3(0, -1.0, 0), 0.045, 2.5, mat_wood_red, false)
	_make_box(banner, "Cloth", Vector3(0.35, 0.15, 0), Vector3(0.7, 1.2, 0.06), mat_cloth, false)
	_make_label(banner, "Text", text, Vector3(0.36, 0.15, -0.045), 18, 0.008, 0.0)

func _build_rongfu_forecourt() -> void:
	var forecourt := Node3D.new()
	forecourt.name = "RongfuForecourt"
	add_child(forecourt)

	_make_box(forecourt, "OuterApproachRoad", Vector3(0, 0.025, -76.5), Vector3(7.0, 0.05, 27.0), mat_stone, true)
	_make_box(forecourt, "GardenGateApproach", Vector3(0, 0.025, -60.0), Vector3(6.0, 0.05, 10.0), mat_stone, true)
	_make_box(forecourt, "RongfuFrontCourt", Vector3(0, 0.025, -86.0), Vector3(28.0, 0.05, 12.0), mat_brick, true)
	_make_box(forecourt, "RongfuSideCourt_L", Vector3(-18.0, 0.025, -84.0), Vector3(8.0, 0.05, 10.0), mat_brick, true)
	_make_box(forecourt, "RongfuSideCourt_R", Vector3(18.0, 0.025, -84.0), Vector3(8.0, 0.05, 10.0), mat_brick, true)

	_build_simple_house(forecourt, "RongfuGatehouse_L", Vector3(-18, 0, -88), 10, 4.5, 8)
	_build_simple_house(forecourt, "RongfuGatehouse_R", Vector3(18, 0, -88), 10, 4.5, 8)
	_build_simple_house(forecourt, "RongfuSideHall_L", Vector3(-32, 0, -80), 12, 4.2, 9)
	_build_simple_house(forecourt, "RongfuSideHall_R", Vector3(32, 0, -80), 12, 4.2, 9)
	_build_forecourt_traffic(forecourt)

	_make_box(forecourt, "OuterWall_L", Vector3(-17.5, 2.2, -94), Vector3(35.0, 4.4, 0.8), mat_white_wall, true)
	_make_box(forecourt, "OuterWall_R", Vector3(17.5, 2.2, -94), Vector3(35.0, 4.4, 0.8), mat_white_wall, true)
	_make_mesh(forecourt, "OuterWallCap_L", Vector3(-17.5, 4.5, -94), Vector3(35.4, 0.25, 1.1), mat_wall_top)
	_make_mesh(forecourt, "OuterWallCap_R", Vector3(17.5, 4.5, -94), Vector3(35.4, 0.25, 1.1), mat_wall_top)

	var label := Label3D.new()
	label.name = "RongfuLabel"
	label.text = "荣 国 府"
	label.position = Vector3(0, 5.2, -94.5)
	label.rotation.y = PI
	label.font_size = 48
	label.modulate = Color(0.85, 0.7, 0.2)
	label.outline_size = 8
	label.outline_modulate = Color(0.05, 0.03, 0.01, 1)
	label.double_sided = true
	label.no_depth_test = true
	forecourt.add_child(label)

func _build_forecourt_traffic(parent: Node3D) -> void:
	var traffic := Node3D.new()
	traffic.name = "ForecourtTraffic"
	parent.add_child(traffic)

	_build_carriage(traffic, "CarriageWaiting", Vector3(-8.0, 0.0, -82.0), deg_to_rad(8.0))
	_build_carriage(traffic, "CarriageArriving", Vector3(7.5, 0.0, -89.0), deg_to_rad(-5.0))
	_build_horse(traffic, "HorseLeft", Vector3(-3.0, 0.0, -82.0), deg_to_rad(86.0))
	_build_horse(traffic, "HorseRight", Vector3(12.5, 0.0, -89.0), deg_to_rad(94.0))
	_build_hitching_post(traffic, Vector3(-13.0, 0.0, -80.0))
	_build_hitching_post(traffic, Vector3(14.5, 0.0, -86.5))
	_make_box(traffic, "PorterBundle_L", Vector3(-11.5, 0.35, -78.8), Vector3(1.2, 0.7, 0.9), mat_wood_red, false)
	_make_box(traffic, "PorterBundle_R", Vector3(11.0, 0.35, -86.0), Vector3(1.0, 0.7, 0.8), mat_wood_red, false)

func _build_carriage(parent: Node3D, name_s: String, pos: Vector3, rot_y: float) -> void:
	var carriage := Node3D.new()
	carriage.name = name_s
	carriage.position = pos
	carriage.rotation.y = rot_y
	parent.add_child(carriage)

	_make_box(carriage, "Cabin", Vector3(0, 1.35, 0), Vector3(3.2, 1.8, 2.2), mat_wood_red, false)
	_make_box(carriage, "Roof", Vector3(0, 2.35, 0), Vector3(3.6, 0.35, 2.5), mat_roof, false)
	_make_box(carriage, "Shaft_L", Vector3(2.7, 0.75, -0.55), Vector3(2.4, 0.12, 0.12), mat_wood_red, false)
	_make_box(carriage, "Shaft_R", Vector3(2.7, 0.75, 0.55), Vector3(2.4, 0.12, 0.12), mat_wood_red, false)
	for side in [-1, 1]:
		var wheel_front := _make_cylinder(carriage, "Wheel_F_%d" % side, Vector3(1.15, 0.65, side * 1.25), 0.45, 0.16, mat_stone, false)
		wheel_front.rotation.x = PI / 2.0
		var wheel_back := _make_cylinder(carriage, "Wheel_B_%d" % side, Vector3(-1.15, 0.65, side * 1.25), 0.45, 0.16, mat_stone, false)
		wheel_back.rotation.x = PI / 2.0

func _build_horse(parent: Node3D, name_s: String, pos: Vector3, rot_y: float) -> void:
	var horse := Node3D.new()
	horse.name = name_s
	horse.position = pos
	horse.rotation.y = rot_y
	parent.add_child(horse)

	_make_box(horse, "Body", Vector3(0, 1.15, 0), Vector3(1.8, 0.75, 0.55), mat_dirt, false)
	_make_box(horse, "Neck", Vector3(0.95, 1.55, 0), Vector3(0.35, 0.8, 0.35), mat_dirt, false)
	_make_box(horse, "Head", Vector3(1.25, 1.95, 0), Vector3(0.55, 0.45, 0.38), mat_dirt, false)
	_make_box(horse, "Tail", Vector3(-1.0, 1.35, 0), Vector3(0.45, 0.18, 0.18), mat_wall_top, false)
	for x in [-0.65, 0.65]:
		for z in [-0.2, 0.2]:
			_make_box(horse, "Leg_%s_%s" % [str(x), str(z)], Vector3(x, 0.5, z), Vector3(0.16, 0.95, 0.16), mat_dirt, false)

func _build_hitching_post(parent: Node3D, pos: Vector3) -> void:
	var post := Node3D.new()
	post.name = "HitchingPost"
	post.position = pos
	parent.add_child(post)
	_make_cylinder(post, "Post_L", Vector3(-0.6, 0.7, 0), 0.08, 1.4, mat_wood_red, false)
	_make_cylinder(post, "Post_R", Vector3(0.6, 0.7, 0), 0.08, 1.4, mat_wood_red, false)
	_make_box(post, "Rail", Vector3(0, 1.2, 0), Vector3(1.4, 0.12, 0.12), mat_wood_red, false)

# ============================================================
# 12. 稻香村菜畦
# ============================================================
func _build_farm_plots(parent: Node3D, base_pos: Vector3) -> void:
	var farm_root := Node3D.new()
	farm_root.name = "DaoxiangFarm"
	farm_root.position = base_pos
	parent.add_child(farm_root)

	# 6块菜畦
	for row in range(2):
		for col in range(3):
			var x := -8 + col * 8
			var z := -5 + row * 6
			# 田埂
			var plot_mat := StandardMaterial3D.new()
			plot_mat.albedo_color = Color(0.4 + row * 0.05, 0.5 + col * 0.03, 0.2)
			plot_mat.roughness = 0.95
			_make_mesh(farm_root, "Plot_%d_%d" % [row, col], Vector3(x, 0.05, z),
				Vector3(6, 0.1, 4), plot_mat)
			# 田垄 (凸起线条)
			_make_mesh(farm_root, "Ridge_%d_%d" % [row, col], Vector3(x, 0.12, z),
				Vector3(6, 0.08, 0.3), mat_dirt)

	# 篱笆
	for side in [-1, 1]:
		for i in range(7):
			var x := -12 + i * 4
			_make_cylinder(farm_root, "FencePost_%d_%d" % [side, i],
				Vector3(x, 0.5, side * 8), 0.05, 1.0, mat_wood_red, false)
		_make_box(farm_root, "FenceRail_%d" % side, Vector3(0, 0.7, side * 8),
			Vector3(28, 0.08, 0.08), mat_wood_red, false)

# ============================================================
# 辅助：单个中式民居
# ============================================================
func _build_simple_house(parent: Node3D, name_s: String, pos: Vector3,
		w: float, h: float, d: float) -> void:
	var house := Node3D.new()
	house.name = name_s
	house.position = pos
	parent.add_child(house)
	# 墙体
	_make_box(house, "Wall", Vector3(0, h / 2.0, 0), Vector3(w, h, d), mat_wall, true)
	# 屋顶
	_make_box(house, "Roof", Vector3(0, h + 0.6, 0), Vector3(w + 2, 0.8, d + 1.5), mat_roof, false)
	# 门
	_make_box(house, "Door", Vector3(0, 1.5, d / 2.0 + 0.05), Vector3(2, 3, 0.15), mat_wood_red, false)

# ============================================================
# 辅助：院落围合墙
# ============================================================
func _build_courtyard(parent: Node3D, name_s: String, pos: Vector3,
		display_name: String, _character: String, roof_color: Color) -> void:
	var cy := Node3D.new()
	cy.name = name_s
	cy.position = pos
	parent.add_child(cy)

	var w := 16.0
	var d := 14.0
	var wall_h := 3.5
	var wall_t := 0.6

	# 四面院墙 (留南面正门缺口 4m)
	# 北
	_make_box(cy, "Wall_N", Vector3(0, wall_h / 2.0, -d / 2.0),
		Vector3(w, wall_h, wall_t), mat_wall, true)
	# 南左
	_make_box(cy, "Wall_SL", Vector3(-w / 2.0 + 3, wall_h / 2.0, d / 2.0),
		Vector3(w - 8, wall_h, wall_t), mat_wall, true)
	# 南右
	_make_box(cy, "Wall_SR", Vector3(w / 2.0 - 3, wall_h / 2.0, d / 2.0),
		Vector3(w - 8, wall_h, wall_t), mat_wall, true)
	# 东
	_make_box(cy, "Wall_E", Vector3(w / 2.0, wall_h / 2.0, 0),
		Vector3(wall_t, wall_h, d), mat_wall, true)
	# 西
	_make_box(cy, "Wall_W", Vector3(-w / 2.0, wall_h / 2.0, 0),
		Vector3(wall_t, wall_h, d), mat_wall, true)

	# 院内主建筑 (小号)
	var bldg_h := 4.0
	var bldg_w := 10.0
	var bldg_d := 8.0
	_make_box(cy, "House", Vector3(0, bldg_h / 2.0, -1), Vector3(bldg_w, bldg_h, bldg_d), mat_wall, true)
	# 屋顶
	var roof_mi := MeshInstance3D.new()
	roof_mi.name = "Roof"
	roof_mi.position = Vector3(0, bldg_h + 0.5, -1)
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(bldg_w + 2, 0.6, bldg_d + 1.5)
	roof_mi.mesh = roof_mesh
	var roof_mat := mat_roof.duplicate()
	roof_mat.albedo_color = roof_color
	roof_mi.material_override = roof_mat
	cy.add_child(roof_mi)

	# 两根前柱
	_make_cylinder(cy, "Pillar_L", Vector3(-3, 2.5, bldg_d / 2.0 - 1), 0.15, 5, mat_wood_red, false)
	_make_cylinder(cy, "Pillar_R", Vector3(3, 2.5, bldg_d / 2.0 - 1), 0.15, 5, mat_wood_red, false)

	# 庭院铺砖
	_make_mesh(cy, "CourtyardFloor", Vector3(0, 0.02, bldg_d / 2.0 + 2),
		Vector3(w - 2, 0.04, 4), mat_brick)

	# 门洞月门
	_make_cylinder(cy, "MoonGate", Vector3(0, 2, d / 2.0 - 0.3), 1.5, 4, mat_stone, false)

	# 匾额
	if display_name != "":
		_make_label(cy, "NameLabel", display_name, Vector3(0, bldg_h + 1.5, bldg_d / 2.0), 30, 0.011)

# ============================================================
# 辅助：院落纯围墙 (补充已有建筑)
# ============================================================
func _build_courtyard_wall(parent: Node3D, name_s: String, pos: Vector3,
		w: float, d: float) -> void:
	var cw := Node3D.new()
	cw.name = name_s
	cw.position = pos
	parent.add_child(cw)

	var wall_h := 3.5
	var wall_t := 0.6
	# 四面院墙，南面留门
	_make_box(cw, "Wall_N", Vector3(0, wall_h / 2.0, -d / 2.0),
		Vector3(w, wall_h, wall_t), mat_wall, true)
	_make_box(cw, "Wall_SL", Vector3(-w / 2.0 + 3, wall_h / 2.0, d / 2.0),
		Vector3(w - 8, wall_h, wall_t), mat_wall, true)
	_make_box(cw, "Wall_SR", Vector3(w / 2.0 - 3, wall_h / 2.0, d / 2.0),
		Vector3(w - 8, wall_h, wall_t), mat_wall, true)
	_make_box(cw, "Wall_E", Vector3(w / 2.0, wall_h / 2.0, 0),
		Vector3(wall_t, wall_h, d), mat_wall, true)
	_make_box(cw, "Wall_W", Vector3(-w / 2.0, wall_h / 2.0, 0),
		Vector3(wall_t, wall_h, d), mat_wall, true)

# ============================================================
# 辅助：游廊
# gap_center: 在游廊局部坐标 z 方向留出通道口的中心位置（默认0=中间）
# gap_width: 通道口宽度（0=不留口）
# ============================================================
func _build_corridor(parent: Node3D, name_s: String, from: Vector3, to: Vector3, width: float,
		gap_center: float = 0.0, gap_width: float = 0.0) -> void:
	var cr := Node3D.new()
	cr.name = name_s
	cr.position = (from + to) / 2.0
	parent.add_child(cr)

	var diff: Vector3 = to - from
	var length: float = diff.length()
	var angle: float = atan2(diff.x, diff.z)
	cr.rotation.y = angle

	var roof_width: float = width + 1.3
	var eave_width: float = width + 1.8
	var floor_width := width - 0.4
	var post_offset := width / 2.0 - 0.25
	var post_count: int = int(length / 3.5) + 2

	# 接地铺砖，略高于地面但低于玩家可跨台阶高度
	var gap_half: float = gap_width / 2.0
	if gap_width > 0.0:
		# 通道口左侧地板
		var left_len: float = (length / 2.0 + gap_center) - gap_half
		if left_len > 0.5:
			var left_center: float = -length / 2.0 + left_len / 2.0
			_make_box(cr, "CorridorFloor_L", Vector3(0, 0.04, left_center),
				Vector3(floor_width, 0.08, left_len), mat_brick, true)
			_make_mesh(cr, "CenterStonePath_L", Vector3(0, 0.105, left_center),
				Vector3(floor_width - 0.45, 0.03, left_len - 0.35), mat_stone)
		# 通道口右侧地板
		var right_len: float = (length / 2.0 - gap_center) - gap_half
		if right_len > 0.5:
			var right_center: float = length / 2.0 - right_len / 2.0
			_make_box(cr, "CorridorFloor_R", Vector3(0, 0.04, right_center),
				Vector3(floor_width, 0.08, right_len), mat_brick, true)
			_make_mesh(cr, "CenterStonePath_R", Vector3(0, 0.105, right_center),
				Vector3(floor_width - 0.45, 0.03, right_len - 0.35), mat_stone)
		# 通道口两端的收边柱
		for gap_side in [-1, 1]:
			var gap_edge_z: float = gap_center + float(gap_side) * gap_half
			for side_val in [-1.0, 1.0]:
				_make_cylinder(cr, "GapEdgePillar_%d_%d" % [gap_side, side_val],
					Vector3(side_val * post_offset, 1.55, gap_edge_z), 0.12, 3.1, mat_wood_red, false)
	else:
		_make_box(cr, "CorridorFloor", Vector3(0, 0.04, 0),
			Vector3(floor_width, 0.08, length), mat_brick, true)
		_make_mesh(cr, "CenterStonePath", Vector3(0, 0.105, 0),
			Vector3(floor_width - 0.45, 0.03, length - 0.35), mat_stone)

	# 两端过渡踏步，避免从地面走上廊道时被碰撞边缘卡住
	for end_side in [-1, 1]:
		_make_box(cr, "Step_%d" % end_side,
			Vector3(0, 0.025, end_side * (length / 2.0 + 0.45)),
			Vector3(floor_width + 0.2, 0.05, 0.9), mat_brick, true)
	_decorate_corridor_exits(cr, length, floor_width)

	# 廊顶：坡屋面 + 薄檐 + 中脊，减少大块盒子压迫感
	_make_box(cr, "CorridorEave", Vector3(0, 3.05, 0),
		Vector3(eave_width, 0.12, length + 1.0), mat_wall_top, false)
	_make_gable_roof(cr, "CorridorRoof", Vector3(0, 3.08, 0),
		roof_width, length + 0.7, 0.65, mat_roof)
	_make_box(cr, "RoofRidge", Vector3(0, 3.78, 0),
		Vector3(0.22, 0.16, length + 0.9), mat_wall_top, false)

	# 廊柱与低栏，沿局部 Z 方向均匀排布（跳过通道口区域）
	for i in range(post_count):
		var t: float = float(i) / max(post_count - 1, 1)
		var z: float = -length / 2.0 + t * length
		# 跳过通道口区域的柱子
		if gap_width > 0.0 and abs(z - gap_center) < gap_half + 0.3:
			continue
		for side_value in [-1.0, 1.0]:
			var side: float = side_value
			var x: float = side * post_offset
			_make_cylinder(cr, "CorridorPillar_%d_%d" % [i, side],
				Vector3(x, 1.55, z), 0.09, 3.1, mat_wood_red, false)
			_make_box(cr, "LanternBracket_%d_%d" % [i, side],
				Vector3(x - side * 0.18, 2.55, z), Vector3(0.36, 0.08, 0.08), mat_wood_red, false)

	for side_value in [-1.0, 1.0]:
		var side: float = side_value
		var x: float = side * post_offset
		# 栏杆也需要留出通道口
		if gap_width > 0.0:
			var rail_left_len: float = (length / 2.0 + gap_center) - gap_half - 0.5
			if rail_left_len > 0.5:
				var rail_left_z: float = -length / 2.0 + rail_left_len / 2.0
				_make_box(cr, "LowRail_L_%d" % side, Vector3(x, 0.9, rail_left_z),
					Vector3(0.12, 0.12, rail_left_len), mat_wood_red, false)
				_make_box(cr, "TopRail_L_%d" % side, Vector3(x, 1.55, rail_left_z),
					Vector3(0.1, 0.1, rail_left_len), mat_wood_red, false)
			var rail_right_len: float = (length / 2.0 - gap_center) - gap_half - 0.5
			if rail_right_len > 0.5:
				var rail_right_z: float = length / 2.0 - rail_right_len / 2.0
				_make_box(cr, "LowRail_R_%d" % side, Vector3(x, 0.9, rail_right_z),
					Vector3(0.12, 0.12, rail_right_len), mat_wood_red, false)
				_make_box(cr, "TopRail_R_%d" % side, Vector3(x, 1.55, rail_right_z),
					Vector3(0.1, 0.1, rail_right_len), mat_wood_red, false)
		else:
			_make_box(cr, "LowRail_%d" % side, Vector3(x, 0.9, 0),
				Vector3(0.12, 0.12, length - 1.0), mat_wood_red, false)
			_make_box(cr, "TopRail_%d" % side, Vector3(x, 1.55, 0),
				Vector3(0.1, 0.1, length - 1.0), mat_wood_red, false)
			_make_box(cr, "BenchRail_%d" % side, Vector3(x - side * 0.25, 0.45, 0),
				Vector3(0.12, 0.12, length - 1.2), mat_wood_red, false)

func _decorate_corridor_exits(corridor: Node3D, length: float, floor_width: float) -> void:
	for end_side in [-1, 1]:
		var end_z: float = float(end_side) * (length / 2.0 + 1.1)
		_make_box(corridor, "ExitLanding_%d" % end_side,
			Vector3(0, 0.055, end_z), Vector3(floor_width + 1.2, 0.08, 1.9), mat_stone, true)
		_make_box(corridor, "ExitGoldLine_%d" % end_side,
			Vector3(0, 0.125, end_z), Vector3(0.34, 0.035, 1.45), mat_gold, false)
		_make_label(corridor, "ExitLabel_%d" % end_side, "出口",
			Vector3(0, 1.85, float(end_side) * (length / 2.0 + 0.2)), 22, 0.011,
			PI if end_side < 0 else 0.0)
		for side_value in [-1.0, 1.0]:
			_make_cylinder(corridor, "ExitLanternPost_%d_%d" % [end_side, side_value],
				Vector3(side_value * (floor_width / 2.0 + 0.45), 1.35, float(end_side) * (length / 2.0 + 0.6)),
				0.08, 2.7, mat_wood_red, false)
			_make_cylinder(corridor, "ExitLantern_%d_%d" % [end_side, side_value],
				Vector3(side_value * (floor_width / 2.0 + 0.45), 2.55, float(end_side) * (length / 2.0 + 0.6)),
				0.18, 0.32, mat_gold, false)

# ============================================================
# 五处核心院落专项优化
# ============================================================
func _build_core_courtyard_optimization() -> void:
	var root := Node3D.new()
	root.name = "CoreCourtyardOptimization"
	add_child(root)

	_build_named_courtyard_frame(root, "XiaoxiangFrame", Vector3(-35, 0, 10), 24, 22, "潇湘馆")
	_build_named_courtyard_frame(root, "YihongFrame", Vector3(35, 0, 10), 24, 22, "怡红院")
	_build_named_courtyard_frame(root, "QiushuangFrame", Vector3(-40, 0, -5), 24, 20, "秋爽斋")
	_build_named_courtyard_frame(root, "HengwuFrame", Vector3(25, 0, -15), 24, 20, "蘅芜苑")
	_build_named_courtyard_frame(root, "DaoxiangFrame", Vector3(-25, 0, -15), 26, 22, "稻香村")
	_build_residential_courtyard_enclosures(root)

	_build_bluestone_route(root)
	_build_pond_revetment(root)
	_build_lotus_pond_crossing(root)
	_build_xiaoxiang_details(root)
	_build_yihong_details(root)
	_build_qiushuang_details(root)
	_build_hengwu_details(root)
	_build_daoxiang_details(root)
	_build_garden_ornaments(root)
	_build_layered_garden_sequence(root)

func _build_residential_courtyard_enclosures(parent: Node3D) -> void:
	var enclosures := Node3D.new()
	enclosures.name = "ResidentialCourtyardEnclosures"
	parent.add_child(enclosures)

	var courtyard_specs: Array[Dictionary] = [
		{"name": "DaguanLouEnclosure", "pos": Vector3(0, 0, 25), "w": 30.0, "d": 20.0, "label": "大观楼", "gate": "south"},
		{"name": "LongcuiAnEnclosure", "pos": Vector3(0, 0, 40), "w": 22.0, "d": 18.0, "label": "栊翠庵", "gate": "south"},
		{"name": "ZhuijingeEnclosure", "pos": Vector3(40, 0, 25), "w": 22.0, "d": 18.0, "label": "缀锦阁", "gate": "west"},
		{"name": "ZilingzhouEnclosure", "pos": Vector3(-25, 0, 20), "w": 20.0, "d": 18.0, "label": "紫菱洲", "gate": "east"},
	]
	for spec: Dictionary in courtyard_specs:
		_build_partitioned_courtyard(enclosures, spec)

func _build_partitioned_courtyard(parent: Node3D, spec: Dictionary) -> void:
	var frame := Node3D.new()
	frame.name = String(spec["name"])
	frame.position = spec["pos"]
	parent.add_child(frame)

	var w: float = spec["w"]
	var d: float = spec["d"]
	var gate_side := String(spec["gate"])
	var wall_h := 2.9
	var wall_t := 0.48
	var gate_gap := 4.4

	_build_partition_wall_pair(frame, "North", Vector3(0, wall_h / 2.0, -d / 2.0), w, wall_h, wall_t, gate_gap, gate_side == "north", false)
	_build_partition_wall_pair(frame, "South", Vector3(0, wall_h / 2.0, d / 2.0), w, wall_h, wall_t, gate_gap, gate_side == "south", false)
	_build_partition_wall_pair(frame, "East", Vector3(w / 2.0, wall_h / 2.0, 0), d, wall_h, wall_t, gate_gap, gate_side == "east", true)
	_build_partition_wall_pair(frame, "West", Vector3(-w / 2.0, wall_h / 2.0, 0), d, wall_h, wall_t, gate_gap, gate_side == "west", true)

	var gate_pos := Vector3.ZERO
	var gate_rot := 0.0
	match gate_side:
		"north":
			gate_pos = Vector3(0, 0, -d / 2.0 + 0.1)
			gate_rot = PI
		"east":
			gate_pos = Vector3(w / 2.0 - 0.1, 0, 0)
			gate_rot = -PI / 2.0
		"west":
			gate_pos = Vector3(-w / 2.0 + 0.1, 0, 0)
			gate_rot = PI / 2.0
		_:
			gate_pos = Vector3(0, 0, d / 2.0 - 0.1)
			gate_rot = 0.0
	_build_moon_gate(frame, "PartitionMoonGate", gate_pos, gate_rot, String(spec["label"]))

func _build_partition_wall_pair(parent: Node3D, name_s: String, center: Vector3, length: float,
		wall_h: float, wall_t: float, gate_gap: float, has_gate: bool, rotated: bool) -> void:
	if has_gate:
		var segment_length := (length - gate_gap) / 2.0
		var offset := (gate_gap + segment_length) / 2.0
		_build_partition_wall_segment(parent, name_s + "_A", center, segment_length, wall_h, wall_t, -offset, rotated)
		_build_partition_wall_segment(parent, name_s + "_B", center, segment_length, wall_h, wall_t, offset, rotated)
	else:
		_build_partition_wall_segment(parent, name_s, center, length, wall_h, wall_t, 0.0, rotated)

func _build_partition_wall_segment(parent: Node3D, name_s: String, center: Vector3, length: float,
		wall_h: float, wall_t: float, offset: float, rotated: bool) -> void:
	var pos := center
	if rotated:
		pos.z += offset
	else:
		pos.x += offset
	var size := Vector3(length, wall_h, wall_t)
	if rotated:
		size = Vector3(wall_t, wall_h, length)
	_make_box(parent, name_s, pos, size, mat_white_wall, true)
	_make_mesh(parent, name_s + "_Cap", Vector3(pos.x, wall_h + 0.13, pos.z),
		Vector3(size.x + 0.2, 0.24, size.z + 0.2), mat_wall_top)

func _build_named_courtyard_frame(parent: Node3D, name_s: String, pos: Vector3,
		w: float, d: float, display_name: String) -> void:
	var frame := Node3D.new()
	frame.name = name_s
	frame.position = pos
	parent.add_child(frame)

	var wall_h := 3.2
	var wall_t := 0.5
	var gate_gap := 5.0
	_make_box(frame, "Wall_N", Vector3(0, wall_h / 2.0, -d / 2.0), Vector3(w, wall_h, wall_t), mat_white_wall, true)
	_make_box(frame, "Wall_E", Vector3(w / 2.0, wall_h / 2.0, 0), Vector3(wall_t, wall_h, d), mat_white_wall, true)
	_make_box(frame, "Wall_W", Vector3(-w / 2.0, wall_h / 2.0, 0), Vector3(wall_t, wall_h, d), mat_white_wall, true)
	_make_box(frame, "Wall_S_L", Vector3(-(w + gate_gap) / 4.0, wall_h / 2.0, d / 2.0), Vector3((w - gate_gap) / 2.0, wall_h, wall_t), mat_white_wall, true)
	_make_box(frame, "Wall_S_R", Vector3((w + gate_gap) / 4.0, wall_h / 2.0, d / 2.0), Vector3((w - gate_gap) / 2.0, wall_h, wall_t), mat_white_wall, true)

	for wall_name in ["Wall_N", "Wall_E", "Wall_W", "Wall_S_L", "Wall_S_R"]:
		var wall := frame.get_node_or_null(wall_name)
		if wall and wall is StaticBody3D:
			var cap_size := Vector3(w, 0.25, wall_t + 0.25)
			if wall_name in ["Wall_E", "Wall_W"]:
				cap_size = Vector3(wall_t + 0.25, 0.25, d)
			elif wall_name in ["Wall_S_L", "Wall_S_R"]:
				cap_size = Vector3((w - gate_gap) / 2.0, 0.25, wall_t + 0.25)
			_make_mesh(wall, "GreyTileCap", Vector3(0, wall_h / 2.0 + 0.15, 0), cap_size, mat_wall_top)

	_build_flower_gate(frame, display_name, Vector3(0, 0, d / 2.0 - 0.25))
	_make_mesh(frame, "CourtyardStonePath", Vector3(0, 0.035, d / 2.0 - 4), Vector3(3.2, 0.04, 8), mat_stone)

func _build_flower_gate(parent: Node3D, display_name: String, pos: Vector3) -> void:
	var gate := Node3D.new()
	gate.name = "ChuihuaGate"
	gate.position = pos
	parent.add_child(gate)
	_make_cylinder(gate, "GatePostL", Vector3(-2.2, 1.8, 0), 0.14, 3.6, mat_wood_red, false)
	_make_cylinder(gate, "GatePostR", Vector3(2.2, 1.8, 0), 0.14, 3.6, mat_wood_red, false)
	_make_box(gate, "GateLintel", Vector3(0, 3.4, 0), Vector3(5.2, 0.28, 0.35), mat_wood_red, false)
	_make_gable_roof(gate, "GateRoof", Vector3(0, 3.55, 0), 5.8, 1.4, 0.55, mat_roof)
	_make_cylinder(gate, "MoonDoorRing", Vector3(0, 1.75, 0.08), 1.35, 0.22, mat_stone, false)
	var label := Label3D.new()
	label.name = "CourtyardPlaque"
	label.text = display_name
	label.position = Vector3(0, 3.25, 0.45)
	label.font_size = 42
	label.pixel_size = 0.01
	label.modulate = Color(0.9, 0.72, 0.22)
	label.outline_size = 8
	label.outline_modulate = Color(0.05, 0.03, 0.01)
	label.double_sided = true
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gate.add_child(label)

func _build_bluestone_route(parent: Node3D) -> void:
	var route := Node3D.new()
	route.name = "BluestoneRouteOverlay"
	parent.add_child(route)
	# 石板路高于水面（水面top≈0.085），加厚确保不穿水不落水
	_make_box(route, "MainBluestone", Vector3(0, 0.18, -5), Vector3(4.2, 0.12, 82), mat_stone, true)
	_make_box(route, "EntranceToBridgeBluestone", Vector3(0, 0.19, -32), Vector3(5.4, 0.14, 32), mat_stone, true)
	_make_box(route, "WestBluestone", Vector3(-19, 0.18, 10), Vector3(32, 0.12, 3.2), mat_stone, true)
	_make_box(route, "EastBluestone", Vector3(19, 0.18, 10), Vector3(32, 0.12, 3.2), mat_stone, true)
	_make_box(route, "SouthCourtyardBluestone", Vector3(0, 0.19, -15), Vector3(50, 0.12, 3.0), mat_stone, true)
	_make_box(route, "NorthCourtyardBluestone", Vector3(0, 0.18, 25), Vector3(56, 0.12, 3.0), mat_stone, true)

func _build_pond_revetment(parent: Node3D) -> void:
	var pond := Node3D.new()
	pond.name = "PondRevetmentAndRails"
	parent.add_child(pond)
	for x in [-18, 8]:
		_make_box(pond, "RevetmentX_%s" % str(x), Vector3(x, 0.25, -22), Vector3(0.7, 0.5, 19), mat_stone, true)
	for z in [-31, -13]:
		_make_box(pond, "RevetmentZ_L_%s" % str(z), Vector3(-13.0, 0.25, z), Vector3(10.0, 0.5, 0.7), mat_stone, true)
		_make_box(pond, "RevetmentZ_R_%s" % str(z), Vector3(3.0, 0.25, z), Vector3(10.0, 0.5, 0.7), mat_stone, true)
	for x in range(-16, 9, 4):
		if x < -8 or x > -2:
			_make_cylinder(pond, "RailPostN_%d" % x, Vector3(x, 0.85, -13.7), 0.06, 1.3, mat_stone, false)
			_make_cylinder(pond, "RailPostS_%d" % x, Vector3(x, 0.85, -30.3), 0.06, 1.3, mat_stone, false)
	_make_box(pond, "RailNorth_L", Vector3(-13.5, 1.35, -13.7), Vector3(9.0, 0.09, 0.09), mat_stone, false)
	_make_box(pond, "RailNorth_R", Vector3(4.5, 1.35, -13.7), Vector3(7.0, 0.09, 0.09), mat_stone, false)
	_make_box(pond, "RailSouth_L", Vector3(-13.0, 1.35, -30.3), Vector3(10.0, 0.09, 0.09), mat_stone, false)
	_make_box(pond, "RailSouth_R", Vector3(4.5, 1.35, -30.3), Vector3(7.0, 0.09, 0.09), mat_stone, false)

func _build_lotus_pond_crossing(parent: Node3D) -> void:
	var bridge := Node3D.new()
	bridge.name = "WalkablePondBridge"
	bridge.position = Vector3(0, 0, -22)
	parent.add_child(bridge)

	_make_box(bridge, "Deck", Vector3(0, 0.03, 0), Vector3(6.8, 0.06, 22.0), mat_stone, true)
	_make_box(bridge, "SouthRamp", Vector3(0, 0.02, -12.6), Vector3(7.2, 0.04, 3.4), mat_stone, true)
	_make_box(bridge, "NorthRamp", Vector3(0, 0.02, 12.6), Vector3(7.2, 0.04, 3.4), mat_stone, true)
	_make_box(bridge, "SouthBridgeLanding", Vector3(0, 0.015, -15.4), Vector3(7.6, 0.03, 3.0), mat_stone, true)
	_make_box(bridge, "NorthBridgeLanding", Vector3(0, 0.015, 15.4), Vector3(7.6, 0.03, 3.0), mat_stone, true)
	for side_value in [-1.0, 1.0]:
		var side: float = side_value
		for z in [-9.0, -4.5, 0.0, 4.5, 9.0]:
			_make_cylinder(bridge, "PondBridgePost_%s_%s" % [str(side), str(z)], Vector3(side * 2.35, 1.05, z), 0.07, 1.2, mat_stone, false)
		_make_box(bridge, "PondBridgeRail_%s" % str(side), Vector3(side * 2.35, 1.5, 0), Vector3(0.1, 0.12, 19.0), mat_stone, false)

func _build_layered_garden_sequence(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "LayeredGardenSequence"
	parent.add_child(root)

	_build_expanded_water_system(root)
	_build_continuous_veranda_system(root)
	_build_moon_gates_and_screen_walls(root)
	_build_rockery_and_pavilions(root)
	_build_winding_paths_and_planting(root)
	_build_visual_occlusion_layers(root)

func _build_expanded_water_system(parent: Node3D) -> void:
	var water := Node3D.new()
	water.name = "ExpandedWaterSystem"
	parent.add_child(water)

	_make_mesh(water, "GrandLakeCenter", Vector3(0, 0.045, 18), Vector3(32, 0.08, 28), mat_water)
	_make_mesh(water, "GrandLakeWestBay", Vector3(-18, 0.046, 15), Vector3(18, 0.08, 20), mat_water)
	_make_mesh(water, "GrandLakeEastBay", Vector3(18, 0.046, 20), Vector3(18, 0.08, 18), mat_water)
	_make_mesh(water, "SouthCreekBend", Vector3(-10, 0.047, -2), Vector3(6, 0.08, 18), mat_water)
	_make_mesh(water, "EastCreekBend", Vector3(14, 0.047, 2), Vector3(16, 0.08, 6), mat_water)
	_make_mesh(water, "NorthCreekBend", Vector3(5, 0.047, 34), Vector3(8, 0.08, 16), mat_water)

	var bank_points: Array[Vector3] = [
		Vector3(-19, 0.12, 18), Vector3(19, 0.12, 18), Vector3(0, 0.12, 4), Vector3(0, 0.12, 32),
		Vector3(-27, 0.12, 15), Vector3(27, 0.12, 20), Vector3(-8, 0.12, -13), Vector3(12, 0.12, -2)
	]
	var bank_sizes: Array[Vector3] = [
		Vector3(2.0, 0.12, 28), Vector3(2.0, 0.12, 28), Vector3(34, 0.12, 2.0), Vector3(34, 0.12, 2.0),
		Vector3(2.0, 0.12, 20), Vector3(2.0, 0.12, 18), Vector3(8, 0.12, 2.0), Vector3(22, 0.12, 2.0)
	]
	for i in range(bank_points.size()):
		_make_mesh(water, "IrregularBank_%d" % i, bank_points[i], bank_sizes[i], mat_creek_bank)

	# 溪流上的踏脚石，确保主路径附近可通行
	var stepping_stones: Array[Vector3] = [
		Vector3(-4, 0.12, 5), Vector3(-4, 0.12, -5),
		Vector3(4, 0.12, 5), Vector3(4, 0.12, -5),
		Vector3(0, 0.12, 15), Vector3(0, 0.12, 25),
	]
	for i in range(stepping_stones.size()):
		_make_cylinder(water, "SteppingStone_%d" % i, stepping_stones[i], 0.8, 0.15, mat_stone, true)

	for i in range(18):
		var x := -13.0 + float(i % 6) * 5.0
		var z := 10.0 + float(i / 6.0) * 7.0
		_make_mesh(water, "LotusLeaf_%d" % i, Vector3(x, 0.13, z), Vector3(1.4, 0.025, 1.0), mat_farmland)
		if i % 4 == 0:
			_make_cylinder(water, "LotusBud_%d" % i, Vector3(x + 0.35, 0.45, z - 0.2), 0.16, 0.35, mat_gold, false)

func _build_continuous_veranda_system(parent: Node3D) -> void:
	var veranda := Node3D.new()
	veranda.name = "ContinuousVerandaSystem"
	parent.add_child(veranda)

	_build_corridor(veranda, "SouthVeranda", Vector3(-24, 0, -2), Vector3(24, 0, -2), 3.2,
		0.0, 7.0)
	_build_corridor(veranda, "WestLakeVeranda", Vector3(-24, 0, -2), Vector3(-30, 0, 22), 3.0)
	_build_corridor(veranda, "NorthLakeVeranda", Vector3(-30, 0, 22), Vector3(-10, 0, 34), 3.0)
	_build_corridor(veranda, "EastLakeVeranda", Vector3(24, 0, -2), Vector3(31, 0, 18), 3.0)
	_build_corridor(veranda, "TeaVeranda", Vector3(31, 0, 18), Vector3(12, 0, 40), 3.0)
	_build_corridor(veranda, "MainHallVeranda", Vector3(-10, 0, 34), Vector3(10, 0, 31), 3.0)
	# === 连通性修复: 闭合主环路 (TeaVeranda终点→MainHallVeranda终点) ===
	_build_corridor(veranda, "NorthClosureVeranda", Vector3(10, 0, 31), Vector3(12, 0, 40), 3.0)
	# === 连通性修复: 连通栊翠庵南月洞门 (解决妙玉NPC不可达) ===
	_build_corridor(veranda, "LongcuiVeranda", Vector3(12, 0, 40), Vector3(0, 0, 49), 3.0)

func _build_moon_gates_and_screen_walls(parent: Node3D) -> void:
	var gates := Node3D.new()
	gates.name = "MoonGatesAndScreenWalls"
	parent.add_child(gates)

	_build_moon_gate(gates, "SouthMoonGate", Vector3(0, 0, -5), 0.0, "入园")
	_build_moon_gate(gates, "WestMoonGate", Vector3(-27, 0, 7), deg_to_rad(-18.0), "竹径")
	_build_moon_gate(gates, "EastMoonGate", Vector3(27, 0, 8), deg_to_rad(18.0), "花径")
	_build_moon_gate(gates, "NorthMoonGate", Vector3(0, 0, 34), PI, "临水")

	_build_screen_wall(gates, "EntranceScreenWall", Vector3(0, 0, -39), Vector3(12, 4.2, 0.55), 0.0)
	_build_screen_wall(gates, "LakeScreenWallWest", Vector3(-17, 0, 2), Vector3(13, 3.4, 0.45), deg_to_rad(28.0))
	_build_screen_wall(gates, "LakeScreenWallEast", Vector3(18, 0, 6), Vector3(11, 3.4, 0.45), deg_to_rad(-24.0))
	_build_screen_wall(gates, "NorthScreenWall", Vector3(11, 0, 29), Vector3(10, 3.2, 0.45), deg_to_rad(18.0))

	_build_flower_window_wall(gates, "WestFlowerWindowWall", Vector3(-36, 0, 11), deg_to_rad(8.0), 18.0)
	_build_flower_window_wall(gates, "EastFlowerWindowWall", Vector3(36, 0, 14), deg_to_rad(-8.0), 18.0)
	_build_flower_window_wall(gates, "NorthFlowerWindowWall", Vector3(0, 0, 39), PI / 2.0, 24.0)

func _build_moon_gate(parent: Node3D, name_s: String, pos: Vector3, rot_y: float, label_text: String) -> void:
	var gate: Node3D = Node3D.new()
	gate.name = name_s
	gate.position = pos
	gate.rotation.y = rot_y
	parent.add_child(gate)
	_make_box(gate, "WallL", Vector3(-3.1, 1.9, 0), Vector3(2.2, 3.8, 0.5), mat_white_wall, true)
	_make_box(gate, "WallR", Vector3(3.1, 1.9, 0), Vector3(2.2, 3.8, 0.5), mat_white_wall, true)
	_make_box(gate, "Lintel", Vector3(0, 3.75, 0), Vector3(7.2, 0.5, 0.55), mat_white_wall, true)
	_make_cylinder(gate, "MoonRing", Vector3(0, 1.85, -0.02), 1.75, 0.28, mat_stone, false)
	var label: Label3D = Label3D.new()
	label.name = "MoonGateLabel"
	label.text = label_text
	label.position = Vector3(0, 3.55, -0.34)
	label.font_size = 30
	label.pixel_size = 0.012
	label.modulate = Color(0.84, 0.68, 0.22)
	label.outline_size = 6
	label.outline_modulate = Color(0.04, 0.025, 0.01)
	label.double_sided = true
	gate.add_child(label)

func _build_screen_wall(parent: Node3D, name_s: String, pos: Vector3, size: Vector3, rot_y: float) -> void:
	var wall := _make_box(parent, name_s, pos + Vector3(0, size.y / 2.0, 0), size, mat_white_wall, true)
	wall.rotation.y = rot_y
	_make_mesh(wall, "ScreenWallCap", Vector3(0, size.y / 2.0 + 0.18, 0), Vector3(size.x + 0.4, 0.28, size.z + 0.3), mat_wall_top)
	_make_box(wall, "ReliefPanel", Vector3(0, 0.25, -size.z / 2.0 - 0.05), Vector3(size.x - 1.2, size.y - 1.0, 0.08), mat_stone, false)

func _build_flower_window_wall(parent: Node3D, name_s: String, pos: Vector3, rot_y: float, length: float) -> void:
	var wall := Node3D.new()
	wall.name = name_s
	wall.position = pos
	wall.rotation.y = rot_y
	parent.add_child(wall)
	_make_box(wall, "WallBase", Vector3(0, 1.65, 0), Vector3(length, 3.3, 0.45), mat_white_wall, true)
	_make_mesh(wall, "TileCap", Vector3(0, 3.45, 0), Vector3(length + 0.4, 0.25, 0.7), mat_wall_top)
	for i in range(4):
		var x := -length / 2.0 + 3.0 + i * ((length - 6.0) / 3.0)
		_make_cylinder(wall, "RoundFlowerWindow_%d" % i, Vector3(x, 1.9, -0.27), 0.75, 0.18, mat_stone, false)
		_make_box(wall, "WindowCrossH_%d" % i, Vector3(x, 1.9, -0.39), Vector3(1.2, 0.08, 0.08), mat_wood_red, false)
		_make_box(wall, "WindowCrossV_%d" % i, Vector3(x, 1.9, -0.39), Vector3(0.08, 1.2, 0.08), mat_wood_red, false)

func _build_rockery_and_pavilions(parent: Node3D) -> void:
	var rockery := Node3D.new()
	rockery.name = "RockeryAndPavilionSequence"
	parent.add_child(rockery)

	_build_rockery_cluster(rockery, "WestRockery", Vector3(-28, 0, 31), 1.1)
	_build_rockery_cluster(rockery, "EastRockery", Vector3(27, 0, 32), 0.95)
	_build_rockery_cluster(rockery, "SouthRockery", Vector3(14, 0, -9), 0.75)
	_build_pavilion(rockery, "LakeHeartPavilion", Vector3(4, 0.12, 19), 1.0)
	_build_pavilion(rockery, "HillPavilion", Vector3(-32, 1.0, 37), 0.9)
	var lake_bridge_points: Array[Vector3] = [Vector3(-16, 0.24, 12), Vector3(-9, 0.24, 18), Vector3(-2, 0.24, 15), Vector3(4, 0.24, 20), Vector3(12, 0.24, 18)]
	var tea_bridge_points: Array[Vector3] = [Vector3(8, 0.22, 29), Vector3(13, 0.22, 33), Vector3(10, 0.22, 38), Vector3(3, 0.22, 40)]
	_build_zigzag_bridge(rockery, "LakeZigzagBridge", lake_bridge_points)
	_build_zigzag_bridge(rockery, "TeaZigzagBridge", tea_bridge_points)

func _build_rockery_cluster(parent: Node3D, name_s: String, base_pos: Vector3, scale: float) -> void:
	var root := Node3D.new()
	root.name = name_s
	root.position = base_pos
	parent.add_child(root)
	var positions: Array[Vector3] = [Vector3(0, 1.4, 0), Vector3(-2.3, 1.1, 1.4), Vector3(2.1, 1.3, -0.8), Vector3(-0.8, 2.0, -1.6), Vector3(1.3, 2.4, 1.5), Vector3(-3.2, 0.7, -1.5)]
	var sizes: Array[Vector3] = [Vector3(3.6, 2.8, 2.8), Vector3(2.7, 2.2, 2.2), Vector3(2.6, 2.6, 2.0), Vector3(2.2, 4.0, 2.2), Vector3(2.0, 4.8, 2.0), Vector3(2.8, 1.4, 2.3)]
	for i in range(positions.size()):
		_make_box(root, "LayerRock_%d" % i, positions[i] * scale, sizes[i] * scale, mat_stone, true)

func _build_pavilion(parent: Node3D, name_s: String, pos: Vector3, scale: float) -> void:
	var pavilion := Node3D.new()
	pavilion.name = name_s
	pavilion.position = pos
	parent.add_child(pavilion)
	for x in [-1.5, 1.5]:
		for z in [-1.5, 1.5]:
			_make_cylinder(pavilion, "Post_%s_%s" % [str(x), str(z)], Vector3(x, 1.9, z) * scale, 0.13 * scale, 3.8 * scale, mat_wood_red, false)
	_make_box(pavilion, "Floor", Vector3(0, 0.12, 0), Vector3(4.6, 0.18, 4.6) * scale, mat_stone, true)
	_make_gable_roof(pavilion, "Roof", Vector3(0, 4.0, 0) * scale, 5.4 * scale, 5.4 * scale, 0.8 * scale, mat_roof)
	_make_box(pavilion, "Seat", Vector3(0, 0.65, -1.6) * scale, Vector3(3.0, 0.28, 0.38) * scale, mat_wood_red, false)

func _build_zigzag_bridge(parent: Node3D, name_s: String, points: Array[Vector3]) -> void:
	var bridge := Node3D.new()
	bridge.name = name_s
	parent.add_child(bridge)
	for i in range(points.size() - 1):
		var from: Vector3 = points[i]
		var to: Vector3 = points[i + 1]
		var mid: Vector3 = (from + to) / 2.0
		var diff: Vector3 = to - from
		var segment: StaticBody3D = _make_box(bridge, "Deck_%d" % i, mid, Vector3(3.0, 0.16, diff.length()), mat_stone, true)
		segment.rotation.y = atan2(diff.x, diff.z)
		for side: float in [-1.0, 1.0]:
			var rail: StaticBody3D = _make_box(segment, "Rail_%s" % str(side), Vector3(side * 1.35, 1.0, 0), Vector3(0.08, 0.14, diff.length() - 0.4), mat_stone, false)
			rail.rotation.y = 0.0

func _build_winding_paths_and_planting(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "WindingPathsAndPlanting"
	parent.add_child(root)

	var west_path_points: Array[Vector3] = [Vector3(-6, 0.12, -8), Vector3(-14, 0.12, -3), Vector3(-20, 0.12, 6), Vector3(-25, 0.12, 16), Vector3(-32, 0.12, 27)]
	var east_path_points: Array[Vector3] = [Vector3(7, 0.12, -7), Vector3(15, 0.12, -2), Vector3(22, 0.12, 8), Vector3(28, 0.12, 19), Vector3(18, 0.12, 32), Vector3(8, 0.12, 39)]
	var north_path_points: Array[Vector3] = [Vector3(-18, 0.12, 32), Vector3(-9, 0.12, 38), Vector3(0, 0.12, 35), Vector3(10, 0.12, 39)]
	_build_stepping_stone_path(root, "WestWindingPath", west_path_points)
	_build_stepping_stone_path(root, "EastWindingPath", east_path_points)
	_build_stepping_stone_path(root, "NorthWindingPath", north_path_points)

	var flower_bed_positions: Array[Vector3] = [Vector3(-11, 0, -6), Vector3(-18, 0, 4), Vector3(-24, 0, 13), Vector3(13, 0, -5), Vector3(21, 0, 5), Vector3(24, 0, 25), Vector3(8, 0, 35), Vector3(-11, 0, 35)]
	for pos: Vector3 in flower_bed_positions:
		_build_flower_bed(root, pos, Vector3(5.0, 0.12, 2.2))
	var shrub_positions: Array[Vector3] = [Vector3(-30, 0, 6), Vector3(-34, 0, 18), Vector3(32, 0, 7), Vector3(34, 0, 24), Vector3(-4, 0, -12), Vector3(4, 0, -12)]
	for pos: Vector3 in shrub_positions:
		_build_shrub_group(root, pos)
	var landscape_stone_positions: Array[Vector3] = [Vector3(-22, 0, -6), Vector3(22, 0, -7), Vector3(-15, 0, 27), Vector3(17, 0, 28), Vector3(0, 0, 41)]
	for pos: Vector3 in landscape_stone_positions:
		_make_box(root, "LandscapeStone", pos + Vector3(0, 0.65, 0), Vector3(1.8, 1.3, 1.1), mat_stone, true)

func _build_stepping_stone_path(parent: Node3D, name_s: String, points: Array[Vector3]) -> void:
	var path := Node3D.new()
	path.name = name_s
	parent.add_child(path)
	for i in range(points.size() - 1):
		var from: Vector3 = points[i]
		var to: Vector3 = points[i + 1]
		var diff: Vector3 = to - from
		var count: int = max(2, int(diff.length() / 2.2))
		for j in range(count):
			var t: float = float(j) / float(count)
			var pos: Vector3 = from.lerp(to, t)
			pos.x += sin(float(i * 7 + j) * 1.3) * 0.25
			pos.z += cos(float(i * 5 + j) * 1.1) * 0.2
			var stone: StaticBody3D = _make_box(path, "Stone_%d_%d" % [i, j], pos, Vector3(1.35, 0.1, 0.95), mat_stone, true)
			stone.rotation.y = atan2(diff.x, diff.z) + sin(float(j)) * 0.18

func _build_flower_bed(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var bed := Node3D.new()
	bed.name = "FlowerBed"
	bed.position = pos
	parent.add_child(bed)
	_make_mesh(bed, "Soil", Vector3(0, 0.04, 0), size, mat_dirt)
	for i in range(10):
		var x := -size.x / 2.0 + 0.5 + float(i % 5) * (size.x - 1.0) / 4.0
		var z := -size.z / 2.0 + 0.35 + float(i / 5.0) * (size.z - 0.7)
		_make_cylinder(bed, "FlowerStem_%d" % i, Vector3(x, 0.35, z), 0.035, 0.7, mat_farmland, false)
		_make_box(bed, "FlowerHead_%d" % i, Vector3(x, 0.78, z), Vector3(0.35, 0.22, 0.35), mat_gold, false)

func _build_shrub_group(parent: Node3D, pos: Vector3) -> void:
	var shrubs := Node3D.new()
	shrubs.name = "ShrubGroup"
	shrubs.position = pos
	parent.add_child(shrubs)
	for i in range(5):
		var x := -1.8 + float(i % 3) * 1.6
		var z := -0.9 + float(i / 3.0) * 1.4
		_make_box(shrubs, "Shrub_%d" % i, Vector3(x, 0.65, z), Vector3(1.4, 1.1, 1.2), mat_farmland, false)

func _build_visual_occlusion_layers(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "VisualOcclusionLayers"
	parent.add_child(root)

	var wall_positions: Array[Vector3] = [
		Vector3(-12, 0, -26), Vector3(13, 0, -20), Vector3(-39, 0, 2),
		Vector3(39, 0, 4), Vector3(-20, 0, 38), Vector3(22, 0, 36)
	]
	var wall_rotations: Array[float] = [deg_to_rad(18.0), deg_to_rad(-16.0), deg_to_rad(-8.0), deg_to_rad(8.0), deg_to_rad(22.0), deg_to_rad(-20.0)]
	var wall_lengths: Array[float] = [18.0, 16.0, 20.0, 20.0, 18.0, 18.0]
	for i in range(wall_positions.size()):
		_build_flower_window_wall(root, "OcclusionFlowerWall_%d" % i, wall_positions[i], wall_rotations[i], wall_lengths[i])

	for i in range(34):
		var angle := float(i) * 0.73
		var radius := 28.0 + float(i % 5) * 4.0
		var pos := Vector3(cos(angle) * radius, 0, -4 + sin(angle) * 34.0)
		if abs(pos.x) < 7.0 and pos.z < 34.0:
			continue
		_build_tree(root, "LayerTree_%d" % i, pos, 3.6 + float(i % 3) * 0.8)

	for i in range(30):
		var x := -43.0 + float(i % 10) * 2.1
		var z := 24.0 + float(i / 10.0) * 3.1
		_make_cylinder(root, "WestBamboo_%d" % i, Vector3(x, 2.1, z), 0.055, 4.2, mat_wood_red, false)
		_make_box(root, "WestBambooLeaf_%d" % i, Vector3(x + 0.25, 4.1, z), Vector3(0.7, 0.45, 0.55), mat_farmland, false)

func _build_tree(parent: Node3D, name_s: String, pos: Vector3, height: float) -> void:
	var tree := Node3D.new()
	tree.name = name_s
	tree.position = pos
	parent.add_child(tree)
	_make_cylinder(tree, "Trunk", Vector3(0, height / 2.0, 0), 0.16, height, mat_wood_red, false)
	_make_box(tree, "CrownLower", Vector3(0, height + 0.6, 0), Vector3(2.6, 1.7, 2.6), mat_farmland, false)
	_make_box(tree, "CrownUpper", Vector3(0.35, height + 1.5, -0.2), Vector3(2.0, 1.4, 2.0), mat_farmland, false)

func _build_xiaoxiang_details(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "XiaoxiangDetails"
	root.position = Vector3(-35, 0, 10)
	parent.add_child(root)
	_make_mesh(root, "WaterSidePath", Vector3(5.5, 0.075, 4), Vector3(2.4, 0.04, 12), mat_stone)
	for i in range(18):
		var x := -10 + (i % 6) * 2.0
		var z := -8 + floori(float(i) / 6.0) * 4.0
		_make_cylinder(root, "BambooCluster_%d" % i, Vector3(x, 2.0, z), 0.055, 4.0, mat_wood_red, false)

func _build_yihong_details(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "YihongDetails"
	root.position = Vector3(35, 0, 10)
	parent.add_child(root)
	_build_corridor(root, "WatersideVeranda", Vector3(-9, 0, 2), Vector3(-9, 0, 12), 2.6)
	var begonia_positions: Array[Vector3] = [Vector3(-6, 1.8, -5), Vector3(7, 1.8, -3), Vector3(5, 1.8, 6)]
	for pos: Vector3 in begonia_positions:
		_make_cylinder(root, "BegoniaTrunk", pos, 0.18, 3.6, mat_wood_red, false)
		_make_box(root, "BegoniaCrown", pos + Vector3(0, 2.1, 0), Vector3(2.8, 2.0, 2.8), mat_farmland, false)
	var banana_positions: Array[Vector3] = [Vector3(-8, 0.9, 7), Vector3(8, 0.9, 6), Vector3(3, 0.9, -7)]
	for pos: Vector3 in banana_positions:
		_make_box(root, "BananaPlant", pos, Vector3(1.0, 1.8, 0.5), mat_farmland, false)

func _build_qiushuang_details(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "QiushuangDetails"
	root.position = Vector3(-40, 0, -5)
	parent.add_child(root)
	_make_mesh(root, "OpenCourt", Vector3(0, 0.08, 4), Vector3(16, 0.05, 10), mat_brick)
	var wutong_positions: Array[Vector3] = [Vector3(-8, 2.8, -5), Vector3(8, 2.8, -4), Vector3(-9, 2.8, 6), Vector3(9, 2.8, 5)]
	for pos: Vector3 in wutong_positions:
		_make_cylinder(root, "WutongTrunk", pos, 0.22, 5.6, mat_wood_red, false)
		_make_box(root, "WutongCrown", pos + Vector3(0, 3.0, 0), Vector3(4, 2.2, 4), mat_farmland, false)

func _build_hengwu_details(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "HengwuDetails"
	root.position = Vector3(25, 0, -15)
	parent.add_child(root)
	var hengwu_rock_positions: Array[Vector3] = [Vector3(-10, 1, -5), Vector3(10, 1, -4), Vector3(-8, 1, 6), Vector3(8, 1, 7), Vector3(0, 1.2, 8)]
	for pos: Vector3 in hengwu_rock_positions:
		_make_box(root, "Rockery", pos, Vector3(3.2, 2.2, 2.4), mat_stone, true)
	var trellis_positions: Array[Vector3] = [Vector3(-6, 0.5, -7), Vector3(6, 0.5, -7), Vector3(-5, 0.5, 7), Vector3(5, 0.5, 7)]
	for pos: Vector3 in trellis_positions:
		_make_box(root, "HerbVineTrellis", pos, Vector3(2.4, 1.0, 0.35), mat_farmland, false)

func _build_daoxiang_details(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "DaoxiangDetails"
	root.position = Vector3(-25, 0, -15)
	parent.add_child(root)
	for row in range(2):
		for col in range(3):
			_make_mesh(root, "VegetablePlot_%d_%d" % [row, col], Vector3(-7 + col * 7, 0.08, -7 + row * 5), Vector3(5.5, 0.08, 3.5), mat_farmland)
	var mulberry_positions: Array[Vector3] = [Vector3(-11, 2.2, 7), Vector3(12, 2.2, 6), Vector3(-12, 2.2, -9)]
	for pos: Vector3 in mulberry_positions:
		_make_cylinder(root, "MulberryElmTrunk", pos, 0.2, 4.4, mat_wood_red, false)
		_make_box(root, "MulberryElmCrown", pos + Vector3(0, 2.4, 0), Vector3(3.2, 2.2, 3.2), mat_farmland, false)
	_make_box(root, "RusticHouseFace", Vector3(0, 1.8, -3.8), Vector3(9, 3.2, 0.25), mat_dirt, false)

func _build_garden_ornaments(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "GardenOrnaments"
	parent.add_child(root)
	var points: Array[Vector3] = [
		Vector3(-12, 0, -2), Vector3(12, 0, -2), Vector3(-18, 0, 24), Vector3(18, 0, 24),
		Vector3(-48, 0, 28), Vector3(48, 0, 28), Vector3(-8, 0, -33), Vector3(8, 0, -33)
	]
	for i in range(points.size()):
		var pos: Vector3 = points[i]
		_make_cylinder(root, "StoneLanternBase_%d" % i, pos + Vector3(0, 0.35, 0), 0.25, 0.7, mat_stone, true)
		_make_box(root, "StoneLanternTop_%d" % i, pos + Vector3(0, 0.9, 0), Vector3(0.9, 0.35, 0.9), mat_stone, false)
		if i % 2 == 0:
			_make_cylinder(root, "StoneTable_%d" % i, pos + Vector3(2, 0.45, 0), 0.55, 0.18, mat_stone, true)
		else:
			_make_box(root, "WaterJar_%d" % i, pos + Vector3(-2, 0.55, 0), Vector3(0.9, 1.1, 0.9), mat_stone, true)

# ============================================================
# 构建摘要
# ============================================================
func _print_build_summary() -> void:
	print("=== GardenBuilder: 大观园场景构建完成 ===")
	print("  围墙: 闭合白墙灰瓦高墙 (南正门、北后门、东侧门)")
	print("  出入口: 正门可通行，后门和侧门为锁闭门楼防止越界")
	print("  假山: 曲径通幽 (正门内)")
	print("  沁芳溪: 南北贯穿水系")
	print("  石桥: 沁芳亭桥")
	print("  码头: 游船码头")
	print("  山体: 北侧主山 + 西北/东北山坡")
	print("  五院: 怡红院、潇湘馆、秋爽斋、蘅芜苑、稻香村独立围合")
	print("  补充: 青石板路、驳岸护栏、菜畦、假山、园林小品")
	print("  游廊: 西片区 + 东片区")
	print("  层次: 连续回廊、月洞门、影壁、花窗、扩湖、溪流、曲桥、竹林、遮挡墙")
	print("  外围: 民居(南)、府邸(东西)、农田(北)")
	print("==========================================")
