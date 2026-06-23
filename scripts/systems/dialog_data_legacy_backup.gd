class_name DialogDataLegacy
# 对话数据定义 - 刘姥姥进大观园剧情对话（旧版备份，不参与运行）
# 主版本位于 scripts/dialog/dialog_data.gd
# 本文件因 class_name 冲突已重命名，保留供参考

static var dialogs: Dictionary = {
	"intro_arrival": {
		"speaker": "旁白",
		"text": "刘姥姥带着板儿，一路打听着来到了荣国府。只见门前两只大石狮子，三间兽头大门，门前坐着十来个华冠丽服之人。",
		"next": "intro_2"
	},
	"intro_2": {
		"speaker": "刘姥姥",
		"text": "哎呦喂，这门面可真够气派的！咱们乡下人哪里见过这样的排场。",
		"next": "intro_3"
	},
	"intro_3": {
		"speaker": "旁白",
		"text": "刘姥姥战战兢兢地进了大门，只见两边厢房雕梁画栋，院中假山流水，花木扶疏，真是一派富贵气象。",
		"events": ["intro_arrival"],
		"next": null
	},
	"jiamu_greeting": {
		"speaker": "贾母",
		"text": "这位便是刘姥姥吧？快请坐，不必拘礼。",
		"choices": [
			{"text": "（拘谨地行礼）给老太太请安了。", "next": "jiamu_greeting_2"},
			{"text": "（四处张望）哎呦，这屋子可真气派！", "next": "jiamu_surprised"}
		]
	},
	"jiamu_greeting_2": {
		"speaker": "刘姥姥",
		"text": "给老太太请安了。我们乡下人，没见过世面，还望老太太莫怪。",
		"next": "jiamu_kind"
	},
	"jiamu_surprised": {
		"speaker": "刘姥姥",
		"text": "哎呦，这屋子可真气派！我们乡下人做梦也梦不到这样的好地方。",
		"next": "jiamu_kind"
	},
	"jiamu_kind": {
		"speaker": "贾母",
		"text": "姥姥不必多礼，今日难得来一回，就让凤丫头领着你到处逛逛，看看我们这园子。",
		"events": ["meet_jiamu"],
		"next": null
	},
	"xifeng_intro": {
		"speaker": "王熙凤",
		"text": "姥姥，跟我来吧，这大观园里的景致可多着呢！保准让您大开眼界。",
		"next": null
	},
	"daiyu_meet": {
		"speaker": "林黛玉",
		"text": "这位姥姥好，我是黛玉。这潇湘馆是我住的地方，园中竹子最多，倒是清静。",
		"choices": [
			{"text": "这竹子长得真好看，姑娘好福气。", "next": "daiyu_bamboo"},
			{"text": "姑娘一个人住这么大的院子，不闷得慌？", "next": "daiyu_lonely"}
		]
	},
	"daiyu_bamboo": {
		"speaker": "林黛玉",
		"text": "姥姥过奖了。这竹子虽好，却也清冷得很。正所谓'潇湘馆里竹千竿，翠影摇风月满栏'。",
		"events": ["visit_xiaoxiang"],
		"next": null
	},
	"daiyu_lonely": {
		"speaker": "林黛玉",
		"text": "姥姥说笑了。我素喜清静，有这些竹子作伴，倒也不觉得闷。",
		"events": ["visit_xiaoxiang"],
		"next": null
	},
	"baoyu_meet": {
		"speaker": "贾宝玉",
		"text": "姥姥来了？快请坐！袭人，倒茶来。姥姥，这怡红院是我的住处，可还看得过去？",
		"choices": [
			{"text": "公子这院子真阔气，老身开了眼了。", "next": "baoyu_humble"},
			{"text": "好俊的哥儿！这屋里摆设可真讲究。", "next": "baoyu_pleased"}
		]
	},
	"baoyu_humble": {
		"speaker": "贾宝玉",
		"text": "姥姥客气了。这些不过身外之物，倒是姥姥从乡下来，那田园风光才是真好呢。",
		"events": ["visit_yihong"],
		"next": null
	},
	"baoyu_pleased": {
		"speaker": "贾宝玉",
		"text": "姥姥过奖了。来来来，尝尝这新得的茶，是今年的碧螺春。",
		"events": ["visit_yihong"],
		"next": null
	},
	"miaoyu_tea": {
		"speaker": "妙玉",
		"text": "姥姥，请用茶。这是我用梅花上的雪水沏的老君眉，你且尝尝。",
		"choices": [
			{"text": "（接过来一饮而尽）好茶！就是淡了点。", "next": "miaoyu_plain"},
			{"text": "（细细品味）好精致的茶具，这茶也香得很。", "next": "miaoyu_refined"}
		]
	},
	"miaoyu_plain": {
		"speaker": "妙玉",
		"text": "（微微皱眉）姥姥竟是个大俗人，这茶岂是这样喝的。罢了，这杯子也脏了，不要了罢。",
		"events": ["tea_ceremony"],
		"next": null
	},
	"miaoyu_refined": {
		"speaker": "妙玉",
		"text": "姥姥倒是个雅人。这茶须得细细品，方能得其真味。这杯子便送给姥姥做个念想罢。",
		"events": ["tea_ceremony"],
		"next": null
	},
	"banquet_scene": {
		"speaker": "旁白",
		"text": "大观楼上摆开了宴席，贾母居中而坐，两旁是众姐妹。刘姥姥被安排在末座，只见满桌珍馐美味，令人目不暇接。",
		"next": "banquet_2"
	},
	"banquet_2": {
		"speaker": "刘姥姥",
		"text": "这一顿饭，够我们庄稼人吃一年的了！",
		"next": "banquet_3"
	},
	"banquet_3": {
		"speaker": "王熙凤",
		"text": "姥姥，这是茄鲞，您尝尝。",
		"next": "banquet_4"
	},
	"banquet_4": {
		"speaker": "刘姥姥",
		"text": "别哄我了，茄子跑出这个味儿来了，我们也不用种粮食，只种茄子了。",
		"events": ["banquet"],
		"next": null
	},
	"xichun_painting": {
		"speaker": "惜春",
		"text": "姥姥来看我画画？我正在画这园子的景致呢，姥姥觉得如何？",
		"next": "xichun_painting_2"
	},
	"xichun_painting_2": {
		"speaker": "刘姥姥",
		"text": "哎呦，姑娘好巧的手！这画上的花儿跟真的一样，老身可算开了眼了。",
		"events": ["painting"],
		"next": null
	},
	"farewell": {
		"speaker": "刘姥姥",
		"text": "老太太、太太们的恩情，老身这辈子也忘不了。今日见了这大观园，才知道什么叫富贵人家。",
		"next": "farewell_2"
	},
	"farewell_2": {
		"speaker": "贾母",
		"text": "姥姥常来走动，咱们园子里的东西，你挑几样带回去。",
		"next": "farewell_3"
	},
	"farewell_3": {
		"speaker": "旁白",
		"text": "刘姥姥千恩万谢地告辞了。这一日大观园之行，成了她一辈子也说不完的故事。",
		"events": ["farewell"],
		"next": null
	}
}
