class_name DialogData

# 对话数据 - 大观园剧情对话
static var dialogs: Dictionary = {
	"intro_arrival": {
		"speaker": "旁白",
		"text": "刘姥姥带着板儿，跟着荣国府仆妇周瑞家，一路来到荣国府门外。门前车马往来，两侧门房高墙相连，里头还隔着层层院门。",
		"next": "intro_arrival_2"
	},
	"intro_arrival_2": {
		"speaker": "刘姥姥",
		"text": "哎呦喂！还没进门呢，就这门楼墙院，已经比我们村祠堂气派多了！",
		"next": "intro_arrival_3"
	},
	"intro_arrival_3": {
		"speaker": "周瑞家",
		"text": "姥姥莫要大惊小怪，里面好看的还多着呢。随我来吧。",
		"events": ["intro_complete"]
	},
	# === 路径氛围对话 ===
	"path_gate": {
		"speaker": "旁白",
		"text": "穿过荣府前院，眼前才是大观园门。白墙夹道，石柱撑起门楼，门廊下悬着两盏大红灯笼，门前石狮威风凛凛。",
		"next": "path_gate_2"
	},
	"path_gate_2": {
		"speaker": "刘姥姥",
		"text": "哎呦，这门口的石狮子可真威武！比我们村土地庙的还大好几倍！",
		"events": ["path_gate_seen"]
	},
	"path_garden": {
		"speaker": "旁白",
		"text": "穿过石牌坊，眼前豁然开朗——一条朱红廊柱、青瓦覆顶的抄手游廊横亘眼前，廊下石径笔直通幽。东望远处修竹掩映白墙，西边池水粼粼，荷叶田田铺展水面，几尾锦鲤在荷影间悠然穿行。",
		"next": "path_garden_2"
	},
	"path_garden_2": {
		"speaker": "刘姥姥",
		"text": "这鱼可真肥！比我们塘里的大十倍都不止！哎，这竹子绿得跟翡翠似的！",
		"events": ["path_complete"]
	},
	"meet_jiamu": {
		"speaker": "贾母",
		"text": "这位便是刘姥姥吧？快请坐。",
		"choices": [
			{"text": "（拘谨地行礼）给老太太请安了。", "next": "meet_jiamu_2a"},
			{"text": "（四处张望）哎呦，这屋子真气派！", "next": "meet_jiamu_2b"}
		]
	},
	"meet_jiamu_2a": {
		"speaker": "刘姥姥",
		"text": "给老太太请安了。我们乡下人，没见过世面，还望老太太莫怪。",
		"next": "meet_jiamu_3"
	},
	"meet_jiamu_2b": {
		"speaker": "刘姥姥",
		"text": "哎呦！这屋子可真敞亮！那柱子都比我们家房子粗！",
		"next": "meet_jiamu_3"
	},
	"meet_jiamu_3": {
		"speaker": "贾母",
		"text": "姥姥不必客气。今日就在这园子里好生逛逛，有什么好看的只管说。",
		"next": "meet_jiamu_4"
	},
	"meet_jiamu_4": {
		"speaker": "王熙凤",
		"text": "老太太，不如让姥姥先在园子里转转，回头再来陪您说话。",
		"events": ["meet_jiamu_complete", "unlock_xiaoxiang", "unlock_yihong", "unlock_longcui"]
	},
	"meet_xifeng": {
		"speaker": "王熙凤",
		"text": "姥姥，我是琏二奶奶。这园子里的事儿，有什么不懂的尽管问我。",
		"next": "meet_xifeng_2"
	},
	"meet_xifeng_2": {
		"speaker": "刘姥姥",
		"text": "哎呦！这奶奶可真标致！说话又爽利，跟我们村里的媒婆似的！",
		"next": "meet_xifeng_3"
	},
	"meet_xifeng_3": {
		"speaker": "王熙凤",
		"text": "（噗嗤一笑）姥姥真会说话！来，我领您去潇湘馆看看，那可是林姑娘住的地方。",
		"events": ["meet_xifeng_complete"]
	},
	"visit_xiaoxiang": {
		"speaker": "旁白",
		"text": "潇湘馆内翠竹掩映，清幽雅致。林黛玉正倚在窗前看书。",
		"next": "visit_xiaoxiang_2"
	},
	"visit_xiaoxiang_2": {
		"speaker": "刘姥姥",
		"text": "这姑娘长得可真俊！跟画儿里的人似的！",
		"next": "visit_xiaoxiang_3"
	},
	"visit_xiaoxiang_3": {
		"speaker": "林黛玉",
		"text": "姥姥过奖了。请坐，紫鹃，倒茶来。",
		"next": "visit_xiaoxiang_4"
	},
	"visit_xiaoxiang_4": {
		"speaker": "刘姥姥",
		"text": "这满院子的竹子，比我们村后山上的还密还绿呢！姑娘住在这儿，可真有福气。",
		"next": "visit_xiaoxiang_5"
	},
	"visit_xiaoxiang_5": {
		"speaker": "林黛玉",
		"text": "这竹子虽好，却也孤单。风一吹，满院都是潇潇之声，倒像是替人叹气呢。",
		"events": ["visit_xiaoxiang_complete"]
	},
	"visit_yihong": {
		"speaker": "旁白",
		"text": "怡红院里陈设华丽，到处是新奇玩意儿。贾宝玉正歪在榻上，和丫鬟们说笑。",
		"next": "visit_yihong_2"
	},
	"visit_yihong_2": {
		"speaker": "刘姥姥",
		"text": "哎呦！这公子哥儿的屋子，跟皇宫似的！这些个小玩意儿我见都没见过！",
		"next": "visit_yihong_3"
	},
	"visit_yihong_3": {
		"speaker": "贾宝玉",
		"text": "姥姥不必拘束，这些都是些俗物罢了。来，尝尝这个点心。",
		"next": "visit_yihong_4"
	},
	"visit_yihong_4": {
		"speaker": "刘姥姥",
		"text": "这点心做得跟花儿似的，我都不忍心吃了！",
		"events": ["visit_yihong_complete"]
	},
	"visit_daoxiang": {
		"speaker": "旁白",
		"text": "稻香村门前稻田青青，篱笆环绕，一派田园风光。李纨正坐在廊下做针线。",
		"next": "visit_daoxiang_2"
	},
	"visit_daoxiang_2": {
		"speaker": "刘姥姥",
		"text": "哎呦！这地方跟我们乡下似的，看着就亲切！这稻子长得可真好！",
		"next": "visit_daoxiang_3"
	},
	"visit_daoxiang_3": {
		"speaker": "李纨",
		"text": "姥姥请坐。这里虽简陋，倒也清净，正合我这寡居之人。",
		"next": "visit_daoxiang_4"
	},
	"visit_daoxiang_4": {
		"speaker": "刘姥姥",
		"text": "姑娘这话说的！这叫雅致，哪叫简陋呢！我们乡下要是有这一半好，我做梦都能笑醒！",
		"events": ["visit_daoxiang_complete"]
	},
	"visit_qiushuang": {
		"speaker": "旁白",
		"text": "秋爽斋内阔朗大方，窗明几净。院中梧桐亭亭，贾探春正伏案挥毫写字。",
		"next": "visit_qiushuang_2"
	},
	"visit_qiushuang_2": {
		"speaker": "刘姥姥",
		"text": "哟！这位姑娘的字写得可真有劲道！比我见过的那些秀才都强！",
		"next": "visit_qiushuang_3"
	},
	"visit_qiushuang_3": {
		"speaker": "贾探春",
		"text": "姥姥过奖了。我这儿虽不比别处奢华，倒也敞亮，正宜读书挥墨。姥姥快请进来坐。",
		"next": "visit_qiushuang_4"
	},
	"visit_qiushuang_4": {
		"speaker": "刘姥姥",
		"text": "这院子真叫一个豁亮！秋风一吹，满院子梧桐叶沙沙响，怪不得叫秋爽斋呢！",
		"events": ["visit_qiushuang_complete"]
	},
	"tea_ceremony": {
		"speaker": "旁白",
		"text": "栊翠庵中檀香袅袅，妙玉一身素衣，神态清冷。",
		"next": "tea_ceremony_2"
	},
	"tea_ceremony_2": {
		"speaker": "妙玉",
		"text": "这是旧年蠲的雨水，姥姥请尝尝。",
		"next": "tea_ceremony_3"
	},
	"tea_ceremony_3": {
		"speaker": "刘姥姥",
		"text": "好茶！好茶！这水都是甜的！",
		"next": "tea_ceremony_4"
	},
	"tea_ceremony_4": {
		"speaker": "妙玉",
		"text": "（微微蹙眉）姥姥若是喜欢，这只成窑杯便送与姥姥吧。",
		"events": ["tea_ceremony_complete", "collect_teacup"]
	},
	"banquet": {
		"speaker": "旁白",
		"text": "大观楼内张灯结彩，贾母设宴款待众人。刘姥姥被安排在末席。",
		"next": "banquet_2"
	},
	"banquet_2": {
		"speaker": "王熙凤",
		"text": "姥姥，今日这席上的菜，您可得每样都尝尝。",
		"next": "banquet_3"
	},
	"banquet_3": {
		"speaker": "刘姥姥",
		"text": "哎呦！这一桌子菜，够我们全村吃三天的了！",
		"next": "banquet_4"
	},
	"banquet_4": {
		"speaker": "贾母",
		"text": "姥姥说笑了。来人，给姥姥夹菜。",
		"next": "banquet_5"
	},
	"banquet_5": {
		"speaker": "刘姥姥",
		"text": "老太太大恩大德！我刘姥姥这辈子算是开了眼了！",
		"events": ["banquet_complete"]
	},
	"farewell": {
		"speaker": "贾母",
		"text": "姥姥今日受累了。这些东西带回去，给家里人尝尝。",
		"next": "farewell_2"
	},
	"farewell_2": {
		"speaker": "刘姥姥",
		"text": "老太太的恩情，我刘姥姥这辈子忘不了！",
		"next": "farewell_3"
	},
	"farewell_3": {
		"speaker": "旁白",
		"text": "刘姥姥千恩万谢，带着满车的礼物，离开了大观园。这一趟，她见了一辈子都没见过的富贵，也留下了最质朴的笑声。\n\n—— 全剧终 ——",
		"events": ["game_complete"]
	}
}
