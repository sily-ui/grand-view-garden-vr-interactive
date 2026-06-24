"""
批量生成《刘姥姥进大观园》所有台词语音
使用 mimo-v2.5-tts 模型
"""
import json
import os
import re
import time
import base64
import requests
from pathlib import Path

API_BASE = "https://token-plan-cn.xiaomimimo.com/v1/chat/completions"
API_KEY = "tp-ct3pneq2dgy6lf7khqb8ruyxvtkhyw1g4jn3z3t26v5ab4qg"
MODEL = "mimo-v2.5-tts"

OUTPUT_DIR = Path(r"d:\project_godot\assets\audio\voice")

# 角色 → voice key 映射
SPEAKER_VOICE_MAP = {
    "旁白": "narrator",
    "刘姥姥": "liulaolao",
    "贾母": "jiamu",
    "王熙凤": "xifeng",
    "林黛玉": "daiyu",
    "贾宝玉": "baoyu",
    "妙玉": "miaoyu",
    "周瑞家": "zhou",
}

# 语音风格
SPEECH_STYLES = {
    "旁白": "成熟男性纪录片讲解员，语速稳，情绪克制，声音厚度中等，不能像任何女性角色。",
    "刘姥姥": "表演成刘姥姥：乡下老太太进豪门开眼界，惊奇、热络、嘴快，句首句尾带笑意和上扬惊叹，不能沉稳端庄。",
    "贾母": "表演成贾母：女性老祖母声线，低柔、慈爱、雍容、慢速，带轻微年迈气息；不要男中音，不要纪录片旁白腔，不要乡土口音。",
    "王熙凤": "表演成王熙凤：年轻女性，明亮爽利、精明干练，语气带笑但有管家人的利落劲儿；不要旁白男声。",
    "林黛玉": "表演成林黛玉：年轻女性，声音清冷柔弱，带一丝幽怨和才气，语速偏慢，像在低吟诗词。",
    "贾宝玉": "表演成贾宝玉：少年公子，温和随意，带点玩世不恭和天真，语气亲切不端着。",
    "妙玉": "表演成妙玉：出家女子，清冷淡漠，语气疏离有距离感，声音干净利落不拖沓。",
    "周瑞家": "表演成周瑞家的：中年仆妇，干练低眉，语气恭敬但不卑微，有办事老练的利索劲儿。",
}

SPEED_MAP = {
    "旁白": 1.05,
    "刘姥姥": 1.2,
    "贾母": 1.0,
    "王熙凤": 1.15,
    "林黛玉": 1.02,
    "贾宝玉": 1.1,
    "妙玉": 0.98,
    "周瑞家": 1.1,
}

# 全部台词 (dialog_id, speaker, text)
DIALOG_LINES = [
    ("intro_arrival", "旁白", "刘姥姥带着板儿，跟着荣国府仆妇周瑞家，一路来到荣国府门外。门前车马往来，两侧门房高墙相连，里头还隔着层层院门。"),
    ("intro_arrival_2", "刘姥姥", "哎呦喂！还没进门呢，就这门楼墙院，已经比我们村祠堂气派多了！"),
    ("intro_arrival_3", "周瑞家", "姥姥莫要大惊小怪，里面好看的还多着呢。随我来吧。"),
    ("path_gate", "旁白", "穿过荣府前院，眼前才是大观园门。白墙夹道，石柱撑起门楼，门廊下悬着两盏大红灯笼，门前石狮威风凛凛。"),
    ("path_gate_2", "刘姥姥", "哎呦，这门口的石狮子可真威武！比我们村土地庙的还大好几倍！"),
    ("path_garden", "旁白", "穿过石牌坊，眼前豁然开朗——一条朱红廊柱、青瓦覆顶的抄手游廊横亘眼前，廊下石径笔直通幽。东望远处修竹掩映白墙，西边池水粼粼，荷叶田田铺展水面，几尾锦鲤在荷影间悠然穿行。"),
    ("path_garden_2", "刘姥姥", "这鱼可真肥！比我们塘里的大十倍都不止！哎，这竹子绿得跟翡翠似的！"),
    ("meet_jiamu", "贾母", "这位便是刘姥姥吧？快请坐。"),
    ("meet_jiamu_2a", "刘姥姥", "给老太太请安了。我们乡下人，没见过世面，还望老太太莫怪。"),
    ("meet_jiamu_2b", "刘姥姥", "哎呦！这屋子可真敞亮！那柱子都比我们家房子粗！"),
    ("meet_jiamu_3", "贾母", "姥姥不必客气。今日就在这园子里好生逛逛，有什么好看的只管说。"),
    ("meet_jiamu_4", "王熙凤", "老太太，不如让姥姥先在园子里转转，回头再来陪您说话。"),
    ("meet_xifeng", "王熙凤", "姥姥，我是琏二奶奶。这园子里的事儿，有什么不懂的尽管问我。"),
    ("meet_xifeng_2", "刘姥姥", "哎呦！这奶奶可真标致！说话又爽利，跟我们村里的媒婆似的！"),
    ("meet_xifeng_3", "王熙凤", "姥姥真会说话！来，我领您去潇湘馆看看，那可是林姑娘住的地方。"),
    ("visit_xiaoxiang", "旁白", "潇湘馆内翠竹掩映，清幽雅致。林黛玉正倚在窗前看书。"),
    ("visit_xiaoxiang_2", "刘姥姥", "这姑娘长得可真俊！跟画儿里的人似的！"),
    ("visit_xiaoxiang_3", "林黛玉", "姥姥过奖了。请坐，紫鹃，倒茶来。"),
    ("visit_xiaoxiang_4", "刘姥姥", "这满院子的竹子，比我们村后山上的还密还绿呢！姑娘住在这儿，可真有福气。"),
    ("visit_xiaoxiang_5", "林黛玉", "这竹子虽好，却也孤单。风一吹，满院都是潇潇之声，倒像是替人叹气呢。"),
    ("visit_yihong", "旁白", "怡红院里陈设华丽，到处是新奇玩意儿。贾宝玉正歪在榻上，和丫鬟们说笑。"),
    ("visit_yihong_2", "刘姥姥", "哎呦！这公子哥儿的屋子，跟皇宫似的！这些个小玩意儿我见都没见过！"),
    ("visit_yihong_3", "贾宝玉", "姥姥不必拘束，这些都是些俗物罢了。来，尝尝这个点心。"),
    ("visit_yihong_4", "刘姥姥", "这点心做得跟花儿似的，我都不忍心吃了！"),
    ("tea_ceremony", "旁白", "栊翠庵中檀香袅袅，妙玉一身素衣，神态清冷。"),
    ("tea_ceremony_2", "妙玉", "这是旧年蠲的雨水，姥姥请尝尝。"),
    ("tea_ceremony_3", "刘姥姥", "好茶！好茶！这水都是甜的！"),
    ("tea_ceremony_4", "妙玉", "姥姥若是喜欢，这只成窑杯便送与姥姥吧。"),
    ("banquet", "旁白", "大观楼内张灯结彩，贾母设宴款待众人。刘姥姥被安排在末席。"),
    ("banquet_2", "王熙凤", "姥姥，今日这席上的菜，您可得每样都尝尝。"),
    ("banquet_3", "刘姥姥", "哎呦！这一桌子菜，够我们全村吃三天的了！"),
    ("banquet_4", "贾母", "姥姥说笑了。来人，给姥姥夹菜。"),
    ("banquet_5", "刘姥姥", "老太太大恩大德！我刘姥姥这辈子算是开了眼了！"),
    ("farewell", "贾母", "姥姥今日受累了。这些东西带回去，给家里人尝尝。"),
    ("farewell_2", "刘姥姥", "老太太的恩情，我刘姥姥这辈子忘不了！"),
    ("farewell_3", "旁白", "刘姥姥千恩万谢，带着满车的礼物，离开了大观园。这一趟，她见了一辈子都没见过的富贵，也留下了最质朴的笑声。"),
]


