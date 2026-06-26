# 大观园 VR 互动体验 —— 技术架构文档

> **项目名称**: 刘姥姥进大观园  
> **引擎版本**: Godot 4.7  
> **渲染管线**: Forward Plus (Vulkan / DirectX 12)  
> **物理引擎**: Jolt Physics  

---

## 一、项目概述

本项目是一款基于中国古典名著《红楼梦》经典桥段「刘姥姥进大观园」的沉浸式 3D/VR 互动叙事体验。玩家以第一人称视角化身刘姥姥，探索大观园，与贾母、王熙凤、林黛玉、贾宝玉等经典角色互动，体验原著中的幽默与深意。

---

## 二、技术栈总览

| 类别 | 技术方案 |
|------|----------|
| **游戏引擎** | Godot 4.7 |
| **脚本语言** | GDScript |
| **渲染管线** | Forward Plus (Vulkan / DirectX 12) |
| **物理引擎** | Jolt Physics |
| **AI 语音** | MiMo TTS (mimo-v2.5-tts) |
| **AI 集成** | Godot AI MCP Server |
| **行为树** | Beehave 插件 |
| **寻路 AI** | GDQuest Steering AI Framework |
| **字体** | 霞鹜文楷 LXGW WenKai |
| **场景管理** | Asset Placer 插件 |

---

## 三、核心系统架构

### 3.1 自动加载系统 (Autoloads)

项目采用全局单例模式管理核心系统，确保跨场景访问：

| 单例名称 | 文件路径 | 职责 |
|----------|----------|------|
| `GameManager` | `scripts/autoload/game_manager.gd` | 游戏状态机 (MENU → PLAYING → DIALOG → PAUSED → CUTSCENE) |
| `GameState` | `scripts/autoload/game_state.gd` | 游戏进度数据（当前区域、已解锁区域、收集物品） |
| `EventBus` | `scripts/autoload/event_bus.gd` | 全局事件总线（建筑进入/退出、时间变化等） |
| `SaveSystem` | `scripts/systems/save_system.gd` | 存档/读档系统 |
| `DialogManager` | `scripts/dialog/dialog_manager.gd` | 对话流程控制 |
| `TTSSystem` | `scripts/systems/tts_system.gd` | AI 语音配音系统 |

### 3.2 状态机设计

```gdscript
# GameManager 核心状态枚举
enum GameStateType { MENU, PLAYING, DIALOG, PAUSED, CUTSCENE }

# 状态转换时自动处理输入模式
match new_state:
    GameStateType.PLAYING:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # 锁定鼠标
        get_tree().paused = false
    GameStateType.DIALOG:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)   # 显示鼠标
    GameStateType.PAUSED:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        get_tree().paused = true
```

---

## 四、核心功能模块

### 4.1 剧情对话系统

**文件**: `scripts/dialog/dialog_manager.gd` + `scripts/ui/dialog_ui.gd`

**特性**:
- 卷轴展开动画效果
- 打字机逐字显示
- 角色头像自动匹配（8 位主要角色立绘）
- 分支对话选择
- 对话历史记录
- 事件触发机制

```gdscript
# 对话数据结构示例
{
    "speaker": "贾母",
    "text": "这位姥姥从哪里来？",
    "choices": [
        {"text": "乡下来的", "next": "jiamu_response_1"},
        {"text": "久仰大名", "next": "jiamu_response_2"}
    ],
    "events": ["unlock_area_hall"]
}
```

### 4.2 AI 语音配音系统

**文件**: `scripts/systems/tts_system.gd`  
**配置**: `assets/config/tts_config.json`  
**模型**: MiMo TTS (mimo-v2.5-tts)

**特性**:
- 10 个角色独立音色配置
- VoiceDesign 角色音色描述驱动
- 每角色独立播放速度
- 对话时 BGM 自动闪避
- 本地预生成 WAV 缓存

