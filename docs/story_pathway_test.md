# 《刘姥姥进大观园》主角动线测试文档

> 基于原著《红楼梦》第三十九回至四十二回，刘姥姥二进荣国府游览大观园的叙事线。
> 本文档覆盖主角刘姥姥在游戏中全部13条主剧情动线及6条支线，逐一验证剧情、人物、旁白、声音、状态的正确性与防重复机制。

---

## 一、全局状态流转总览

```
入场(0,−84) → 照壁(−8.8,−58) → 石路(0,−38) → 石桥(0,−16/−10) → 游廊(0,−2)
    → 正厅拜贾母(0,35) → 见王熙凤(3.2,27.5)
        → 左: 潇湘馆(−35,15) → 右: 怡红院(35,15)
            → 后: 栊翠庵(0,57) → 回: 赴宴(0,35) → 出: 告别(0,−84)
```

**条件链 (Condition Chain)**：
```
intro_done → met_jiamu → met_xifeng → visited_xiaoxiang → visited_yihong → completed_tea → attended_banquet → game_completed
```

**区域解锁链**：
```
["entrance"] → +xiaoxiang_guan, +yihong_yuan, +longcui_an (贾母对话后同时解锁)
```

---

## 二、主动线逐一测试

### 动线 1：入场 — 荣国府门外

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, −84)，IntroTrigger |
| **触发条件** | 无（游戏启动后延迟2秒自动触发） |
| **对话ID** | `intro_arrival` |
| **触发方式** | main.gd `_ready()` 延迟2秒调用 `intro_trigger._on_body_entered()` |
| **对话链** | `intro_arrival` → `intro_arrival_2` → `intro_arrival_3`（末句触发事件） |
| **说话人** | 旁白 → 刘姥姥 → 周瑞家 |
| **旁白内容** | "刘姥姥带着板儿，跟着荣国府仆妇周瑞家，一路来到荣国府门外……" |
| **事件触发** | `intro_complete` |
| **条件变化** | `GameState.conditions["intro_done"] = true` |
| **区域变化** | 无 |
| **TTS语音** | 旁白音色 → 刘姥姥音色 → 周瑞家音色 |
| **可见NPC** | EventTrigger自动推断 `visible_npc_name = "周瑞家"` |
| **场景特效** | 无 |
| **导航箭头** | 阶段1"前往荣国府门外"消失，切换到阶段2"从照壁左侧石路绕行" |

**测试步骤**：
1. [ ] 启动新游戏，等待2秒
2. [ ] 确认对话自动弹出，旁白叙述荣国府门外场景
3. [ ] 按E推进到刘姥姥发言
4. [ ] 按E推进到周瑞家发言
5. [ ] 对话结束后确认 `intro_done == true`
6. [ ] 确认导航箭头切换到"绕过照壁"
7. [ ] 确认周瑞家NPC模型出现在触发区域附近

**防重复测试**：
1. [ ] 对话结束后回到(0,−84)位置，确认不再触发（`trigger_once=true` + `has_triggered`）

---

### 动线 2：绕过照壁

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (−8.8, −58)，导航路点 |
| **触发条件** | `intro_done == true` |
| **对话ID** | 无（纯路点） |
| **完成条件** | 玩家接近目标6米内即跳过 |

**测试步骤**：
1. [ ] 入场对话结束后，导航箭头指向照壁方向
2. [ ] 走到(−8.8, −58)附近，确认箭头消失
3. [ ] 导航切换到"回到入园石路"

---

### 动线 3：回到入园石路

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, −38)，导航路点 |
| **触发条件** | `intro_done == true` |
| **对话ID** | 无（纯路点） |

**测试步骤**：
1. [ ] 从照壁方向走回中轴线
2. [ ] 到达(0, −38)附近，确认箭头切换到"前往沁芳桥"

---

### 动线 4：过石桥

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, −16)，导航路点 |
| **触发条件** | `intro_done == true` |
| **对话ID** | 无（纯路点） |

---

### 动线 5：走上石桥

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, −10) |
| **触发条件** | `intro_done == true` |
| **对话ID** | `path_garden`（PathGardenTrigger，条件：`path_gate_seen`） |
| **前置触发** | PathGateTrigger (0, −62) 触发 `path_gate` → 设置 `path_gate_seen` |
| **对话链** | `path_garden` → `path_garden_2` |
| **说话人** | 旁白 → 刘姥姥 |
| **事件触发** | `path_complete` → 设置 `path_done` |
| **场景特效** | 锦鲤跳跃动画（`scene_ambience.play_koi_jump_sequence()`） |

