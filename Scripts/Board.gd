extends Node2D
class_name Board

const TILE_WALL = 0
const TILE_FLOOR = 1
const TILE_BOX = 2
const TILE_BOX_ON = 3
const TILE_GOAL = 4

@onready var levels = get_node("/root/Levels")
@onready var player = load("res://Scenes/Player.tscn").instantiate()
@onready var map: TileMap = $Window/TileMap
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
	get_tree().get_root().connect("size_changed", Callable(self, "on_resized"))
	
func on_resized():
	var viewport_size = get_viewport_rect().size
	var map_rect = map.get_used_rect()
	var map_width = map_rect.size.x
	var map_height = map_rect.size.y
	var board_width = map_width * map.tile_set.tile_size.x
	var board_height = map_height * map.tile_set.tile_size.y
	var margin = min(viewport_size.x * 0.8 / map_width, viewport_size.y * 0.8 / map_height)
	var scale = min((viewport_size.x - margin) / board_width, (viewport_size.y - margin) / board_height)

	map.scale = Vector2(scale, scale)
	map.position = Vector2((viewport_size.x - board_width * scale) / 2, (viewport_size.y - board_height * scale) / 2)
	
func _input(event):
	if event.is_action_pressed("ui_page_up"):
		previous_level()
		
	if event.is_action_pressed("ui_page_down"):
		next_level()
		
	if event.is_action_pressed("ui_restart"):
		load_level(current_level)
		
	if event.is_action_pressed("ui_undo"):
		if states.size() >= 1:
			var state = states.pop_back()

			if state.pushed:
				if get_cell(player.x + state.h, player.y + state.v) == TILE_BOX_ON:
					set_cell(player.x + state.h, player.y + state.v, TILE_GOAL)
				else:
					set_cell(player.x + state.h, player.y + state.v, TILE_FLOOR)
					
				if get_cell(player.x, player.y) == TILE_GOAL:
					set_cell(player.x, player.y, TILE_BOX_ON)
				else:
					set_cell(player.x, player.y, TILE_BOX)
					
			player.move(-state.h, -state.v)
					
func move_player(h: int, v: int):
	var next_cell = get_cell(player.x + h, player.y + v)
	
	match next_cell:
		TILE_FLOOR, TILE_GOAL:
			player.move(h, v)
			append_state(h, v, false)

		TILE_BOX, TILE_BOX_ON:
			var next_next_cell = get_cell(player.x + h * 2, player.y + v * 2)
			
			match next_next_cell:
				TILE_FLOOR, TILE_GOAL:
					if next_cell == TILE_BOX_ON:
						set_cell(player.x + h, player.y + v, TILE_GOAL)
					else:
						set_cell(player.x + h, player.y + v, TILE_FLOOR)

					if next_next_cell == TILE_GOAL:
						set_cell(player.x + h * 2, player.y + v * 2, TILE_BOX_ON)
					else:
						set_cell(player.x + h * 2, player.y + v * 2, TILE_BOX)
					
					player.move(h, v)
					append_state(h, v, true)

	# Check cleared
	var map_rect = map.get_used_rect()

	for y in range(map_rect.position.y, map_rect.end.y):
		for x in range(map_rect.position.x, map_rect.end.x):
			if get_cell(x, y) == TILE_BOX:
				return
	
	next_level()

func get_cell(x: int, y: int):
	var map_rect = map.get_used_rect()

	if x < map_rect.position.x or y < map_rect.position.y or x >= map_rect.end.x or y >= map_rect.end.y:
		return -2

	return map.get_cell_source_id(0, Vector2i(x, y))

func set_cell(x: int, y: int, tile: int):
	map.set_cell(0, Vector2i(x, y), tile, Vector2i(0, 0))

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
					set_cell(x, y, TILE_WALL)
				'.':
					set_cell(x, y, TILE_GOAL)
				'$':
					set_cell(x, y, TILE_BOX)
				'*':
					set_cell(x, y, TILE_BOX_ON)
				'@':
					player.move_to(x, y)
				'+':
					player.move_to(x, y)
					set_cell(x, y, TILE_GOAL)

	# Fill floor
	var map_rect = map.get_used_rect()
	
	for y in range(map_rect.position.y, map_rect.end.y):
		for x in range(map_rect.position.x, map_rect.end.x):
			match get_cell(x, y):
				TILE_GOAL, TILE_BOX, TILE_BOX_ON:
					fill_floor(x, y, true)

	# Force resize
	on_resized()
			
func fill_floor(x: int, y: int, forced: bool):
	var branch = forced
	
	if get_cell(x, y) == -1:
		set_cell(x, y, TILE_FLOOR)
		branch = true
	
	if branch:
		fill_floor(x - 1, y, false)
		fill_floor(x, y - 1, false)
		fill_floor(x + 1, y, false)
		fill_floor(x, y + 1, false)
