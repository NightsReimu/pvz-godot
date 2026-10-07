extends RefCounted
const KIND:="sanae_boss"
const FRAME_FOLDER:="res://art/sanae"
const FRAME_COUNT:=24
const CANVAS:=Vector2i(512,384)
const PIVOT:=Vector2i(256,320)
const IDLE_HEIGHT:=231.0
const IDLE_BOTTOM:=321.0
const ACTIONS:={"idle":[0,1,2,1],"walk":[3,4,5,4],"arrival":[3,4,5,4],"shift":[3,4,5,4],"shot":[6,7,8,7],"sweep":[6,7,8,7],"stars":[9,10,11,10],"prayer":[9,10,11,10],"frog":[15,16,17,16],"wind":[15,16,17,16],"phase":[15,16,17,23],"final":[18,19,20,19],"hit":[12,13,14],"defeat":[21,22]}
static func frame_index(boss:Dictionary,time:float)->int:
	var state:String=String(boss.get("sanae_pose",boss.get("rumia_state","idle")))
	if float(boss.get("health",1.0))<=0.0:state="defeat"
	elif float(boss.get("impact_timer",0.0))>0.0:state="hit"
	var frames:Array=ACTIONS.get(state,ACTIONS.idle)
	return int(frames[maxi(0,int(time*(3.0 if state=="idle" else 7.0)+float(boss.get("anim_phase",0.0))*frames.size()))%frames.size()])
