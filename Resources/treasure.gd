extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var txt = get_node("Label")

var val = 1

var isOpen = false

onready var spr = get_node("AnimatedSprite")

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group('treasures')

func try_take():
	var pval = val
	if val > 0:
		if isOpen:
			val -= 1
		else:
			isOpen = true
	if (val == 0):
		remove_from_group('treasures')
	return val == 0 && pval > 0

func can_fast_take():
	return false

func close_box():
	isOpen = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	txt.text = String(val)
	z_index = floor(global_position.y / 8)

	if isOpen:
		if (val > 0):
			spr.play("glow")
		else:
			spr.play("empty")
	else:
		spr.play("closed")
