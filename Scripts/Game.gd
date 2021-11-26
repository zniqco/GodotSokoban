extends Node

onready var levels = get_node("/root/Levels")
onready var map = $TileMap

onready var tile_floor = map.tile_set.find_tile_by_name("floor")
onready var tile_wall = map.tile_set.find_tile_by_name("wall")
onready var tile_box = map.tile_set.find_tile_by_name("box")
onready var tile_box_on = map.tile_set.find_tile_by_name("box_on")
onready var tile_goal = map.tile_set.find_tile_by_name("goal")
onready var tile_player = map.tile_set.find_tile_by_name("player")
onready var tile_player_on = map.tile_set.find_tile_by_name("player_on")

var begin_x: int
var begin_y: int
var end_x: int
var end_y: int
var current_level = 0
var states = []

class State:
	var h: int
	var v: int
	var pushed: bool

func _ready():
	levels.load_levels("res://Levels/Default.txt")
	load_level(current_level)
	
func _input(event):
	if event.is_action_pressed("ui_left"):
		move_player(-1, 0)
	if event.is_action_pressed("ui_right"):
		move_player(1, 0)
	if event.is_action_pressed("ui_up"):
		move_player(0, -1)
	if event.is_action_pressed("ui_down"):
		move_player(0, 1)
	if event.is_action_pressed("ui_undo"):
		if states.size() >= 1:
			var position = get_player_position()
			var state = states.pop_back()

			if map.get_cell(position[0], position[1]) == tile_player_on:
				map.set_cell(position[0], position[1], tile_goal)
			else:
				map.set_cell(position[0], position[1], tile_floor)
			
			if map.get_cell(position[0] - state.h, position[1] - state.v) == tile_goal:
				map.set_cell(position[0] - state.h, position[1] - state.v, tile_player_on)
			else:
				map.set_cell(position[0] - state.h, position[1] - state.v, tile_player)
				
			if state.pushed:
				if map.get_cell(position[0] + state.h, position[1] + state.v) == tile_box_on:
					map.set_cell(position[0] + state.h, position[1] + state.v, tile_goal)
				else:
					map.set_cell(position[0] + state.h, position[1] + state.v, tile_floor)
					
				if map.get_cell(position[0], position[1]) == tile_goal:
					map.set_cell(position[0], position[1], tile_box_on)
				else:
					map.set_cell(position[0], position[1], tile_box)

func move_player(h: int, v: int):
	var is_moved = false
	var position = get_player_position()
	var cell = get_cell(position[0], position[1])
	var remain: int
	
	if cell == tile_player_on:
		remain = tile_goal
	else:
		remain = tile_floor

	match get_cell(position[0] + h, position[1] + v):
		tile_floor:
			map.set_cell(position[0], position[1], remain)
			map.set_cell(position[0] + h, position[1] + v, tile_player)

			append_state(h, v, false)
			
		tile_goal:
			map.set_cell(position[0], position[1], remain)
			map.set_cell(position[0] + h, position[1] + v, tile_player_on)
			
			append_state(h, v, false)
			
		tile_box:
			match get_cell(position[0] + h * 2, position[1] + v * 2):
				tile_floor:
					map.set_cell(position[0], position[1], remain)
					map.set_cell(position[0] + h, position[1] + v, tile_player)
					map.set_cell(position[0] + h * 2, position[1] + v * 2, tile_box)
					
					append_state(h, v, true)
					
				tile_goal:
					map.set_cell(position[0], position[1], remain)
					map.set_cell(position[0] + h, position[1] + v, tile_player)
					map.set_cell(position[0] + h * 2, position[1] + v * 2, tile_box_on)
					
					append_state(h, v, true)
					
		tile_box_on:
			match get_cell(position[0] + h * 2, position[1] + v * 2):
				tile_floor:
					map.set_cell(position[0], position[1], remain)
					map.set_cell(position[0] + h, position[1] + v, tile_player_on)
					map.set_cell(position[0] + h * 2, position[1] + v * 2, tile_box)
					
					append_state(h, v, true)
					
				tile_goal:
					map.set_cell(position[0], position[1], remain)
					map.set_cell(position[0] + h, position[1] + v, tile_player_on)
					map.set_cell(position[0] + h * 2, position[1] + v * 2, tile_box_on)
					
					append_state(h, v, true)

	# Check cleared
	for y in range(begin_y, end_y):
		for x in range(begin_x, end_x):
			if map.get_cell(x, y) == tile_box:
				return
	
	current_level += 1
	load_level(current_level)
	
func get_cell(x: int, y: int):
	if x < begin_x or y < begin_y or x >= end_x or y >= end_y:
		return -1
		
	return map.get_cell(x, y)
	
func get_player_position():
	for y in range(begin_y, end_y):
		for x in range(begin_x, end_x):
			var cell = map.get_cell(x, y)
			match cell:
				tile_player, tile_player_on:
					return [x, y]
					
	return [-1, -1]

func append_state(h: int, v: int, pushed: bool):
	var state = State.new()
	
	state.h = h
	state.v = v
	state.pushed = pushed
	
	states.append(state)
	
func load_level(index: int):
	var level = levels.get_level(index)
	
	map.clear()
	states.clear()

	for y in level.size():
		var line = level[y]
		
		for x in line.length():
			match line[x]:
				'#':
					map.set_cell(x, y, tile_wall)
				'.':
					map.set_cell(x, y, tile_goal)
				'$':
					map.set_cell(x, y, tile_box)
				'*':
					map.set_cell(x, y, tile_box_on)
				'@':		
					map.set_cell(x, y, tile_player)
				'+':		
					map.set_cell(x, y, tile_player_on)
					
	# Fill floor
	var used_cells = map.get_used_rect()
	
	begin_x = used_cells.position.x
	end_x = used_cells.position.x + used_cells.end.x
	begin_y = used_cells.position.y
	end_y = used_cells.position.y + used_cells.end.y
	
	for y in range(begin_y, end_y):
		for x in range(begin_x, end_x):
			match map.get_cell(x, y):
				tile_goal, tile_box, tile_box_on:
					fill_floor(x, y, used_cells.end.x, used_cells.end.y, true)
			
func fill_floor(x: int, y: int, width: int, height: int, forced: bool):
	var branch = forced
	
	if map.get_cell(x, y) == -1:
		map.set_cell(x, y, tile_floor)
		branch = true
	
	if branch:
		if x >= 1:
			fill_floor(x - 1, y, width, height, false)
		if y >= 1:
			fill_floor(x, y - 1, width, height, false)
		if x < width:
			fill_floor(x + 1, y, width, height, false)
		if y < height:
			fill_floor(x, y + 1, width, height, false)
