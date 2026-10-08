extends RefCounted
const KIND:="kanako_boss"
const FRAME_FOLDER:="res://art/kanako"
const FRAME_COUNT:=24
const CANVAS:=Vector2i(512,384)
const PIVOT:=Vector2i(256,320)
const IDLE_HEIGHT:=239.0
const IDLE_BOTTOM:=320.0
# Reviewed supplied slots: 00-05 idle/drift with the mirror held, 06-08 the
# pointed red arrow, 09-11 the mirror ring, 12-13 raised mirror, 14-17 the red
# wind aura, 18 collapse, 19 eyes-shut recoil, 20-21 summoned crystals and
# 22-23 the battle-torn divine form. Hit and collapse never enter a spell cycle.
const ACTIONS:={"idle":[0,1,2,1],"walk":[3,4,5,4],"arrival":[3,4,5,4],"shift":[3,4,5,4],"shot":[6,7,8,7],"arrow":[6,7,8,7],"mirror":[9,10,11,10],"seal":[9,10,11,10],"channel":[12,13,12,13],"prayer":[12,13,12,13],"wind":[14,15,16,17],"storm":[14,15,16,17],"crystal":[20,21,20,21],"pillar":[20,21,20,21],"final":[22,23,22,23],"phase":[14,15,16,17,22],"hit":[19],"defeat":[22,18]}
static func frame_index(boss:Dictionary,time:float)->int:
	var state:String=String(boss.get("kanako_pose",boss.get("rumia_state","idle")))
	if float(boss.get("health",1.0))<=0.0:state="defeat"
	elif float(boss.get("impact_timer",0.0))>0.0:state="hit"
	var frames:Array=ACTIONS.get(state,ACTIONS.idle)
	return int(frames[maxi(0,int(time*(3.0 if state=="idle" else 7.0)+float(boss.get("anim_phase",0.0))*frames.size()))%frames.size()])
