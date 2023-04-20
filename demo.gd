extends Control

# var example = preload(
# Called when the node enters the scene tree for the first time.
func _ready():
	var example = preload("res://assets/example.csv").setup()
	var shooter = example.fetch(1)
	print(shooter)
