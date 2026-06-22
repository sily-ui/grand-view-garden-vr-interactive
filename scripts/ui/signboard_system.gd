extends Node
## 中式木质解说立牌系统
## 替换原NPC节点，在原位放置木质立牌+触发区域+VR适配剧情面板

# ═══════════════════════════════════════════════════════
# 立牌数据
# ═══════════════════════════════════════════════════════
var _signboard_data: Array = [
	{
		"pos": Vector3(0, 0, 20),
		"name": "贾母",
		"title": "荣国府史太君",
		"trigger_radius": 2.5,
		"story_title": "刘姥姥二进大观园 —— 贾母设宴",
		"story_body": (
			"刘姥姥二进荣国府，贾母亲自设宴款待。席间刘姥姥说出\"老刘老刘，食量大如牛，吃个老母猪不抬头\"等乡野俚语，引得众人捧腹大笑。" +
			"\n\n贾母见刘姥姥质朴有趣，命凤姐好生款待，又带她游览大观园各处景致。" +
			"\n\n此次宴席是全书最精彩的喜剧场景之一，以刘姥姥的\"村气\"反衬贾府的奢华，暗伏日后败落之兆。"
		)
	},
	{
		"pos": Vector3(3, 0, 20),
		"name": "王熙凤",
		"title": "琏二奶奶",
		"trigger_radius": 2.5,
		"story_title": "凤姐弄权 —— 簪花逗趣",
		"story_body": (
			"王熙凤是荣国府的实际管家人，精明强干、八面玲珑。" +
			"\n\n刘姥姥进园时，凤姐与鸳鸯合谋，将各色鲜花插满刘姥姥头上，取笑她\"老妖精\"，引得贾母众人笑成一片。" +
			"\n\n刘姥姥自嘲道：\"我虽老了，年轻时也风流，爱个花儿粉儿的。\"尽显乡间老妪的豁达。" +
			"\n\n凤姐此举表面戏弄，实为讨好贾母，亦是日后巧姐遇难时刘姥姥出手相救的伏笔。"
		)
	},
	{
		"pos": Vector3(-35, 0, 15),
		"name": "林黛玉",
		"title": "潇湘妃子",
		"trigger_radius": 2.5,
		"story_title": "潇湘馆 —— 黛玉的诗意天地",
		"story_body": (
			"潇湘馆是林黛玉的居所，翠竹掩映、清幽雅致，正合黛玉\"潇湘妃子\"的雅号。" +
			"\n\n刘姥姥进园时赞潇湘馆\"比那上等的书房还好\"，黛玉在此处显得格外清高孤傲。" +
			"\n\n黛玉与刘姥姥虽境遇天差地别，却同是寄人篱下之人。曹雪芹以刘姥姥的朴实映衬黛玉的敏感多情。" +
			"\n\n潇湘馆的竹子象征黛玉高洁的品格与\"一年三百六十日，风刀霜剑严相逼\"的悲凉命运。"
		)
	},
	{
		"pos": Vector3(35, 0, 15),
		"name": "贾宝玉",
		"title": "怡红公子",
		"trigger_radius": 2.5,
		"story_title": "怡红院 —— 宝玉的温柔乡",
		"story_body": (
			"怡红院是贾宝玉的居所，陈设华丽，新奇玩意儿甚多，恰合宝玉\"富贵闲人\"的性情。" +
			"\n\n刘姥姥误入怡红院，醉倒在宝玉床上，袭人发现后赶紧收拾，不让宝玉知晓。" +
			"\n\n这一情节既写出刘姥姥的率真，也暗写宝玉对女儿世界的珍视——他的卧室不容世俗沾染。" +
			"\n\n怡红院之名取\"怡红快绿\"之意，宝玉最爱与姐妹丫鬟们在此吟诗作画、嬉笑玩闹。"
		)
	},
	{
		"pos": Vector3(0, 0, 45),
		"name": "妙玉",
		"title": "槛外人",
		"trigger_radius": 3.0,
		"story_title": "栊翠庵 —— 妙玉奉茶",
		"story_body": (
			"栊翠庵是妙玉修行之处，清静之地，非一般人能入。" +
			"\n\n贾母携刘姥姥至栊翠庵品茶。妙玉以旧年雨水烹茶奉贾母，却嫌刘姥姥用过的成窑杯\"腌臜了\"，欲弃之。" +
			"\n\n宝玉替刘姥姥求情，妙玉才将茶杯赠予刘姥姥。此节写出妙玉\"欲洁何曾洁，云空未必空\"的矛盾。" +
			"\n\n栊翠庵茶事是全书最精致的雅事之一，与刘姥姥的\"村气\"形成绝妙对照。"
		)
	},
	{
		"pos": Vector3(-25, 0, -10),
		"name": "李纨",
		"title": "稻香老农",
		"trigger_radius": 2.5,
		"story_title": "稻香村 —— 稻花香里说丰年",
		"story_body": (
			"稻香村是李纨的居所，仿田园风光，茅檐土壁、槿篱竹牖，一派农家气象。" +
			"\n\n李纨青春守寡，甘心\"竹篱茅舍自甘心\"，在稻香村教子读书、针黹度日。" +
			"\n\n刘姥姥见稻香村倍感亲切，此景最合她乡间老妪的身份，亦暗合\"退步原来是向前\"的人生哲理。" +
			"\n\n曹雪芹以稻香村之\"朴\"对照大观园之\"华\"，暗示繁华终将归于平淡。"
		)
	},
	{
		"pos": Vector3(25, 0, -10),
		"name": "薛宝钗",
		"title": "蘅芜君",
		"trigger_radius": 2.5,
		"story_title": "蘅芜苑 —— 冷香丸的主人",
		"story_body": (
			"蘅芜苑是薛宝钗的居所，满苑蘅芜异香扑鼻，室内却\"雪洞一般\"素净无饰。" +
			"\n\n宝钗为人端庄稳重、藏愚守拙，与黛玉的锋芒毕露恰成对比。" +
			"\n\n刘姥姥进园时，宝钗的蘅芜苑之素与黛玉潇湘馆之雅各有千秋。贾母赞宝钗\"稳重和平\"。" +
			"\n\n蘅芜苑之名出自《离骚》香草意象，暗喻宝钗\"任是无情也动人\"的品格。"
		)
	},
]

