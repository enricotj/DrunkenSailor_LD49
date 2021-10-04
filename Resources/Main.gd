extends Node2D


var spawnA = [10, 22, 24, 30, 36]

var spawnB = [2, 12, 23, 25, 33]

var planks = null

var t = 0

var enemy_scene = preload("res://Scenes/Enemy.tscn")

var player = null

var lost = false
var won = false

var is_start = true

var restart_timer = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	planks = get_tree().get_nodes_in_group("planks")
	spawnA.sort()
	spawnB.sort()
	player = weakref(get_node("Player"))

func _check_spawn(arr):
	var numT = get_tree().get_nodes_in_group('treasures').size()
	if arr.size() > 0 && numT > 0:
		if arr[0] < t:
			return true
	return false

func _spawn(plank):
	var tf = plank.get_transform()
	var offset = 350 if tf.get_rotation() == 0 else -350
	var pt = tf.get_origin() + Vector2(0, offset)
	var en = enemy_scene.instance()
	en.init(tf.get_rotation() != 0, tf.get_origin())
	en.global_position = pt
	add_child(en)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_start:
		t += delta
		if _check_spawn(spawnA):
			_spawn(planks[0])
			spawnA.remove(0)
		if _check_spawn(spawnB):
			_spawn(planks[1])
			spawnB.remove(0)
		
		if spawnA.size() == 0 && spawnB.size() == 0 && get_tree().get_nodes_in_group('enemies').size() == 0 && !lost:
			get_node("WinLabel").visible = true
			won = true
		
		var isTreasureWithEnemy = false
		for en in get_tree().get_nodes_in_group('enemies'):
			if en.has_coin():
				isTreasureWithEnemy = true
		
		if !player.get_ref() || (get_tree().get_nodes_in_group('treasures').size() == 0 && !isTreasureWithEnemy) && !won:
			get_node("LoseLabel").visible = true
			lost = true
		
		if won or lost:
			get_node("RestartLabel").visible = true
			if Input.is_action_just_pressed("restart"):
				get_tree().reload_current_scene()