def clean_text(text: str) -> str:
    """去掉括号动作描述"""
    cleaned = re.sub(r'[（\(][^）\)]*[）\)]', '', text)
    cleaned = cleaned.replace('……', '。').replace('…', '。').replace('\n', ' ')
    return cleaned.strip()


def generate_voice(speaker: str, text: str, output_path: Path) -> bool:
    """调用 mimo TTS API 生成一条语音"""
    clean = clean_text(text)
    if not clean:
        return False

    style = SPEECH_STYLES.get(speaker, "")
    speed = SPEED_MAP.get(speaker, 1.0)

    user_prompt = "请用语音朗读以下内容"
    if style:
        user_prompt += f"。本句说话人是{speaker}，务必遵守声线和表演要求：{style}"

    payload = {
        "model": MODEL,
        "messages": [
            {"role": "user", "content": user_prompt},
            {"role": "assistant", "content": clean},
        ],
        "speed": speed,
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
    }

    try:
        resp = requests.post(API_BASE, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        data = resp.json()

        choices = data.get("choices", [])
        if not choices:
            print(f"  [FAIL] 无 choices: {speaker} - {clean[:20]}")
            return False

        audio_data = choices[0].get("message", {}).get("audio", {})
        b64 = audio_data.get("data", "")
        if not b64:
            print(f"  [FAIL] 无音频数据: {speaker} - {clean[:20]}")
            return False

        wav_bytes = base64.b64decode(b64)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "wb") as f:
            f.write(wav_bytes)

        print(f"  [OK] {output_path.name} ({len(wav_bytes)} bytes)")
        return True

    except Exception as e:
        print(f"  [ERR] {speaker} - {clean[:20]}... => {e}")
        return False


def main():
    print(f"=== 批量生成语音 ===")
    print(f"输出目录: {OUTPUT_DIR}")
    print(f"总台词数: {len(DIALOG_LINES)}")
    print()

    ok_count = 0
    fail_count = 0

    for i, (dialog_id, speaker, text) in enumerate(DIALOG_LINES):
        clean = clean_text(text)
        if not clean:
            continue

        voice_key = SPEAKER_VOICE_MAP.get(speaker, "narrator")
        filename = f"{dialog_id}.wav"
        output_path = OUTPUT_DIR / voice_key / filename

        if output_path.exists():
            print(f"  [SKIP] {output_path.relative_to(OUTPUT_DIR.parent.parent)} 已存在")
            ok_count += 1
            continue

        print(f"[{i+1}/{len(DIALOG_LINES)}] {speaker}: {clean[:30]}...")
        success = generate_voice(speaker, text, output_path)
        if success:
            ok_count += 1
        else:
            fail_count += 1

        # 限速，避免 API 限流
        time.sleep(0.5)

    print()
    print(f"=== 完成 ===")
    print(f"成功: {ok_count}, 失败: {fail_count}")


if __name__ == "__main__":
    main()