# ═══════════════════════════════════════════════════════
# 材质缓存
# ═══════════════════════════════════════════════════════
var _mat_post: StandardMaterial3D        # 木柱
var _mat_board: StandardMaterial3D       # 牌匾木底
var _mat_border: StandardMaterial3D      # 牌匾边框
var _mat_name_gold: StandardMaterial3D   # 金字

# ═══════════════════════════════════════════════════════
# UI 引用
# ═══════════════════════════════════════════════════════
var _ui_layer: CanvasLayer
var _ui_panel: PanelContainer
var _ui_title: RichTextLabel
var _ui_body: RichTextLabel
var _ui_close_btn: Button
var _current_signboard_name: String = ""
var _active_trigger: Area3D = null

# ═══════════════════════════════════════════════════════
# 生命周期
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	_init_materials()
	_clear_old_npcs()
	_create_all_signboards()
	_create_ui_panel()

# ═══════════════════════════════════════════════════════
# 材质初始化
# ═══════════════════════════════════════════════════════
func _init_materials() -> void:
	# 深色木柱
	_mat_post = StandardMaterial3D.new()
	_mat_post.albedo_color = Color(0.35, 0.22, 0.12, 1)
	_mat_post.roughness = 0.72
	_mat_post.metallic = 0.0

	# 牌匾木底（红木色）
	_mat_board = StandardMaterial3D.new()
	_mat_board.albedo_color = Color(0.42, 0.18, 0.1, 1)
	_mat_board.roughness = 0.55
	_mat_board.metallic = 0.05

	# 边框（深红）
	_mat_border = StandardMaterial3D.new()
	_mat_border.albedo_color = Color(0.58, 0.12, 0.08, 1)
	_mat_border.roughness = 0.5
	_mat_border.metallic = 0.1

	# 金字
	_mat_name_gold = StandardMaterial3D.new()
	_mat_name_gold.albedo_color = Color(0.92, 0.78, 0.28, 1)
	_mat_name_gold.roughness = 0.3
	_mat_name_gold.metallic = 0.4
	_mat_name_gold.emission_enabled = true
	_mat_name_gold.emission = Color(0.6, 0.48, 0.12)
	_mat_name_gold.emission_energy_multiplier = 0.4

