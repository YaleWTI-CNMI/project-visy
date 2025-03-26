extends Node

var server_url = "ws://localhost:8765"

var socket = WebSocketPeer.new()
var is_connected: bool = false

signal connected
signal disconnected(code)

signal plot_added(data)
signal plot_updated(data)
signal plot_removed(data)

func _ready() -> void:
	socket.inbound_buffer_size = 200000000
	var thread = Thread.new()
	thread.start(_main, Thread.PRIORITY_HIGH)

func try_connect(url) -> bool:
	var err = socket.connect_to_url(url)
	if err != OK:
		print("Unable to connect")
		print("Attempting reconnect")
	else:
		print("Connected")
	
	return err == OK


func _main():
	while true:
		if not try_connect(server_url):
			await get_tree().create_timer(3.0).timeout
			continue
		
		socket.poll()
		var state = socket.get_ready_state()
		
		while state != WebSocketPeer.STATE_CLOSED:
			if state == WebSocketPeer.STATE_OPEN:
				if is_connected == false:
					connected.emit()
					is_connected = true
				
				socket.set_no_delay(true)
				while socket.get_available_packet_count():
					var data = socket.get_packet().get_string_from_utf8()
					print("Got data from server: ", data)
					process_new_message(data)
			elif state == WebSocketPeer.STATE_CLOSING:
				pass
			
			socket.poll()
			state = socket.get_ready_state()
		
		var code = socket.get_close_code()
		disconnected.emit.call_deferred(code)
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		print("Attempting reconnect")


func process_new_message(data: String):
	var message = JSON.parse_string(data)
	if message == null:
		push_error("Received bad data from server!")
		return
	
	match message.type:
		"CONNECTED":
			connected.emit.call_deferred()
		"PLOT_ADDED":
			plot_added.emit.call_deferred(message.data)
		"PLOT_UPDATED":
			plot_updated.emit.call_deferred(message.data)
		"PLOT_REMOVED":
			plot_removed.emit.call_deferred(message.data)
		_:
			push_error("Unknown message from server! %s" % message.type)
			return
