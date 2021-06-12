extends Node


var level = ""
var rng_seed = 1000
var rng = RandomNumberGenerator.new()

# time for all move animations 
var move_animation_time = .3

func _ready():
	rng.set_seed(rng_seed)
