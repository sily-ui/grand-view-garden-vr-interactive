extends Node3D
class_name NavigationGuide

# ============================================================
# 剧情导航引导系统
# 在玩家偏离路线时，生成闪烁的3D箭头指引方向
# ============================================================

# 故事阶段定义：每个阶段包含触发位置、激活条件、完成条件
var story_stages: Array[Dictionary] = [
	{
		"name": "走向荣国府大门",
		"target": Vector3(0, 1.5, -84),
		"condition": "",
		"completion": "intro_done",
		"hint": "前往荣国府门外"
	},
	{
		"name": "绕过照壁",
		"target": Vector3(-8.8, 1.5, -58),
		"condition": "intro_done",
		"completion": "",
		"hint": "从照壁左侧石路绕行"
	},
	{
		"name": "回到入园石路",
		"target": Vector3(0, 1.5, -38),
		"condition": "intro_done",
		"completion": "",
		"hint": "回到中轴石路"
	},
	{
		"name": "过石桥",
		"target": Vector3(0, 1.5, -16),
		"condition": "intro_done",
		"completion": "",
		"hint": "沿中轴石路前往沁芳桥"
	},
	{
		"name": "走上石桥",
		"target": Vector3(0, 1.5, -10),
		"condition": "intro_done",
		"completion": "",
		"hint": "走上明显的石桥桥面"
	},
	{
		"name": "沿游廊前行",
		"target": Vector3(0, 1.5, -2),
		"condition": "intro_done",
		"completion": "",
		"hint": "下桥后沿石路入园"
	},
	{
		"name": "去拜见贾母",
		"target": Vector3(0, 1.5, 29),
		"condition": "intro_done",
		"completion": "met_jiamu",
		"hint": "进正厅拜见贾母"
	},
	{
		"name": "找王熙凤问路",
		"target": Vector3(3.2, 1.5, 27.5),
		"condition": "met_jiamu",
		"completion": "met_xifeng",
		"hint": "找王熙凤问下一站"
	},
	{
		"name": "游潇湘馆",
		"target": Vector3(-35, 1.5, 15),
		"condition": "met_xifeng",
		"completion": "visited_xiaoxiang",
		"hint": "去潇湘馆见林黛玉"
	},
	{
		"name": "游怡红院",
		"target": Vector3(35, 1.5, 15),
		"condition": "visited_xiaoxiang",
		"completion": "visited_yihong",
		"hint": "去怡红院见贾宝玉"
	},
	{
		"name": "栊翠庵品茶",
		"target": Vector3(0, 1.5, 45),
		"condition": "visited_yihong",
		"completion": "completed_tea",
		"hint": "去栊翠庵找妙玉品茶"
	},
	{
		"name": "赴宴",
		"target": Vector3(0, 1.5, 25),
		"condition": "completed_tea",
		"completion": "attended_banquet",
		"hint": "回大观楼赴宴"
	},
	{
		"name": "告别",
		"target": Vector3(0, 1.5, -84),
		"condition": "attended_banquet",
		"completion": "game_completed",
		"hint": "回到荣国府门外告别"
	}
]

# 箭头相关
var arrow_nodes: Array[Node3D] = []
var current_stage_index: int = 0
var arrow_container: Node3D

# 箭头外观参数
const ARROW_GOLD := Color(0.85, 0.7, 0.25, 1.0)
const ARROW_GLOW  := Color(1.0, 0.9, 0.4, 1.0)
const FLOAT_HEIGHT := 2.5
const ARROW_SCALE := Vector3(0.6, 0.6, 0.6)
const ACTIVATE_DISTANCE := 6.0      # 距触发点多近时隐藏箭头
const INTERACT_DISTANCE := 2.8      # 距任务目标足够近时显示交互提示
const SPAWN_DISTANCE := 50.0        # 箭头显示的最大距离
const ARROW_SPACING := 8.0          # 多个箭头之间的间距

# HUD 提示
var hud_hint_label: Label = null
var player: CharacterBody3D = null

