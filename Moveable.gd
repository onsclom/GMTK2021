extends Node2D

var prev_position
var new_target
export var player = false
var time_since_moved = Singleton.move_animation_time

# Called when the node enters the scene tree for the first time.
func _ready():
	if not player:
		$Dust.emitting = false
	pass # Replace with function body.


func set_target(new_target_value):
	prev_position = position
	new_target = new_target_value
	time_since_moved = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_since_moved += delta
	time_since_moved = min(Singleton.move_animation_time, time_since_moved)
	
	if prev_position && new_target:
		var animation_factor = time_since_moved/Singleton.move_animation_time
		animation_factor = easeOutElastic(animation_factor)
		position = new_target*animation_factor+(1.0-animation_factor)*prev_position

func easeOutElastic(x):
	return 1 - pow(1 - x, 5)

func activate(neighbor):
	$AnimatedSprite.playing = true
	
	$Connect.position = Vector2(-1,-1)*neighbor*8
	if neighbor.y != 0:
		$Connect.rotation_degrees = 90
	
	$Connect.visible = true
	$Connect.playing = true
	
	$Dust.emitting = true


func _on_Connect_animation_finished():
	$Connect.visible = false
	pass # Replace with function body.