| 角色 | 音色风格 | 播放速度 |
|------|----------|----------|
| 旁白 | 成熟男性纪录片讲解员 | 1.25x |
| 刘姥姥 | 乡下老太太，惊奇热络 | 1.1x |
| 贾母 | 老祖母，低柔慈爱 | 1.1x |
| 王熙凤 | 年轻女性，明亮爽利 | 1.05x |
| 林黛玉 | 清冷柔弱，带幽怨 | 0.92x |
| 贾宝玉 | 少年公子，温和随意 | 1.0x |
| 妙玉 | 出家女子，清冷淡漠 | 0.88x |
| 薛宝钗 | 温婉大方，沉稳得体 | 1.05x |

### 4.3 导航引导系统

**文件**: `scripts/systems/navigation_guide.gd`

**特性**:
- 金色闪烁 3D 箭头指引
- HUD 方向提示文字
- 多阶段故事流程定义
- 通过半径判定（到达某点自动触发下一阶段）
- 支持路线点序列

```gdscript
# 故事阶段定义示例
{
    "name": "去拜见贾母",
    "target": Vector3(0, 1.5, 30),
    "condition": "intro_done",
    "completion": "met_jiamu",
    "hint": "去见贾母",
    "route": [
        {"pos": Vector3(0, 1.5, -2), "hint": "从游廊中央入园"},
        {"pos": Vector3(0, 1.5, 13), "hint": "前往大观楼"},
        {"pos": Vector3(0, 1.5, 30), "hint": "去见贾母"}
    ]
}
```

### 4.4 场景氛围系统

**文件**: `scripts/systems/scene_ambience.gd`

**特性**:
- 🦋 蝴蝶飞舞（QuadMesh + Tween 动画）
- 🍃 落叶飘零（物理模拟）
- 💨 风粒子效果（GPUParticles3D）
- 🐦 鸟鸣音效（随机间隔触发）
- 🐟 锦鲤跃水（定时触发）

```gdscript
# 氛围元素初始化
func _init_ambience() -> void:
    _create_butterflies(3)      # 3 只蝴蝶
    _create_falling_leaves(8)   # 8 片落叶
    _create_wind_particles()    # 风粒子
```

### 4.5 解说立牌系统

**文件**: `scripts/ui/signboard_system.gd`

**特性**:
- 中式木质立牌 3D 模型
- 接近触发区域自动显示
- 角色百科弹窗（宣纸红木风格）
- 包含角色背景故事
- VR 适配剧情面板

### 4.6 玩家控制器

**文件**: `scripts/player/player_controller.gd`

**特性**:
- 第一人称视角 (CharacterBody3D)
- WASD 移动 + 鼠标视角控制
- 行走/奔跑切换
- 跳跃 + 台阶自动吸附
- 射线交互检测
- 区域进入/退出事件

```gdscript
@export var walk_speed: float = 3.0
@export var run_speed: float = 5.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var look_limit: float = 80.0
```

### 4.7 3D 富文本系统

**文件**: `rich_text_3d.gd`

**特性**:
- BBCode 格式支持
- 3D 空间中的文字渲染
- 可配置字体、大小、描边
- 动态可见比例控制
- VR 场景下的清晰文字显示

```gdscript
@tool
class_name RichText3D
extends MeshInstance3D

@export_multiline var text := ""
@export var font: Font
@export var font_size: int = 16
@export var size := Vector2(.7, .5)
@export_range(100, 2000) var resolution := 1000.
```

### 4.8 场景构建系统

**文件**: `scripts/systems/garden_builder.gd`

**特性**:
- 动态场景元素加载
- 分层初始化（轻量 → 中等 → 重型）
- 编辑器预览模式
- 场景诊断日志

```gdscript
# 分层初始化策略
# 第一批：轻量系统（立即初始化）
_init_plaque_system()
_init_signboard_system()

# 第二批：中等重量系统
_init_scene_ambience()

# 第三批：重型系统（每帧一个避免卡死）
_init_vegetation_system()
_init_garden_builder()
```

---

## 五、插件系统

### 5.1 Beehave - 行为树系统

**路径**: `addons/beehave/`

用于 NPC 行为逻辑的可视化行为树编辑器，支持：
- 节点式行为树编辑
- 黑板数据共享
- 运行时调试器
- 性能指标监控

