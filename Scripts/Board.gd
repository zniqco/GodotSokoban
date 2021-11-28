extends Node2D
class_name Board

onready var levels = get_node("/root/Levels")
onready var player = load("res://Scenes/Player.tscn").instance()
onready var map = $Window/TileMap

onready var tile_floor = map.tile_set.find_tile_by_name("floor")
onready var tile_wall = map.tile_set.find_tile_by_name("wall")
onready var tile_box = map.tile_set.find_tile_by_name("box")
onready var tile_box_on = map.tile_set.find_tile_by_name("box_on")
onready var tile_goal = map.tile_set.find_tile_by_name("goal")

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
	player.set_board(self)
	map.add_child(player)

	levels.load_levels("res://Levels/Default.txt")
	load_level(current_level)
	
	on_resized()
	get_tree().get_root().connect("size_changed", self, "on_resized")
	
func on_resized():
	var viewport_size = get_viewport_rect().size
	var map_width = max(1, end_x - begin_x)
	var map_height = max(1, end_y - begin_y)
	var board_width = map_width * map.cell_size.x
	var board_height = map_height * map.cell_size.y
	var margin = min(viewport_size.x / 1.25 / map_width, viewport_size.y / 1.25 / map_height)
	var scale = min((viewport_size.x - margin) / board_width, (viewport_size.y - margin) / board_height)

	map.scale = Vector2(scale, scale)
	map.position = Vector2((viewport_size.x - board_width * scale) / 2, (viewport_size.y - board_height * scale) / 2)
	
func _input(event):
	if event.is_action_pressed("ui_page_up"):
		previous_level()
	if event.is_action_pressed("ui_page_down"):
		next_level()
	if event.is_action_pressed("ui_undo"):
		if states.size() >= 1:
			var state = states.pop_back()

			if state.pushed:
				if get_cell(player.x + state.h, player.y + state.v) == tile_box_on:
					set_cell(player.x + state.h, player.y + state.v, tile_goal)
				else:
					set_cell(player.x + state.h, player.y + state.v, tile_floor)
					
				if get_cell(player.x, player.y) == tile_goal:
					set_cell(player.x, player.y, tile_box_on)
				else:
					set_cell(player.x, player.y, tile_box)
					
			player.move(-state.h, -state.v)
					
func move_player(h: int, v: int):
	var next_cell = get_cell(player.x + h, player.y + v)
	
	match next_cell:
		tile_floor, tile_goal:
			player.move(h, v)
			append_state(h, v, false)

		tile_box, tile_box_on:
			var next_next_cell = get_cell(player.x + h * 2, player.y + v * 2)
			
			match next_next_cell:
				tile_floor, tile_goal:
					if next_cell == tile_box_on:
						set_cell(player.x + h, player.y + v, tile_goal)
					else:
						set_cell(player.x + h, player.y + v, tile_floor)

					if next_next_cell == tile_goal:
						set_cell(player.x + h * 2, player.y + v * 2, tile_box_on)
					else:
						set_cell(player.x + h * 2, player.y + v * 2, tile_box)
					
					player.move(h, v)
					append_state(h, v, true)

	# Check cleared
	for y in range(begin_y, end_y):
		for x in range(begin_x, end_x):
			if get_cell(x, y) == tile_box:
				return
	
	next_level()

func get_cell(x: int, y: int):
	if x < begin_x or y < begin_y or x >= end_x or y >= end_y:
		return -1
		
	return map.get_cell(x, y)

func set_cell(x: int, y: int, tile: int):
	map.set_cell(x, y, tile)

func append_state(h: int, v: int, pushed: bool):
	var state = State.new()
	
	state.h = h
	state.v = v
	state.pushed = pushed
	
	states.append(state)
	
func previous_level():
	if current_level >= 1:
		current_level -= 1
		load_level(current_level)
		
		return true
		
	return false
	
func next_level():
	if current_level < levels.count() - 1:
		current_level += 1
		load_level(current_level)

		return true
		
	return false
	
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
					player.move_to(x, y)
				'+':
					player.move_to(x, y)
					map.set_cell(x, y, tile_goal)

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

	# Force resize
	on_resized()
			
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
