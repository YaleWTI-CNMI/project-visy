extends Node

@export var server_url = "ws://localhost:8765"

var socket = WebSocketPeer.new()


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
			print("Got data from server: ", socket.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		print("Attempting reconnect")
		set_process(false)
		get_tree().create_timer(3.0).timeout.connect(func(): try_connect(server_url))