# ═══════════════════════════════════════════════════════
# 清除旧NPC节点
# ═══════════════════════════════════════════════════════
func _clear_old_npcs() -> void:
	var npc_container := get_node_or_null("../NPCs")
	if not npc_container:
		push_warning("SignboardSystem: 找不到 NPCs 容器节点")
		return
	for child in npc_container.get_children():
		child.queue_free()

# ═══════════════════════════════════════════════════════
# 创建全部立牌
# ═══════════════════════════════════════════════════════
func _create_all_signboards() -> void:
	var npc_container := get_node_or_null("../NPCs")
	if not npc_container:
		return
	for data in _signboard_data:
		_create_one_signboard(npc_container, data)

# ═══════════════════════════════════════════════════════
# 创建单个立牌
# ═══════════════════════════════════════════════════════
func _create_one_signboard(parent: Node3D, data: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "Sign_" + data["name"]
	root.position = data["pos"]

	# ── 木柱（高2.8m，直径0.12m） ──
	var post_mesh := MeshInstance3D.new()
	var post_cyl := CylinderMesh.new()
	post_cyl.top_radius = 0.06
	post_cyl.bottom_radius = 0.07
	post_cyl.height = 2.8
	post_mesh.mesh = post_cyl
	post_mesh.material_override = _mat_post
	post_mesh.position = Vector3(0, 1.4, 0)
	post_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(post_mesh)

	# ── 牌匾木底板（宽1.6m, 高0.8m, 厚0.06m） ──
	var board_mesh := MeshInstance3D.new()
	var board_box := BoxMesh.new()
	board_box.size = Vector3(1.6, 0.8, 0.06)
	board_mesh.mesh = board_box
	board_mesh.material_override = _mat_board
	board_mesh.position = Vector3(0, 2.9, 0)
	board_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(board_mesh)

	# ── 牌匾边框（宽1.7, 高0.9, 厚0.04） ──
	var border_mesh := MeshInstance3D.new()
	var border_box := BoxMesh.new()
	border_box.size = Vector3(1.7, 0.9, 0.04)
	border_mesh.mesh = border_box
	border_mesh.material_override = _mat_border
	border_mesh.position = Vector3(0, 2.9, -0.025)
	root.add_child(border_mesh)

	# ── 顶部横梁装饰 ──
	var top_beam := MeshInstance3D.new()
	var top_box := BoxMesh.new()
	top_box.size = Vector3(1.85, 0.08, 0.12)
	top_beam.mesh = top_box
	top_beam.material_override = _mat_post
	top_beam.position = Vector3(0, 3.38, 0)
	root.add_child(top_beam)

	# ── 底部横档 ──
	var bottom_beam := MeshInstance3D.new()
	var bot_box := BoxMesh.new()
	bot_box.size = Vector3(1.85, 0.06, 0.1)
	bottom_beam.mesh = bot_box
	bottom_beam.material_override = _mat_post
	bottom_beam.position = Vector3(0, 2.46, 0)
	root.add_child(bottom_beam)

	# ── 地面石基（稳固底座） ──
	var base_mesh := MeshInstance3D.new()
	var base_box := BoxMesh.new()
	base_box.size = Vector3(0.35, 0.12, 0.35)
	base_mesh.mesh = base_box
	base_mesh.material_override = StandardMaterial3D.new()
	base_mesh.material_override.albedo_color = Color(0.5, 0.48, 0.44, 1)
	base_mesh.material_override.roughness = 0.85
	base_mesh.position = Vector3(0, 0.06, 0)
	root.add_child(base_mesh)

	# ── 牌匾名称（金字Label3D，正面朝-Z） ──
	var name_lbl := Label3D.new()
	name_lbl.text = data["name"]
	name_lbl.font_size = 48
	name_lbl.pixel_size = 0.01
	name_lbl.position = Vector3(0, 2.9, 0.04)
	name_lbl.modulate = Color(0.92, 0.78, 0.28, 1)
	name_lbl.outline_size = 8
	name_lbl.outline_modulate = Color(0.08, 0.06, 0.02, 1)
	name_lbl.double_sided = true
	name_lbl.no_depth_test = false
	name_lbl.fixed_size = false
	name_lbl.double_sided = true
	name_lbl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(name_lbl)

	# ── 标题小字（姓名下方） ──
	var title_lbl := Label3D.new()
	title_lbl.text = data["title"]
	title_lbl.font_size = 24
	title_lbl.pixel_size = 0.01
	title_lbl.position = Vector3(0, 2.52, 0.04)
	title_lbl.modulate = Color(0.82, 0.72, 0.5, 1)
	title_lbl.outline_size = 5
	title_lbl.outline_modulate = Color(0.06, 0.04, 0.02, 1)
	title_lbl.double_sided = true
	title_lbl.double_sided = true
	title_lbl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(title_lbl)

	# ── Area3D 触发区域（限主路径内，不超出院墙） ──
	var trigger := Area3D.new()
	trigger.name = "TriggerZone"
	trigger.position = Vector3(0, 1.5, 0)
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = data["trigger_radius"]
	col.shape = sphere
	trigger.add_child(col)
	# 存储关联的立牌数据
	trigger.set_meta("signboard_data", data)
	# 连接信号
	trigger.body_entered.connect(_on_trigger_entered.bind(trigger))
	trigger.body_exited.connect(_on_trigger_exited.bind(trigger))
	root.add_child(trigger)

	parent.add_child(root)

# ═══════════════════════════════════════════════════════
# 触发回调
# ═══════════════════════════════════════════════════════
func _on_trigger_entered(body: Node3D, trigger: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	var data: Dictionary = trigger.get_meta("signboard_data", {})
	if data.is_empty():
		return
	_current_signboard_name = data.get("name", "")
	_active_trigger = trigger
	_show_panel(data)

func _on_trigger_exited(body: Node3D, trigger: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	if trigger == _active_trigger:
		_hide_panel()

# ═══════════════════════════════════════════════════════
# UI 面板：创建（中式古风VR适配大面板）
# ═══════════════════════════════════════════════════════
func _create_ui_panel() -> void:
	# ── CanvasLayer ──
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "SignboardUILayer"
	_ui_layer.layer = 10
	_ui_layer.visible = false

	# ── 全屏半透明背景 ──
	var bg := ColorRect.new()
	bg.name = "DimBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	bg.theme = load("res://assets/fonts/wenkai_theme.tres")
	_ui_layer.add_child(bg)

	# ── 主面板 ──
	_ui_panel = PanelContainer.new()
	_ui_panel.name = "Panel"
	# 居中定位：水平50%, 垂直50%, 偏移-400x-300
	_ui_panel.set_anchors_preset(Control.PRESET_CENTER)
	_ui_panel.offset_left = -420
	_ui_panel.offset_top = -320
	_ui_panel.offset_right = 420
	_ui_panel.offset_bottom = 320
	# 宣纸+红木面板样式（与对话框一致）
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.91, 0.8, 0.97)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.35, 0.2, 0.1, 0.95)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	style.content_margin_left = 32
	style.content_margin_top = 24
	style.content_margin_right = 32
	style.content_margin_bottom = 24
	_ui_panel.add_theme_stylebox_override("panel", style)
	_ui_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	bg.add_child(_ui_panel)

	# ── 内容容器 ──
	var vbox := VBoxContainer.new()
	vbox.name = "Content"
	vbox.add_theme_constant_override("separation", 16)
	_ui_panel.add_child(vbox)

	# ── 标题 ──
	_ui_title = RichTextLabel.new()
	_ui_title.name = "Title"
	_ui_title.bbcode_enabled = true
	_ui_title.fit_content = true
	_ui_title.scroll_active = false
	_ui_title.custom_minimum_size = Vector2(0, 50)
	_ui_title.add_theme_font_size_override("normal_font_size", 32)
	_ui_title.add_theme_color_override("default_color", Color(0.55, 0.3, 0.08, 1))
	vbox.add_child(_ui_title)

	# ── 分隔线 ──
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.45, 0.28, 0.12, 0.6)
	sep_style.thickness = 2
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# ── 正文（可滚动） ──
	_ui_body = RichTextLabel.new()
	_ui_body.name = "Body"
	_ui_body.bbcode_enabled = true
	_ui_body.scroll_active = true
	_ui_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ui_body.add_theme_font_size_override("normal_font_size", 24)
	_ui_body.add_theme_color_override("default_color", Color(0.2, 0.15, 0.08, 1))
	_ui_body.add_theme_constant_override("line_separation", 8)
	vbox.add_child(_ui_body)

	# ── 底部按钮行 ──
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	_ui_close_btn = Button.new()
	_ui_close_btn.name = "CloseBtn"
	_ui_close_btn.text = "  关  闭  "
	_ui_close_btn.custom_minimum_size = Vector2(200, 52)
	_ui_close_btn.add_theme_font_size_override("font_size", 26)
	# 木质牌匾按钮样式
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.35, 0.22, 0.1, 0.95)
	btn_normal.border_width_left = 3
	btn_normal.border_width_top = 3
	btn_normal.border_width_right = 3
	btn_normal.border_width_bottom = 3
	btn_normal.border_color = Color(0.2, 0.12, 0.05, 0.9)
	btn_normal.corner_radius_top_left = 0
	btn_normal.corner_radius_top_right = 0
	btn_normal.corner_radius_bottom_right = 0
	btn_normal.corner_radius_bottom_left = 0
	btn_normal.content_margin_left = 20
	btn_normal.content_margin_right = 20
	_ui_close_btn.add_theme_stylebox_override("normal", btn_normal)
	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = Color(0.45, 0.3, 0.15, 0.95)
	btn_hover.border_color = Color(0.55, 0.35, 0.1, 0.95)
	_ui_close_btn.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed := btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.28, 0.18, 0.08, 0.95)
	_ui_close_btn.add_theme_stylebox_override("pressed", btn_pressed)
	_ui_close_btn.add_theme_color_override("font_color", Color(0.82, 0.7, 0.35, 1))
	_ui_close_btn.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.5, 1))
	_ui_close_btn.pressed.connect(_on_close_pressed)
	btn_row.add_child(_ui_close_btn)

	# 添加到场景树
	add_child(_ui_layer)

