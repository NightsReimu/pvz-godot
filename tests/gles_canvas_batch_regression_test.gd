extends SceneTree

# Native renderer regression for Godot#117725. Run with -- --render; a dummy
# headless canvas cannot verify GLES batch reclamation or the GPU object count.
class CapacityCanvas extends Node2D:
	var count:=49152
	func _draw()->void:
		var polygon:=PackedVector2Array([Vector2(0,0),Vector2(2,0),Vector2(3,1),Vector2(2,3),Vector2(0,3),Vector2(-1,1)])
		for i in range(count):draw_colored_polygon(polygon,Color(.3,.6,.4))
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var v:Dictionary=Engine.get_version_info()
	check(int(v.major)>4 or (int(v.major)==4 and (int(v.minor)>6 or (int(v.minor)==6 and int(v.patch)>=3))),"Supported runtime needs the canvas-batch reclamation fix in Godot4.6.3 or newer")
	if failures:quit(1);return
	if OS.get_cmdline_user_args().has("--render"):
		check(DisplayServer.get_name()!="headless","Render regression requires a real graphics surface")
		if failures:quit(1);return
		var canvas:=CapacityCanvas.new();root.add_child(canvas)
		for count in [49152,49152,32769,32769,16384,16385]:
			canvas.count=count;canvas.queue_redraw();await process_frame
			RenderingServer.force_draw(true)
			var drawn:int=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
			check(drawn==count,"Exact capacity batches must draw current commands once: expected%d actual%d"%[count,drawn])
		canvas.free();await process_frame
	print("Native canvas capacity/command lifetime regression: ",failures," failures; Engine",Engine.get_version_info().string)
	quit(1 if failures else 0)
