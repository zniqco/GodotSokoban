extends Node

enum {
	NONE,
	LEVEL,
}

var levels = []

func load_levels(filename: String):
	var file = FileAccess.open(filename, FileAccess.READ)
	var state = NONE
	var lines = []
	
	levels.clear()
	
	while !file.eof_reached():
		var line = file.get_line()
		var first_character = ""
		
		if line.length() >= 1:
			first_character = line.left(1)

		if state == NONE:
			if first_character != "" and first_character != ";":
				state = LEVEL
					
		if state == LEVEL:
			if first_character == ";":
				levels.append(lines)
				lines = []
				state = NONE
			else:
				lines.append(line)
	
	file.close()

func get_level(index: int):
	return levels[index]

func count():
	return levels.size()