### 5.2 Godot AI - MCP 集成

**路径**: `addons/godot_ai/`

提供 Model Context Protocol 集成，支持：
- AI 辅助开发
- 编辑器内 AI 对话
- 代码生成与分析
- 客户端配置管理

### 5.3 GDQuest Steering AI Framework

**路径**: `addons/com.gdquest.godot-steering-ai-framework/`

提供高级 AI 寻路与避障：
- 代理位置管理
- 转向行为
- 群体行为
- 路径跟随

### 5.4 Asset Placer - 场景资产放置器

**路径**: `addons/asset_placer/`

可视化场景资产放置工具，支持：
- 缩略图预览
- 拖拽放置
- 资产分组管理

---

## 六、场景架构

```
scenes/
├── player/
│   └── player.tscn           # 玩家角色场景
├── ui/
│   ├── main_menu.tscn        # 主菜单
│   ├── dialog_ui.tscn        # 对话界面
│   ├── game_hud.tscn         # 游戏 HUD
│   ├── pause_menu.tscn       # 暂停菜单
│   └── signboard_popup.tscn  # 立牌弹窗
└── world/
    └── main.tscn             # 主世界场景
        ├── Terrain            # 地形
        ├── Buildings          # 建筑群
        ├── Vegetation         # 植被系统
        ├── GardenFeatures     # 园林元素
        ├── NPCs               # NPC 节点
        ├── TriggerZones       # 触发区域
        └── Items              # 物品
```

---

## 七、故事流程

```
荣国府大门外 → 开场对话（刘姥姥 + 周瑞家）
    ↓
石牌坊大门 → 石狮子、红灯笼描写
    ↓
石桥 + 荷塘 → 锦鲤、翠竹、抄手游廊
    ↓
正厅 → 拜见贾母（选择分支）
    ↓
园中游览 → 潇湘馆（林黛玉）、怡红院（贾宝玉）、蘅芜苑（薛宝钗）
    ↓
栊翠庵 → 品茶（妙玉）
    ↓
宴席 → 经典搞笑桥段
    ↓
告别 → 返回大门
```

---

## 八、角色系统

### NPC 基础类

**文件**: `scripts/npcs/npc_base.gd` + `scripts/npcs/npc_visual_builder.gd`

支持：
- NPC 可视化构建
- 交互触发
- 对话关联
- 条件判定

### 主要角色

| 角色 | 居所 | 触发对话 |
|------|------|----------|
| 贾母 | 正厅 | `meet_jiamu` |
| 王熙凤 | 正厅旁 | `meet_xifeng` |
| 林黛玉 | 潇湘馆 | `visit_xiaoxiang` |
| 贾宝玉 | 怡红院 | `visit_yihong` |
| 妙玉 | 栊翠庵 | `visit_longcui` |
| 薛宝钗 | 蘅芜苑 | `visit_hengwu` |

---

## 九、UI 设计风格

### 清代中式 UI

- **背景**: 宣纸纹理
- **边框**: 红木风格
- **字体**: 霞鹜文楷 LXGW WenKai (SIL OFL 1.1)
- **配色**: 古典中国色系

### 对话框设计

- 卷轴展开动画
- 打字机效果
- 角色头像显示
- 选项按钮

---

## 十、性能优化策略

### 10.1 分层初始化

将系统按重量分为三层，逐帧加载避免卡顿：
1. **轻量级**: 牌匾系统、立牌系统、导航引导
2. **中量级**: 场景氛围系统
3. **重量级**: 植被系统、场景构建器

### 10.2 场景分割

主场景按功能分割为独立节点：
- Terrain / Buildings / Vegetation / GardenFeatures
- NPCs / TriggerZones / Items

### 10.3 加载诊断

内置加载日志系统，记录每个阶段的初始化时间：

```gdscript
const LOAD_LOG_PATH := "user://main_scene_load.log"
func _log_load(msg: String) -> void:
    # 记录加载时间和状态
```

---

## 十一、输入系统

