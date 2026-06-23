@tool
extends Node
## 园林植被系统
## 基于 Ultimate Nature Pack 替换场景中所有球形简模植被
## 不改动建筑位置、游览动线、导航区域、碰撞约束

# ═══════════════════════════════════════════════════════
# FBX 模型路径
# ═══════════════════════════════════════════════════════
var _fbx := "res://assets/models/vegetation/FBX/"

# 树木
var _tree_willow: Array = []
var _tree_common: Array = []
var _tree_pine: Array = []
var _tree_birch: Array = []

# 灌木花草
var _shrub_1 := ""
var _shrub_2 := ""
var _berry_1 := ""
var _berry_2 := ""
var _flowers := ""
var _plant_1 := ""
var _plant_2 := ""
var _plant_3 := ""

# 草地
var _grass_1 := ""
var _grass_2 := ""
var _grass_s := ""

# 岩石
var _rocks: Array = []
var _rock_moss: Array = []

# 水生
var _lily := ""

# ═══════════════════════════════════════════════════════
# 荷塘中心坐标
# ═══════════════════════════════════════════════════════
var _pond_center := Vector3(-5, 0, -22)
var _pond_size := Vector3(28, 0.15, 18)

# ═══════════════════════════════════════════════════════
# 模型缓存
# ═══════════════════════════════════════════════════════
var _cache: Dictionary = {}

# ═══════════════════════════════════════════════════════
# 初始化路径数据
# ═══════════════════════════════════════════════════════
func _init_paths() -> void:
	_tree_willow = [_fbx+"Willow_1.fbx", _fbx+"Willow_2.fbx", _fbx+"Willow_3.fbx"]
	_tree_common = [_fbx+"CommonTree_1.fbx", _fbx+"CommonTree_2.fbx", _fbx+"CommonTree_3.fbx"]
	_tree_pine   = [_fbx+"PineTree_1.fbx", _fbx+"PineTree_2.fbx", _fbx+"PineTree_3.fbx"]
	_tree_birch  = [_fbx+"BirchTree_1.fbx", _fbx+"BirchTree_2.fbx", _fbx+"BirchTree_3.fbx"]

	_shrub_1 = _fbx+"Bush_1.fbx"
	_shrub_2 = _fbx+"Bush_2.fbx"
	_berry_1 = _fbx+"BushBerries_1.fbx"
	_berry_2 = _fbx+"BushBerries_2.fbx"
	_flowers = _fbx+"Flowers.fbx"
	_plant_1 = _fbx+"Plant_1.fbx"
	_plant_2 = _fbx+"Plant_2.fbx"
	_plant_3 = _fbx+"Plant_3.fbx"

	_grass_1 = _fbx+"Grass.fbx"
	_grass_2 = _fbx+"Grass_2.fbx"
	_grass_s = _fbx+"Grass_Short.fbx"

	_rocks     = [_fbx+"Rock_1.fbx", _fbx+"Rock_2.fbx", _fbx+"Rock_3.fbx", _fbx+"Rock_4.fbx"]
	_rock_moss = [_fbx+"Rock_Moss_1.fbx", _fbx+"Rock_Moss_2.fbx", _fbx+"Rock_Moss_3.fbx"]

	_lily = _fbx+"Lilypad.fbx"

# ═══════════════════════════════════════════════════════
# 生命周期
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	_init_paths()
	if Engine.is_editor_hint():
		_preload_models()
		_place_pond_vegetation()
		_place_path_trees()
		_place_building_greenery()
		_place_rockery_greenery()
		_place_lawn_grass()
		_place_roadside_plants()
		return
	# 延迟一帧让其他系统先初始化
	await get_tree().process_frame
	# 初始化路径数据
	_init_paths()
	# 调试输出
	print("[VegetationSystem] 开始初始化植被系统")
	# 1. 清除旧的球形植被
	_cleanup_old_vegetation()
	await get_tree().process_frame
	# 2. 预加载常用模型
	_preload_models()
	print("[VegetationSystem] 已缓存 ", _cache.size(), " 个模型")
	await get_tree().process_frame
	# 3. 部署新植被（每个步骤间隔一帧，避免卡死）
	_place_pond_vegetation()
	await get_tree().process_frame
	_place_path_trees()
	await get_tree().process_frame
	_place_building_greenery()
	await get_tree().process_frame
	_place_rockery_greenery()
	await get_tree().process_frame
	_place_lawn_grass()
	await get_tree().process_frame
	_place_roadside_plants()
	print("[VegetationSystem] 植被部署完成")