# 国风导航 HUD
var navigation_hud_layer: CanvasLayer = null
var navigation_hud_root: Control = null
var compass_panel: PanelContainer = null
var compass_heading_label: Label = null
var compass_needle_label: Label = null
var compass_marker_labels: Array[Label] = []
var top_arrow_panel: PanelContainer = null
var top_arrow_label: Label = null
var top_target_label: Label = null
var top_distance_label: Label = null
var top_turn_label: Label = null
var navigation_hud_visible: bool = true

var compass_places: Array[Dictionary] = [
	{"name": "潇湘馆", "pos": Vector3(-35, 0, 15)},
	{"name": "怡红院", "pos": Vector3(35, 0, 15)},
	{"name": "秋爽斋", "pos": Vector3(-40, 0, -5)},
	{"name": "蘅芜苑", "pos": Vector3(25, 0, -15)},
	{"name": "稻香村", "pos": Vector3(-25, 0, -15)},
	{"name": "栊翠庵", "pos": Vector3(0, 0, 45)},
]

func _ready() -> void:
	arrow_container = Node3D.new()
	arrow_container.name = "GuideArrows"
	add_child(arrow_container)
	
	# 延迟初始化，等待场景加载完毕
	call_deferred("_init_guide")

func _init_guide() -> void:
	# 获取玩家
	player = get_tree().get_first_node_in_group("player")
	
	# 创建HUD提示标签
	_create_hud_hint()
	_create_navigation_hud()
	
	# 监听事件
	EventBus.dialog_ended.connect(_on_dialog_ended)
	
	# 初始显示第一阶段箭头
	_update_arrows()

func _process(delta: float) -> void:
	if not player:
		return
	if not GameManager.is_playing():
		_set_arrows_visible(false)
		_update_navigation_hud()
		return
	
	# 找到当前应激活的阶段
	_find_current_stage()
	
	# 更新箭头位置和可见性
	_update_arrows()
	
	# 更新HUD提示
	_update_hud_hint()
	_update_navigation_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_M:
			navigation_hud_visible = not navigation_hud_visible
			if navigation_hud_layer:
				navigation_hud_layer.visible = navigation_hud_visible

func _find_current_stage() -> void:
	var prev_stage: int = current_stage_index
	for i in range(story_stages.size()):
		var stage: Dictionary = story_stages[i]
		var completion_key: String = stage.get("completion", "")
		# 检查完成条件（completion为空表示中间路点，不检查完成条件）
		if completion_key != "" and GameState.get_condition(completion_key, false):
			continue
		# 检查激活条件
		var cond: String = stage.get("condition", "")
		if cond == "" or GameState.get_condition(cond, false):
			# 如果是中间路点（无completion），检查玩家是否接近目标
			if completion_key == "" and player:
				var target_pos: Vector3 = stage["target"]
				var dist: float = Vector2(player.global_position.x - target_pos.x, player.global_position.z - target_pos.z).length()
				if dist < ACTIVATE_DISTANCE:
					continue  # 已到达，跳到下一个
			current_stage_index = i
			# 阶段变化时显示通知
			if prev_stage != current_stage_index:
				_show_stage_notification(stage.get("hint", ""))
			return
	# 所有阶段完成
	current_stage_index = story_stages.size()