**测试步骤**：
1. [ ] 先经过PathGateTrigger (0, −62)，确认 `path_gate` 对话弹出
2. [ ] 对话中确认旁白描述大观园门 + 刘姥姥感叹石狮子
3. [ ] `path_gate_seen` 被设置
4. [ ] 走到石桥(0, −10)，确认 `path_garden` 对话弹出
5. [ ] 确认锦鲤跳跃动画播放
6. [ ] `path_done` 被设置

**防重复测试**：
1. [ ] path_gate 和 path_garden 均为 `trigger_once=true`，往返不重复触发

---

### 动线 6：沿游廊前行

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, −2)，导航路点 |
| **触发条件** | `intro_done == true` |
| **对话ID** | 无（纯路点） |

---

### 动线 7：拜见贾母 ⭐ 关键节点

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, 35)，MeetJiamuTrigger |
| **触发条件** | `intro_done == true`（`required_condition="intro_done"`） |
| **对话ID** | `meet_jiamu` |
| **对话链** | `meet_jiamu` → 选项分支 → `meet_jiamu_3` → `meet_jiamu_4` |
| **说话人** | 贾母 → 刘姥姥(玩家选) → 贾母 → 王熙凤 |

**选择分支**：
| 选项 | 跳转 | 刘姥姥台词 |
|------|------|-----------|
| A. 拘谨行礼 | `meet_jiamu_2a` | "给老太太请安了。我们乡下人，没见过世面……" |
| B. 四处张望 | `meet_jiamu_2b` | "哎呦！这屋子可真敞亮！那柱子都比我们家房子粗！" |

**事件触发**（`meet_jiamu_4`末句触发4个事件）：
| 事件ID | 效果 |
|--------|------|
| `meet_jiamu_complete` | `conditions["met_jiamu"] = true` |
| `unlock_xiaoxiang` | `unlocked_areas += "xiaoxiang_guan"` |
| `unlock_yihong` | `unlocked_areas += "yihong_yuan"` |
| `unlock_longcui` | `unlocked_areas += "longcui_an"` |

**TTS语音**：贾母音色 → 刘姥姥音色 → 贾母音色 → 王熙凤音色

**测试步骤**：
1. [ ] 走到(0, 35)附近，确认对话自动触发
2. [ ] 确认贾母头像显示、打字机效果
3. [ ] 选择选项A，确认跳转到 `meet_jiamu_2a`
4. [ ]（新游戏）选择选项B，确认跳转到 `meet_jiamu_2b`
5. [ ] 两条分支均汇入 `meet_jiamu_3`
6. [ ] 对话结束后确认 `met_jiamu == true`
7. [ ] 确认 `xiaoxiang_guan`、`yihong_yuan`、`longcui_an` 三个区域已解锁
8. [ ] 导航箭头切换到"找王熙凤问路"

**防重复测试**：
1. [ ] 对话结束后回到(0, 35)，确认不重复触发（`trigger_once=true`）

---

### 动线 8：找王熙凤问路

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (3.2, 27.5)，NPC交互 |
| **触发条件** | `met_jiamu == true`（导航条件） |
| **对话ID** | `meet_xifeng` |
| **触发方式** | 玩家走近王熙凤NPC → 交互提示 → 按E触发 |
| **对话链** | `meet_xifeng` → `meet_xifeng_2` → `meet_xifeng_3` |
| **说话人** | 王熙凤 → 刘姥姥 → 王熙凤 |
| **事件触发** | `meet_xifeng_complete` → `conditions["met_xifeng"] = true` |

**测试步骤**：
1. [ ] 导航箭头指向王熙凤位置(3, 20)
2. [ ] 靠近王熙凤，确认交互提示"与王熙凤对话"
3. [ ] 按E触发对话，确认NPC转头面向玩家（TALKING状态）
4. [ ] 对话结束后确认NPC恢复巡逻
5. [ ] `met_xifeng == true`
6. [ ] 导航箭头切换到"去潇湘馆见林黛玉"

