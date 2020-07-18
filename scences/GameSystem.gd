extends Node


const WorldScene = preload("res://scences/World.tscn")
const MainPlayer = preload("res://scences/MainPlayer.tscn")

export(int) var server_port = 25566
export(int) var max_player = 20

var the_world:Node
var the_player:Node

var peer_id_list:Array

var cmd_mode = false

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connect_failed")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _input(event):
	if the_player == null:
		return
	if event is InputEventMouseButton:
		if not cmd_mode and event.pressed and event.button_index == BUTTON_LEFT:
			pause(false)

func _unhandled_input(event):
	if not cmd_mode and Input.is_action_just_pressed("ui_chat"):
		cmd_mode = true
		$Control/ChatPanel.visible = true
		$Control/ChatPanel/LineEdit.grab_focus()
		pause(true)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		pause(true)
#--------- Methods ------------------

func init_server_network_peer():
	var p = NetworkedMultiplayerENet.new()
	p.create_server(server_port, max_player)
	get_tree().network_peer = p
	peer_id_list = [get_tree().get_network_unique_id()]
	
func init_client_network_peer():
	var p = NetworkedMultiplayerENet.new()
	p.create_client("localhost", server_port)
	get_tree().network_peer = p

func load_world():
	the_world = WorldScene.instance()
	add_child(the_world)

func create_main_player():
	the_player = MainPlayer.instance()
	the_world.add_child(the_player)
	the_player.peer_id = get_tree().get_network_unique_id()
	the_player.set_network_master(the_player.peer_id)
	the_player.get_node("Camera").make_current()
	the_player.enable = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pause(v = true):
	if the_player:
		the_player.enable = not v
	if v:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


#---------- RPC ---------------------
remote func add_dummy_players_with(_peer_id_list):
	for id in _peer_id_list:
		add_dummy_player(id)

remotesync func add_dummy_player(id):
	if id == get_tree().get_network_unique_id():
		return
	
	# check redundunt
	var ps = get_tree().get_nodes_in_group("player")
	for p in ps:
		if p.peer_id == id:
			return
	
	# add
	var p = MainPlayer.instance()
	the_world.add_child(p)
	p.peer_id = id
	p.set_network_master(id)

remotesync func remove_dummy_player(id):
	var ps = get_tree().get_nodes_in_group("player")
	for p in ps:
		if p.peer_id == id:
			p.queue_free()
#---------- Signals -----------------

func _on_StartServerButton_pressed():
	init_server_network_peer()
	load_world()
	create_main_player()
	

func _on_StartClientButton_pressed():
	init_client_network_peer()
	load_world()
	create_main_player()

func _on_network_peer_connected(id):
	print(id, " has conneted!")
	if get_tree().is_network_server():
		peer_id_list.append(id)
		rpc("add_dummy_player", id)
		rpc_id(id, "add_dummy_players_with", peer_id_list)

func _on_network_peer_disconnected(id):
	print(id, " has disconnected!")
	if get_tree().is_network_server():
		var pos = peer_id_list.find(id)
		if pos >= 0:
			peer_id_list.remove(pos)
		rpc("remove_dummy_player", id)

func _on_connected_to_server():
	print("Connect to server successfully!")

func _on_connect_failed():
	print("Connect to server failed!")

func _on_server_disconnected():
	print("Disconnected from server!")

func _on_LineEdit_text_entered(cmd:String):
	cmd_mode = false
	pause(false)
	$Control/ChatPanel.visible = false
	
	if cmd.empty():
		return
	
	if not $Control/ChatPanel/RichTextLabel.text.empty():
		$Control/ChatPanel/RichTextLabel.text += "\n"
	$Control/ChatPanel/RichTextLabel.text += cmd
	$Control/ChatPanel/LineEdit.text = ""
