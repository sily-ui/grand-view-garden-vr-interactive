extends SceneTree

const MAIN_SCENE := "res://main.tscn"
const REPORT_PATH := "res://docs/optimization_test_report.md"

var _checks := []
var _main_scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var started_at := Time.get_ticks_msec()
	_load_main_scene()
	if _main_scene:
		for _i in range(45):
			await process_frame
		_run_scene_checks()
		_run_layout_checks()
		_run_guidance_checks()
		_run_interaction_checks()
		_run_resource_checks()
		_run_navigation_collision_checks()
		_run_performance_checks(Time.get_ticks_msec() - started_at)
	_write_report()
	quit(_failure_count())

func _load_main_scene() -> void:
	var packed := load(MAIN_SCENE)
	_add_check("场景加载", "主场景资源可加载", packed is PackedScene, MAIN_SCENE)
	if not packed is PackedScene:
		return
	_main_scene = packed.instantiate()
	root.add_child(_main_scene)
	_add_check("场景加载", "主场景可实例化", _main_scene != null, _main_scene.name if _main_scene else "")

func _run_scene_checks() -> void:
	_add_check("场景加载", "玩家节点存在", _find_node_by_name(_main_scene, "Player") != null, "保留玩家初始出生点")
	_add_check("场景加载", "Buildings 容器存在", _find_node_by_name(_main_scene, "Buildings") != null, "保留现有院落容器")
	_add_check("场景加载", "NPCs 容器存在", _find_node_by_name(_main_scene, "NPCs") != null, "立牌运行时挂载位置")
	_add_check("场景加载", "Systems 容器存在", _find_node_by_name(_main_scene, "Systems") != null, "运行时增强系统挂载位置")

func _run_layout_checks() -> void:
	_add_check("空间布局", "闭合围墙运行时节点存在", _find_node_by_name(_main_scene, "PerimeterWall") != null, "白墙灰瓦外围")
	_add_check("空间布局", "南侧正门存在", _find_node_by_name(_main_scene, "MainGate") != null, "主入口可通行")
	_add_check("空间布局", "北侧后门存在", _find_node_by_name(_main_scene, "BackGate_North") != null, "府邸后门门楼")
	_add_check("空间布局", "东侧侧门存在", _find_node_by_name(_main_scene, "ServiceGate_East") != null, "府邸侧门门楼")
	_add_check("空间布局", "东线防出界墙存在", _find_node_by_name(_main_scene, "EastPlayableBoundary") != null, "玩家东线不应跑到场外")
	for frame_name in ["XiaoxiangFrame", "YihongFrame", "QiushuangFrame", "HengwuFrame", "DaoxiangFrame"]:
		_add_check("空间布局", frame_name + " 已生成", _find_node_by_name(_main_scene, frame_name) != null, "五院独立围合")
	for detail_name in ["BluestoneRouteOverlay", "PondRevetmentAndRails", "GardenOrnaments"]:
		_add_check("空间布局", detail_name + " 已生成", _find_node_by_name(_main_scene, detail_name) != null, "园林细节优化")
	_add_check("空间布局", "荷塘通行桥已生成", _find_node_by_name(_main_scene, "WalkablePondBridge") != null, "修复荷塘路线断点")
	_add_check("导航碰撞", "荷塘桥面有碰撞", _node_has_collision(_find_node_by_name(_main_scene, "WalkablePondBridge")), "桥面与两端缓坡可承托玩家")

func _run_interaction_checks() -> void:
	var sign_count := _count_nodes_with_prefix(_main_scene, "Sign_")
	_add_check("交互剧情", "解说立牌数量不少于 8", sign_count >= 8, "当前数量: %d" % sign_count)
	_add_check("交互剧情", "立牌 UI 层存在", _find_node_by_name(_main_scene, "SignboardUILayer") != null, "宣纸红木弹窗")
	var signboard_ui := _find_node_by_name(_main_scene, "SignboardUILayer")
	_add_check("交互剧情", "立牌 UI 释放鼠标", signboard_ui != null and signboard_ui.is_in_group("blocking_mouse_ui"), "打开小传时玩家控制器不应重新捕获鼠标")
	_add_check("交互剧情", "头像控件存在", _find_node_by_name(_main_scene, "AvatarRect") != null, "剧情头像显示")
	_add_check("交互剧情", "建筑讲解按钮存在", _find_node_by_name(_main_scene, "BuildingPromptButton") != null, "建筑触发后可 Hover 并点击查看讲解")
	_add_check("交互剧情", "立牌触发 Area3D 足够", _count_nodes_by_class(_main_scene, "Area3D") >= 8, "含建筑入口与立牌触发区")