# ═══════════════════════════════════════════════════════
# 清除旧球形植被（保留容器节点结构）
# ═══════════════════════════════════════════════════════
func _cleanup_old_vegetation() -> void:
	# 删除旧 LotusPad / LotusFlower（点状荷花）
	var terrain := get_node_or_null("../Terrain")
	if terrain:
		for child in terrain.get_children():
			if child.name.begins_with("LotusPad") or child.name.begins_with("LotusFlower"):
				child.queue_free()

	# 删除旧 Vegetation 下的球形树和花
	var veg := get_node_or_null("../Vegetation")
	if veg:
		for child in veg.get_children():
			child.queue_free()
		# Vegetation 保留作新植被容器

	# 删除旧 BambooGrove（竹子简模）
	var bamboo_parent := get_node_or_null("../Buildings/XiaoxiangGuan/BambooGrove")
	if bamboo_parent:
		for child in bamboo_parent.get_children():
			child.queue_free()

# ═══════════════════════════════════════════════════════
# 预加载模型
# ═══════════════════════════════════════════════════════
func _preload_models() -> void:
	var all_paths: Array = []
	for arr in [_tree_willow, _tree_common, _tree_pine, _tree_birch, _rocks, _rock_moss]:
		for p in arr:
			all_paths.append(p)
	all_paths.append_array([_shrub_1, _shrub_2, _berry_1, _berry_2, _flowers,
		_plant_1, _plant_2, _plant_3, _grass_1, _grass_2, _grass_s, _lily])

	for path in all_paths:
		if ResourceLoader.exists(path):
			_cache[path] = load(path)

# ═══════════════════════════════════════════════════════
# 辅助：实例化一个 FBX 模型
# ═══════════════════════════════════════════════════════
func _inst(path: String, parent: Node3D, pos: Vector3, scale_f: float = 1.0, rot_y: float = -1.0) -> Node3D:
	if not _cache.has(path):
		return Node3D.new()
	var resource = _cache[path]
	if not resource:
		return Node3D.new()
	var node: Node3D
	# FBX 导入后可能是 PackedScene 或 ArrayMesh
	if resource is PackedScene:
		node = resource.instantiate()
	elif resource is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = resource
		node = mi
	else:
		return Node3D.new()
	node.position = pos
	if scale_f != 1.0:
		node.scale = Vector3(scale_f, scale_f, scale_f)
	if rot_y >= 0:
		node.rotation.y = rot_y
	else:
		node.rotation.y = randf() * TAU
	# LOD + 阴影配置
	if node is MeshInstance3D:
		node.lod_bias = 0.7
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	return node

func _rand_from(arr: Array) -> String:
	return arr[randi() % arr.size()]

# ═══════════════════════════════════════════════════════
# 一、荷塘精细化改造
# ═══════════════════════════════════════════════════════
func _place_pond_vegetation() -> void:
	var terrain := get_node_or_null("../Terrain")
	if not terrain:
		return

	# 荷叶散布在池塘水面（中心 y=0.05, 水面高度）
	var pond_positions := [
		Vector3(-10, 0.08, -20), Vector3(-8, 0.08, -24), Vector3(-3, 0.08, -20),
		Vector3(-6, 0.08, -25), Vector3(-12, 0.08, -23), Vector3(-1, 0.08, -22),
		Vector3(-9, 0.08, -19), Vector3(-4, 0.08, -26), Vector3(-7, 0.08, -21),
		Vector3(-11, 0.08, -24), Vector3(-2, 0.08, -23), Vector3(-5, 0.08, -19),
	]
	for i in pond_positions.size():
		var s := 0.6 + randf() * 0.5
		var r := randf() * TAU
		_inst(_lily, terrain, pond_positions[i], s, r)

	# 池塘岸边水生植物（芦苇用 Plant 替代）
	var shore_positions := [
		Vector3(-16, 0.1, -22), Vector3(-14, 0.1, -20), Vector3(-14, 0.1, -25),
		Vector3(4, 0.1, -22),   Vector3(3, 0.1, -20),   Vector3(5, 0.1, -25),
		Vector3(-5, 0.1, -13),  Vector3(-3, 0.1, -13),   Vector3(-7, 0.1, -13),
		Vector3(-5, 0.1, -31),  Vector3(-3, 0.1, -31),   Vector3(-7, 0.1, -31),
	]
	for pos in shore_positions:
		_inst(_plant_2, terrain, pos, 0.8 + randf() * 0.4, -1)