func _update_arrows() -> void:
	if current_stage_index >= story_stages.size():
		_clear_arrows()
		_hide_hud_hint()
		return
	
	var stage: Dictionary = story_stages[current_stage_index]
	var target: Vector3 = stage["target"]
	var player_pos: Vector3 = player.global_position
	var dist_to_target: float = Vector2(player_pos.x - target.x, player_pos.z - target.z).length()
	
	# 距离触发点太近，隐藏箭头
	if dist_to_target < ACTIVATE_DISTANCE:
		_clear_arrows()
		return
	
	# 距离太远也不显示
	if dist_to_target > SPAWN_DISTANCE:
		_clear_arrows()
		return
	
	# 计算需要几个箭头（沿路径放置）
	var dir_to_target := Vector2(target.x - player_pos.x, target.z - player_pos.z).normalized()
	var num_arrows := clampi(int(dist_to_target / ARROW_SPACING), 1, 5)
	
	# 调整箭头数量
	while arrow_nodes.size() < num_arrows:
		_create_arrow()
	while arrow_nodes.size() > num_arrows:
		_remove_last_arrow()
	
	# 放置箭头
	for i in range(arrow_nodes.size()):
		var fraction := float(i + 1) / float(num_arrows + 1)
		var arrow_pos := Vector3(
			lerp(player_pos.x, target.x, fraction),
			FLOAT_HEIGHT,
			lerp(player_pos.z, target.z, fraction)
		)
		arrow_nodes[i].global_position = arrow_pos
		
		# 让箭头朝向目标
		var look_target := Vector3(target.x, FLOAT_HEIGHT, target.z)
		arrow_nodes[i].look_at(look_target, Vector3.UP)
		
		# 闪烁效果
		var time := Time.get_ticks_msec() / 1000.0
		var blink_speed := 2.0 + i * 0.5
		var alpha := 0.5 + 0.5 * sin(time * blink_speed + i * 1.2)
		var color := ARROW_GOLD.lerp(ARROW_GLOW, alpha)
		
		# 设置材质颜色
		_apply_arrow_color(arrow_nodes[i], color)
		
		# 浮动动画
		var float_offset := sin(time * 1.5 + i * 0.8) * 0.3
		arrow_nodes[i].position.y = FLOAT_HEIGHT + float_offset
	
	_set_arrows_visible(true)

func _create_arrow() -> void:
	var arrow := Node3D.new()
	arrow.name = "GuideArrow"
	
	# 箭头杆（水平向前的扁长方体）
	var shaft := MeshInstance3D.new()
	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(0.12, 0.5, 0.12)
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, -0.25)
	arrow.add_child(shaft)
	
	# 箭头头部（三角形箭头，朝前 -Z方向）
	var head := MeshInstance3D.new()
	var head_mesh := PrismMesh.new()
	head_mesh.size = Vector3(0.5, 0.12, 0.4)
	head.mesh = head_mesh
	head.position = Vector3(0, 0, -0.6)
	head.rotation.y = deg_to_rad(180)
	arrow.add_child(head)
	
	# 发光效果 - 底部光圈
	var glow_ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.3
	ring_mesh.outer_radius = 0.5
	ring_mesh.rings = 16
	glow_ring.mesh = ring_mesh
	glow_ring.position = Vector3(0, -0.3, 0)
	glow_ring.rotation.x = deg_to_rad(90)
	arrow.add_child(glow_ring)
	
	# 设置材质
	_apply_arrow_material(arrow)
	
	arrow.scale = ARROW_SCALE
	arrow_container.add_child(arrow)
	arrow_nodes.append(arrow)

func _remove_last_arrow() -> void:
	if arrow_nodes.size() > 0:
		var last: Node3D = arrow_nodes.pop_back()
		last.queue_free()

func _clear_arrows() -> void:
	for arrow in arrow_nodes:
		arrow.queue_free()
	arrow_nodes.clear()

func _set_arrows_visible(vis: bool) -> void:
	arrow_container.visible = vis

func _apply_arrow_material(arrow_node: Node3D) -> void:
	for child in arrow_node.get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = ARROW_GOLD
			mat.emission_enabled = true
			mat.emission = ARROW_GLOW
			mat.emission_energy_multiplier = 2.0
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.no_depth_test = false
			child.material_override = mat

func _apply_arrow_color(arrow_node: Node3D, color: Color) -> void:
	for child in arrow_node.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = child.material_override
			mat.albedo_color = color
			mat.emission = color

# ============================================================
# HUD 地面方向提示
# ============================================================

func _create_hud_hint() -> void:
	# 获取玩家的HUD层
	if not player:
		return
	var hud := player.get_node_or_null("UILayer/HUD")
	if not hud:
		return
	
	hud_hint_label = Label.new()
	hud_hint_label.name = "GuideHint"
	hud_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_hint_label.add_theme_font_size_override("font_size", 20)
	hud_hint_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.25, 0.9))
	hud_hint_label.anchors_preset = Control.PRESET_CENTER_TOP
	hud_hint_label.offset_top = 50
	hud_hint_label.offset_bottom = 75
	hud_hint_label.offset_left = -200
	hud_hint_label.offset_right = 200
	hud_hint_label.text = ""
	hud_hint_label.visible = false
	hud.add_child(hud_hint_label)

