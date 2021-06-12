extends WorldEnvironment


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var total_time = 0

var noise = OpenSimplexNoise.new()

var flicker_speed = 10
var flicker_strength = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	# Configure
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20.0
	noise.persistence = 0.8
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	total_time += delta
	environment.glow_intensity = noise.get_noise_1d(total_time*flicker_speed)*flicker_strength+2.0
	pass
