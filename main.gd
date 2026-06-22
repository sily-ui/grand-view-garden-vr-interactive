extends Node3D
# 刘姥姥进大观园 - 主场景脚本

func _ready() -> void:
	# 启动新游戏
	GameManager.start_new_game()
	print("=== 刘姥姥进大观园 ===")
	print("按 WASD 移动，鼠标转动视角")
	print("按 ESC 暂停游戏")
	
	# 初始化院落匾额对联系统
	_init_plaque_system()
	# 初始化解说立牌系统（替换NPC）
	_init_signboard_system()
	# 初始化场景增强（光照、音效、LOD）
	_init_scene_enhancements()
	# 初始化植被系统（替换球形树木）
	_init_vegetation_system()
	# 初始化剧情导航引导
	_init_navigation_guide()
	# 初始化场景氛围（蝴蝶、落叶、鸟鸣、锦鲤）
	_init_scene_ambience()
	# 初始化大观园场景构建（围墙、水系、新院落、地形、外围建筑）
	_init_garden_builder()
	
	# 延迟触发入场剧情
	await get_tree().create_timer(2.0).timeout
	var intro_trigger := get_node_or_null("TriggerZones/IntroTrigger")
	if intro_trigger and not intro_trigger.has_triggered:
		intro_trigger._on_body_entered(get_tree().get_first_node_in_group("player"))

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

func _init_scene_ambience() -> void:
	var ambience := Node3D.new()
	ambience.name = "SceneAmbience"
	ambience.set_script(load("res://scripts/systems/scene_ambience.gd"))
	add_child(ambience)

func _init_garden_builder() -> void:
	var builder := Node3D.new()
	builder.name = "GardenBuilder"
	builder.set_script(load("res://scripts/systems/garden_builder.gd"))
	add_child(builder)