# ═══════════════════════════════════════════════════════
# UI 面板：显示/隐藏
# ═══════════════════════════════════════════════════════
func _show_panel(data: Dictionary) -> void:
	if not _ui_layer:
		return
	var title_text: String = data.get("story_title", "")
	var body_text: String = data.get("story_body", "")
	_ui_title.text = "[center][b]" + title_text + "[/b][/center]"
	_ui_body.text = "\n" + body_text
	_ui_body.scroll_to_line(0)
	_ui_layer.visible = true

func _hide_panel() -> void:
	if _ui_layer:
		_ui_layer.visible = false
	_current_signboard_name = ""
	_active_trigger = null

func _on_close_pressed() -> void:
	_hide_panel()

# ═══════════════════════════════════════════════════════
# 输入处理：VR手柄/键盘关闭
# ═══════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if not _ui_layer or not _ui_layer.visible:
		return
	# ESC键 / 手柄B键关闭
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_hide_panel()
		get_viewport().set_input_as_handled()
	# 鼠标左键点击面板外区域关闭（VR手柄映射为鼠标左键时同样生效）
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var panel_rect: Rect2 = _ui_panel.get_global_rect()
		if not panel_rect.has_point(event.position):
			_hide_panel()
			get_viewport().set_input_as_handled()
