extends Node2D

export(String, MULTILINE) var level_text
var width = 24
var height = 14
var square_size = 16

var level = []

var player_tscn = preload("res://Player.tscn")
var ground_tscn = preload("res://Ground.tscn")
var body_tscn = preload("res://Body.tscn")
var finish_tscn = preload("res://Finish.tscn")
var wall_tscn = preload("res://Wall.tscn")
var square_object = preload("res://SquareObject.gd")

var explosion_tscn = preload("res://Explosion.tscn")
enum {EMPTY, GROUND, PLAYER, BODY, FINISH}
var WALL=EMPTY;

var blocks = []

#list of locations of where player is
var player_part_object = preload("res://PlayerPart.gd")
var player_parts = []

func _ready():
	if Singleton.level != "":
		level_text = Singleton.level
	elif OS.has_feature('JavaScript'):
		var potential_level = JavaScript.eval(""" 
				var url_string = window.location.href;
				var url = new URL(url_string);
				url.searchParams.get("level");
			""")
		if potential_level:
			level_text = potential_level
		
		
		
	var level_1_line = level_text.replace("\n","")
	level_1_line = level_1_line.replace("\r\n","")
	level_1_line = level_1_line.replace("\r","")
	print(level_1_line)

	for y in range(height):
		level.push_back([])
		for x in range(width):
			var ground_val = int(level_1_line[y*width+x])!=0
			var tile_val = int(level_1_line[y*width+x])
			level[y].push_back( square_object.new(ground_val, tile_val, null) )
	
	for y in range(height):
		for x in range(width):
			match level[y][x].tile_type:
				EMPTY:
					var new_wall = wall_tscn.instance()
					add_child(new_wall)
					new_wall.position = Vector2(x*square_size+square_size/2, y*square_size+square_size/2)
				GROUND:
					pass	
				PLAYER:
					var new_player = player_tscn.instance()
					add_child(new_player)
					new_player.position = Vector2(x*square_size+square_size/2, y*square_size+square_size/2)
					player_parts.push_back( player_part_object.new(Vector2(x,y), new_player) )
				BODY:
					var new_body = body_tscn.instance()
					new_body.position = Vector2(x*square_size+square_size/2, y*square_size+square_size/2)
					add_child(new_body)
					level[y][x].node = new_body
				FINISH:
					var new_finish = finish_tscn.instance()
					new_finish.position = Vector2(x*square_size+square_size/2, y*square_size+square_size/2)
					add_child(new_finish)
					level[y][x].node = new_finish
				_:
					print("unrecognized??")
				

func _process(delta):
	if Input.is_action_just_pressed("ui_left"):
		attempt_move(-1,0)
	elif Input.is_action_just_pressed("ui_right"):
		attempt_move(1,0)
	elif Input.is_action_just_pressed("ui_up"):
		attempt_move(0,-1)
	elif Input.is_action_just_pressed("ui_down"):
		attempt_move(0,1)
		
	if Input.is_action_just_pressed("c"):
		OS.set_clipboard(level_text)
	if Input.is_action_just_pressed("v"):
		print(OS.get_clipboard())
		Singleton.level = OS.get_clipboard()
	if Input.is_action_just_pressed("r"):
		get_tree().reload_current_scene()
		
func attempt_move(x,y):
	print(x)
	
	#must check that every body part not blocked to move to new spot
	var safe_move=true
	
	for part in player_parts:
		#make sure inside bounds of screen
		var new_x = part.position.x+x
		var new_y = part.position.y+y
		
		#no ground = not safe
		if level[new_y][new_x].is_ground == false:
			safe_move = false
		
	if safe_move:
		var new_body_parts=[]
		#go through all player parts and update them
		for part in player_parts:
			var new_x = part.position.x+x
			var new_y = part.position.y+y
			
			part.position = Vector2(new_x, new_y)
			part.node.set_target( grid_to_world(part.position) )
			
			#readd original
			new_body_parts.push_back( player_part_object.new(Vector2(new_x,new_y), part.node) )
			
			#Check if one of 4 neighbors is a bodypart
			for neighbor in [Vector2(-1,0), Vector2(1,0), Vector2(0,1), Vector2(0,-1)]:
				var check_x = new_x+neighbor.x
				var check_y = new_y+neighbor.y
				if level[check_y][check_x].tile_type == BODY:
					level[check_y][check_x].tile_type = EMPTY
					print("JOINED")
					
					#create spark inbetween two spots
					var new_explosion = explosion_tscn.instance()
					add_child(new_explosion)
					new_explosion.position = grid_to_world( Vector2(new_x+neighbor.x/2, new_y+neighbor.y/2) )
					
					#add new
					new_body_parts.push_back( player_part_object.new(Vector2(check_x,check_y), 
						level[check_y][check_x].node) )
					level[check_y][check_x].node.activate()
		player_parts = new_body_parts
	else:
		print("not a safe move!")
	
func grid_to_world(position):
	return Vector2(position.x*square_size+square_size/2, position.y*square_size+square_size/2)
