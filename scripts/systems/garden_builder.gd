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

func _ready() -> void:
	_init_materials()
	_build_perimeter_wall()
	_build_main_gate()
	_build_side_gates()
	_build_entrance_rockery()
	_build_qinfang_creek()
	_build_qinfang_bridge()
	_build_boat_dock()
	_build_mountain_terrain()
	_build_west_courtyards()
	_build_east_courtyards()
	_build_outer_buildings()
	# 稻香村菜畦在 _build_west_courtyards 中已构建
	_print_build_summary()

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

# ============================================================
# 1. 围墙系统 — 闭合青砖高墙
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
		Vector3(x_max - x_min, wall_h, wall_t), mat_wall)
	_make_mesh(wall_root, "Wall_North_Cap", Vector3(0, wall_h + cap_h / 2.0, z_max),
		Vector3(x_max - x_min + 0.4, cap_h, wall_t + 0.4), mat_wall_top)

	# 南墙 — 分两段，中间留正门洞 (门宽12)
	var gate_half_w := 6.0
	# 南墙左段
	var left_seg_len := (x_max - gate_half_w) - x_min
	_make_box(wall_root, "Wall_South_Left",
		Vector3((x_min + x_max - gate_half_w) / 2.0, wall_h / 2.0, z_min),
		Vector3(left_seg_len, wall_h, wall_t), mat_wall)
	# 南墙右段
	var right_seg_len := x_max - gate_half_w - x_min
	_make_box(wall_root, "Wall_South_Right",
		Vector3((gate_half_w + x_min) / 2.0 + left_seg_len, wall_h / 2.0, z_min),
		Vector3(x_max - gate_half_w, wall_h, wall_t), mat_wall)
	# 南墙帽
	_make_mesh(wall_root, "Wall_South_Cap_L",
		Vector3((x_min + x_max - gate_half_w) / 2.0, wall_h + cap_h / 2.0, z_min),
		Vector3(left_seg_len + 0.4, cap_h, wall_t + 0.4), mat_wall_top)
	_make_mesh(wall_root, "Wall_South_Cap_R",
		Vector3((gate_half_w + x_max) / 2.0, wall_h + cap_h / 2.0, z_min),
		Vector3(x_max - gate_half_w, cap_h, wall_t + 0.4), mat_wall_top)

	# 东墙 (x = x_max)
	_make_box(wall_root, "Wall_East", Vector3(x_max, wall_h / 2.0, 0),
		Vector3(wall_t, wall_h, z_max - z_min), mat_wall)
	_make_mesh(wall_root, "Wall_East_Cap", Vector3(x_max, wall_h + cap_h / 2.0, 0),
		Vector3(wall_t + 0.4, cap_h, z_max - z_min + 0.4), mat_wall_top)

	# 西墙 (x = x_min)
	_make_box(wall_root, "Wall_West", Vector3(x_min, wall_h / 2.0, 0),
		Vector3(wall_t, wall_h, z_max - z_min), mat_wall)
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

# ============================================================
# 2. 正门 — 五间大门楼
# ============================================================
func _build_main_gate() -> void:
	var gate_root := Node3D.new()
	gate_root.name = "MainGate"
	gate_root.position = Vector3(0, 0, -65)
	add_child(gate_root)

	var bay_w := 2.4
	var bay_count := 5
	var total_w := bay_w * bay_count
	var pillar_h := 7.0
	var roof_h := 2.5

	# 6根门柱 (五间六柱)
	for i in range(bay_count + 1):
		var x := -total_w / 2.0 + i * bay_w
		_make_cylinder(gate_root, "GatePillar_%d" % i,
			Vector3(x, pillar_h / 2.0, 0), 0.25, pillar_h, mat_wood_red)

	# 前后横梁
	_make_box(gate_root, "Beam_Front", Vector3(0, pillar_h - 0.3, 1.5),
		Vector3(total_w + 0.6, 0.3, 0.3), mat_wood_red, false)
	_make_box(gate_root, "Beam_Back", Vector3(0, pillar_h - 0.3, -1.5),
		Vector3(total_w + 0.6, 0.3, 0.3), mat_wood_red, false)

	# 大屋顶
	_make_box(gate_root, "GateRoof", Vector3(0, pillar_h + roof_h / 2.0, 0),
		Vector3(total_w + 4, roof_h, 6), mat_roof)
	_make_box(gate_root, "GateRoofOverhang", Vector3(0, pillar_h + 0.1, 0),
		Vector3(total_w + 6, 0.15, 8), mat_wall_top)

	# 门扇 — 中间两间
	for side in [-1, 1]:
		var door_x: float = side * bay_w / 2.0
		_make_box(gate_root, "Door_%s" % ("L" if side < 0 else "R"),
			Vector3(door_x, 2.5, 0), Vector3(bay_w * 0.8, 5, 0.3), mat_wood_red, false)

	# 门匾
	var plaque_mi := MeshInstance3D.new()
	plaque_mi.name = "GatePlaque"
	plaque_mi.position = Vector3(0, pillar_h - 1.2, 2.5)
	var plaque_mesh := BoxMesh.new()
	plaque_mesh.size = Vector3(6, 1.2, 0.15)
	plaque_mi.mesh = plaque_mesh
	var plaque_mat := StandardMaterial3D.new()
	plaque_mat.albedo_color = Color(0.15, 0.08, 0.03)
	plaque_mi.material_override = plaque_mat
	gate_root.add_child(plaque_mi)

	# 匾额文字 (Label3D)
	var label := Label3D.new()
	label.name = "GateLabel"
	label.text = "大 观 园"
	label.position = Vector3(0, pillar_h - 1.2, 2.7)
	label.font_size = 60
	label.modulate = Color(0.85, 0.7, 0.2)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	gate_root.add_child(label)

	# 石狮一对
	for side in [-1, 1]:
		var lion := StaticBody3D.new()
		lion.name = "StoneLion_%s" % ("L" if side < 0 else "R")
		lion.position = Vector3(side * 8, 0, 2)
		var lion_mi := MeshInstance3D.new()
		var lion_mesh := BoxMesh.new()
		lion_mesh.size = Vector3(1.5, 2.5, 1.5)
		lion_mi.mesh = lion_mesh
		lion_mi.material_override = mat_stone
		lion.add_child(lion_mi)
		var lion_col := CollisionShape3D.new()
		var lion_shape := BoxShape3D.new()
		lion_shape.size = Vector3(1.5, 2.5, 1.5)
		lion_col.shape = lion_shape
		lion.add_child(lion_col)
		gate_root.add_child(lion)