**防重复测试**：
1. [ ] 再次按E与王熙凤对话，确认可以重复对话（NPC无去重机制——**注意：这是设计缺陷，NPC对话应添加 `dialog_history` 检查**）

---

### 动线 9：游潇湘馆（林黛玉）⭐

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (−35, 15)，NPC交互 |
| **触发条件** | `met_xifeng == true`（导航条件）；区域 `xiaoxiang_guan` 已解锁 |
| **对话ID** | `visit_xiaoxiang` |
| **对话链** | `visit_xiaoxiang` → `visit_xiaoxiang_2` → ... → `visit_xiaoxiang_5`（5句） |
| **说话人** | 旁白 → 刘姥姥 → 林黛玉 → 刘姥姥 → 林黛玉 |
| **旁白内容** | "潇湘馆内翠竹掩映，清幽雅致。林黛玉正倚在窗前看书。" |
| **事件触发** | `visit_xiaoxiang_complete` → `conditions["visited_xiaoxiang"] = true` |
| **TTS语音** | 旁白 → 刘姥姥 → 林黛玉音色 |

**可交互物品**（潇湘馆区域内）：
| 物品 | 位置 | 效果 |
|------|------|------|
| 古琴 | (−36, 13) | 可拾取 |
| 诗集 | (−34, 12) | 可拾取 |
| 花瓶 | (−33, 8) | 可拾取 |

**测试步骤**：
1. [ ] 导航箭头指向(−35, 15)
2. [ ] 靠近林黛玉，确认交互提示
3. [ ] 按E触发，确认5句对话依次显示
4. [ ] 确认林黛玉台词"这竹子虽好，却也孤单"准确
5. [ ] 对话结束，`visited_xiaoxiang == true`
6. [ ] 导航切换到"去怡红院见贾宝玉"
7. [ ] 测试可拾取物品：走近古琴/诗集/花瓶，按E拾取

---

### 动线 10：游怡红院（贾宝玉）⭐

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (35, 15)，NPC交互 |
| **触发条件** | `visited_xiaoxiang == true`（导航条件）；区域 `yihong_yuan` 已解锁 |
| **对话ID** | `visit_yihong` |
| **对话链** | `visit_yihong` → `visit_yihong_2` → `visit_yihong_3` → `visit_yihong_4`（4句） |
| **说话人** | 旁白 → 刘姥姥 → 贾宝玉 → 刘姥姥 |
| **事件触发** | `visit_yihong_complete` → `conditions["visited_yihong"] = true` |

**可交互物品**：
| 物品 | 位置 | 效果 |
|------|------|------|
| 画卷 | (36, 13) | 可拾取 |

**测试步骤**：
1. [ ] 从潇湘馆方向向右走，导航箭头指向(35, 15)
2. [ ] 靠近贾宝玉，确认交互提示
3. [ ] 按E触发，确认4句对话
4. [ ] 对话结束，`visited_yihong == true`
5. [ ] 导航切换到"去栊翠庵找妙玉品茶"

---

### 动线 11：栊翠庵品茶（妙玉）⭐

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, 57)，NPC交互 |
| **触发条件** | `visited_yihong == true`（导航条件）；区域 `longcui_an` 已解锁 |
| **对话ID** | `tea_ceremony` |
| **对话链** | `tea_ceremony` → `tea_ceremony_2` → `tea_ceremony_3` → `tea_ceremony_4`（4句） |
| **说话人** | 旁白 → 妙玉 → 刘姥姥 → 妙玉 |
| **事件触发** | `tea_ceremony_complete` + `collect_teacup` |

**⚠️ 关键bug验证点**：
| 事件ID | 正确效果 | 错误效果（已修复） |
|--------|---------|-------------------|
| `tea_ceremony_complete` | `conditions["completed_tea"] = true` | ~~`conditions["had_tea"]`~~（第二match块覆盖） |
| `collect_teacup` | `collected_items += "miaoyu_teacup"` | ~~`collected_items += "teacup"`~~（第二match块覆盖） |

**可交互物品**：
| 物品 | 位置 | 效果 |
|------|------|------|
| 茶具 | (2, 54) | 可拾取 |

