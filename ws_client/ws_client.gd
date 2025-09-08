extends Node

var server_url = "ws://localhost:8765"

var socket
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
	thread = Thread.new()
	active = true
	thread.start(_main, Thread.PRIORITY_HIGH)


func _exit_tree() -> void:
	active = false
	thread.wait_to_finish()


func _main():
	while active:
		print("Attempting to connect to: ", server_url);
		socket = WebSocketPeer.new()
		socket.inbound_buffer_size = 200000000
		var err = socket.connect_to_url(server_url)
		if err != OK:
			printerr(error_string(err))
			continue
		
		socket.poll()
		var state = socket.get_ready_state()
		var acc_msg: String = ""
		
		while state != WebSocketPeer.STATE_CLOSED && active:
			if state == WebSocketPeer.STATE_OPEN:
				if is_connected == false:
					connected.emit.call_deferred()
					is_connected = true
					print("Socket connected!")
				
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

	
		print("Socket dis-connected!")

		var code = socket.get_close_code()
		is_connected = false
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
