extends Node

onready var levels = get_node("/root/Levels")

func _ready():
	print("Test2")
	
	levels.test()
