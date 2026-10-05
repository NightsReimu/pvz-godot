extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	# Match exported packages: only the .import remap and native MP3 resource
	# exist; the original .mp3 is absent. Use a fresh virtual path to avoid cache.
	const TRACK := "res://__music_export_probe__/finale.mp3"
	const IMPORTED := "res://__music_export_probe__/finale.mp3str"
	const SOURCE := "res://audio/th075_suika_boss.mp3"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/music-export"))
	var config := ConfigFile.new()
	check(config.load(SOURCE + ".import") == OK, "Supplied MP3 import metadata exists")
	var original_import: String = config.get_value("remap", "path", "")
	var remap_file := "res://output/music-export/remap.txt"
	var file := FileAccess.open(remap_file, FileAccess.WRITE)
	file.store_string('[remap]\nimporter="mp3"\ntype="AudioStreamMP3"\npath="%s"\n' % IMPORTED)
	file.close()
	var pack := PCKPacker.new()
	var pack_path := "res://output/music-export/only-imported-audio.pck"
	check(pack.pck_start(pack_path) == OK, "Create export-shaped fixture")
	check(pack.add_file(TRACK + ".import", remap_file) == OK, "Pack MP3 remap")
	check(pack.add_file(IMPORTED, original_import) == OK, "Pack native imported MP3")
	check(pack.flush() == OK and ProjectSettings.load_resource_pack(pack_path), "Mount export-shaped audio fixture")
	check(not FileAccess.file_exists(TRACK) and ResourceLoader.exists(TRACK), "Fixture has an importable track without raw MP3 bytes")
	var game := PreviewGame.new()
	root.add_child(game)
	var stream: AudioStream = game._load_audio_stream(TRACK)
	check(stream is AudioStreamMP3, "Exported BGM must load through the resource remap")
	if stream is AudioStreamMP3:
		check(stream.data == FileAccess.get_file_as_bytes(SOURCE), "Imported playback retains the supplied MP3 bytes")
		check(stream.loop and is_zero_approx(stream.loop_offset), "Imported BGM keeps existing loop behavior")
		game._play_bgm(TRACK)
		check(game.current_bgm_path == TRACK and game.music_player.playing and game.music_player.stream == stream, "Exported track actually plays from the cached imported resource")
	game.save_dirty = false
	game.free()
	await process_frame
	await create_timer(0.15).timeout
	print("Export-shaped MP3 remap, exact bytes, looping and actual playback: %d failure(s)" % failures)
	quit(1 if failures else 0)