func get_current_hint() -> String:
	_find_current_stage()
	if current_stage_index >= story_stages.size():
		return ""
	return story_stages[current_stage_index].get("hint", "")

func get_stage_count() -> int:
	return story_stages.size()

func has_stage_named(stage_name: String) -> bool:
	for stage in story_stages:
		if stage.get("name", "") == stage_name:
			return true
	return false

func _update_hud_hint() -> void:
	if not hud_hint_label:
		return
	if current_stage_index >= story_stages.size():
		_hide_hud_hint()
		return
	
	var stage: Dictionary = story_stages[current_stage_index]
	var target: Vector3 = stage["target"]
	var player_pos: Vector3 = player.global_position
	var dist: float = Vector2(player_pos.x - target.x, player_pos.z - target.z).length()
	
	if dist < INTERACT_DISTANCE:
		hud_hint_label.text = ">>> 已到达：%s <<<" % stage["hint"]
		hud_hint_label.visible = true
		var near_time := Time.get_ticks_msec() / 1000.0
		hud_hint_label.modulate.a = 0.7 + 0.3 * sin(near_time * 3.5)
		return
	
	# 计算方向描述
	var dir: Vector2 = Vector2(target.x - player_pos.x, target.z - player_pos.z).normalized()
	var direction_text: String = _get_direction_text(dir)
	
	hud_hint_label.text = ">>> %s %s（约%d米）<<<" % [direction_text, stage["hint"], int(dist)]
	hud_hint_label.visible = true
	
	# 闪烁效果
	var time := Time.get_ticks_msec() / 1000.0
	var alpha := 0.6 + 0.4 * sin(time * 3.0)
	hud_hint_label.modulate.a = alpha

func _hide_hud_hint() -> void:
	if hud_hint_label:
		hud_hint_label.visible = false

func _create_navigation_hud() -> void:
	if navigation_hud_layer:
		return

	navigation_hud_layer = CanvasLayer.new()
	navigation_hud_layer.name = "QingNavigationHUD"
	navigation_hud_layer.layer = 7
	navigation_hud_layer.visible = navigation_hud_visible
	add_child(navigation_hud_layer)

	navigation_hud_root = Control.new()
	navigation_hud_root.name = "NavigationHUDRoot"
	navigation_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	navigation_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	navigation_hud_layer.add_child(navigation_hud_root)

	_create_top_arrow_hud()
	_create_compass_hud()

func _create_top_arrow_hud() -> void:
	top_arrow_panel = PanelContainer.new()
	top_arrow_panel.name = "TopTargetArrow"
	top_arrow_panel.anchor_left = 0.5
	top_arrow_panel.anchor_right = 0.5
	top_arrow_panel.anchor_top = 0.0
	top_arrow_panel.anchor_bottom = 0.0
	top_arrow_panel.offset_left = -180
	top_arrow_panel.offset_right = 180
	top_arrow_panel.offset_top = 14
	top_arrow_panel.offset_bottom = 100
	top_arrow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_arrow_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.33, 0.17, 0.07, 0.72), Color(0.88, 0.68, 0.22, 0.92), 2, 6))
	navigation_hud_root.add_child(top_arrow_panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	top_arrow_panel.add_child(hbox)

	top_arrow_label = Label.new()
	top_arrow_label.name = "ArrowGlyph"
	top_arrow_label.text = "▲"
	top_arrow_label.custom_minimum_size = Vector2(48, 48)
	top_arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_arrow_label.pivot_offset = Vector2(24, 24)
	top_arrow_label.add_theme_font_size_override("font_size", 40)
	top_arrow_label.add_theme_color_override("font_color", Color(0.96, 0.78, 0.28, 1.0))
	hbox.add_child(top_arrow_label)

	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 0)
	hbox.add_child(text_box)

	top_target_label = Label.new()
	top_target_label.name = "TargetLabel"
	top_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_target_label.add_theme_font_size_override("font_size", 20)
	top_target_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.58, 1.0))
	text_box.add_child(top_target_label)

	top_distance_label = Label.new()
	top_distance_label.name = "DistanceLabel"
	top_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_distance_label.add_theme_font_size_override("font_size", 14)
	top_distance_label.add_theme_color_override("font_color", Color(0.91, 0.74, 0.35, 0.96))
	text_box.add_child(top_distance_label)

	top_turn_label = Label.new()
	top_turn_label.name = "TurnLabel"
	top_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_turn_label.add_theme_font_size_override("font_size", 16)
	top_turn_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.26, 1.0))
	text_box.add_child(top_turn_label)

