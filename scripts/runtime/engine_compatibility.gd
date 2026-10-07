extends RefCounted
# Godot#117725 fixes stale polygon batches at exact GLES buffer capacity.
static func supported(v:Dictionary)->bool:
	return int(v.get("major",0))>4 or (int(v.get("major",0))==4 and (int(v.get("minor",0))>6 or (int(v.get("minor",0))==6 and int(v.get("patch",0))>=3)))
static func explanation(v:Dictionary)->String:
	return "当前引擎 %s 存在已确认的绘图崩溃。\n请使用 Godot 4.6.3 或更新版本启动。\n本地可运行 scripts/tools/launch_game.py；发行安装包已自带修复。"%String(v.get("string","未知版本"))
