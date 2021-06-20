extends Node2D

var rng = RandomNumberGenerator.new()
var main = preload("res://Main.tscn")

export(int) var lower_finish_count
export(int) var upper_finish_count
export(int) var margin = 2
export(int) var stray_power = 60
#if it can lay, how often does it choose lay over walk?
export(float) var lay_percentage = .1

export(bool) var auto_step = true
export(float) var auto_step_time = .1

export(int) var max_moves = 100

var step_cur = 0


var rand_walk_angle

var level_text="""000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000
000000000000000000000000"""
var width = 24
var height = 14
var square_size = 16
var fresh_level = true

var level = []

var GenTile = preload("res://GenTile.tscn")
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

var bodies = []

var goal_count = 0

var won = false
var finished = false

func _ready():
	
	rng.randomize()
	
	if Transition.garage_covering:
		yield(get_tree().create_timer(.5), "timeout")
		Transition.garage_down()
	
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
			var new_gen_tile = GenTile.instance()
			add_child(new_gen_tile)
			new_gen_tile.position = Vector2(x*square_size+square_size/2, y*square_size+square_size/2)
			new_gen_tile.animation = "wall"
			level[y][x].node = new_gen_tile
				
func _update_sprites():
		for y in range(height):
			for x in range(width):
				match level[y][x].tile_type:
					EMPTY:
						level[y][x].node.animation="wall"
					GROUND:
						level[y][x].node.animation="ground"
					PLAYER:
						level[y][x].node.animation="player"
					BODY:
						level[y][x].node.animation="body"
					FINISH:
						level[y][x].node.animation="finish"
						
		# go through player array

func _process(delta):
	if auto_step and finished==false:
		step_cur += delta
		if step_cur > auto_step_time:
			step_cur -= auto_step_time
			gen_level_step()
			_update_sprites()
	
	if Input.is_action_just_pressed("ui_right"):
		if finished:
			return
		gen_level_step()
		_update_sprites()
	pass
	
	if Input.is_action_just_pressed("r"):
		$Stuck.visible = false
		finished = false
		for y in range(height):
			for x in range(width):
				level[y][x].tile_type=WALL
		for part in player_parts:
			part.queue_free()
		player_parts = []
		_update_sprites()
		fresh_level = true
		
	if Input.is_action_just_pressed("c"):
		var cur_move_count = 0
		while !(finished) and cur_move_count<max_moves:
			cur_move_count += 1
			gen_level_step()
		_update_sprites()
	
	if Input.is_action_just_pressed("ui_down"):
		Singleton.level_num = -1
		
		var cur_text = ""
		for y in range(height):
			for x in range(width):
				cur_text += str(level[y][x].tile_type)
				
		Singleton.level = cur_text
		
		get_tree().change_scene_to(main)
	
func gen_level_step():
	
	if fresh_level:
		fresh_level = false
		_make_start()
		rand_walk_angle = rng.randi()%360
	else:
		rand_walk_angle += rng.randi_range(-stray_power,stray_power)
		#possible options:
			#move left, up, right, down [X]
				#cant move adjacent to a placed body part
			#drop a body part 
				#
		var seen = {}
		var possible_moves=[]
		for dir in [Vector2(0,1), Vector2(0,-1), Vector2(-1,0), Vector2(1,0)]:
			var valid = true
			for part in player_parts:
				if not valid:
					break
				
				var new_location = part.grid_pos+dir
				if (new_location.x >= margin and new_location.x <= width-margin-1
					and new_location.y >= margin and new_location.y <= height-margin-1
					and (level[new_location.y][new_location.x].tile_type!=BODY)):
						#must check not moving adjacent to a body part
						for dir2 in [Vector2(0,1), Vector2(0,-1), Vector2(-1,0), Vector2(1,0)]:
							var new_new_location = new_location+dir2
							if level[new_new_location.y][new_new_location.x].tile_type == BODY:
								valid = false
								break 
				else:
					valid = false
					break
			
			if valid:
				possible_moves.push_back(dir)
				seen[str(dir)]=true
				
		var possible_body_lays=[]
		for part in player_parts:
			var layable = true
			#can not lay body part on finish
			if level[part.grid_pos.y][part.grid_pos.x].tile_type == FINISH:
				layable = false
				
			#can only lay body part if not adjacent to another body part
			if layable:
				for dir in [Vector2(0,1), Vector2(0,-1), Vector2(-1,0), Vector2(1,0)]:
					var check_spot=part.grid_pos+dir
					if level[check_spot.y][check_spot.x].tile_type == BODY:
						layable = false 
						break
			
			#structure must be sound if>2 after removing that block
			if player_parts.size()>2:
#				print("CHECKING IF")
#				print(part.grid_pos)
#				print("IS SOUND FOR REMOVAL:")
				
				#create dictionary of player blocks
				#do BFS from rando block to make sure you can reach everything
				
				var potential_island = {}
				for island_part in player_parts:
					if island_part != part:
						potential_island[str(island_part.grid_pos)]=true
				
				var number_to_see = potential_island.size()
				
				if bfs(potential_island)!=number_to_see:
					layable=false
					
			if layable:
				#im not trying to make these sexual innuendos i swear
				possible_body_lays.push_front(part.grid_pos)
			
		print("possible lays:")
		print(possible_body_lays)
		
		var laying = false
		if possible_body_lays!=[] and possible_moves!=[]:
			var random_val = rng.randf_range(0,1)
			if random_val<lay_percentage:
				laying = true
		elif possible_moves==[]:
			if possible_body_lays==[]:
				print("STUCK OH NO")
				$Stuck.visible = true
				return
			laying = true
			
		if laying:
			if player_parts.size()==1:
				finished = true
				level[player_parts[0].grid_pos.y][player_parts[0].grid_pos.x].tile_type = PLAYER
			else:
				#do lay
				var random_lay = possible_body_lays[randi()%possible_body_lays.size()]
				
				print("LAYING")
				
				var new_player_parts = []
				for part in player_parts:
					if part.grid_pos == random_lay:
						level[random_lay.y][random_lay.x].tile_type = BODY
						part.queue_free()
					else:
						new_player_parts.push_back(part)
					
					player_parts = new_player_parts
		else: 
			#do walk
			var quantized_rand_walk = int(rand_walk_angle/90)*90
			quantized_rand_walk = Vector2(int(cos(deg2rad(quantized_rand_walk))),int(sin(deg2rad(quantized_rand_walk))))
			if quantized_rand_walk.y == -0:
				quantized_rand_walk = Vector2(quantized_rand_walk.x, 0)
			if quantized_rand_walk.x == -0:
				quantized_rand_walk = Vector2(0, quantized_rand_walk.y)
			
			var chosen_move
			if str(quantized_rand_walk) in seen:
				chosen_move = quantized_rand_walk
			else:
				rand_walk_angle+=180
				chosen_move = possible_moves[rng.randi()%possible_moves.size()]
				
			for part in player_parts:
				part.grid_pos = part.grid_pos+chosen_move
				part.position = grid_to_world(part.grid_pos)
				if level[part.grid_pos.y][part.grid_pos.x].tile_type != FINISH:
					level[part.grid_pos.y][part.grid_pos.x].tile_type=GROUND
	
	pass
	
func bfs(input_dict):
	var first = str2var("Vector2"+input_dict.keys()[0])
	var to_explore = [first]
	var count = 1
	var seen = {}
	seen[str(first)]=true
	
	while to_explore != []:
		var current = to_explore.pop_front()
		#check dirs		
		for dir in [Vector2(0,1), Vector2(0,-1), Vector2(-1,0), Vector2(1,0)]:
			var check_spot=current+dir
			
			if !(str(check_spot) in seen) and (str(check_spot) in input_dict):
				seen[str(check_spot)] = true
				to_explore.push_back(check_spot)
				count += 1
	
	return count
	
func _make_start():
	var ends = []
	var random_end = Vector2(rng.randi_range(margin,width-margin-1), rng.randi_range(margin,height-margin-1))
	
	level[random_end.y][random_end.x].tile_type = FINISH
	
	ends.push_back(random_end)
	var random_end_cur=1
	var random_end_amount=rng.randi_range(lower_finish_count, upper_finish_count)
	
	#print("making a: " + str(random_end_amount))
	
	while random_end_cur<random_end_amount:
		#add more ends based on walks from currents
		# get all possible next ends
		var possible = []
		for end in ends:
			for neighbor in [Vector2(-1,0),Vector2(1,0),Vector2(0,1),Vector2(0,-1)]:
				var possibility = end+neighbor
				if (level[possibility.y][possibility.x].tile_type!=FINISH 
					and (possibility in ends)==false and possibility.y>=margin 
					and possibility.x>=margin and possibility.x<=width-margin-1 
					and possibility.y<height-margin-1):
					possible.push_back(possibility)
					
					
		if (possible.size() == 0):
			print("no more possible lol")
			return
		
		var new_rand_end = possible[rng.randi()%possible.size()]
		level[new_rand_end.y][new_rand_end.x].tile_type = FINISH
		ends.push_back(new_rand_end)
		
		random_end_cur+=1
		
	for end in ends:
		#lets make a player on that end!
		var new_gen_tile = GenTile.instance()
		add_child(new_gen_tile)
		new_gen_tile.position = Vector2(end.x*square_size+square_size/2, end.y*square_size+square_size/2)
		new_gen_tile.animation = "player"
		new_gen_tile.grid_pos=end
		player_parts.push_back(new_gen_tile)
		new_gen_tile.grid_pos = Vector2(end.x, end.y)

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
		pass
		#do_win()
	
func grid_to_world(position):
	return Vector2(position.x*square_size+square_size/2, position.y*square_size+square_size/2)