func _create_compass_hud() -> void:
	compass_panel = PanelContainer.new()
	compass_panel.name = "FengshuiCompass"
	compass_panel.anchor_left = 1.0
	compass_panel.anchor_right = 1.0
	compass_panel.anchor_top = 0.0
	compass_panel.anchor_bottom = 0.0
	compass_panel.offset_left = -236
	compass_panel.offset_right = -18
	compass_panel.offset_top = 18
	compass_panel.offset_bottom = 236
	compass_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compass_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.58, 0.45, 0.23, 0.68), Color(0.9, 0.72, 0.27, 0.95), 2, 108))
	navigation_hud_root.add_child(compass_panel)

	var compass := Control.new()
	compass.name = "CompassFace"
	compass.custom_minimum_size = Vector2(208, 208)
	compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compass_panel.add_child(compass)

	var north := _make_compass_label("北", 22, Color(0.98, 0.82, 0.28, 1.0))
	north.position = Vector2(92, 8)
	compass.add_child(north)
	var south := _make_compass_label("南", 18, Color(0.96, 0.84, 0.54, 1.0))
	south.position = Vector2(94, 174)
	compass.add_child(south)
	var east := _make_compass_label("东", 18, Color(0.96, 0.84, 0.54, 1.0))
	east.position = Vector2(172, 91)
	compass.add_child(east)
	var west := _make_compass_label("西", 18, Color(0.96, 0.84, 0.54, 1.0))
	west.position = Vector2(12, 91)
	compass.add_child(west)

	compass_needle_label = _make_compass_label("◆", 34, Color(0.98, 0.72, 0.22, 1.0))
	compass_needle_label.position = Vector2(83, 80)
	compass_needle_label.pivot_offset = Vector2(20, 20)
	compass.add_child(compass_needle_label)

	compass_heading_label = _make_compass_label("朝向 北", 15, Color(0.98, 0.88, 0.58, 1.0))
	compass_heading_label.position = Vector2(62, 116)
	compass.add_child(compass_heading_label)

	for place in compass_places:
		var label := _make_compass_label(String(place["name"]), 11, Color(0.98, 0.82, 0.36, 0.95))
		label.custom_minimum_size = Vector2(52, 18)
		compass.add_child(label)
		compass_marker_labels.append(label)

