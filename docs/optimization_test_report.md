# 大观园批量优化自动自测报告

- 生成时间: 2026-06-24T09:06:27
- 主场景: `res://main.tscn`
- 通过: 63
- 失败: 1

## 场景加载
- 通过: 主场景资源可加载。res://main.tscn
- 通过: 主场景可实例化。Main
- 通过: 玩家节点存在。保留玩家初始出生点
- 通过: Buildings 容器存在。保留现有院落容器
- 通过: NPCs 容器存在。立牌运行时挂载位置
- 通过: Systems 容器存在。运行时增强系统挂载位置

## 空间布局
- 通过: 闭合围墙运行时节点存在。白墙灰瓦外围
- 通过: 南侧正门存在。主入口可通行
- 通过: 北侧后门存在。府邸后门门楼
- 通过: 东侧侧门存在。府邸侧门门楼
- 通过: 东线防出界墙存在。玩家东线不应跑到场外
- 通过: XiaoxiangFrame 已生成。五院独立围合
- 通过: YihongFrame 已生成。五院独立围合
- 通过: QiushuangFrame 已生成。五院独立围合
- 通过: HengwuFrame 已生成。五院独立围合
- 通过: DaoxiangFrame 已生成。五院独立围合
- 通过: BluestoneRouteOverlay 已生成。园林细节优化
- 通过: PondRevetmentAndRails 已生成。园林细节优化
- 通过: GardenOrnaments 已生成。园林细节优化
- 通过: 荷塘通行桥已生成。修复荷塘路线断点

## 交互剧情
- 通过: 解说立牌数量不少于 8。当前数量: 8
- 通过: 立牌 UI 层存在。宣纸红木弹窗
- 通过: 头像控件存在。剧情头像显示
- 通过: 建筑讲解按钮存在。建筑触发后可 Hover 并点击查看讲解
- 通过: 立牌触发 Area3D 足够。含建筑入口与立牌触发区

## 资源归档
- 通过: avatar_jiamu.png 存在。res://assets/textures/ui/avatar_jiamu.png
- 通过: avatar_wangxifeng.png 存在。res://assets/textures/ui/avatar_wangxifeng.png
- 通过: avatar_lindaiyu.png 存在。res://assets/textures/ui/avatar_lindaiyu.png
- 通过: avatar_jiabaoyu.png 存在。res://assets/textures/ui/avatar_jiabaoyu.png
- 通过: avatar_qingwen.png 存在。res://assets/textures/ui/avatar_qingwen.png
- 通过: avatar_liulaolao.png 存在。res://assets/textures/ui/avatar_liulaolao.png
- 通过: avatar_xuebaochai.png 存在。res://assets/textures/ui/avatar_xuebaochai.png
- 通过: avatar_xiren.png 存在。res://assets/textures/ui/avatar_xiren.png
- 通过: 植被资源目录存在。Ultimate Nature Pack 归档
- 通过: 不存在硬引用音频缺失崩溃。音频流缺失时系统应降级

## 导航碰撞
- 通过: 荷塘桥面有碰撞。桥面与两端缓坡可承托玩家
- 通过: NavigationRegion3D 存在。保留原导航区域
- 通过: StaticBody3D 碰撞节点充足。围墙、院落、建筑碰撞
- 通过: CollisionShape3D 数量充足。碰撞体检查
- 通过: 玩家输入脚本仍挂载。保留玩家控制

## 性能光影
- 通过: 运行时加载耗时可接受。2819 ms
- 失败: MeshInstance3D 数量在预算内。当前数量: 3092
- 通过: 灯光数量在预算内。当前数量: 38
- 通过: SceneEnhancements 已挂载。光影与 LOD 增强
