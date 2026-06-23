# 音频资源目录说明

## bgm/ — 背景音乐
按院落放置对应BGM文件（.ogg格式）：
- daguan_global_loop.ogg — 大观园全园常驻主BGM（默认循环）
- xiaoxiang_ambience.ogg — 潇湘馆（清幽竹笛）
- yihong_ambience.ogg — 怡红院（华丽丝竹）
- longcui_ambience.ogg — 栊翠庵（禅意木鱼）
- daguan_ambience.ogg — 大观楼（宫廷雅乐）
- daoxiang_ambience.ogg — 稻香村（田园牧歌）
- hengwu_ambience.ogg — 蘅芜苑（幽兰清香）
- qiushuang_ambience.ogg — 秋爽斋（秋风高远）
- zhuijin_ambience.ogg — 缀锦阁（锦绣繁华）

## sfx/ — 音效
- footstep_grass.ogg — 草地脚步
- footstep_stone.ogg — 石板脚步
- gate_wood_open.ogg — 大观园正门开门声
- door_open.ogg — 开门声（旧占位，可由 gate_wood_open.ogg 替代）
- water_splash.ogg — 水花声
- bell_ring.ogg — 铃铛声

## ambient/ — 环境音（循环播放）
- courtyard_garden_loop.ogg — 通用庭院微风、树叶、远鸟
- water_garden_loop.ogg — 水系溪流、垂柳、远鸟
- wind_gentle.ogg — 庭院微风
- birds_forest.ogg — 林间鸟鸣
- water_stream.ogg — 池塘流水
- bamboo_rustle.ogg — 竹林沙沙声

## DashScope fun-music-v1 生成
生成清单在 `assets/audio/fun_music_manifest.json`，脚本在 `tools/generate_fun_music.py`。DashScope 的 key 和接口地址填在 `assets/config/dashscope_music_config.json`，这个真实配置文件已加入 `.gitignore`，不会提交。Fun-Music 使用 SSE 接口：`https://dashscope.aliyuncs.com/api/v1/services/audio/music/generation`。

PowerShell 示例：
```powershell
python tools/generate_fun_music.py
```

只生成单个资源：
```powershell
python tools/generate_fun_music.py --only daguan_global_loop
```

运行时混音策略：`AudioSystem` 只保留一路 BGM 播放器，默认播放全园主 BGM；进入潇湘馆或稻香村时淡出主 BGM 并切到专属 BGM，离开后恢复主 BGM。庭院和水系环境音使用低音量独立循环层，不参与主旋律，避免多个 BGM 同时播放。正门开门声作为一次性 SFX 播放。