func _make_panel_style(bg_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _make_compass_label(text_value: String, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(40, 24)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.04, 0.01, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _update_navigation_hud() -> void:
	if not navigation_hud_layer or not player:
		return
	navigation_hud_layer.visible = navigation_hud_visible
	if current_stage_index >= story_stages.size():
		top_target_label.text = "主线完成"
		top_distance_label.text = "已游毕大观园"
		top_turn_label.text = ""
		return

	var stage: Dictionary = story_stages[current_stage_index]
	var target: Vector3 = stage["target"]
	var player_pos: Vector3 = player.global_position
	var target_dir := Vector2(target.x - player_pos.x, target.z - player_pos.z)
	var distance := target_dir.length()
	var relative_angle := 0.0
	if distance > 0.01:
		relative_angle = _get_relative_angle_to(target)

	top_arrow_label.rotation = relative_angle
	top_target_label.text = stage.get("hint", "前往目标")
	if distance <= INTERACT_DISTANCE:
		top_distance_label.text = "已到达，触发剧情后切换下一站"
	else:
		top_distance_label.text = "距目标约 %d 米" % int(distance)
	top_turn_label.text = "回头" if abs(relative_angle) > deg_to_rad(120.0) else _get_turn_hint(relative_angle)

	_update_compass(target)

func _update_compass(target: Vector3) -> void:
	var forward := _get_player_forward_2d()
	var heading_angle := atan2(forward.x, forward.y)
	compass_needle_label.rotation = heading_angle
	compass_heading_label.text = "朝向 %s" % _get_world_heading_name(heading_angle)

	var center := Vector2(104, 104)
	var radius := 76.0
	for i in range(compass_marker_labels.size()):
		var place: Dictionary = compass_places[i]
		var pos: Vector3 = place["pos"]
		var angle := _get_relative_angle_to(pos)
		var marker_pos := center + Vector2(sin(angle), -cos(angle)) * radius
		compass_marker_labels[i].position = marker_pos - Vector2(26, 9)

func _get_player_forward_2d() -> Vector2:
	var forward_3d := -player.global_transform.basis.z
	var forward := Vector2(forward_3d.x, forward_3d.z)
	if forward.length() < 0.01:
		return Vector2(0, -1)
	return forward.normalized()

func _get_relative_angle_to(world_pos: Vector3) -> float:
	var player_pos := player.global_position
	var forward := _get_player_forward_2d()
	var to_target := Vector2(world_pos.x - player_pos.x, world_pos.z - player_pos.z)
	if to_target.length() < 0.01:
		return 0.0
	return forward.angle_to(to_target.normalized())

func _get_turn_hint(relative_angle: float) -> String:
	var deg := rad_to_deg(relative_angle)
	if abs(deg) < 18.0:
		return "正前方"
	if deg > 0.0:
		return "向右 %.0f°" % abs(deg)
	return "向左 %.0f°" % abs(deg)

func _get_world_heading_name(angle: float) -> String:
	var normalized := fposmod(angle + TAU, TAU)
	if normalized < PI / 8.0 or normalized >= 15.0 * PI / 8.0:
		return "北"
	if normalized < 3.0 * PI / 8.0:
		return "东北"
	if normalized < 5.0 * PI / 8.0:
		return "东"
	if normalized < 7.0 * PI / 8.0:
		return "东南"
	if normalized < 9.0 * PI / 8.0:
		return "南"
	if normalized < 11.0 * PI / 8.0:
		return "西南"
	if normalized < 13.0 * PI / 8.0:
		return "西"
	return "西北"

func _get_direction_text(dir: Vector2) -> String:
	var angle := atan2(dir.x, dir.y)
	if angle < 0:
		angle += TAU
	
	if angle < PI / 8 or angle > 15 * PI / 8:
		return "前方"
	elif angle < 3 * PI / 8:
		return "右前方"
	elif angle < 5 * PI / 8:
		return "右侧"
	elif angle < 7 * PI / 8:
		return "右后方"
	elif angle < 9 * PI / 8:
		return "后方"
	elif angle < 11 * PI / 8:
		return "左后方"
	elif angle < 13 * PI / 8:
		return "左侧"
	else:
		return "左前方"

func _on_dialog_ended(dialog_id: String) -> void:
	# 对话结束后重新评估当前阶段
	current_stage_index = 0  # 重置，让 _find_current_stage 重新计算
	_find_current_stage()
	_clear_arrows()
	_update_arrows()

func _show_stage_notification(hint_text: String) -> void:
	if not hud_hint_label or not player:
		return
	var hud := player.get_node_or_null("UILayer/HUD")
	if not hud:
		return
	
	var notify := Label.new()
	notify.name = "StageNotify"
	notify.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notify.add_theme_font_size_override("font_size", 28)
	notify.add_theme_color_override("font_color", Color(0.85, 0.7, 0.25, 1.0))
	notify.anchors_preset = Control.PRESET_CENTER
	notify.offset_top = -60
	notify.offset_bottom = -25
	notify.offset_left = -250
	notify.offset_right = 250
	notify.text = "— %s —" % hint_text
	hud.add_child(notify)
	
	# 淡入淡出动画
	notify.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(notify, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(notify, "modulate:a", 0.0, 0.8)
	tween.finished.connect(notify.queue_free)
