extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var animation = Singleton.rng.randi_range(1,7)
	$AnimatedSprite.animation = str(animation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
