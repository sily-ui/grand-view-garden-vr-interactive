@tool
extends Node3D
class_name SceneAmbience

# ============================================================
# 场景氛围系统 - 鸟鸣、落叶、锦鲤、蝴蝶等动态元素
# ============================================================

# 蝴蝶数据
var butterflies: Array[MeshInstance3D] = []
var butterfly_tweens: Array[Tween] = []

# 飘落的叶子
var falling_leaves: Array[MeshInstance3D] = []

# 鸟鸣计时器
var bird_timer: float = 0.0
var bird_interval: float = 8.0

# 锦鲤跳跃计时器
var koi_timer: float = 0.0
var koi_interval: float = 12.0

# 风声粒子
var wind_particles: GPUParticles3D = null

func _ready() -> void:
	add_to_group("scene_ambience")
	call_deferred("_init_ambience")

func _init_ambience() -> void:
	_create_butterflies(3)
	_create_falling_leaves(8)
	_create_wind_particles()
	bird_timer = randf_range(2.0, 5.0)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_leaves(delta)
		return
	# 鸟鸣
	bird_timer -= delta
	if bird_timer <= 0.0:
		bird_timer = randf_range(bird_interval, bird_interval + 8.0)
		_play_bird_chirp()
	
	# 锦鲤
	koi_timer -= delta
	if koi_timer <= 0.0:
		koi_timer = randf_range(koi_interval, koi_interval + 15.0)
		_spawn_koi_splash()
	
	# 更新叶子
	_update_leaves(delta)

# ============================================================
# 蝴蝶
# ============================================================

func _create_butterflies(count: int) -> void:
	for i in range(count):
		var b := _make_butterfly_mesh()
		var start_pos := Vector3(
			randf_range(-30.0, 30.0),
			randf_range(1.5, 3.5),
			randf_range(-20.0, 20.0)
		)
		b.position = start_pos
		add_child(b)
		butterflies.append(b)
		_start_butterfly_flight(b, i)

func _make_butterfly_mesh() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.25, 0.15)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.75, 0.3, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.4, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = mat
	node.mesh = mesh
	return node

func _start_butterfly_flight(b: MeshInstance3D, idx: int) -> void:
	var tween := create_tween().set_loops()
	var duration := randf_range(3.0, 6.0)
	var radius := randf_range(4.0, 12.0)
	var base_pos := b.position
	var offset := idx * TAU / 3.0
	
	# 螺旋飞行动画
	tween.tween_method(func(t: float) -> void:
		if not is_instance_valid(b):
			return
		var angle := t * TAU + offset
		b.position.x = base_pos.x + cos(angle) * radius * (0.5 + 0.5 * sin(t * 2.0))
		b.position.z = base_pos.z + sin(angle) * radius * (0.5 + 0.5 * cos(t * 3.0))
		b.position.y = base_pos.y + sin(t * 4.0 + idx) * 0.8
		# 朝向飞行方向
		b.rotation.y = angle + PI / 2
		b.rotation.z = sin(t * 8.0) * 0.3  # 翅膀扇动
	, 0.0, duration * 4.0, 0.05)
	tween.set_loops(-1)
	butterfly_tweens.append(tween)

# ============================================================
# 飘落的叶子
# ============================================================

func _create_falling_leaves(count: int) -> void:
	for i in range(count):
		var leaf := _make_leaf_mesh()
		_reset_leaf_position(leaf, true)
		add_child(leaf)
		falling_leaves.append(leaf)

