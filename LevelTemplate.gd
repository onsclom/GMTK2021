extends ColorRect

export var show_UI = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if not show_UI:
		$Game/Camera2D/UI.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
