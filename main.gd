@tool
extends Node3D
# 刘姥姥进大观园 - 主场景脚本

const LOAD_LOG_PATH := "user://main_scene_load.log"
const SPLIT_SCENE_NODES := [
	"Terrain",
	"Buildings",
	"Vegetation",
	"GardenFeatures",
	"NPCs",
	"TriggerZones",
	"Items"
]
const EDITOR_PREVIEW_NODE := "EditorGardenPreview"
const GARDEN_BUILDER_SCRIPT := "res://scripts/systems/garden_builder.gd"

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_refresh_editor_preview")

func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_editor_preview()
		return

	_reset_load_log()
	_log_load("Main scene _ready started")
	_start_scene_fade_in()
	_log_split_scene_status()

	# 启动新游戏
	_log_load("Starting GameManager.start_new_game")
	GameManager.start_new_game()
	_log_load("GameManager.start_new_game finished")
	print("=== 刘姥姥进大观园 ===")
	print("按 WASD 移动，鼠标转动视角")
	print("按 ESC 暂停游戏")
	
	# 第一批：轻量系统（立即初始化）
	_log_load("Initializing plaque system")
	_init_plaque_system()
	_log_load("Initializing signboard system")
	_init_signboard_system()
	_log_load("Initializing scene enhancements")
	_init_scene_enhancements()
	_log_load("Initializing navigation guide")
	_init_navigation_guide()
	_log_load("Initializing building prompt UI")
	_init_building_prompt_ui()

	# 等一帧，让场景先渲染出来
	await get_tree().process_frame

	# 第二批：中等重量系统
	_log_load("Initializing scene ambience")
	_init_scene_ambience()

	# 再等一帧
	await get_tree().process_frame

	# 第三批：重型系统（植被 + 场景构建），每帧一个避免卡死
	_log_load("Initializing vegetation system")
	_init_vegetation_system()
	await get_tree().process_frame
	_log_load("Initializing garden builder")
	_init_garden_builder()
	
	# 延迟触发入场剧情
	await get_tree().create_timer(2.0).timeout
	var intro_trigger := get_node_or_null("TriggerZones/IntroTrigger")
	if intro_trigger and not intro_trigger.has_triggered:
		_log_load("Triggering intro dialog")
		intro_trigger._on_body_entered(get_tree().get_first_node_in_group("player"))
	_log_load("Main scene _ready finished")

func _start_scene_fade_in() -> void:
	var layer := CanvasLayer.new()
	layer.name = "StartupFadeLayer"
	layer.layer = 100
	var fade := ColorRect.new()
	fade.name = "StartupFade"
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade)
	add_child(layer)

	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(fade, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.finished.connect(layer.queue_free)

func _reset_load_log() -> void:
	var file := FileAccess.open(LOAD_LOG_PATH, FileAccess.WRITE)
	if file:
		file.store_line("=== main scene load diagnostics ===")
		file.store_line("time=%s" % Time.get_datetime_string_from_system())
		file.store_line("path=%s" % ProjectSettings.globalize_path(LOAD_LOG_PATH))
		file.close()
	print("Load diagnostics: %s" % ProjectSettings.globalize_path(LOAD_LOG_PATH))

func _log_load(message: String) -> void:
	var line := "[%s] %s" % [Time.get_time_string_from_system(), message]
	print(line)
	var file := FileAccess.open(LOAD_LOG_PATH, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(line)
		file.close()

func _log_split_scene_status() -> void:
	for node_name in SPLIT_SCENE_NODES:
		var node := get_node_or_null(node_name)
		if node:
			_log_load("%s loaded: children=%d" % [node_name, node.get_child_count()])
		else:
			_log_load("%s missing" % node_name)

func _init_plaque_system() -> void:
	var plaque_sys := Node3D.new()
	plaque_sys.name = "PlaqueSystem"
	plaque_sys.set_script(load("res://scripts/ui/plaque_system.gd"))
	add_child(plaque_sys)

func _init_signboard_system() -> void:
	var sb_sys := Node.new()
	sb_sys.name = "SignboardSystem"
	sb_sys.set_script(load("res://scripts/ui/signboard_system.gd"))
	add_child(sb_sys)

func _init_scene_enhancements() -> void:
	var se_sys := Node.new()
	se_sys.name = "SceneEnhancements"
	se_sys.set_script(load("res://scripts/systems/scene_enhancements.gd"))
	add_child(se_sys)

func _init_vegetation_system() -> void:
	var veg_sys := Node.new()
	veg_sys.name = "VegetationSystem"
	veg_sys.set_script(load("res://scripts/systems/vegetation_system.gd"))
	add_child(veg_sys)

func _init_navigation_guide() -> void:
	var nav_guide := NavigationGuide.new()
	nav_guide.name = "NavigationGuide"
	add_child(nav_guide)

func _init_building_prompt_ui() -> void:
	var prompt_ui := BuildingPromptUI.new()
	add_child(prompt_ui)

func _init_scene_ambience() -> void:
	var ambience := Node3D.new()
	ambience.name = "SceneAmbience"
	ambience.set_script(load("res://scripts/systems/scene_ambience.gd"))
	add_child(ambience)

func _init_garden_builder() -> void:
	var builder := Node3D.new()
	builder.name = "GardenBuilder"
	builder.set_script(load(GARDEN_BUILDER_SCRIPT))
	add_child(builder)

func _refresh_editor_preview() -> void:
	var old_preview := get_node_or_null(EDITOR_PREVIEW_NODE)
	if old_preview:
		old_preview.free()

	var builder_script := load(GARDEN_BUILDER_SCRIPT)
	if builder_script == null:
		return

	var preview := Node3D.new()
	preview.name = EDITOR_PREVIEW_NODE
	preview.set_script(builder_script)
	add_child(preview)
