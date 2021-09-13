extends Node2D

export(int, 200) var lengthX
export(int, 200) var lengthY


var ship_timer = 0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#var pos = Vector2(0,0)
#var cell_list = {Vector2(0,0) : 1}
#var pattern = { Vector2(0, 0) : 1}, Vector2(1,0) : 1, Vector2(2,0) : 1, Vector2(2,-1) : 1, Vector2(1,-2) : 1}
var bounds = [Vector2(-1,-1), Vector2(-1, 0), Vector2(-1, 1), Vector2(0,-1), Vector2(0,1), Vector2(1,-1), Vector2(1,0), Vector2(1,1)]

var TOOBIG = 10
var prev_delta = 0.0
var neighbor_list = {}
var pattern = Dictionary()
var cell_list = Dictionary()
var glider = Dictionary()
var ship = Dictionary()
var gun = Dictionary()
var snark = Dictionary()
var eater = Dictionary()
var go = Dictionary()
var generation = 0



# Stuff for score
var zero = load_file("rle/zero.rle")
var one = load_file("rle/one.rle")
var two = load_file("rle/two.rle")
var three = load_file("rle/three.rle")
var four = load_file("rle/four.rle")
var five = load_file("rle/five.rle")
var six = load_file("rle/six.rle")
var seven = load_file("rle/seven.rle")
var eight = load_file("rle/eight.rle")
var nine = load_file("rle/nine.rle")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var top_map = $TopMap
	top_map.clear()
	
	# Clear board
	for i in range(-lengthX/2, lengthX/2):
		for j in range(-lengthY/2, lengthY/2):
			#top_map.set_cell(i, j, (i*i+j*j) % 2)
			top_map.set_cell(i, j, 2)

	# Load .rle pattern files
	var acorn  = load_file("rle/acorn.rle")
	glider = load_file("rle/glider.rle")
	var bar = load_file("rle/bar.rle")
	var border = load_file("rle/border.rle")
	var score = load_file("rle/score.rle")
	var lwss = load_file("rle/natural-LWSS.rle")
	var traffic = load_file("rle/traffic.rle")
	ship = load_file("rle/lwss.rle")
	gun = load_file("rle/gun.rle")
	snark = load_file("rle/snark.rle")
	eater = load_file("rle/eater.rle")
	go = load_file("rle/go.rle")
	
	#load_pattern(acorn, cell_list, 20, 20)
	
	load_pattern(border, cell_list, -55, -70)
	load_pattern(border, cell_list, 51, -70)
	load_pattern(bar, cell_list, -30, -80)
	#load_pattern(score, cell_list, -80, -35)
	load_pattern(traffic, cell_list, -15, -40)
	#load_pattern(gun, cell_list, -10, -65)
	#load_pattern(eater, cell_list, -23, -14)
	#load_pattern(lwss, cell_list, 0, 0)
	load_pattern(go, cell_list, 0, 30)
		
	#load_pattern(glider, cell_list, 0, 80)
#	load_pattern(glider, cell_list, -10, 0)
	#show_score(100, cell_list, -95, -20)
	
	# Draw first generation
	for k in cell_list:
		top_map.set_cell(k.x, k.y, 2)
		
	# Start timer
	var timer = Timer.new()
	timer.connect("timeout", self, "_on_timer_timeout") 
	#timeout is what says in docs, in signals
	#self is who respond to the callback
	#_on_timer_timeout is the callback, can have any name
	add_child(timer) #to process
	timer.set_wait_time(.01)
	timer.start() #to start
	
##########################################################
# Find the neighbor count for all cells in cell list
##########################################################

func neighbor_cnt(list):
	neighbor_list.clear()
	for k in list:		
		# Check the eight neighbors		
		for b in bounds:
			var vec = Vector2(k.x + b.x, k.y + b.y)
			if neighbor_list.has(vec):
				neighbor_list[vec] += 1
			else:
				neighbor_list[vec] = 1
				
		# Check if this cell is isolated
		if ! neighbor_list.has(Vector2(k.x, k.y)):
			neighbor_list[Vector2(k.x, k.y)] = 0
				
	return neighbor_list

var score_ = 100
var delay = 250
###############################################################
# Timer callback
###############################################################
func _on_timer_timeout():
	var cnt
	var top_map = $TopMap
	var list
	
	if ship_timer == 100:
		load_pattern(ship, cell_list, 33, -55)
		show_score(str(score_), cell_list, -78, -35)
		score_ += 1
	elif ship_timer == 200:
		load_pattern(ship, cell_list, -30, -55)
		show_score(str(score_), cell_list, -78, -35)
		score_ += 1
		
		
		
		ship_timer = 0
		
	ship_timer += 1	
	
	
	
	if delay == 0:
		list = neighbor_cnt(cell_list)
		
		
		
		var population = cell_list.size()
		#print("Gen = ", generation, " Pop = ", population)
		generation += 1
		
		for cell in list:
			cnt = list.get(cell)
			
			match cnt:
				0, 1:
					if cell_list.has(cell):
						cell_list[cell] = 2
				2,3:
					if cnt == 3:
						if !cell_list.has(cell):
							cell_list[cell] = 0
				_:
					if cell_list.has(cell):
						cell_list[cell] = 2
	else:
		delay -= 1
			
	# Output cell_list to board
	for c in cell_list.keys():
		top_map.set_cell(c.x, c.y, cell_list[c])
		if cell_list.get(c) == 2:
			cell_list.erase(c)
			
