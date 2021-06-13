extends Node2D


# Declare member variables here. Examples:
export var input_name = "ui_up"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed(input_name):
		$On.visible = true
		$Off.visible = false
	else:
		$On.visible = false
		$Off.visible = true
