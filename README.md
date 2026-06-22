# 大观园 VR 互动体验 | Grand View Garden VR Interactive

<p align="center">
  <img src="assets/textures/ui/avatar_jiamu.png" width="100" alt="贾母">
  <img src="assets/textures/ui/avatar_liulaolao.png" width="100" alt="刘姥姥">
  <img src="assets/textures/ui/avatar_jiabaoyu.png" width="100" alt="贾宝玉">
  <img src="assets/textures/ui/avatar_lindaiyu.png" width="100" alt="林黛玉">
</p>

> 基于《红楼梦》经典桥段「刘姥姥进大观园」的沉浸式 3D/VR 互动叙事体验。

---

## 📖 项目简介 | About

本项目以中国古典名著《红楼梦》为背景，通过第一人称 3D 视角 + VR 支持，让玩家化身刘姥姥，亲历大观园的繁华与风雅。跟随剧情推进，与贾母、王熙凤、林黛玉、贾宝玉等经典角色互动，感受原著中的幽默与深意。

This project is an immersive 3D/VR interactive narrative experience based on the classic Chinese novel *"Dream of the Red Chamber"* (红楼梦). Players take on the role of Granny Liu (刘姥姥), exploring the Grand View Garden (大观园), interacting with iconic characters, and experiencing the humor and depth of the original story.

---

## 🎮 核心功能 | Features

| 功能 | Feature | 说明 |
|------|---------|------|
| 🎭 剧情对话系统 | Dialog System | 卷轴展开动画、打字机效果、角色头像、选择分支 |
| 🧭 导航引导系统 | Navigation Guide | 金色闪烁箭头 + HUD 方向提示，引导玩家完成剧情 |
| 🌿 场景氛围系统 | Scene Ambience | 蝴蝶飞舞、落叶飘零、风粒子、鸟鸣、锦鲤跃水 |
| 📜 解说立牌系统 | Signboard System | 古风立牌 + 角色百科弹窗，宣纸红木风格 |
| 🎨 清代中式 UI | Classical UI | 宣纸背景 + 红木边框，霞鹜文楷字体 |
| 🖼️ 角色头像 | Character Avatars | 8 位主要角色立绘，自动匹配对话显示 |
| 🥽 VR 支持 | VR Support | 适配 VR 视角，文字清晰可读 |
| 🏯 场景匹配台词 | Scene-Dialog Sync | 石狮子、红灯笼、抄手游廊、石桥等场景元素与台词一致 |

---

## 🏛️ 故事流程 | Story Flow

```
荣国府大门外 → 开场对话（刘姥姥 + 周瑞家）
    ↓
石牌坊大门 → 石狮子、红灯笼描写
    ↓
石桥 + 荷塘 → 锦鲤、翠竹、抄手游廊
    ↓
正厅 → 拜见贾母（选择分支）
    ↓
园中游览 → 潇湘馆（林黛玉）、怡红院（贾宝玉）、蘅芜苑（薛宝钗）等
    ↓
宴席 → 经典搞笑桥段
    ↓
告别 → 返回大门
```

---

## 🎭 角色 | Characters

| 角色 | Character | 身份 | 居所 |
|------|-----------|------|------|
| 贾母 | Lady Jia | 荣国府史太君 | 正厅 |
| 刘姥姥 | Granny Liu | 乡间老妪（主角） | — |
| 贾宝玉 | Jia Baoyu | 怡红公子 | 怡红院 |
| 林黛玉 | Lin Daiyu | 潇湘妃子 | 潇湘馆 |
| 王熙凤 | Wang Xifeng | 琏二奶奶 | — |
| 薛宝钗 | Xue Baochai | 蘅芜君 | 蘅芜苑 |
| 袭人 | Xiren | 宝玉贴身丫鬟 | 怡红院 |
| 晴雯 | Qingwen | 宝玉丫鬟 | 怡红院 |

---

## 🛠️ 技术栈 | Tech Stack

- **引擎**: [Godot 4](https://godotengine.org/)
- **脚本语言**: GDScript
- **字体**: [霞鹜文楷 LXGW WenKai](https://github.com/lxgw/LxgwWenKai) (SIL OFL 1.1)
- **物理引擎**: Jolt Physics
- **渲染**: Vulkan (DirectX 12)

---

## 🚀 快速开始 | Getting Started

### 前提条件 | Prerequisites

- [Godot 4.3+](https://godotengine.org/download)

### 运行 | Run

```bash
# 克隆仓库
git clone https://github.com/sily-ui/grand-view-garden-vr-interactive.git

# 用 Godot 打开项目
# File → Open Project → 选择 project.godot
```

### 操作说明 | Controls

| 操作 | Action | 键位 |
|------|--------|------|
| 移动 | Move | W/A/S/D |
| 视角 | Look | 鼠标移动 |
| 奔跑 | Sprint | Shift |
| 跳跃 | Jump | 空格 |
| 交互 | Interact | E |
| 暂停 | Pause | ESC |

---

## 📁 项目结构 | Project Structure

```
project_godot/
├── main.tscn              # 主场景
├── main.gd                # 主场景脚本
├── project.godot           # Godot 项目配置
├── assets/
│   ├── fonts/             # 霞鹜文楷字体
│   ├── textures/ui/       # 角色头像
│   ├── audio/             # 音效
│   └── models/            # 3D 模型
├── scripts/
│   ├── autoload/          # 全局单例（GameManager, GameState, EventBus）
│   ├── dialog/            # 对话系统（DialogData, DialogManager）
│   ├── systems/           # 核心系统
│   │   ├── navigation_guide.gd    # 导航箭头引导
│   │   ├── scene_ambience.gd      # 场景氛围（蝴蝶、落叶、锦鲤）
│   │   ├── event_trigger.gd       # 事件触发器
│   │   └── scene_enhancements.gd  # 场景增强
│   ├── ui/                # UI 组件
│   │   ├── dialog_ui.gd           # 对话弹窗
│   │   ├── signboard_system.gd    # 解说立牌
│   │   ├── plaque_system.gd       # 匾额对联
│   │   ├── game_hud.gd            # 游戏 HUD
│   │   └── pause_menu.gd          # 暂停菜单
│   ├── player/            # 玩家控制器
│   ├── npcs/              # NPC 系统
│   └── buildings/         # 建筑系统
└── scenes/
    ├── player/            # 玩家场景
    └── ui/                # 主菜单场景
```

---

## 📜 开源协议 | License

本项目代码采用 [MIT License](LICENSE.md) 开源。

### 第三方资源 | Third-party Assets

| 资源 | Asset | 协议 License |
|------|-------|-------------|
| 霞鹜文楷 | LXGW WenKai Font | [SIL OFL 1.1](https://openfontlicense.org/) |
| Asset Placer | Godot 插件 | MIT License |
| Godot AI MCP | 编辑器工具 | MIT License |

---

## 🙏 致谢 | Acknowledgments

- [曹雪芹](https://zh.wikipedia.org/wiki/曹雪芹) — 《红楼梦》原著
- [lxgw](https://github.com/lxgw) — 霞鹜文楷开源字体
- [Godot Engine](https://godotengine.org/) — 开源游戏引擎
- [Fontworks](https://github.com/fontworks-fonts) — Klee 原始开源字体

---

## 📸 截图 | Screenshots

> 待补充 | Coming soon

---

## 🌐 多语言 | Languages

- [中文](#大观园-vr-互动体验--grand-view-garden-vr-interactive) (当前)
- [English](#-项目简介--about)
