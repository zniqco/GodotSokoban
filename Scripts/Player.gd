extends Node2D

var board: Board
var x: int = 0
var y: int = 0

func set_board(board: Board):
	self.board = board

func move(h: int, v: int):
	move_to(x + h, y + v)

func move_to(x: int, y: int):
	var map = board.map
	
	self.x = x
	self.y = y
	
	position = Vector2(x * map.cell_size.x, y * map.cell_size.y)

func _input(event):
	if board != null:
		if event.is_action_pressed("ui_left"):
			board.move_player(-1, 0)
		if event.is_action_pressed("ui_right"):
			board.move_player(1, 0)
		if event.is_action_pressed("ui_up"):
			board.move_player(0, -1)
		if event.is_action_pressed("ui_down"):
			board.move_player(0, 1)