# ============================================================
# 3. 侧门 — 东西墙各一个
# ============================================================
func _build_side_gates() -> void:
	# 东侧门 (通往宁国府)
	_build_single_side_gate("SideGate_East", Vector3(60, 0, -20), 0)
	# 西侧门 (通往荣国府)
	_build_single_side_gate("SideGate_West", Vector3(-60, 0, -20), PI)

func _build_single_side_gate(gate_name: String, pos: Vector3, rot_y: float) -> void:
	var gate := Node3D.new()
	gate.name = gate_name
	gate.position = pos
	gate.rotation.y = rot_y
	add_child(gate)

	var pillar_h := 5.0
	# 两根门柱
	_make_cylinder(gate, "Pillar_L", Vector3(-3, pillar_h / 2.0, 0), 0.2, pillar_h, mat_wood_red)
	_make_cylinder(gate, "Pillar_R", Vector3(3, pillar_h / 2.0, 0), 0.2, pillar_h, mat_wood_red)
	# 横梁
	_make_box(gate, "Beam", Vector3(0, pillar_h - 0.2, 0), Vector3(6.6, 0.25, 0.25), mat_wood_red, false)
	# 小屋顶
	_make_box(gate, "Roof", Vector3(0, pillar_h + 0.8, 0), Vector3(8, 1.2, 4), mat_roof)

# ============================================================
# 4. 正门内假山 — "曲径通幽"
# ============================================================
func _build_entrance_rockery() -> void:
	var rock_root := Node3D.new()
	rock_root.name = "EntranceRockery"
	rock_root.position = Vector3(0, 0, -55)
	add_child(rock_root)

	# 随机堆放的假山石块
	var rock_positions := [
		Vector3(0, 1.5, 0), Vector3(-2.5, 2.2, 1), Vector3(2, 1.8, -0.5),
		Vector3(-1, 3.0, -1), Vector3(1.5, 2.8, 1.5), Vector3(-3, 1.2, -2),
		Vector3(3, 1.0, 2), Vector3(0, 3.5, 0.5), Vector3(-2, 0.8, 3),
		Vector3(2.5, 1.5, -2.5)
	]
	var rock_sizes := [
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
	var sign := Label3D.new()
	sign.name = "PathSign"
	sign.text = "曲径通幽"
	sign.position = Vector3(0, 5.5, 2)
	sign.font_size = 36
	sign.modulate = Color(0.75, 0.65, 0.35)
	rock_root.add_child(sign)

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
		Vector3(0, creek_y, -50), Vector3(1, creek_y, -30),
		Vector3(-1, creek_y, -10), Vector3(0, creek_y, 10),
		Vector3(1, creek_y, 30), Vector3(0, creek_y, 48),
	]
	var seg_sizes: Array[Vector3] = [
		Vector3(creek_w, 0.1, 20), Vector3(creek_w, 0.1, 20),
		Vector3(creek_w, 0.1, 20), Vector3(creek_w, 0.1, 20),
		Vector3(creek_w, 0.1, 20), Vector3(creek_w + 6, 0.1, 16),
	]
	for i in range(seg_positions.size()):
		_make_mesh(creek_root, "CreekSeg_%d" % i, seg_positions[i], seg_sizes[i], mat_water)

	# 溪岸 — 两侧土岸
	for i in range(seg_positions.size()):
		var s_pos := seg_positions[i]
		var s_size := seg_sizes[i]
		_make_mesh(creek_root, "Bank_L_%d" % i, Vector3(s_pos.x - s_size.x / 2.0 - 1.0, 0.02, s_pos.z),
			Vector3(2, 0.04, s_size.z), mat_creek_bank)
		_make_mesh(creek_root, "Bank_R_%d" % i, Vector3(s_pos.x + s_size.x / 2.0 + 1.0, 0.02, s_pos.z),
			Vector3(2, 0.04, s_size.z), mat_creek_bank)