# ═══════════════════════════════════════════════════════
# 二、道路两侧 & 竹林
# ═══════════════════════════════════════════════════════
func _place_path_trees() -> void:
	var veg := get_node_or_null("../Vegetation")
	if not veg:
		return

	# 主石板路两侧垂柳（z=-40 到 z=25 沿中轴 x=0）
	var willow_left := [
		Vector3(-7, 0, -30), Vector3(-7, 0, -18), Vector3(-7, 0, -5),
		Vector3(-7, 0, 8), Vector3(-7, 0, 18),
	]
	var willow_right := [
		Vector3(7, 0, -30), Vector3(7, 0, -18), Vector3(7, 0, -5),
		Vector3(7, 0, 8), Vector3(7, 0, 18),
	]
	for pos in willow_left + willow_right:
		_inst(_rand_from(_tree_willow), veg, pos, 1.0 + randf() * 0.3, -1)

	# 横向路径两侧阔叶树
	var cross_tree_pos := [
		Vector3(-20, 0, 12), Vector3(-15, 0, 12),
		Vector3(15, 0, 12),  Vector3(20, 0, 12),
		Vector3(-20, 0, -5), Vector3(20, 0, -5),
	]
	for pos in cross_tree_pos:
		_inst(_rand_from(_tree_common), veg, pos, 0.9 + randf() * 0.3, -1)

	# 潇湘馆竹林（替换旧竹子简模）
	var bamboo_parent := get_node_or_null("../Buildings/XiaoxiangGuan/BambooGrove")
	if bamboo_parent:
		var bamboo_positions := [
			Vector3(-8, 0, 3), Vector3(-7, 0, 5), Vector3(-9, 0, 1),
			Vector3(-10, 0, 4), Vector3(-6, 0, 7), Vector3(-11, 0, 2),
			Vector3(-8, 0, 6), Vector3(-10, 0, 7), Vector3(-12, 0, 3),
			Vector3(-9, 0, 8), Vector3(-7, 0, 0), Vector3(-11, 0, 6),
		]
		# 用 BirchTree 替代竹子（白桦树干细长，视觉上接近竹子效果）
		for pos in bamboo_positions:
			_inst(_rand_from(_tree_birch), bamboo_parent, pos, 0.7 + randf() * 0.3, -1)

	# 庭院间稀疏乔木（不做密集种植，保持通透感）
	var sparse_tree_pos := [
		Vector3(-40, 0, 0), Vector3(40, 0, 0),
		Vector3(-45, 0, 20), Vector3(45, 0, 20),
		Vector3(-30, 0, -20), Vector3(30, 0, -20),
		Vector3(-20, 0, 30), Vector3(20, 0, 30),
		Vector3(0, 0, -45), Vector3(0, 0, 48),
	]
	for pos in sparse_tree_pos:
		_inst(_rand_from(_tree_common), veg, pos, 1.1 + randf() * 0.4, -1)

# ═══════════════════════════════════════════════════════
# 三、建筑周边绿化（弱化方块边缘）
# ═══════════════════════════════════════════════════════
func _place_building_greenery() -> void:
	var buildings := get_node_or_null("../Buildings")
	if not buildings:
		return

	# 每个建筑四角放灌木/花丛
	var building_offsets := {
		"EntranceGate":  Vector3(0, 0, -40),
		"XiaoxiangGuan": Vector3(-35, 0, 10),
		"YihongYuan":    Vector3(35, 0, 10),
		"LongcuiAn":     Vector3(0, 0, 40),
		"DaguanLou":     Vector3(0, 0, 25),
		"DaoxiangCun":   Vector3(-25, 0, -15),
		"HengwuYuan":    Vector3(25, 0, -15),
	}

	for bname in building_offsets:
		var base: Vector3 = building_offsets[bname]
		var corners := [
			base + Vector3(-7, 0, 5.5),   # 前左
			base + Vector3(7, 0, 5.5),    # 前右
			base + Vector3(-7, 0, -5.5),  # 后左
			base + Vector3(7, 0, -5.5),   # 后右
		]
		for i in corners.size():
			var path = [_shrub_1, _shrub_2, _berry_1, _berry_2][i % 4]
			_inst(path, buildings, corners[i], 0.8 + randf() * 0.3, -1)

		# 前门两侧各一株花丛
		_inst(_flowers, buildings, base + Vector3(-4, 0, 6.5), 0.7, randf() * TAU)
		_inst(_flowers, buildings, base + Vector3(4, 0, 6.5), 0.7, randf() * TAU)

