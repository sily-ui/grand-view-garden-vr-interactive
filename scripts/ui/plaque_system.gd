@tool
extends Node3D
## 3D匾额对联系统
## 为院落大门添加黑底金字古风宋体匾额与对联
## VR优化：大字号、发光金字、无远距离模糊、适配VR头戴设备

# ═══════════════════════════════════════════════════════
# 常量配置
# ═══════════════════════════════════════════════════════
const GOLD := Color(0.92, 0.78, 0.28, 1.0)
const GOLD_DARK := Color(0.75, 0.62, 0.18, 1.0)
const BLACK_BG := Color(0.05, 0.04, 0.03, 1.0)
const BLACK_COUPLET := Color(0.06, 0.05, 0.04, 1.0)

# 匾额字号（大字号适配VR远距离查看）
const PLAK_FONT := 76
# 对联字号
const CPLT_FONT := 44
# 像素尺寸（1像素 = 1cm 世界单位）
const PX := 0.01
# 匾额面板尺寸
const PLAK_SIZE := Vector3(3.4, 1.4, 0.16)
# 对联面板尺寸
const CPLT_SIZE := Vector3(0.52, 2.8, 0.13)

# 院落建筑尺寸（与现有建筑一致）
const HOUSE_SIZE := Vector3(12, 4, 10)
const ROOF_SIZE := Vector3(14, 0.5, 12)
const FOUNDATION_SIZE := Vector3(13, 0.4, 11)
const PILLAR_RADIUS := 0.18
const PILLAR_HEIGHT := 3.5
const COURTYARD_WALL_SIZE := Vector3(0.4, 3.2, 16)
const COURTYARD_WALL_CAP_SIZE := Vector3(0.7, 0.2, 16.4)

# ═══════════════════════════════════════════════════════
# 运行时材质
# ═══════════════════════════════════════════════════════
var _mat_plak_bg: StandardMaterial3D
var _mat_cplt_bg: StandardMaterial3D
var _mat_wall: StandardMaterial3D
var _mat_roof: StandardMaterial3D
var _mat_pillar_red: StandardMaterial3D
var _mat_beam_dark: StandardMaterial3D
var _mat_stone: StandardMaterial3D
var _mat_door: StandardMaterial3D
var _mat_courtyard_wall: StandardMaterial3D
var _mat_wall_cap: StandardMaterial3D

# ═══════════════════════════════════════════════════════
# 生命周期
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	_init_materials()
	_hide_legacy_entrance_gate()
	# 2. 潇湘馆：添加匾额和对联
	_setup_xiaoxiang()
	# 3. 怡红院：升级现有匾额和对联
	_setup_yihong()
	# 4. 秋爽斋：新建院落 + 匾额对联
	_setup_qiushuang()
	# 5. 蘅芜苑：升级现有匾额和对联
	_setup_hengwu()
	# 6. 稻香村：升级现有匾额和对联
	_setup_daoxiang()

# ═══════════════════════════════════════════════════════
# 材质初始化
# ═══════════════════════════════════════════════════════
func _init_materials() -> void:
	# 匾额黑底（漆面质感，微发光）
	_mat_plak_bg = StandardMaterial3D.new()
	_mat_plak_bg.albedo_color = BLACK_BG
	_mat_plak_bg.roughness = 0.18
	_mat_plak_bg.metallic = 0.15
	_mat_plak_bg.emission_enabled = true
	_mat_plak_bg.emission = Color(0.04, 0.03, 0.012)
	_mat_plak_bg.emission_energy_multiplier = 0.3

	# 对联黑底（略浅）
	_mat_cplt_bg = StandardMaterial3D.new()
	_mat_cplt_bg.albedo_color = BLACK_COUPLET
	_mat_cplt_bg.roughness = 0.22
	_mat_cplt_bg.metallic = 0.1
	_mat_cplt_bg.emission_enabled = true
	_mat_cplt_bg.emission = Color(0.03, 0.02, 0.008)
	_mat_cplt_bg.emission_energy_multiplier = 0.2

	# 建筑用材质
	_mat_wall = StandardMaterial3D.new()
	_mat_wall.albedo_color = Color(0.92, 0.88, 0.82, 1)
	_mat_wall.roughness = 0.92

	_mat_roof = StandardMaterial3D.new()
	_mat_roof.albedo_color = Color(0.38, 0.4, 0.42, 1)
	_mat_roof.roughness = 0.65

	_mat_pillar_red = StandardMaterial3D.new()
	_mat_pillar_red.albedo_color = Color(0.58, 0.12, 0.08, 1)
	_mat_pillar_red.roughness = 0.65

	_mat_beam_dark = StandardMaterial3D.new()
	_mat_beam_dark.albedo_color = Color(0.35, 0.2, 0.12, 1)
	_mat_beam_dark.roughness = 0.7

	_mat_stone = StandardMaterial3D.new()
	_mat_stone.albedo_color = Color(0.55, 0.55, 0.52, 1)
	_mat_stone.roughness = 0.78

	_mat_door = StandardMaterial3D.new()
	_mat_door.albedo_color = Color(0.55, 0.15, 0.1, 1)
	_mat_door.roughness = 0.7

	_mat_courtyard_wall = StandardMaterial3D.new()
	_mat_courtyard_wall.albedo_color = Color(0.9, 0.86, 0.78, 1)
	_mat_courtyard_wall.roughness = 0.9

	_mat_wall_cap = StandardMaterial3D.new()
	_mat_wall_cap.albedo_color = Color(0.35, 0.35, 0.38, 1)
	_mat_wall_cap.roughness = 0.65