# ============================================================
# 6. 沁芳亭石桥 — 横跨沁芳溪
# ============================================================
func _build_qinfang_bridge() -> void:
	var bridge := Node3D.new()
	bridge.name = "QinfangBridge"
	bridge.position = Vector3(0, 0, -10)
	add_child(bridge)

	# 桥面
	_make_box(bridge, "Deck", Vector3(0, 0.8, 0), Vector3(8, 0.3, 4), mat_stone)
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
	label.font_size = 30
	label.modulate = Color(0.8, 0.65, 0.25)
	bridge.add_child(label)

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
	_build_corridor(west_root, "WestCorridor",
		Vector3(-37, 0, 3), Vector3(-32, 0, -5), 3.0)
	_build_corridor(west_root, "WestCorridor2",
		Vector3(-32, 0, -5), Vector3(-27, 0, 20), 3.0)

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

	# 东片区连接游廊 (怡红院 → 缀锦阁)
	_build_corridor(east_root, "EastCorridor",
		Vector3(37, 0, 15), Vector3(42, 0, 25), 3.0)

# ============================================================
# 11. 外围建筑
# ============================================================
func _build_outer_buildings() -> void:
	var outer := Node3D.new()
	outer.name = "OuterBuildings"
	add_child(outer)

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
		display_name: String, character: String, roof_color: Color) -> void:
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
		var label := Label3D.new()
		label.name = "NameLabel"
		label.text = display_name
		label.position = Vector3(0, bldg_h + 1.5, bldg_d / 2.0)
		label.font_size = 28
		label.modulate = Color(0.8, 0.65, 0.25)
		cy.add_child(label)

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
# ============================================================
func _build_corridor(parent: Node3D, name_s: String, from: Vector3, to: Vector3, width: float) -> void:
	var cr := Node3D.new()
	cr.name = name_s
	parent.add_child(cr)

	var mid := (from + to) / 2.0
	var diff := to - from
	var length := diff.length()
	var angle := atan2(diff.x, diff.z)

	# 廊顶
	_make_box(cr, "CorridorRoof", Vector3(mid.x, 3.2, mid.z),
		Vector3(width + 1, 0.3, length + 1), mat_roof, false)
	# 廊地面
	_make_box(cr, "CorridorFloor", Vector3(mid.x, 0.05, mid.z),
		Vector3(width, 0.1, length), mat_brick, true)
	# 廊柱 (沿廊道每隔 4m 一根)
	var count := int(length / 4.0) + 1
	for i in range(count):
		var t: float = float(i) / max(count - 1, 1)
		var p := from.lerp(to, t)
		for side in [-1, 1]:
			var offset := Vector3(side * width / 2.0, 0, 0).rotated(Vector3.UP, angle)
			_make_cylinder(cr, "CorridorPillar_%d_%d" % [i, side],
				Vector3(p.x + offset.x, 1.6, p.z + offset.z), 0.1, 3.2, mat_wood_red, false)

	cr.rotation.y = 0  # 已通过位置计算旋转

# ============================================================
# 构建摘要
# ============================================================
func _print_build_summary() -> void:
	print("=== GardenBuilder: 大观园场景构建完成 ===")
	print("  围墙: 闭合青砖高墙 (120x120)")
	print("  正门: 五间大门楼 (南侧中轴)")
	print("  侧门: 东(宁国府) + 西(荣国府)")
	print("  假山: 曲径通幽 (正门内)")
	print("  沁芳溪: 南北贯穿水系")
	print("  石桥: 沁芳亭桥")
	print("  码头: 游船码头")
	print("  山体: 北侧主山 + 西北/东北山坡")
	print("  新增院落: 秋爽斋、紫菱洲、缀锦阁")
	print("  补充: 稻香村菜畦、栊翠庵围墙")
	print("  游廊: 西片区 + 东片区")
	print("  外围: 民居(南)、府邸(东西)、农田(北)")
	print("==========================================")
