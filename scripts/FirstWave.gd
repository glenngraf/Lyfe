extends Node2D

var lyfe_scene = preload("res://scenes/Lyfe/Lyfe.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	var instance = lyfe_scene.instance()	
	add_child(instance)


#	glider = lyfe_scene.load_file("rle/glider.rle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