**测试步骤**：
1. [ ] 导航箭头指向(0, 57)
2. [ ] 靠近妙玉，确认交互提示
3. [ ] 按E触发，确认4句对话
4. [ ] 确认妙玉送茶杯的台词准确
5. [ ] 对话结束，`completed_tea == true`（**注意：必须是 `completed_tea`，不是 `had_tea`**）
6. [ ] 确认 `collected_items` 包含 `"miaoyu_teacup"`（**不是 `"teacup"`**）
7. [ ] 导航切换到"回大观楼赴宴"

---

### 动线 12：赴宴 ⭐

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, 35)，BanquetTrigger |
| **触发条件** | `completed_tea == true`（`required_condition="completed_tea"`） |
| **对话ID** | `banquet` |
| **对话链** | `banquet` → `banquet_2` → `banquet_3` → `banquet_4` → `banquet_5`（5句） |
| **说话人** | 旁白 → 王熙凤 → 刘姥姥 → 贾母 → 刘姥姥 |
| **事件触发** | `banquet_complete` → `conditions["attended_banquet"] = true` |

**⚠️ 条件依赖验证**：
- BanquetTrigger 的 `required_condition = "completed_tea"`
- 如果栊翠庵事件错误设置为 `had_tea`（而非 `completed_tea`），此处**永远无法触发**

**测试步骤**：
1. [ ] 品茶结束后导航指向(0, 35)
2. [ ] 走到(0, 35)附近，确认对话自动触发（EventTrigger，非NPC交互）
3. [ ] 确认5句对话顺序正确
4. [ ] `attended_banquet == true`
5. [ ] 导航切换到"回到荣国府门外告别"

---

### 动线 13：告别 — 全剧终

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, −84)，FarewellTrigger |
| **触发条件** | `attended_banquet == true`（`required_condition="attended_banquet"`） |
| **对话ID** | `farewell` |
| **对话链** | `farewell` → `farewell_2` → `farewell_3` |
| **说话人** | 贾母 → 刘姥姥 → 旁白 |
| **旁白内容** | "刘姥姥千恩万谢，带着满车的礼物，离开了大观园……\n\n—— 全剧终 ——" |
| **事件触发** | `game_complete` → `conditions["game_completed"] = true` |
| **可见NPC** | EventTrigger自动推断 `visible_npc_name = "刘姥姥"` |

**测试步骤**：
1. [ ] 赴宴结束后，导航指引回到(0, −84)
2. [ ] 走到门外，确认对话自动触发
3. [ ] 确认3句对话，最后一句包含"全剧终"
4. [ ] `game_completed == true`
5. [ ] 导航箭头全部消失（所有阶段完成）

---

## 三、支线动线测试

### 支线 A：路径氛围 — 大观园门（PathGateTrigger）

| 项目 | 预期值 |
|------|--------|
| **触发位置** | (0, −62) |
| **对话ID** | `path_gate` → `path_gate_2` |
| **事件** | `path_gate_seen` → 设置 `path_gate_seen = true` |
| **前提** | 无条件限制，但 `trigger_once=true` |

---

### 支线 B：NPC直接对话 — 李纨

| 项目 | 预期值 |
|------|--------|
| **NPC位置** | (−25, −10) |
| **dialog_id** | `visit_daoxiang` |
| **⚠️ 问题** | `DialogData.dialogs` 中**无 `visit_daoxiang` 条目**！触发会产生 `push_warning` 并跳过 |

---

### 支线 C：NPC直接对话 — 薛宝钗

| 项目 | 预期值 |
|------|--------|
| **NPC位置** | (25, −10) |
| **dialog_id** | `visit_hengwu` |
| **⚠️ 问题** | `DialogData.dialogs` 中**无 `visit_hengwu` 条目**！触发会产生 `push_warning` 并跳过 |

---

### 支线 D：物品拾取系统

| 物品 | 位置 | 可拾取 | item_id | 测试点 |
|------|------|--------|---------|--------|
| 石碑 | (6, −38) | 否 | 无 | 按E查看描述弹窗 |
| 花瓶 | (−33, 8) | 是 | 有 | 按E拾取，物品消失，`collected_items` 更新 |
| 古琴 | (−36, 13) | 是 | 有 | 同上 |
| 诗集 | (−34, 12) | 是 | 有 | 同上 |
| 茶具 | (2, 42) | 是 | 有 | 同上 |
| 画卷 | (36, 13) | 是 | 有 | 同上 |

