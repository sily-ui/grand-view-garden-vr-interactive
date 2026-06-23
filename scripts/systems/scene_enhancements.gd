extends Node
## 场景增强系统：光照、音效、LOD/遮挡剔除
## 运行时自动配置，无需手动编辑.tscn

# ═══════════════════════════════════════════════════════
# 建筑位置数据（运行时初始化，避免const中使用Vector3）
# ═══════════════════════════════════════════════════════
var _building_positions: Dictionary = {}

# 灯笼色温：暖橙色（烛光约1800K-2200K）
const LANTERN_COLOR_R := 1.0
const LANTERN_COLOR_G := 0.72
const LANTERN_COLOR_B := 0.35
const LANTERN_ENERGY := 1.2
const LANTERN_RANGE := 8.0

# 院落BGM映射（资源路径，运行时需手动配置实际音频文件）
var _courtyard_bgm: Dictionary = {}

# ═══════════════════════════════════════════════════════
# 生命周期
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	_init_data()
	# 1. 光照系统
	_setup_sun_light()
	_setup_indoor_lanterns()
	# 2. 音效系统
	_setup_ambient_audio()
	# BGM 切换由 AudioSystem 单路管理，避免多系统同时淡入淡出造成叠音。
	# 3. LOD + 遮挡剔除
	_setup_lod_and_occlusion()

func _init_data() -> void:
	_building_positions = {
		"EntranceGate":  Vector3(0, 0, -40),
		"XiaoxiangGuan": Vector3(-35, 0, 10),
		"YihongYuan":    Vector3(35, 0, 10),
		"LongcuiAn":     Vector3(0, 0, 40),
		"DaguanLou":     Vector3(0, 0, 25),
		"DaoxiangCun":   Vector3(-25, 0, -15),
		"HengwuYuan":    Vector3(25, 0, -15),
	}
	_courtyard_bgm = {
		"潇湘馆": "res://assets/audio/bgm/xiaoxiang_ambience.ogg",
		"怡红院": "res://assets/audio/bgm/yihong_ambience.ogg",
		"栊翠庵": "res://assets/audio/bgm/longcui_ambience.ogg",
		"大观楼": "res://assets/audio/bgm/daguan_ambience.ogg",
		"稻香村": "res://assets/audio/bgm/daoxiang_ambience.ogg",
		"蘅芜苑": "res://assets/audio/bgm/hengwu_ambience.ogg",
		"秋爽斋": "res://assets/audio/bgm/qiushuang_ambience.ogg",
		"缀锦阁": "res://assets/audio/bgm/zhuijin_ambience.ogg",
	}