###############################################################
# Open and load .rle pattern file
###############################################################
func load_file(filename):
	var result = {}
	var f = File.new()
	f.open(filename, 1)
	var index = 1
  
	while not f.eof_reached():
		var line = f.get_line()
		result[str(index)] = line
		index += 1

	f.close()			
	return parse_rle(result)
	

###############################################################
# Parse a .rle pattern file
###############################################################
func parse_rle(lines):

	var x_max = 0
	var y_max = 0
	var rule = ""
	var rule_read = false
	
	var regex = RegEx.new()
	regex.compile("[\\d]+|[b,o,B,O]|\\$|\\!")
	var x = 0
	var y = 0
	var repeat = 1
	var pattern = Dictionary()
		
	# Skip header lines
	for l in lines:
		if  lines[l].empty() or lines[l].substr(0, 1) == '#':
			continue
#		print(lines[l])	
		
		# Find the rule
		if rule_read == false:
			rule_read = true
			var sub = lines[l].split(",", false)
			
			for i in range(0, sub.size()):
				var sub2 = sub[i].split("=", false)
				match i:
					0:
						x_max = sub2[1].to_int()
					1:
						y_max = sub2[1].to_int()
						
			#print(x_max, " ", y_max)
			continue

		# Get the RLE data
				
		var res = regex.search(lines[l])
		
		while res != null:
			#print (res.get_string(0))
			if res.get_string(0).is_valid_integer():
				repeat = res.get_string(0).to_int()
			else:
				var c = res.get_string(0)
				match c:
					"o", "O":
						while repeat >= 1:
							pattern[Vector2(x, y)] = 1
							# print("Create V2 ", x, " ", y, " ", 1)
							x += 1
							repeat -= 1
					"b", "B":
						while repeat >= 1:
							# print("Create V2 ", x, " ", y, " ", 0)
							x += 1
							repeat -= 1
					"$":
						while repeat >= 1:
							y += 1
							x = 0
							repeat -= 1
					"!":
						return pattern
	
				repeat = 1
				
			res = regex.search(lines[l], res.get_end(0))		
		
	return pattern.clear()
	
###############################################################
# Get mouse input
###############################################################	
func _input(event):
	var top_map = $TopMap
	if event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				BUTTON_LEFT:
					print("mouse")
					
					var mouse_pos = get_global_mouse_position()
					var tile_pos = top_map.world_to_map(mouse_pos)
					#top_map.set_cell(tile_pos.x, tile_pos.y, 1)
					load_pattern(glider, cell_list, tile_pos.x, tile_pos.y)
					print(tile_pos.x, " ", tile_pos.y)


###############################################################
# Load a pattern list
###############################################################

func load_pattern(pattern, list, x , y):
		for cell in pattern:
			list[Vector2(cell.x + x, cell.y + y)] = pattern[cell]
	
###############################################################
# Show score
###############################################################

var FONT_HEIGHT = 20
func show_score(score, list, x, y):
	clear_area(list, x-1, y-2, x+23, y + FONT_HEIGHT)
	var offset = 0
	print(score)
	for c in score:
		match c:
				
			"0":	
				load_pattern(zero, cell_list, x + offset, y)
				offset += 10
			"1":	
				load_pattern(one, cell_list, x + offset, y+1)
				offset += 5
			"2":	
				load_pattern(two, cell_list, x + offset, y+1)	
				offset += 10
			"3":	
				offset -= 4
				load_pattern(three, cell_list, x + offset, y+1)
				offset += 8
			"4":
				offset -= 1
				load_pattern(four, cell_list, x + offset, y+2)
				offset += 10
			"5":	
				offset -= 1
				load_pattern(five, cell_list, x + offset, y+1)
				offset += 10
			"6":	
				offset -= 1
				load_pattern(six, cell_list, x + offset, y)
				offset += 10
			"7":	
				offset -= 1
				load_pattern(seven, cell_list, x + offset, y)
				offset += 10
			"8":	
				load_pattern(eight, cell_list, x + offset, y+2)
				offset += 10
			"9":	
				offset -= 2
				load_pattern(nine, cell_list, x + offset, y+1)
				offset += 12
			
	
		

###############################################################
# Clear area
###############################################################

func clear_area(list, x, y, x_max, y_max):
	var top_map = $TopMap
		
	for i in range(x, x_max):		
		for j in range(y, y_max):
			if list.has(Vector2(i,j)):
				list.erase(Vector2(i, j)) 
				top_map.set_cell(i, j, 2)