**测试步骤**：
1. [ ] 逐个接近物品，确认 `hint_radius=3` 范围内显示"按 E 拾取/查看"
2. [ ] 确认标签有脉冲闪烁动画
3. [ ] 拾取后物品从场景移除
4. [ ] 重复走回已拾取位置，确认物品不再出现

---

### 支线 E：匾额与立牌系统

**匾额**（5处）：潇湘馆、怡红院、秋爽斋、蘅芜苑、稻香村
**立牌**（8处NPC旁）：接近时弹出剧情面板

**测试步骤**：
1. [ ] 走近每个匾额，确认黑底金字3D匾额可见
2. [ ] 走近每个立牌，确认木质解说立牌出现
3. [ ] 接近立牌时弹出宣纸红木面板，含头像和故事背景

---

### 支线 F：场景氛围系统

| 功能 | 预期 |
|------|------|
| 蝴蝶 | 3只螺旋飞行+翅膀扇动 |
| 飘叶 | 8片飘落树叶 |
| 鸟鸣 | 8-16秒间隔播放 |
| 锦鲤 | 12-27秒间隔跳跃（含粒子水花） |
| 环境音 | 庭院循环（风声鸟鸣）+ 水系循环（溪流垂柳） |

---

## 四、条件依赖矩阵

下表验证每条动线的前置条件是否与前序动线的输出一致：

| 动线 | 触发所需条件 | 来源动线 | 来源事件 | 是否一致 |
|------|-------------|---------|---------|---------|
| 1. 入场 | 无 | — | — | ✅ |
| 2. 照壁 | `intro_done` | 动线1 | `intro_complete` | ✅ |
| 7. 拜贾母 | `intro_done` | 动线1 | `intro_complete` | ✅ |
| 8. 见凤姐 | `met_jiamu` | 动线7 | `meet_jiamu_complete` | ✅ |
| 9. 潇湘馆 | `met_xifeng` | 动线8 | `meet_xifeng_complete` | ✅ |
| 10. 怡红院 | `visited_xiaoxiang` | 动线9 | `visit_xiaoxiang_complete` | ✅ |
| 11. 栊翠庵 | `visited_yihong` | 动线10 | `visit_yihong_complete` | ✅ |
| 12. 赴宴 | `completed_tea` | 动线11 | `tea_ceremony_complete` | ⚠️ 需修复 |
| 13. 告别 | `attended_banquet` | 动线12 | `banquet_complete` | ✅ |
| BanquetTrigger | `completed_tea` | 动线11 | `tea_ceremony_complete` | ⚠️ 需修复 |

---

## 五、发现的代码BUG清单

### BUG-1：`_execute_event()` 存在重复match块（严重）

**文件**：`scripts/dialog/dialog_manager.gd`
**问题**：`_execute_event()` 函数中存在两个几乎相同的 `match event_id` 块。第二块覆盖第一块的值：
- `tea_ceremony_complete` 第一块设置 `completed_tea`，第二块覆盖为 `had_tea`
- `collect_teacup` 第一块收集 `miaoyu_teacup`，第二块覆盖为 `teacup`
- `banquet_complete` 第二块额外添加 `unlock_area("farewell")`
**影响**：导航系统检查 `completed_tea` 但实际被设为 `had_tea`，导致赴宴动线**永远无法触发**。

### BUG-2：`EventBus.trigger_event()` 被调用3次（中等）

**文件**：`scripts/dialog/dialog_manager.gd`
**问题**：`_execute_event()` 函数顶部调用一次，两个 match 块之后又各调用一次。事件信号被触发3次。
**影响**：`event_triggered` 信号的监听者会被执行3次，可能造成UI闪烁、重复动画等。

### BUG-3：`scripts/systems/dialog_data.gd` 与主版本冲突（中等）

**问题**：两份 `DialogData` 脚本使用相同的 `class_name DialogData`，Godot 只加载一份。两份文件的对话ID、对话内容、事件名完全不同。
**影响**：如果系统版本被加载，所有触发区域的 `dialog_id` 都找不到（如 `intro_arrival_2`、`meet_jiamu_2a` 等）。

### BUG-4：NPC对话无防重复机制（轻微）

