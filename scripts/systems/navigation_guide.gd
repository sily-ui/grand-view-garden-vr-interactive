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
		"target": Vector3(0, 1.5, -38),
		"condition": "",
		"completion": "intro_done",
		"hint": "向大门走去"
	},
	{
		"name": "穿过大门",
		"target": Vector3(0, 1.5, -32),
		"condition": "intro_done",
		"completion": null,
		"hint": "进入大门"
	},
	{
		"name": "过石桥",
		"target": Vector3(-5, 1.5, -22),
		"condition": "intro_done",
		"completion": null,
		"hint": "走左侧石桥过荷塘"
	},
	{
		"name": "沿游廊前行",
		"target": Vector3(-5, 1.5, -10),
		"condition": "intro_done",
		"completion": null,
		"hint": "沿游廊继续前行"
	},
	{
		"name": "去拜见贾母",
		"target": Vector3(0, 1.5, 15),
		"condition": "intro_done",
		"completion": "met_jiamu",
		"hint": "前往正厅拜见贾母"
	},
	{
		"name": "赴宴",
		"target": Vector3(0, 1.5, 25),
		"condition": "met_jiamu",
		"completion": "attended_banquet",
		"hint": "前往宴席"
	},
	{
		"name": "告别",
		"target": Vector3(0, 1.5, -42),
		"condition": "attended_banquet",
		"completion": "game_completed",
		"hint": "返回大门处告别"
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
const SPAWN_DISTANCE := 50.0        # 箭头显示的最大距离
const ARROW_SPACING := 8.0          # 多个箭头之间的间距

# HUD 提示
var hud_hint_label: Label = null
var player: CharacterBody3D = null

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
	
	# 监听事件
	EventBus.dialog_ended.connect(_on_dialog_ended)
	
	# 初始显示第一阶段箭头
	_update_arrows()

func _process(delta: float) -> void:
	if not player:
		return
	if not GameManager.is_playing():
		_set_arrows_visible(false)
		return
	
	# 找到当前应激活的阶段
	_find_current_stage()
	
	# 更新箭头位置和可见性
	_update_arrows()
	
	# 更新HUD提示
	_update_hud_hint()

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
	
	if dist < ACTIVATE_DISTANCE:
		_hide_hud_hint()
		return
	
	# 计算方向描述
	var dir: Vector2 = Vector2(target.x - player_pos.x, target.z - player_pos.z).normalized()
	var direction_text: String = _get_direction_text(dir)
	
	hud_hint_label.text = ">>> %s（约%d米）<<<" % [stage["hint"], int(dist)]
	hud_hint_label.visible = true
	
	# 闪烁效果
	var time := Time.get_ticks_msec() / 1000.0
	var alpha := 0.6 + 0.4 * sin(time * 3.0)
	hud_hint_label.modulate.a = alpha

func _hide_hud_hint() -> void:
	if hud_hint_label:
		hud_hint_label.visible = false

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
