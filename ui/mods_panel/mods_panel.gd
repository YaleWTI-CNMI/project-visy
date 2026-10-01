extends Panel

var rows: Dictionary = {}

func _ready() -> void:
	WSClient.plot_added.connect(_on_plot_added)
	WSClient.plot_updated.connect(_on_plot_updated)
	WSClient.plot_removed.connect(_on_plot_removed)
	WSClient.disconnected.connect(_on_client_disconnected)

func _on_client_disconnected(_code) -> void:
	for child in %ModMatrix.get_children():
		child.queue_free()
	rows.clear()

func _on_plot_removed(data) -> void:
	var id := int(data.id)
	if rows.has(id):
		for row in rows[id].values():
			row.label.queue_free()
			row.slider.queue_free()
		rows.erase(id)

func _on_plot_added(data) -> void:
	var id := int(data.id)
	if rows.has(id):
		_on_plot_updated(data)
		return
	rows[id] = {}
	for mod_name in data.mods:
		var info: Dictionary = data.mods[mod_name]
		if info.definition.type != "continuous":
			continue
		var label := Label.new()
		var slider := HSlider.new()
		%ModMatrix.add_child(label)
		%ModMatrix.add_child(slider)
		label.text = "%s (%d): %s" % [mod_name, id, str(info.value)]
		slider.custom_minimum_size.x = 120
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = info.definition.range[0]
		slider.max_value = info.definition.range[1]
		slider.step = info.definition.step
		slider.set_value_no_signal(info.value)
		slider.tooltip_text = str(info.value)
		slider.value_changed.connect(func(value):
			slider.tooltip_text = str(value)
			label.text = "%s (%d): %s" % [mod_name, id, str(value)]
			WSClient.queue_message({"type": "UPDATE_MODS", "data": {"id": id, "mods": {mod_name: value}}})
		)
		rows[id][mod_name] = {"label": label, "slider": slider}

func _on_plot_updated(data) -> void:
	var id := int(data.id)
	if not rows.has(id):
		return
	for mod_name in data.mods:
		if rows[id].has(mod_name):
			rows[id][mod_name].slider.set_value_no_signal(data.mods[mod_name].value)
			rows[id][mod_name].label.text = "%s (%d): %s" % [mod_name, id, str(data.mods[mod_name].value)]
