#@tool
extends Node

const WIDTH := 256
const HEIGHT := 256
const DEPTH := 113

const INPUT_DIR := r"C:/Users/Alex/Downloads/CThead_png"  # <- You can import this folder into your project
const OUTPUT_PATH := "res://CT_texture_3d_from_png.tres"


#@export_tool_button("DO IT!") var do_it = generate_texture_from_pngs


func generate_texture_from_pngs():
	var slices: Array[Image] = []

	for i in range(1, DEPTH + 1):
		var fname = "slice_%03d.png" % i
		var fpath = INPUT_DIR + "/" + fname

		var img := Image.new()
		var err = img.load(fpath)
		if err != OK:
			push_error("❌ Failed to load: " + fpath)
			return

		img.decompress()  # This is key
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)

		if img.get_width() != WIDTH or img.get_height() != HEIGHT:
			push_error("❌ Wrong size in %s" % fname)
			return

		slices.append(img)


	if slices.size() != DEPTH:
		push_error("❌ Incomplete volume: only %d slices loaded" % slices.size())
		return

	var tex3d := ImageTexture3D.new()
	var error = tex3d.create(WIDTH, HEIGHT, DEPTH, Image.FORMAT_RGBA8, false, slices)
	
	if error != OK:
		print("❌ Failed to create ImageTexture3D: %s", error)
	
	$"../MeshInstance3D".tex3d
	return
	var result = ResourceSaver.save(tex3d, OUTPUT_PATH)
	if result == OK:
		print("✅ Saved texture to ", OUTPUT_PATH)
	else:
		push_error("❌ Failed to save texture: %s" % result)