# ═══════════════════════════════════════════════════════
# 1. 太阳光：暖色柔光 + 软阴影
# ═══════════════════════════════════════════════════════
func _setup_sun_light() -> void:
	var sun := get_node_or_null("../Sun")
	if not sun or not sun is DirectionalLight3D:
		push_warning("SceneEnhancements: 找不到 Sun 节点")
		return

	# 暖色调日间光（约5000K色温偏暖）
	sun.light_color = Color(1.0, 0.92, 0.78, 1.0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	# 软阴影：增大阴影模糊半径
	sun.shadow_blur = 1.5
	# 阴影偏移避免条纹瑕疵
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_split_1 = 0.1
	sun.directional_shadow_split_2 = 0.2
	sun.directional_shadow_split_3 = 0.5
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 3.0
	sun.directional_shadow_pancake_size = 5.0

	# 同步调整环境光
	var world_env := get_node_or_null("../WorldEnvironment")
	if world_env and world_env is WorldEnvironment and world_env.environment:
		var env: Environment = world_env.environment
		env.ambient_light_color = Color(0.6, 0.56, 0.5, 1)
		env.ambient_light_energy = 0.55
		# 调整雾效配合暖光
		env.fog_light_color = Color(0.82, 0.78, 0.72, 1)
		env.fog_density = 0.003

# ═══════════════════════════════════════════════════════
# 1b. 室内灯笼点光源
# ═══════════════════════════════════════════════════════
func _setup_indoor_lanterns() -> void:
	var buildings := get_node_or_null("../Buildings")
	if not buildings:
		return

	for building in buildings.get_children():
		if not building is Node3D:
			continue
		# 每个建筑内部放置2-4个灯笼
		var positions := _get_lantern_positions(building.name)
		for i in positions.size():
			_add_lantern(building, positions[i], building.name + "_Lantern" + str(i + 1))

func _get_lantern_positions(building_name: String) -> Array:
	# 建筑内部灯笼位置（相对坐标）
	match building_name:
		"EntranceGate":
			return [Vector3(-3, 3.5, 0), Vector3(3, 3.5, 0)]
		"DaguanLou":
			return [Vector3(-3, 4.5, 2), Vector3(3, 4.5, 2), Vector3(-3, 4.5, -2), Vector3(3, 4.5, -2)]
		_:
			# 默认2个灯笼，挂在前柱内侧
			return [Vector3(-3, 3.0, 3), Vector3(3, 3.0, 3)]

func _add_lantern(parent: Node3D, pos: Vector3, lantern_name: String) -> void:
	var lantern_color := Color(LANTERN_COLOR_R, LANTERN_COLOR_G, LANTERN_COLOR_B, 1.0)
	var light := OmniLight3D.new()
	light.name = lantern_name
	light.position = pos
	light.light_color = lantern_color
	light.light_energy = LANTERN_ENERGY
	light.omni_range = LANTERN_RANGE
	light.omni_attenuation = 1.5
	light.shadow_enabled = true
	# 灯笼光不产生过强阴影
	light.shadow_blur = 2.0
	parent.add_child(light)

	# 灯笼视觉模型（小发光球体）
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = lantern_color
	mat.emission_enabled = true
	mat.emission = lantern_color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

# ═══════════════════════════════════════════════════════
# 2. 环境音效系统
# ═══════════════════════════════════════════════════════
func _setup_ambient_audio() -> void:
	# 创建3个环境音播放器（风声、鸟鸣、流水）
	_create_ambient_player("WindAmbient", -12.0)    # 庭院风声
	_create_ambient_player("BirdAmbient", -18.0)    # 林间鸟鸣
	_create_ambient_player("WaterAmbient", -15.0)   # 池塘流水

func _create_ambient_player(player_name: String, vol_db: float) -> void:
	var player := AudioStreamPlayer3D.new()
	player.name = player_name
	player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	player.volume_db = vol_db
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.max_distance = 40.0
	player.unit_size = 5.0

	# 生成环境白噪声音调（占位，实际项目替换为.ogg音频文件）
	# 风声：低频噪声 | 鸟鸣：高频脉冲 | 流水：中频噪声
	match player_name:
		"WindAmbient":
			player.position = Vector3(0, 3, 0)
		"BirdAmbient":
			player.position = Vector3(-20, 6, 20)
		"WaterAmbient":
			player.position = Vector3(-5, 1, -22)

	var parent := get_tree().current_scene
	if not parent:
		parent = self
	parent.add_child(player)

# ═══════════════════════════════════════════════════════
# 2b. 院落BGM自动切换
# ═══════════════════════════════════════════════════════
func _setup_building_bgm_triggers() -> void:
	# 连接EventBus信号实现院落BGM切换
	if EventBus:
		EventBus.building_entered.connect(_on_building_entered_for_bgm)
		EventBus.building_exited.connect(_on_building_exited_for_bgm)

func _on_building_entered_for_bgm(building_name: String) -> void:
	# 获取AudioSystem并切换BGM
	var audio_sys := get_node_or_null("../Systems/AudioSystem")
	if not audio_sys:
		audio_sys = get_tree().get_first_node_in_group("audio_system")
	if not audio_sys:
		return

	# 查找匹配的BGM
	for key in _courtyard_bgm:
		if building_name.contains(key) or key.contains(building_name):
			var path: String = _courtyard_bgm[key]
			if ResourceLoader.exists(path):
				audio_sys.play_bgm(path, 1.5)
			return

func _on_building_exited_for_bgm(_building_name: String) -> void:
	# 离开院落后渐弱并停止BGM
	var audio_sys := get_node_or_null("../Systems/AudioSystem")
	if not audio_sys:
		audio_sys = get_tree().get_first_node_in_group("audio_system")
	if audio_sys:
		audio_sys.stop_bgm(1.5)

# ═══════════════════════════════════════════════════════
# 3. LOD 细节分级 + 遮挡剔除
# ═══════════════════════════════════════════════════════
func _setup_lod_and_occlusion() -> void:
	# 设置全局渲染参数优化VR帧率
	_configure_rendering_settings()

	# 为所有建筑添加LOD和遮挡剔除
	var buildings := get_node_or_null("../Buildings")
	if buildings:
		for child in buildings.get_children():
			_apply_lod_to_node(child)

	# 为植被添加LOD
	var vegetation := get_node_or_null("../Vegetation")
	if vegetation:
		for child in vegetation.get_children():
			_apply_lod_to_node(child)

	# 为园林要素添加LOD
	var features := get_node_or_null("../GardenFeatures")
	if features:
		for child in features.get_children():
			_apply_lod_to_node(child)

func _configure_rendering_settings() -> void:
	# VR性能优化渲染设置
	RenderingServer.directional_shadow_atlas_set_size(2048, true)
	# 设置全局LOD偏移（值越大LOD切换越早，节省性能）
	# Godot 4.7中通过项目设置控制，此处为运行时提示

func _apply_lod_to_node(node: Node) -> void:
	if not node is Node3D:
		return

	# 为建筑添加遮挡剔除（OccluderInstance3D）
	if node is StaticBody3D and node.is_in_group("building"):
		_add_occlusion_culling(node)

	# 遍历子节点，为所有MeshInstance3D配置LOD
	for child in node.get_children():
		if child is MeshInstance3D:
			_configure_mesh_lod(child)
		elif child is Node3D:
			# 递归处理子节点
			for grandchild in child.get_children():
				if grandchild is MeshInstance3D:
					_configure_mesh_lod(grandchild)

func _configure_mesh_lod(mi: MeshInstance3D) -> void:
	# 设置LOD偏移：越远越早切换到低精度
	# lod_bias > 1 使LOD更早切换（更激进的优化）
	mi.lod_bias = 0.8
	# 设置最大绘制距离（超出此距离不渲染）
	mi.extra_cull_margin = 0.5
	# 建筑主体不设置过短的绘制距离
	if mi.get_parent() and mi.get_parent().is_in_group("building"):
		mi.visibility_range_begin = 0.0
		mi.visibility_range_end = 120.0   # 建筑120m外不渲染
		mi.visibility_range_begin_margin = 5.0
		mi.visibility_range_end_margin = 15.0
	else:
		# 装饰性小物件更早隐藏
		var size_approx := _estimate_mesh_size(mi)
		if size_approx < 1.0:
			mi.visibility_range_begin = 0.0
			mi.visibility_range_end = 50.0   # 小物件50m外隐藏
			mi.visibility_range_end_margin = 8.0
		elif size_approx < 3.0:
			mi.visibility_range_begin = 0.0
			mi.visibility_range_end = 80.0
			mi.visibility_range_end_margin = 10.0

func _estimate_mesh_size(mi: MeshInstance3D) -> float:
	if mi.mesh:
		var aabb := mi.mesh.get_aabb()
		return aabb.size.length()
	return 1.0

func _add_occlusion_culling(building: Node3D) -> void:
	# 使用OccluderInstance3D为建筑添加遮挡剔除
	var occluder_inst := OccluderInstance3D.new()
	occluder_inst.name = "Occluder"
	# 使用BoxOccluder3D匹配建筑大小
	var box_occ := BoxOccluder3D.new()
	box_occ.size = Vector3(14, 6, 12)  # 略大于建筑包围盒
	occluder_inst.occluder = box_occ
	occluder_inst.position = Vector3(0, 3, 0)  # 居中
	building.add_child(occluder_inst)