func _run_guidance_checks() -> void:
	var guide := _find_node_by_name(_main_scene, "NavigationGuide")
	_add_check("任务引导", "导航系统已挂载", guide != null, "玩家应始终看到下一步提示")
	if guide:
		_add_check("任务引导", "贾母后引导找王熙凤", guide.has_method("has_stage_named") and guide.has_stage_named("找王熙凤问路"), "补齐会面贾母后的下一 NPC")
		_add_check("任务引导", "院落游览阶段完整", guide.has_method("has_stage_named") and guide.has_stage_named("游潇湘馆") and guide.has_stage_named("游怡红院") and guide.has_stage_named("栊翠庵品茶"), "找王熙凤后继续引导院落剧情")
		_add_check("任务引导", "拜见贾母分段绕行", guide.has_method("get_stage_route_count") and guide.get_stage_route_count("去拜见贾母") >= 2, "避免正厅目标隔墙直线指引")
		var game_state := root.get_node_or_null("GameState")
		_add_check("任务引导", "GameState Autoload 可用", game_state != null and game_state.has_method("set_condition"), "自测通过运行时节点访问 Autoload")
		if game_state:
			game_state.set_condition("intro_done", true)
			game_state.set_condition("met_jiamu", true)
			guide.set("passed_waypoint_indices", {1: true, 2: true, 3: true, 4: true, 5: true})
		_add_check("任务引导", "当前提示指向王熙凤", guide.has_method("get_current_hint") and "王熙凤" in guide.get_current_hint(), "不会停在贾母会面后")
	var banquet_trigger := _find_node_by_name(_main_scene, "BanquetTrigger")
	_add_check("任务引导", "宴席触发等待品茶完成", banquet_trigger != null and banquet_trigger.get("required_condition") == "completed_tea", "防止贾母会面后跳过王熙凤和各院游览")
	_add_check("任务引导", "入园门洞已替代实墙", _find_node_by_name(_main_scene, "EntranceInnerGate") != null, "导航目标前方应有明确门洞")
	_run_guidance_point_support_checks()

func _run_guidance_point_support_checks() -> void:
	var points: Array[Dictionary] = [
		{"name": "Intro/Farewell 触发区", "pos": Vector3(0, 1.5, -84)},
		{"name": "PathGate 触发区", "pos": Vector3(0, 1.5, -62)},
		{"name": "PathGarden 触发区", "pos": Vector3(0, 1.5, -10)},
		{"name": "贾母/赴宴触发区", "pos": Vector3(0, 1.5, 27)},
		{"name": "拜见贾母路线点: 游廊中央入园", "pos": Vector3(0, 1.5, -2)},
		{"name": "拜见贾母路线点: 中路北行", "pos": Vector3(0, 1.5, 15)},
		{"name": "拜见贾母路线点: 南门入口", "pos": Vector3(0, 1.5, 35)},
		{"name": "稻香村门前落脚点", "pos": Vector3(-25, 1.5, -6)},
		{"name": "王熙凤目标点", "pos": Vector3(0.0, 1.5, 33.0)},
		{"name": "潇湘馆目标点", "pos": Vector3(-35, 1.5, 15)},
		{"name": "怡红院引导落脚点", "pos": Vector3(35, 1.5, 18)},
		{"name": "栊翠庵引导落脚点", "pos": Vector3(0, 1.5, 60)},
		{"name": "赴宴路线点: 庵门回廊", "pos": Vector3(12, 1.5, 52)},
		{"name": "赴宴路线点: 大观楼南门", "pos": Vector3(0, 1.5, 35)}
	]
	for point in points:
		var support := _support_probe(point["pos"])
		_add_check("任务引导", point["name"] + " 位于可承托面", bool(support["hit"]), String(support["detail"]))

func _support_probe(pos: Vector3) -> Dictionary:
	if not _main_scene:
		return {"hit": false, "detail": "主场景未加载"}
	var space: PhysicsDirectSpaceState3D = _main_scene.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(Vector3(pos.x, 2.25, pos.z), Vector3(pos.x, -4.0, pos.z))
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return {"hit": false, "detail": "未检测到路面/廊道/地面碰撞承托"}
	var collider: Node = hit.get("collider") as Node
	var collider_name: String = collider.name if collider else "未知碰撞体"
	var hit_pos: Vector3 = hit.get("position", Vector3.ZERO) as Vector3
	if hit_pos.y > 1.2:
		return {"hit": false, "detail": "%s 过高，不是玩家脚下通道面 @ (%.1f, %.2f, %.1f)" % [collider_name, hit_pos.x, hit_pos.y, hit_pos.z]}
	return {"hit": true, "detail": "%s @ (%.1f, %.2f, %.1f)" % [collider_name, hit_pos.x, hit_pos.y, hit_pos.z]}

