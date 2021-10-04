extends KinematicBody2D

# Controller Movement
var velocity = Vector2()
const accel = 9

# Drunken Movement
var drunkV = Vector2()
var drunkR = randf()*2*PI
var drunkT = 0
const drunkAccel_min = 1.0 * 0.8
const drunkAccel_max = 1.4 * 0.8
var drunkAccel = 0
var soberT = 0

# Get other nodes
onready var spr = get_node("AnimatedSprite")
onready var bottle = get_node("Bottle")
onready var drink_bottle = get_node("Bottle2")
onready var db_x = drink_bottle.transform.x
onready var db_rot = drink_bottle.rotation

var bottle_rate = 1.5 * PI

var enemy = null

# Dash
var dash_cd = 0
var dash_time = 0

var coinbag_scene = preload("res://Scenes/CoinBag.tscn")

var dashing = false

onready var dashSound = get_node("DashSound")
onready var enemyDieSound = get_node("EnemyDieSound")
onready var drinkSound = get_node("DrinkSound")

func get_input(delta):
	# Apply friction
	velocity = velocity * 0.98
	
	var dir = Vector2()
	if Input.is_action_pressed("right"):
		dir.x += 1 + rand_range(-0.2, 0.2)
	if Input.is_action_pressed("left"):
		dir.x -= 1 + rand_range(-0.2, 0.2)
	if Input.is_action_pressed("down"):
		dir.y += 1 + rand_range(-0.2, 0.2)
	if Input.is_action_pressed("up"):
		dir.y -= 1 + rand_range(-0.2, 0.2)
	velocity += dir.normalized() * accel
	
	# Apply drunkness
	if true:
		if drunkT > 0:
			drunkT -= delta
			drunkV += Vector2(cos(drunkR), sin(drunkR)).normalized() * drunkAccel
			velocity += drunkV
		else:
			soberT -= delta
			if soberT < 0:
				drunkV = Vector2()
				drunkR = rand_range(drunkR + PI/2, drunkR + 1.5*PI)
				drunkT = rand_range(0.2, 0.4)
				drunkAccel = rand_range(drunkAccel_min, drunkAccel_max)
				soberT = 0.8
	# clamp velocity
	velocity = velocity.clamped(800)

func can_hit():
	return dash_time <= 0

func _process(delta):
	if enemy && dash_time > 0:
		if enemy.has_coin():
			var inst = coinbag_scene.instance()
			inst.position = enemy.global_position
			get_parent().add_child(inst)
		enemyDieSound.play()
		enemy.queue_free()
	
	z_index = floor(global_position.y / 8)

func _physics_process(delta):
	if dash_time <= 0: # WALK
		get_input(delta)
	else: # DASHING
		dash_time -= delta
		if dash_time <= 0: # STOP DASHING
			spr.modulate = Color(1, 1, 1)
			spr.play("drink_walk")
			drink_bottle.visible = true
			drink_bottle.frame = 0
			dash_cd = 2
			drinkSound.play()
			velocity = velocity.clamped(400)
			dashing = false
	
	# detect dash and override velocity
	bottle.rotation = (bottle.rotation + bottle_rate * delta)
	
	if dash_cd <= 0 && !dashing:
		if Input.is_action_just_pressed("dash"): # START DASH
			var ang = randf() * 2 * PI
			velocity = Vector2(cos(bottle.rotation - PI/2), sin(bottle.rotation - PI/2)).normalized() * 1000
			dash_time = 0.2
			dashing = true
			spr.modulate = Color(0, 1, 0)
			bottle.visible = false
			dashSound.play()
	elif dash_cd > 0: # DRINKING
		dash_cd -= delta
		if dash_cd <= 0: # STOP DRINKING
			var cframe = spr.frame
			spr.play("walk")
			spr.frame = cframe
			bottle.visible = true
			bottle_rate *= -1
			drink_bottle.visible = false

	# mutate sprite based on velocity
	spr.rotation = ((velocity.x / 800) * PI / 4)
	spr.scale.y = ((-1.5 * velocity.y / 800) + 4)
	spr.flip_h = velocity.x > 0
	if velocity.x > 0:
		drink_bottle.position.x = -22.146
		drink_bottle.rotation_degrees = 100
	else:
		drink_bottle.position.x = 22.146
		drink_bottle.rotation_degrees = -100
	velocity = move_and_slide(velocity)

func _on_Area2D_body_entered(body):
	if body.get_parent().is_in_group("enemies"):
		enemy = body.get_parent()


func _on_Area2D_body_exited(body):
	if body.get_parent().get_instance_id() == enemy.get_instance_id():
		enemy = null
