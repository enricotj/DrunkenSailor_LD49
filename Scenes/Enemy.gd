extends KinematicBody2D

var vel = Vector2()
var acc = 10
var target = null

var ready_timer = 0.5
var isReady = false

onready var spr = get_node("AnimatedSprite")
onready var coinBag = get_node("coin_bag")

var atTarget = false

const tt = 2
var takeT = tt

var isTargetTreasure = true
var taken = false

var shoot_rate = 3.5
var shoot_timer = 1
var shooting_speed = 1
var shooting_timer = 0
var fired = false

var player = null

var esc = false
var esc_up = false

var esc_timer = 5

var bullet_scene = preload("res://Scenes/Bullet.tscn")

var spawning = true
var spawn_down = false

var og_cl = 0
var og_cm = 0

#collision_layer = og_cl
#collision_mask = og_cm

var spawn_tp

func init(spawn_down, tp):
	self.spawn_down = spawn_down
	spawn_tp = tp

func _ready():
	add_to_group("enemies")
	player = weakref(get_parent().get_node("Player"))
	og_cl = collision_layer
	og_cm = collision_mask
	collision_layer = 0
	collision_mask = 0
	spr.modulate = Color(0, 0, 1, 0.9)
	coinBag.visible = false

func _process(delta):
	if ready_timer <= 0 && !isReady:
		var all_treasure = get_tree().get_nodes_in_group("treasures")
		if all_treasure.size() > 0:
			target = weakref(all_treasure[floor(randf() * all_treasure.size())])
		else:
			isTargetTreasure = false
			var all_planks = get_tree().get_nodes_in_group("planks")
			var dist = 9999999
			target = null
			coinBag.visible = taken
			for plank in all_planks:
				var pp = plank.get_transform().get_origin()
				var pd = global_position.distance_to(pp)
				if pd < dist:
					target = weakref(plank)
					dist = pd
					if (plank.get_transform().get_rotation() != 0):
						esc_up = true
					atTarget = false
		isReady = true
		if target.get_ref() && target.get_ref().can_fast_take():
			takeT = 1
	else:
		ready_timer -= delta
	
	if shooting_timer > 0: # PAUSE FOR SOME TIME TO AIM AND SHOOT
		shooting_timer -= delta
		spr.modulate = Color(1, 0.5, 0.5)
		if player.get_ref(): # FACE PLAYER DIRECTION
			spr.flip_h = player.get_ref().get_transform().get_origin().x < global_position.x
		if shooting_timer < shooting_speed * 0.25 && !fired: # SHOOT GUN
			fired = true
			var b = bullet_scene.instance()
			b.position = global_position
			get_parent().add_child(b)
			get_node("gun_shot").play()
		if shooting_timer <= 0: # RESET SHOOTING TIMER
			fired = false
			spr.modulate = Color(1, 1, 1)
			shoot_timer = rand_range(shoot_rate - 0.5, shoot_rate + 0.5)
	
	coinBag.position.x = -12 if !spr.flip_h else 12
	
	z_index = floor(global_position.y / 8)

func has_coin():
	return taken

func _physics_process(delta):
	if spawning:
		spr.play("walk")
		global_position.y -= 2 if !spawn_down else -2
		if (!spawn_down && global_position.y < spawn_tp.y) || (spawn_down && global_position.y > spawn_tp.y):
			spawning = false
			collision_layer = og_cl
			collision_mask = og_cm
			spr.modulate = Color(1, 1, 1, 1)
	elif esc:
		spr.play("walk")
		global_position.y += 2 if !esc_up else -2
		esc_timer -= delta
		if esc_timer <= 0:
			queue_free()
	else:
		_phys_move(delta)

func _phys_move(delta):
	if shooting_timer <= 0: # ONLY MOVE IF NOT AIMING & SHOOTING
		shoot_timer-= delta
		if shoot_timer < 0 && !atTarget:
			shooting_timer = shooting_speed
			spr.play('shoot')
			vel = Vector2()
		
		if isReady && target.get_ref() && !atTarget:
			var tp = target.get_ref().get_transform().get_origin()
			vel += (tp - global_position).normalized() * acc
			vel = vel.clamped(200)
			vel = move_and_slide(vel)
			spr.flip_h = vel.x < 0

			if (global_position.distance_to(tp) <= 50 && isTargetTreasure) || (global_position.distance_to(tp) <= 5 && !isTargetTreasure):
				vel = Vector2()
				atTarget = true
		elif atTarget && isTargetTreasure: # AT TREASURE
			takeT -= delta
			if takeT < 0:
				var numT = get_tree().get_nodes_in_group("treasures").size()
				takeT = tt
				if target.get_ref() && target.get_ref().is_in_group('treasures'): # try to take the treasure
					taken = target.get_ref().try_take()
				elif numT > 0: # get new treasure target
					var all_treasure = get_tree().get_nodes_in_group("treasures")
					target = weakref(all_treasure[floor(randf() * all_treasure.size())])
					atTarget = false
					if target.get_ref() && target.get_ref().can_fast_take():
						takeT = 1
				
				if taken:
					get_node("take").play()
				
				if taken || numT == 0:
					isTargetTreasure = false
					var all_planks = get_tree().get_nodes_in_group("planks")
					var dist = 9999999
					target = null
					coinBag.visible = taken
					for plank in all_planks:
						var pp = plank.get_transform().get_origin()
						var pd = global_position.distance_to(pp)
						if pd < dist:
							target = weakref(plank)
							dist = pd
							if (plank.get_transform().get_rotation() != 0):
								esc_up = true
							atTarget = false
		elif atTarget && !isTargetTreasure: # AT PLANK
			_escape()
	
	# set animations
	if shooting_timer <= 0:
		if vel.length() == 0:
			spr.play("idle")
		else:
			spr.play("walk")

func _escape():
	global_position = target.get_ref().global_position
	spr.modulate = Color(1, 1, 0.5, 0.9)
	esc = true
	collision_layer = 0
	collision_mask = 0
