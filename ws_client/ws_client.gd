extends Node

var server_url = "ws://localhost:8765"

var socket = WebSocketPeer.new()

signal connected
signal plot_added(plot_id, data)
signal plot_updated(plot_id, data)
signal plot_removed(plot_id)

func _ready() -> void:
	try_connect(server_url)

func try_connect(url):
	var err = socket.connect_to_url(url)
	if err != OK:
		print("Unable to connect")
		print("Attempting reconnect")
		get_tree().create_timer(3.0).timeout.connect(func(): try_connect(server_url))
		set_process(false)
	else:
		print("Connected")
		set_process(true)

func _process(delta: float) -> void:
	socket.poll()

	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var data = socket.get_packet().get_string_from_utf8()
			print("Got data from server: ", data)
			process_new_message(data)
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		print("Attempting reconnect")
		set_process(false)
		get_tree().create_timer(3.0).timeout.connect(func(): try_connect(server_url))

func process_new_message(data: String):
	var message = JSON.parse_string(data)
	if message == null:
		push_error("Received bad data from server!")
		return
	
	match message.type:
		"CONNECTED":
			connected.emit()
		"PLOT_ADDED":
			plot_added.emit(message.plot_id, message.data)
		"PLOT_UPDATED":
			plot_updated.emit(message.plot_id, message.data)
		"PLOT_REMOVED":
			plot_removed.emit(message.plot_id)
		_:
			push_error("Unknown message from server! %s" % message.type)
			return
