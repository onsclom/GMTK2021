extends AnimatedSprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var activated = false
var animation_num


# Called when the node enters the scene tree for the first time.
func _ready():
	animation_num = Singleton.rng.randi_range(1,7)
	print("this called??")
	animation = str(animation_num)
	
func activate():
	if not activated:
		activated = true
		animation_num+=7
		animation = str(animation_num)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
