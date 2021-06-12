extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var cur_idx = 0
var probs = [.42,.08,.08,.08,.08,.08,.08,.02,.02,.02,.02]
var cur_amount = probs[0]

# Called when the node enters the scene tree for the first time.
func _ready():
	var animation_num = Singleton.rng.randf_range(0,1)

	
	while cur_amount < animation_num  && cur_idx<10:
		cur_idx+=1 
		cur_amount += probs[cur_idx]

	
	$AnimatedSprite.animation = str(cur_idx+1)
	$AnimatedSprite.frame = Singleton.rng.randi()%$AnimatedSprite.frames.get_frame_count(str(cur_idx+1))
	


	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
