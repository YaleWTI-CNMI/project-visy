extends Node

var server_url = "ws://localhost:8765"
var socket := WebSocketPeer.new()
var is_connected := false
var queue: Array[String] = []
var _incoming := ""
var _retry_at := 0

signal connected
signal disconnected(code)
signal plot_added(data)
signal plot_updated(data)
signal plot_removed(data)

func _process(_delta: float) -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if is_connected:
			is_connected = false
			disconnected.emit(socket.get_close_code())
			queue.clear()
			_incoming = ""
			_retry_at = Time.get_ticks_msec() + 1000
		if Time.get_ticks_msec() < _retry_at:
			return
		socket = WebSocketPeer.new()
		socket.inbound_buffer_size = 200000000
		socket.connect_to_url(server_url)
		_retry_at = Time.get_ticks_msec() + 1000
		_incoming = ""
		return
	socket.poll()
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	while socket.get_available_packet_count():
		feed_packet(socket.get_packet().get_string_from_utf8())
	while not queue.is_empty():
		socket.send_text(queue.pop_front())

func feed_packet(packet: String) -> void:
	_incoming += packet
	var boundary := _incoming.find("\n")
	while boundary >= 0:
		process_new_message(_incoming.substr(0, boundary))
		_incoming = _incoming.substr(boundary + 1)
		boundary = _incoming.find("\n")

func process_new_message(data: String) -> void:
	var message = JSON.parse_string(data)
	if not message is Dictionary or not message.has_all(["type", "data"]):
		push_error("VISY: invalid server message")
		return
	match message.type:
		"CONNECTED":
			if not is_connected:
				is_connected = true
				connected.emit()
		"PLOT_ADDED": plot_added.emit(message.data)
		"PLOT_UPDATED": plot_updated.emit(message.data)
		"PLOT_REMOVED": plot_removed.emit(message.data)
		_: push_error("VISY: unknown message type %s" % message.type)

func queue_message(data: Dictionary) -> void:
	if is_connected:
		queue.append(JSON.stringify(data))

func queue_vrid_call(vrid, args) -> void:
	queue_message({"type": "VRID_CALL", "data": {"vrid": vrid, "args": args}})

func _exit_tree() -> void:
	socket.close()
