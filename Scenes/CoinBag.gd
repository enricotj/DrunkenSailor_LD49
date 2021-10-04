extends KinematicBody2D

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group('treasures')

func try_take():
	queue_free()
	return true

func can_fast_take():
	return true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	z_index = floor(global_position.y / 8)
