extends KinematicBody2D

onready var area = get_node("Area2D")
var vel = Vector2()

func _ready():
	var spr = get_node("spr_bullet")
	var player = get_parent().get_node("Player")
	if player:
		var target = player.get_transform().get_origin()
		vel = (target - global_position).normalized() * 12
		spr.rotation = vel.angle()
	else:
		free()

func _physics_process(delta):
	move_and_collide(vel)

func _on_Area2D_body_entered(body):
	if body.get_parent().is_in_group("player") && body.get_parent().can_hit():
		var lives = get_tree().get_nodes_in_group("lives")
		if lives.size() <= 1:
			get_parent().get_node("Death_Sound").play()
			body.get_parent().queue_free()
		if lives.size() > 0:
			get_parent().get_node("Hit_Sound").play()
			lives[lives.size() - 1].queue_free()
	queue_free()