**文件**：`scripts/npcs/npc_base.gd`
**问题**：`interact()` 没有检查 `dialog_history` 或 `completed_events`，玩家可以反复与同一NPC对话。
**影响**：同一段对话可以被反复触发，TTS语音重复播放。

### BUG-5：李纨和薛宝钗的dialog_id缺失（轻微）

**文件**：`scenes/world/npcs.tscn` vs `scripts/dialog/dialog_data.gd`
**问题**：NPC场景中李纨的 `dialog_id = "visit_daoxiang"`、薛宝钗的 `dialog_id = "visit_hengwu"`，但 `DialogData.dialogs` 中无这两个条目。
**影响**：与这两个NPC交互只产生 `push_warning`，无对话显示。

---

## 六、音频系统验证

### TTS语音映射表

| 角色 | TTS音色 | 出现动线 |
|------|---------|---------|
| 旁白 | narrator | 1, 5, 9, 10, 11, 12, 13 |
| 刘姥姥 | liulaolao | 1, 5, 7, 8, 9, 10, 11, 12, 13 |
| 周瑞家 | zhourui | 1 |
| 贾母 | jiamu | 7, 12, 13 |
| 王熙凤 | xifeng | 7, 8, 12 |
| 林黛玉 | lindaiyu | 9 |
| 贾宝玉 | jiabaoyu | 10 |
| 妙玉 | miaoyu | 11 |

### BGM切换验证

| 场景 | 预期BGM |
|------|---------|
| 全局 | `daguan_global_loop.ogg`（默认禁用） |
| 潇湘馆内 | `xiaoxiang_ambience.ogg` |
| 稻香村内 | `daoxiang_ambience.ogg` |
| 离开建筑 | 恢复全局BGM |

---

## 七、完整通关流程速查表

| 步骤 | 位置 | 触发方式 | 对话ID | 关键事件 | 状态变化 |
|------|------|---------|--------|---------|---------|
| 1 | (0,−84) | 自动 | intro_arrival | intro_complete | intro_done=true |
| 2 | (−8.8,−58) | 路点 | — | — | — |
| 3 | (0,−38) | 路点 | — | — | — |
| 4 | (0,−62) | 触发区 | path_gate | path_gate_seen | path_gate_seen=true |
| 5 | (0,−10) | 触发区 | path_garden | path_complete | path_done=true |
| 6 | (0,−2) | 路点 | — | — | — |
| 7 | (0,35) | 触发区 | meet_jiamu | meet_jiamu_complete + 3个unlock | met_jiamu=true, 解锁3区域 |
| 8 | (3,20) | NPC交互 | meet_xifeng | meet_xifeng_complete | met_xifeng=true |
| 9 | (−35,15) | NPC交互 | visit_xiaoxiang | visit_xiaoxiang_complete | visited_xiaoxiang=true |
| 10 | (35,15) | NPC交互 | visit_yihong | visit_yihong_complete | visited_yihong=true |
| 11 | (0,57) | NPC交互 | tea_ceremony | tea_ceremony_complete + collect_teacup | completed_tea=true |
| 12 | (0,35) | 触发区 | banquet | banquet_complete | attended_banquet=true |
| 13 | (0,−84) | 触发区 | farewell | game_complete | game_completed=true |

---

## 八、测试执行检查清单

### 新游戏全流程（正向）

- [ ] 步骤1-13依次完成，无卡死、无跳过
- [ ] 每步对话内容与原著风格一致
- [ ] 每步TTS语音正常播放
- [ ] 导航箭头始终指引下一目标
- [ ] 选择分支（贾母对话）两条路径均可通过
- [ ] 所有可拾取物品可正常拾取
- [ ] 全剧终后导航箭头全部消失

### 防重复测试

- [ ] 回到每个触发区位置，确认不重复触发
- [ ] 与每个NPC多次交互，确认对话可重复（当前设计）或不重复（修复后）

### 存档读档测试

- [ ] 在动线9（潇湘馆）中间存档
- [ ] 读档后确认 `conditions`、`unlocked_areas`、`collected_items` 恢复正确
- [ ] 读档后导航箭头指向正确的下一阶段

### 边界情况

- [ ] 对话中按ESC暂停，确认暂停菜单正常
- [ ] 对话中鼠标可见，不受捕获
- [ ] 对话结束后鼠标恢复捕获
- [ ] 快速连按E不会跳过多句对话（打字机效果保护）
