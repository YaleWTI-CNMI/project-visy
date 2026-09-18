extends Node

var server_url = "ws://localhost:8765"

var socket = WebSocketPeer.new()
var is_connected: bool = false
var queue: Array = []


signal connected
signal disconnected(code)

signal plot_added(data)
signal plot_updated(data)
signal plot_removed(data)


var active: bool = false
var thread: Thread


func _ready() -> void:
	socket.inbound_buffer_size = 200000000
	thread = Thread.new()
	active = true
	thread.start(_main, Thread.PRIORITY_HIGH)


func _exit_tree() -> void:
	active = false
	if thread.is_alive():
		thread.wait_to_finish()

func try_connect(url) -> bool:
	var err = socket.connect_to_url(url)
	if err != OK:
		print("Unable to connect")
		print("Attempting reconnect")
	else:
		print("Connected")
	
	return err == OK


func _main():
	while active:
		if not try_connect(server_url):
			await get_tree().create_timer(3.0).timeout
			continue
		
		socket.poll()
		var state = socket.get_ready_state()
		var acc_msg: String = ""
		
		while state != WebSocketPeer.STATE_CLOSED && active:
			if state == WebSocketPeer.STATE_OPEN:
				if is_connected == false:
					connected.emit.call_deferred()
					is_connected = true
				
				socket.set_no_delay(true)
				
				# Receive
				while socket.get_available_packet_count():
					var msg_split = socket.get_packet().get_string_from_utf8()
					acc_msg += msg_split
					
					if acc_msg.ends_with("\n"):
						process_new_message(acc_msg)
						acc_msg = ""
				
				# Send
				while len(queue):
					var message_str = queue.pop_front()
					socket.send_text(message_str)
				
			elif state == WebSocketPeer.STATE_CLOSING:
				pass
			
			socket.poll()
			state = socket.get_ready_state()
		
		var code = socket.get_close_code()
		disconnected.emit.call_deferred(code)
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		print("Attempting reconnect")
		
		await get_tree().create_timer(1).timeout


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

func queue_message(data):
	var message_str = JSON.stringify(data)
	queue.append(message_str)
	
func queue_vrid_call(vrid, args):
	var message_str = JSON.stringify({
		type = "VRID_CALL",
		data = {
			vrid = vrid,
			args = args
		}
	})
	
	queue.append(message_str)