| 操作 | 按键 |
|------|------|
| 移动 | WASD |
| 视角 | 鼠标 |
| 跳跃 | Space |
| 交互 | E |
| 暂停 | ESC |
| 奔跑 | Shift |

---

## 十二、音频系统

**文件**: `scripts/systems/audio_system.gd`

**音频总线**:
- `Master`: 主音量
- `BGM`: 背景音乐
- `SFX`: 音效
- `Voice`: 语音配音

**特性**:
- 对话时 BGM 自动闪避
- 环境音效随机触发
- 3D 空间音频

---

## 十三、项目配置

```ini
# project.godot 关键配置
[application]
config/name="刘姥姥进大观园"
run/main_scene="res://scenes/ui/main_menu.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")

[display]
window/size/mode=3                    # 全屏模式
window/stretch/mode="canvas_items"    # 画布拉伸
window/stretch/aspect="expand"        # 宽高比扩展
```

---

## 十四、创新亮点

### 14.1 文化与技术融合

将中国传统文学经典《红楼梦》与现代 3D/VR 技术结合，创造沉浸式文化体验。

### 14.2 AI 语音驱动

使用 MiMo TTS 的 VoiceDesign 功能，为每个角色定义独特的音色描述，实现：
- 角色性格通过声音体现
- 语速与角色性格匹配
- 预生成缓存优化性能

### 14.3 分层渐进加载

创新的三层初始化策略，确保复杂场景平滑加载，避免玩家等待。

### 14.4 场景-剧情同步

3D 场景元素（石狮子、红灯笼、抄手游廊）与原著台词精确对应，增强代入感。

### 14.5 MCP AI 集成

集成 Model Context Protocol，支持 AI 辅助开发，提升开发效率。

---

## 十五、文件结构

```
project_godot/
├── main.gd                    # 主场景脚本
├── rich_text_3d.gd            # 3D 富文本组件
├── setup.gd                   # 项目初始化
├── project.godot              # 项目配置
├── assets/
│   ├── audio/                 # 音频资源
│   │   ├── ambient/           # 环境音效
│   │   ├── bgm/               # 背景音乐
│   │   └── voice/             # 语音文件
│   ├── config/
│   │   └── tts_config.json    # TTS 配置
│   ├── fonts/                 # 字体资源
│   └── textures/              # 纹理资源
├── scripts/
│   ├── autoload/              # 全局单例
│   ├── buildings/             # 建筑系统
│   ├── dialog/                # 对话系统
│   ├── items/                 # 物品系统
│   ├── npcs/                  # NPC 系统
│   ├── player/                # 玩家控制
│   ├── systems/               # 核心系统
│   ├── tests/                 # 测试用例
│   └── ui/                    # UI 界面
├── scenes/                    # 场景文件
├── addons/                    # 插件目录
└── tools/                     # 开发工具
```

---

## 十六、技术栈总结

```
┌─────────────────────────────────────────────────────────┐
│                    刘姥姥进大观园                         │
├─────────────────────────────────────────────────────────┤
│  引擎: Godot 4.7 + Forward Plus                        │
│  语言: GDScript                                         │
│  物理: Jolt Physics                                     │
│  渲染: Vulkan / DirectX 12                              │
├─────────────────────────────────────────────────────────┤
│  AI 集成:                                               │
│  ├── MiMo TTS (语音合成)                                │
│  ├── Godot AI MCP (开发辅助)                            │
│  └── Beehave (行为树)                                   │
├─────────────────────────────────────────────────────────┤
│  核心系统:                                              │
│  ├── 对话系统 (卷轴动画 + 分支选择)                      │
│  ├── 导航引导 (3D 箭头 + HUD 提示)                      │
│  ├── 场景氛围 (蝴蝶/落叶/风/鸟鸣/锦鲤)                  │
│  ├── 立牌百科 (木质立牌 + 角色故事)                      │
│  ├── 语音配音 (10 角色独立音色)                          │
│  └── VR 适配 (清晰文字 + 视角优化)                      │
└─────────────────────────────────────────────────────────┘
```

---

*文档生成时间: 2026-06-26*  
*项目版本: Godot 4.7 + Forward Plus*