# ═══════════════════════════════════════════════════════
# 四、假山周边绿化
# ═══════════════════════════════════════════════════════
func _place_rockery_greenery() -> void:
	var features := get_node_or_null("../GardenFeatures")
	if not features:
		return

	# 假山1（55, 0, 30）周边
	var rock1_pos := [
		Vector3(52, 0, 28), Vector3(58, 0, 32), Vector3(50, 0, 33),
		Vector3(56, 0, 27), Vector3(60, 0, 29),
	]
	# 假山2（-55, 0, 30）周边
	var rock2_pos := [
		Vector3(-52, 0, 28), Vector3(-58, 0, 32), Vector3(-50, 0, 33),
		Vector3(-56, 0, 27), Vector3(-60, 0, 29),
	]
	for pos in rock1_pos + rock2_pos:
		# 假山旁放苔藓岩石 + 灌木
		if randf() > 0.5:
			_inst(_rand_from(_rock_moss), features, pos, 0.5 + randf() * 0.4, -1)
		else:
			_inst(_rand_from([_shrub_1, _berry_1, _plant_3]), features, pos, 0.7, -1)

	# 凉亭周围点缀小型植物
	var pavilion1 := Vector3(15, 0, -20)
	var pavilion2 := Vector3(-15, 0, -20)
	for base in [pavilion1, pavilion2]:
		for off in [Vector3(-4, 0, 0), Vector3(4, 0, 0), Vector3(0, 0, -4), Vector3(0, 0, 4)]:
			_inst(_plant_1, features, base + off, 0.6, -1)

# ═══════════════════════════════════════════════════════
# 五、草坪草丛
# ═══════════════════════════════════════════════════════
func _place_lawn_grass() -> void:
	var veg := get_node_or_null("../Vegetation")
	if not veg:
		return

	# 生成伪随机草地散布点（避开建筑和水域）
	var grass_positions: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # 固定种子保证可复现

	for i in 80:
		var x := rng.randf_range(-55, 55)
		var z := rng.randf_range(-38, 48)
		# 避开池塘区域
		if x > -19 and x < 9 and z > -31 and z < -13:
			continue
		# 避开建筑中心区域（简单圆形排斥）
		var skip := false
		for bpos in [Vector3(0,0,-40), Vector3(-35,0,10), Vector3(35,0,10),
			Vector3(0,0,40), Vector3(0,0,25), Vector3(-25,0,-15), Vector3(25,0,-15)]:
			if Vector2(x - bpos.x, z - bpos.z).length() < 10:
				skip = true
				break
		if skip:
			continue
		grass_positions.append(Vector3(x, 0.02, z))

	for pos in grass_positions:
		var path = [_grass_1, _grass_2, _grass_s][randi() % 3]
		var s := 0.4 + randf() * 0.5
		_inst(path, veg, pos, s, -1)
		# 草丛旁随机放小花
		if randf() > 0.7:
			var flower_off := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
			_inst(_flowers, veg, pos + flower_off, 0.3 + randf() * 0.3, -1)

# ═══════════════════════════════════════════════════════
# 六、路边小型绿植（引导行进路线）
# ═══════════════════════════════════════════════════════
func _place_roadside_plants() -> void:
	var veg := get_node_or_null("../Vegetation")
	if not veg:
		return

	# 主石板路边缘（x=0 路，宽度约3m，绿植放在 x=±2.5 外侧）
	var road_plant_pos: Array = []
	var z_pos := -38.0
	while z_pos < 45:
		z_pos += 3.0 + randf() * 2.0
		if randf() > 0.4:
			road_plant_pos.append(Vector3(-2.5 - randf() * 0.5, 0.02, z_pos))
		if randf() > 0.4:
			road_plant_pos.append(Vector3(2.5 + randf() * 0.5, 0.02, z_pos))

	for pos in road_plant_pos:
		var path = [_plant_1, _plant_2, _plant_3, _grass_s][randi() % 4]
		_inst(path, veg, pos, 0.4 + randf() * 0.3, -1)

	# 横向路径（z=15 交叉路口）
	for x in range(-30, 31, 4):
		if randf() > 0.5:
			_inst(_plant_2, veg, Vector3(x, 0.02, 15.5), 0.5, -1)