func _make_leaf_mesh() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.15, 0.12)
	var mat := StandardMaterial3D.new()
	# 随机深浅绿色
	var green := randf_range(0.3, 0.55)
	mat.albedo_color = Color(green * 0.7, green, green * 0.4, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = mat
	node.mesh = mesh
	return node

func _reset_leaf_position(leaf: MeshInstance3D, random_y: bool) -> void:
	leaf.position = Vector3(
		randf_range(-40.0, 40.0),
		randf_range(4.0, 10.0) if random_y else randf_range(6.0, 10.0),
		randf_range(-40.0, 40.0)
	)
	leaf.rotation = Vector3(
		randf_range(-0.5, 0.5),
		randf_range(0, TAU),
		randf_range(-0.5, 0.5)
	)

func _update_leaves(delta: float) -> void:
	for leaf in falling_leaves:
		if not is_instance_valid(leaf):
			continue
		# 缓慢下落 + 水平飘动
		leaf.position.y -= delta * randf_range(0.3, 0.8)
		leaf.position.x += sin(Time.get_ticks_msec() / 1000.0 + leaf.position.z) * delta * 0.5
		leaf.rotation.z += delta * 0.8
		leaf.rotation.y += delta * 0.3
		# 落地后重置
		if leaf.position.y < 0.0:
			_reset_leaf_position(leaf, false)

# ============================================================
# 鸟鸣音效
# ============================================================

func _play_bird_chirp() -> void:
	var audio_sys := get_tree().get_first_node_in_group("audio_system")
	if not audio_sys:
		return
	# 通过 AudioSystem 播放鸟鸣
	if audio_sys.has_method("play_sfx"):
		audio_sys.play_sfx("bird_chirp")

# ============================================================
# 锦鲤跃水
# ============================================================

func _spawn_koi_splash() -> void:
	# 在荷塘区域生成一个水花粒子效果
	var splash_pos := Vector3(
		randf_range(-3.0, 3.0),
		0.2,
		randf_range(-14.0, -6.0)
	)
	
	var splash := GPUParticles3D.new()
	splash.amount = 6
	splash.lifetime = 1.0
	splash.one_shot = true
	splash.emitting = true
	splash.position = splash_pos
	
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.3
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 20.0
	mat.initial_velocity_min = 1.5
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, -6.0, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.6
	mat.color = Color(0.85, 0.9, 0.95, 0.7)
	splash.process_material = mat
	
	# 用一个小球作为draw pass
	var draw_mesh := SphereMesh.new()
	draw_mesh.radius = 0.06
	draw_mesh.height = 0.12
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.85, 0.92, 0.98, 0.8)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mesh.material = draw_mat
	splash.draw_pass_1 = draw_mesh
	
	add_child(splash)
	
	# 自动销毁
	await splash.finished
	splash.queue_free()

func play_koi_jump_sequence() -> void:
	for i in range(3):
		_spawn_koi_arc(Vector3(randf_range(-2.5, 2.5), 0.32, randf_range(-13.0, -7.0)), i * 0.22)

func _spawn_koi_arc(start_pos: Vector3, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	var koi := MeshInstance3D.new()
	koi.name = "KoiJump"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.42
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.34, 0.12)
	mat.roughness = 0.55
	mesh.material = mat
	koi.mesh = mesh
	koi.position = start_pos
	koi.rotation.x = PI / 2.0
	add_child(koi)
	var tween := create_tween()
	tween.tween_property(koi, "position", start_pos + Vector3(0.55, 0.75, 0.4), 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(koi, "position", start_pos + Vector3(1.1, -0.04, 0.8), 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		_spawn_koi_splash()
		koi.queue_free()
	)

# ============================================================
# 风吹树叶粒子
# ============================================================

func _create_wind_particles() -> void:
	wind_particles = GPUParticles3D.new()
	wind_particles.amount = 15
	wind_particles.lifetime = 4.0
	wind_particles.emitting = true
	wind_particles.position = Vector3(0, 3, 0)
	
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(30, 2, 30)
	mat.direction = Vector3(1, -0.3, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3(0.3, -0.5, 0)
	mat.scale_min = 0.2
	mat.scale_max = 0.5
	mat.color = Color(0.5, 0.65, 0.35, 0.6)
	wind_particles.process_material = mat
	
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.15, 0.1)
	var mesh_mat := StandardMaterial3D.new()
	mesh_mat.albedo_color = Color(0.5, 0.65, 0.35, 0.7)
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = mesh_mat
	wind_particles.draw_pass_1 = mesh
	
	add_child(wind_particles)
