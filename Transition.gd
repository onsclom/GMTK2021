extends Sprite
var bottom = Vector2(192,326+16)
var middle = Vector2(192, 108) 
# Called when the node enters the scene tree for the first time.

signal garage_up
var garage_covering = false

var going_up = false
var total_time = 1.0
var time_since = total_time

func _ready():
	Singleton.garage = self
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta):
#	if Input.is_action_just_pressed("ui_up"):
#		garage_up()
#	elif Input.is_action_just_pressed("ui_down"):
#		garage_down()
	
	time_since += delta
	time_since = min(total_time, time_since)
	if going_up:
		if !garage_covering and total_time==time_since:
			garage_covering = true
			emit_signal("garage_up")
			print("yepyep")
		position = (time_since/total_time)*middle+(1.0-(time_since/total_time))*bottom
	else:
		position = (time_since/total_time)*bottom+(1.0-(time_since/total_time))*middle

func garage_up():
	time_since = 0
	going_up = true
	
func garage_down():
	garage_covering = false
	time_since = 0
	going_up = false
