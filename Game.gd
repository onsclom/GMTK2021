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

var game_over_tscn = preload("res://GameOver.tscn")

var explosion_tscn = preload("res://Explosion.tscn")
enum {EMPTY, GROUND, PLAYER, BODY, FINISH}
var WALL=EMPTY;

var blocks = []
var dir_held_counts = [0,0,0,0]

var initial_hold = .4
var additional_hold = .15

#list of locations of where player is
var player_part_object = preload("res://PlayerPart.gd")

var main_players = []
var player_parts = []

var goal_count = 0

var won = false

func _ready():
	
	if Transition.garage_covering:
		yield(get_tree().create_timer(.5), "timeout")
		Transition.garage_down()
	
	$Camera2D/UI/LevelNum.text = str(Singleton.level_num)
	
	if Singleton.level != "":
		level_text = Singleton.level
	if OS.has_feature('JavaScript'):
		var potential_level = JavaScript.eval(""" 
				var url_string = window.location.href;
				var url = new URL(url_string);
				url.searchParams.get("level");
			""")
		if potential_level:
			Singleton.level_num = -1
			level_text = potential_level
			
	if Singleton.level_num == 1:
		$Level1.visible=true
	elif Singleton.level_num == 2:
		$Level2.visible=true
	elif Singleton.level_num == Singleton.levels.size():
		$LastLevel.visible = true
	
	var level_1_line = level_text.replace("\n","")
	level_1_line = level_1_line.replace("\r\n","")
	level_1_line = level_1_line.replace("\r","")
	
	Singleton.rng.set_seed(hash(level_1_line))

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
					#player_parts.push_back( player_part_object.new(Vector2(x,y), new_player) )
					main_players.push_back( new_player )
					new_player.grid_position = Vector2(x,y)
				BODY:
					var new_body = body_tscn.instance()
					new_body.position = Vector2(x*square_size+square_size/2, y*square_size+square_size/2)
					new_body.grid_position = Vector2(x, y)
					add_child(new_body)
					level[y][x].node = new_body
				FINISH:
					var new_finish = finish_tscn.instance()
					new_finish.position = Vector2(x*square_size+square_size/2, y*square_size+square_size/2)
					add_child(new_finish)
					level[y][x].node = new_finish
					goal_count += 1
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
		
	
	if Input.is_action_pressed("ui_left"):
		dir_held_counts[0]+=delta
	elif Input.is_action_pressed("ui_right"):
		dir_held_counts[1]+=delta
	elif Input.is_action_pressed("ui_up"):
		dir_held_counts[2]+=delta
	elif Input.is_action_pressed("ui_down"):
		dir_held_counts[3]+=delta
	
	for x in range(4):
		if dir_held_counts[x] > initial_hold:
			if dir_held_counts[x] >= initial_hold+additional_hold:
				dir_held_counts[x] -= additional_hold
				var dirs = [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]
				attempt_move(dirs[x].x,dirs[x].y)
		
	if Input.is_action_just_released("ui_left"):
		dir_held_counts[0]=0
	if Input.is_action_just_released("ui_right"):
		dir_held_counts[1]=0
	if Input.is_action_just_released("ui_up"):
		dir_held_counts[2]=0
	if Input.is_action_just_released("ui_down"):
		dir_held_counts[3]=0
		
	if Input.is_action_just_pressed("c"):
		OS.set_clipboard(level_text)
	if Input.is_action_just_pressed("v"):
		print(OS.get_clipboard())
		Singleton.level_num=-1
		Singleton.level = OS.get_clipboard()
		Transition.garage_up()
		yield(Transition, "garage_up")
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("r"):
		Transition.is_retry = true
		Transition.garage_up()
		yield(Transition, "garage_up")
		get_tree().reload_current_scene()
		
func attempt_move(x,y):
	if won:
		return
	#must check that every body part not blocked to move to new spot
	
	var goals_covered = 0
	for main_player in main_players:
		var safe_move=true
		for part in main_player.body_parts:
			#make sure inside bounds of screen
			var new_x = part.grid_position.x+x
			var new_y = part.grid_position.y+y
			
			#no ground = not safe
			if level[new_y][new_x].is_ground == false:
				safe_move = false
			
		if safe_move:
			
			#go through all player parts and update them
			var new_body_parts=[]
			for part in main_player.body_parts:
				
				var new_x = part.grid_position.x+x
				var new_y = part.grid_position.y+y
				
				part.grid_position = Vector2(new_x, new_y)
				part.set_target( grid_to_world(part.grid_position) )
				
				if level[new_y][new_x].tile_type == FINISH:
					goals_covered += 1
				
				#readd original
				#new_body_parts.push_back( player_part_object.new(Vector2(new_x,new_y), part.node) )
				
				#Check if one of 4 neighbors is a bodypart
				for neighbor in [Vector2(-1,0), Vector2(1,0), Vector2(0,1), Vector2(0,-1)]:
					var check_x = new_x+neighbor.x
					var check_y = new_y+neighbor.y
					if level[check_y][check_x].tile_type == BODY:
						level[check_y][check_x].tile_type = EMPTY
						print("JOINED")
						$Attach.play()
						
						#create spark inbetween two spots
						var new_explosion = explosion_tscn.instance()
						add_child(new_explosion)
						new_explosion.position = grid_to_world( Vector2(new_x+neighbor.x/2, new_y+neighbor.y/2) )
						$Camera2D.add_trauma(1.0)
						$Camera2D/UI.animation = "activate"
						
						#add new
						new_body_parts.push_back( level[check_y][check_x].node )
						level[check_y][check_x].node.activate(neighbor)
			
			for new_part in new_body_parts:
				main_player.body_parts.push_back(new_part)
			$Move.play()
			
			
		else:
			for part in main_player.body_parts:
				if level[part.grid_position.y][part.grid_position.x].tile_type == FINISH:
					goals_covered += 1
			$BadMove.play()
			$Camera2D.add_trauma(1.0)
	if goals_covered == goal_count:
		do_win()
		
func do_win():
	$Camera2D.add_trauma(1.0)
	$Camera2D/UI.animation = "activate"
	won = true
	$Win.play()
	print("YAY WIN")
	
	if Singleton.level_num == 1:
		$Level1/Sign.playing = true
		Song.play()
		yield(get_tree().create_timer(3.0), "timeout")
		
	if Singleton.level_num != -1:
		Singleton.level_num += 1
		if Singleton.level_num<Singleton.levels.size()+1:
			print("LEVEL CHANGE BABY")
			Singleton.level = Singleton.levels[Singleton.level_num-1]
			
	if Singleton.level_num == Singleton.levels.size()+1:
		$LastLevel/AnimatedSprite.animation="activated"
		return
		
	Transition.garage_up()
	yield(Transition, "garage_up")
	
	if Singleton.level_num==Singleton.levels.size()+1:
		get_tree().change_scene_to(game_over_tscn)
		return
	get_tree().reload_current_scene()
	
func grid_to_world(position):
	return Vector2(position.x*square_size+square_size/2, position.y*square_size+square_size/2)
