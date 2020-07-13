extends Spatial


export(int) var server_port = 25566
export(int) var max_player = 20


func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connect_failed")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _process(delta):
	if Input.is_action_just_pressed("ui_left"):
		init_server_network_peer()
	if Input.is_action_just_pressed("ui_right"):
		init_client_network_peer()

func init_server_network_peer():
	var p = NetworkedMultiplayerENet.new()
	p.create_server(server_port, max_player)
	get_tree().network_peer = p
	
func init_client_network_peer():
	var p = NetworkedMultiplayerENet.new()
	p.create_client("localhost", server_port)
	get_tree().network_peer = p

func _on_network_peer_connected(id):
	print(id, " has conneted!")

func _on_network_peer_disconnected(id):
	print(id, " has disconnected!")

func _on_connected_to_server():
	print("Connect to server successfully!")

func _on_connect_failed():
	print("Connect to server failed!")

func _on_server_disconnected():
	print("Disconnected from server!")

