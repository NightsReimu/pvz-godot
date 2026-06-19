extends SceneTree

const SAMPLE_RATE := 44100


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://audio/sfx"))
	_write_hit_wav("res://audio/sfx/hit-soft.wav", 440.0, 860.0, 0.1, 0.42)
	_write_hit_wav("res://audio/sfx/hit-bright.wav", 620.0, 1420.0, 0.085, 0.34)
	_write_hit_wav("res://audio/sfx/hit-heavy.wav", 220.0, 520.0, 0.14, 0.56)
	_write_hit_wav("res://audio/sfx/hit-explosion.wav", 150.0, 420.0, 0.18, 0.68)
	_write_hit_wav("res://audio/sfx/hit-ice.wav", 760.0, 1880.0, 0.16, 0.38)
	_write_hit_wav("res://audio/sfx/hit-electric.wav", 920.0, 2460.0, 0.12, 0.46)
	_write_hit_wav("res://audio/sfx/hit-bite.wav", 310.0, 1180.0, 0.09, 0.34)
	# Per-attack firing SFX, grouped by attack family (6 families).
	_write_shoot_wav("res://audio/sfx/shoot-pea.wav", 520.0, 1200.0, 0.07, 0.34, true)
	_write_shoot_wav("res://audio/sfx/shoot-lob.wav", 240.0, 540.0, 0.1, 0.4, false)
	_write_shoot_wav("res://audio/sfx/shoot-fire.wav", 180.0, 680.0, 0.13, 0.46, true)
	_write_shoot_wav("res://audio/sfx/shoot-ice.wav", 880.0, 2100.0, 0.11, 0.32, false)
	_write_shoot_wav("res://audio/sfx/shoot-energy.wav", 1100.0, 2800.0, 0.09, 0.38, true)
	_write_shoot_wav("res://audio/sfx/shoot-spore.wav", 380.0, 940.0, 0.12, 0.34, false)
	print("Generated combat polish SFX. Run scripts/tools/run_image2_full_assets.sh for gpt-image-2 PNG assets.")
	quit(0)


func _write_hit_wav(path: String, base_frequency: float, click_frequency: float, duration: float, gain: float) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	var sample_count := int(float(SAMPLE_RATE) * duration)
	var data_size := sample_count * 2
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + data_size)
	file.store_buffer("WAVE".to_ascii_buffer())
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data_size)
	for i in range(sample_count):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 24.0) * (1.0 - clampf(t / duration, 0.0, 1.0))
		var click_env := exp(-t * 80.0)
		var sample := (sin(TAU * base_frequency * t) * env + sin(TAU * click_frequency * t) * click_env * 0.55) * gain
		var value := clampi(int(sample * 32767.0), -32768, 32767)
		file.store_16(value & 0xffff)


# Firing/shooting SFX: a short rising chirp (pew) instead of the impact's
# decaying sine. `rising` sweeps the pitch up to mimic a projectile launch.
func _write_shoot_wav(path: String, base_frequency: float, click_frequency: float, duration: float, gain: float, rising: bool) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	var sample_count := int(float(SAMPLE_RATE) * duration)
	var data_size := sample_count * 2
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + data_size)
	file.store_buffer("WAVE".to_ascii_buffer())
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data_size)
	for i in range(sample_count):
		var t := float(i) / float(SAMPLE_RATE)
		var ratio := float(i) / float(sample_count)
		var sweep := 1.0 + (0.6 if rising else -0.25) * ratio
		var env := exp(-t * 30.0) * (1.0 - clampf(t / duration, 0.0, 1.0))
		var attack := exp(-t * 260.0)
		var sample := (sin(TAU * base_frequency * sweep * t) * env + sin(TAU * click_frequency * sweep * t) * attack * 0.45) * gain
		var value := clampi(int(sample * 32767.0), -32768, 32767)
		file.store_16(value & 0xffff)