# ═══════════════════════════════════════════════════════
# 辅助函数：创建匾额面板
# ═══════════════════════════════════════════════════════
func _make_plaque_board(parent: Node3D, pos: Vector3, size: Vector3 = PLAK_SIZE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = _mat_plak_bg
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

# ═══════════════════════════════════════════════════════
# 辅助函数：创建金字Label3D
# ═══════════════════════════════════════════════════════
func _make_gold_label(parent: Node3D, text: String, pos: Vector3, font_size: int) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = font_size
	lbl.pixel_size = PX
	lbl.modulate = GOLD
	lbl.position = pos
	# 黑色描边增强对比度
	lbl.outline_size = 10
	lbl.outline_modulate = Color(0.08, 0.06, 0.02, 1.0)
	lbl.no_depth_test = false
	lbl.fixed_size = false
	lbl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# 双面渲染确保远处可见
	lbl.double_sided = true
	parent.add_child(lbl)
	return lbl

func _face_south(node: Node3D) -> void:
	node.rotation.y = PI

# ═══════════════════════════════════════════════════════
# 辅助函数：创建对联（左右两块板+文字）
# ═══════════════════════════════════════════════════════
func _make_couplet_pair(parent: Node3D, left_pos: Vector3, right_pos: Vector3,
		left_text: String, right_text: String, font_size: int = CPLT_FONT) -> void:
	# 左对联板（面对门口时的左侧）
	_make_plaque_board(parent, left_pos, CPLT_SIZE)
	_make_gold_label(parent, left_text, left_pos + Vector3(0, 0, CPLT_SIZE.z * 0.5 + 0.02), font_size)
	# 右对联板
	_make_plaque_board(parent, right_pos, CPLT_SIZE)
	_make_gold_label(parent, right_text, right_pos + Vector3(0, 0, CPLT_SIZE.z * 0.5 + 0.02), font_size)

# ═══════════════════════════════════════════════════════
# 辅助函数：移除旧的匾额/对联节点
# ═══════════════════════════════════════════════════════
func _remove_old_signs(building: Node) -> void:
	for child_name in ["Plaque", "Couplet", "GateNamePlate", "GateCoupletL", "GateCoupletR", "NamePlate"]:
		var node := building.get_node_or_null(child_name)
		if node and node is Label3D:
			node.queue_free()

# ═══════════════════════════════════════════════════════
# 1. 旧荣国府正门
# ═══════════════════════════════════════════════════════
func _hide_legacy_entrance_gate() -> void:
	var gate := get_node_or_null("../Buildings/EntranceGate")
	if not gate:
		return
	gate.visible = false
	gate.process_mode = Node.PROCESS_MODE_DISABLED
	_disable_collision_shapes(gate)

func _disable_collision_shapes(node: Node) -> void:
	if node is CollisionShape3D:
		node.disabled = true
	for child in node.get_children():
		_disable_collision_shapes(child)

# ═══════════════════════════════════════════════════════
# 2. 潇湘馆
# ═══════════════════════════════════════════════════════
func _setup_xiaoxiang() -> void:
	var building := get_node_or_null("../Buildings/XiaoxiangGuan")
	if not building:
		push_warning("PlaqueSystem: 找不到 XiaoxiangGuan 节点")
		return

	# 移除旧NamePlate
	_remove_old_signs(building)

	# 匾额：位于前立面梁上
	_make_plaque_board(building, Vector3(0, 4.8, 5.2))
	_make_gold_label(building, "潇湘馆", Vector3(0, 4.8, 5.3), PLAK_FONT)

	# 对联（前柱两侧）
	# 上联：宝鼎茶闲烟尚绿
	# 下联：幽窗棋罢指犹凉
	_make_couplet_pair(building,
		Vector3(-5.8, 2.8, 5.2),
		Vector3(5.8, 2.8, 5.2),
		"幽\n窗\n棋\n罢\n指\n犹\n凉",
		"宝\n鼎\n茶\n闲\n烟\n尚\n绿")

# ═══════════════════════════════════════════════════════
# 3. 怡红院
# ═══════════════════════════════════════════════════════
func _setup_yihong() -> void:
	var building := get_node_or_null("../Buildings/YihongYuan")
	if not building:
		push_warning("PlaqueSystem: 找不到 YihongYuan 节点")
		return

	_remove_old_signs(building)
	_make_plaque_board(building, Vector3(0, 4.8, 5.2))
	_make_gold_label(building, "怡红院", Vector3(0, 4.8, 5.3), PLAK_FONT)
	_make_couplet_pair(building,
		Vector3(-5.8, 2.8, 5.2),
		Vector3(5.8, 2.8, 5.2),
		"绿\n蜡\n春\n犹\n卷",
		"红\n妆\n夜\n未\n眠")

# ═══════════════════════════════════════════════════════
# 4. 秋爽斋（新建院落 + 匾额对联）
# ═══════════════════════════════════════════════════════
func _setup_qiushuang() -> void:
	# 秋爽斋位于西南区域，(-25, 0, 25) - 与稻香村对称
	var pos := Vector3(-25, 0, 25)
	var building := _build_courtyard("秋爽斋", pos, "贾探春居所，秋高气爽，阔朗大方", "visit_qiushuang")

	# 匾额
	_make_plaque_board(building, Vector3(0, 4.8, 5.2))
	_make_gold_label(building, "秋爽斋", Vector3(0, 4.8, 5.3), PLAK_FONT)

	# 对联
	# 上联：斜风细雨初相候
	# 下联：落叶归云自在飞
	_make_couplet_pair(building,
		Vector3(-5.8, 2.8, 5.2),
		Vector3(5.8, 2.8, 5.2),
		"落\n叶\n归\n云\n自\n在\n飞",
		"斜\n风\n细\n雨\n初\n相\n候")

# ═══════════════════════════════════════════════════════
# 5. 蘅芜苑（升级现有匾额对联）
# ═══════════════════════════════════════════════════════
func _setup_hengwu() -> void:
	var building := get_node_or_null("../Buildings/HengwuYuan")
	if not building:
		push_warning("PlaqueSystem: 找不到 HengwuYuan 节点")
		return

	# 移除旧匾额和对联
	_remove_old_signs(building)

	# 匾额
	_make_plaque_board(building, Vector3(0, 4.8, 5.2))
	_make_gold_label(building, "蘅芜苑", Vector3(0, 4.8, 5.3), PLAK_FONT)

	# 对联
	# 上联：吟成豆蔻诗犹艳
	# 下联：睡足酴醾梦亦香
	_make_couplet_pair(building,
		Vector3(-5.8, 2.8, 5.2),
		Vector3(5.8, 2.8, 5.2),
		"睡\n足\n酴\n醾\n梦\n亦\n香",
		"吟\n成\n豆\n蔻\n诗\n犹\n艳")

# ═══════════════════════════════════════════════════════
# 6. 稻香村
# ═══════════════════════════════════════════════════════
func _setup_daoxiang() -> void:
	var building := get_node_or_null("../Buildings/DaoxiangCun")
	if not building:
		push_warning("PlaqueSystem: 找不到 DaoxiangCun 节点")
		return

	_remove_old_signs(building)
	_make_plaque_board(building, Vector3(0, 4.8, 5.2))
	_make_gold_label(building, "稻香村", Vector3(0, 4.8, 5.3), PLAK_FONT)
	_make_couplet_pair(building,
		Vector3(-5.8, 2.8, 5.2),
		Vector3(5.8, 2.8, 5.2),
		"杏\n帘\n在\n望\n香\n风\n暖",
		"稻\n花\n深\n处\n野\n云\n闲")

# ═══════════════════════════════════════════════════════
# 建筑生成：创建完整院落（与现有建筑风格一致）
# ═══════════════════════════════════════════════════════
func _build_courtyard(building_name: String, world_pos: Vector3, desc: String, dialog_id: String) -> Node3D:
	var building_script = preload("res://scripts/buildings/building_base.gd")

	# 根节点
	var root := StaticBody3D.new()
	root.name = building_name.replace(" ", "")
	root.set_script(building_script)
	root.building_name = building_name
	root.building_description = desc
	root.associated_dialog = dialog_id
	root.position = world_pos
	root.add_to_group("building")

	# ── 基座 ──
	var foundation := _make_box_mesh(FOUNDATION_SIZE, _mat_stone, Vector3(0, 0.2, 0))
	root.add_child(foundation)

	# ── 主体 ──
	var house := _make_box_mesh(HOUSE_SIZE, _mat_wall, Vector3(0, 2, 0))
	root.add_child(house)

	# ── 屋顶 ──
	var roof := _make_box_mesh(ROOF_SIZE, _mat_roof, Vector3(0, 4.25, 0))
	root.add_child(roof)

	var roof_layer := _make_box_mesh(Vector3(15, 0.15, 13), _mat_roof, Vector3(0, 4.45, 0))
	root.add_child(roof_layer)

	# ── 前柱（圆柱） ──
	_add_column(root, Vector3(-5.5, 2.15, 4.5))
	_add_column(root, Vector3(5.5, 2.15, 4.5))
	# 后柱
	_add_column(root, Vector3(-5.5, 2.15, -4.5))
	_add_column(root, Vector3(5.5, 2.15, -4.5))

	# ── 梁 ──
	var beam_front := _make_box_mesh(Vector3(12, 0.22, 0.22), _mat_beam_dark, Vector3(0, 3.7, 4.5))
	root.add_child(beam_front)
	var beam_back := _make_box_mesh(Vector3(12, 0.22, 0.22), _mat_beam_dark, Vector3(0, 3.7, -4.5))
	root.add_child(beam_back)

	# ── 碰撞体 ──
	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = HOUSE_SIZE
	col.shape = col_shape
	col.position = Vector3(0, 2, 0)
	root.add_child(col)

	# ── 入口检测区域 ──
	var entrance := Area3D.new()
	entrance.name = "EntranceArea"
	entrance.position = Vector3(0, 2, 6)
	var entrance_col := CollisionShape3D.new()
	var entrance_shape := BoxShape3D.new()
	entrance_shape.size = Vector3(6, 4, 4)
	entrance_col.shape = entrance_shape
	entrance.add_child(entrance_col)
	root.add_child(entrance)

	# ── NamePlate ──
	var name_lbl := Label3D.new()
	name_lbl.name = "NamePlate"
	name_lbl.text = building_name
	name_lbl.font_size = 48
	name_lbl.pixel_size = PX
	name_lbl.position = Vector3(0, 5, 5.5)
	name_lbl.modulate = GOLD_DARK
	root.add_child(name_lbl)

	# ── 院墙（南墙带门洞、北墙、东墙、西墙） ──
	_add_courtyard_wall(root, Vector3(-5.5, 1.6, -7), Vector3(0, 0, 0))   # 南左墙
	_add_courtyard_wall(root, Vector3(5.5, 1.6, -7), Vector3(0, 0, 0))    # 即使门洞处也可以有半墙
	_add_courtyard_wall(root, Vector3(0, 1.6, 7), Vector3(0, 0, 0))       # 北墙
	_add_courtyard_wall(root, Vector3(-8, 1.6, 0), Vector3(0, deg_to_rad(90), 0))  # 西墙
	_add_courtyard_wall(root, Vector3(8, 1.6, 0), Vector3(0, deg_to_rad(90), 0))   # 东墙

	# ── 翘檐装饰（四角飞檐） ──
	var eave_offsets := [
		Vector3(-7, 4.8, 6.5), Vector3(7, 4.8, 6.5),
		Vector3(-7, 4.8, -6.5), Vector3(7, 4.8, -6.5)
	]
	for offset in eave_offsets:
		var eave := _make_box_mesh(Vector3(0.8, 0.2, 0.8), _mat_roof, offset)
		# 微翘旋转
		var rx := 0.15 if offset.z > 0 else -0.15
		var rz := 0.1 if offset.x < 0 else -0.1
		eave.rotation = Vector3(rx, 0, rz)
		root.add_child(eave)

	# 添加到场景
	get_node("../Buildings").add_child(root)
	return root

# ═══════════════════════════════════════════════════════
# 辅助：创建圆柱柱子
# ═══════════════════════════════════════════════════════
func _add_column(parent: Node3D, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = PILLAR_RADIUS
	cyl.bottom_radius = PILLAR_RADIUS + 0.03
	cyl.height = PILLAR_HEIGHT
	mi.mesh = cyl
	mi.material_override = _mat_pillar_red
	mi.position = pos
	parent.add_child(mi)

# ═══════════════════════════════════════════════════════
# 辅助：创建院墙段
# ═══════════════════════════════════════════════════════
func _add_courtyard_wall(parent: Node3D, pos: Vector3, rot: Vector3) -> void:
	# 墙体
	var wall := _make_box_mesh(COURTYARD_WALL_SIZE, _mat_courtyard_wall, pos)
	wall.rotation = rot
	parent.add_child(wall)
	# 墙帽
	var cap := _make_box_mesh(COURTYARD_WALL_CAP_SIZE, _mat_wall_cap, pos + Vector3(0, 1.7, 0))
	cap.rotation = rot
	parent.add_child(cap)

# ═══════════════════════════════════════════════════════
# 辅助：快速创建BoxMesh MeshInstance3D
# ═══════════════════════════════════════════════════════
func _make_box_mesh(size: Vector3, mat: StandardMaterial3D, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	return mi