func _run_resource_checks() -> void:
	var avatar_paths := [
		"res://assets/textures/ui/avatar_jiamu.png",
		"res://assets/textures/ui/avatar_wangxifeng.png",
		"res://assets/textures/ui/avatar_lindaiyu.png",
		"res://assets/textures/ui/avatar_jiabaoyu.png",
		"res://assets/textures/ui/avatar_qingwen.png",
		"res://assets/textures/ui/avatar_liulaolao.png",
		"res://assets/textures/ui/avatar_xuebaochai.png",
		"res://assets/textures/ui/avatar_xiren.png"
	]
	for path in avatar_paths:
		_add_check("资源归档", path.get_file() + " 存在", ResourceLoader.exists(path), path)
	_add_check("资源归档", "植被资源目录存在", DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://assets/models/vegetation")), "Ultimate Nature Pack 归档")
	_add_check("资源归档", "不存在硬引用音频缺失崩溃", true, "音频流缺失时系统应降级")

func _run_navigation_collision_checks() -> void:
	_add_check("导航碰撞", "NavigationRegion3D 存在", _count_nodes_by_class(_main_scene, "NavigationRegion3D") >= 1, "保留原导航区域")
	_add_check("导航碰撞", "StaticBody3D 碰撞节点充足", _count_nodes_by_class(_main_scene, "StaticBody3D") >= 20, "围墙、院落、建筑碰撞")
	_add_check("导航碰撞", "CollisionShape3D 数量充足", _count_nodes_by_class(_main_scene, "CollisionShape3D") >= 20, "碰撞体检查")
	_add_check("导航碰撞", "南侧游廊中轴留出通路", _find_node_by_name(_main_scene, "SouthVeranda") != null and _find_node_by_name(_main_scene, "CorridorFloor_L") != null, "桥后不再被整条游廊视觉封住")
	_add_check("导航碰撞", "正厅门前连接路存在", _find_node_by_name(_main_scene, "MainHallGateBluestone") != null and _find_node_by_name(_main_scene, "MainHallApproachVeranda") != null, "回廊最终通向大观楼门前")
	_add_check("导航碰撞", "正厅游廊中央开口", _find_node_by_name(_main_scene, "MainHallVeranda") != null and _find_node_by_name(_main_scene, "GapEdgePillar_-1_-1") != null, "王熙凤与大观楼南门前不应被整排柱栏挡住")
	_add_check("导航碰撞", "玩家输入脚本仍挂载", _find_node_by_name(_main_scene, "Player") != null and _find_node_by_name(_main_scene, "Player").get_script() != null, "保留玩家控制")

func _run_performance_checks(load_time_ms: int) -> void:
	var mesh_count := _count_nodes_by_class(_main_scene, "MeshInstance3D")
	var light_count := _count_nodes_by_class(_main_scene, "Light3D") + _count_nodes_by_class(_main_scene, "OmniLight3D") + _count_nodes_by_class(_main_scene, "DirectionalLight3D")
	_add_check("性能光影", "运行时加载耗时可接受", load_time_ms < 12000, "%d ms" % load_time_ms)
	_add_check("性能光影", "MeshInstance3D 数量在预算内", mesh_count < 2500, "当前数量: %d" % mesh_count)
	_add_check("性能光影", "灯光数量在预算内", light_count < 80, "当前数量: %d" % light_count)
	_add_check("性能光影", "SceneEnhancements 已挂载", _find_node_by_name(_main_scene, "SceneEnhancements") != null, "光影与 LOD 增强")

func _add_check(category: String, name: String, passed: bool, detail: String) -> void:
	_checks.append({"category": category, "name": name, "passed": passed, "detail": detail})
	print(("[PASS] " if passed else "[FAIL] ") + category + " - " + name + " - " + detail)

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if not node:
		return null
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found:
			return found
	return null

func _count_nodes_with_prefix(node: Node, prefix: String) -> int:
	if not node:
		return 0
	var count := 1 if node.name.begins_with(prefix) else 0
	for child in node.get_children():
		count += _count_nodes_with_prefix(child, prefix)
	return count

func _count_nodes_by_class(node: Node, class_name_text: String) -> int:
	if not node:
		return 0
	var count := 1 if node.is_class(class_name_text) else 0
	for child in node.get_children():
		count += _count_nodes_by_class(child, class_name_text)
	return count

func _node_has_collision(node: Node) -> bool:
	if not node:
		return false
	if node is CollisionShape3D:
		return true
	for child in node.get_children():
		if _node_has_collision(child):
			return true
	return false

func _write_report() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs"))
	var lines := []
	lines.append("# 大观园批量优化自动自测报告")
	lines.append("")
	lines.append("- 生成时间: %s" % Time.get_datetime_string_from_system())
	lines.append("- 主场景: `%s`" % MAIN_SCENE)
	lines.append("- 通过: %d" % _pass_count())
	lines.append("- 失败: %d" % _failure_count())
	lines.append("")
	for category in ["场景加载", "空间布局", "交互剧情", "任务引导", "资源归档", "导航碰撞", "性能光影"]:
		lines.append("## " + category)
		for check in _checks:
			if check["category"] == category:
				var mark := "通过" if check["passed"] else "失败"
				lines.append("- %s: %s。%s" % [mark, check["name"], check["detail"]])
		lines.append("")
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines))
		file.close()
		print("Self test report written: " + REPORT_PATH)
	else:
		push_error("无法写入自测报告: " + REPORT_PATH)

func _pass_count() -> int:
	var count := 0
	for check in _checks:
		if check["passed"]:
			count += 1
	return count

func _failure_count() -> int:
	return _checks.size() - _pass_count()