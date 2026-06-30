extends Node

@export var total_laps: int = 3
@export var path: Path3D

@onready var car1 = $"../Control/HBoxContainer/SubViewportContainer1/SubViewport/Car"
@onready var car2 = $"../Control/HBoxContainer/SubViewportContainer2/SubViewport/Car"

var cars = []

var car_data = {}

func _ready():	
	await get_tree().process_frame
	cars = [car1, car2]
	print("Car1: ", car1)
	print("Car2: ", car2)
	
	for car in cars:
		car_data[car] = {
			"laps": 0,
			"checkpoints_passed": [],
			"path_progress": 0.0,
			"position": 0,
			"finished": false
		}
	
	_connect_checkpoints()

func _connect_checkpoints():
	for child in get_node("../SouthLoop").get_children():
		if child.is_in_group("checkpoint"):
			child.body_entered.connect(_on_checkpoint_entered.bind(child))
		if child.is_in_group("finish_line"):
			child.body_entered.connect(_on_finish_line_entered.bind(child))

func _on_checkpoint_entered(body: Node, checkpoint: Area3D):
	for car in cars:
		if body == car.get_node("Ball"):
			var data = car_data[car]
			if not checkpoint in data["checkpoints_passed"]:
				data["checkpoints_passed"].append(checkpoint)

func _on_finish_line_entered(body: Node, _finish: Area3D):
	for car in cars:
		if body == car.get_node("Ball"):
			var data = car_data[car]
			var total_checkpoints = get_tree().get_nodes_in_group("checkpoint").size()
			
			if data["checkpoints_passed"].size() >= total_checkpoints:
				data["laps"] += 1
				data["checkpoints_passed"].clear()
				print("Carro completou volta: ", data["laps"])
				
				if data["laps"] >= total_laps:
					data["finished"] = true
					print("Carro terminou a corrida!")

func _process(_delta):
	if cars.is_empty():
		return
	_update_path_progress()
	_update_positions()

func _update_path_progress():
	for car in cars:
		var ball = car.get_node("Ball")
		var closest = path.curve.get_closest_offset(
			path.to_local(ball.global_position)
		)
		var data = car_data[car]
		var curve_length = path.curve.get_baked_length()
		data["path_progress"] = (data["laps"] * curve_length) + closest

func _update_positions():
	var sorted = cars.filter(func(c): return not car_data[c]["finished"])
	sorted.sort_custom(func(a, b):
		return car_data[a]["path_progress"] > car_data[b]["path_progress"]
	)
	
	for i in sorted.size():
		car_data[sorted[i]]["position"] = i + 1

func get_position(car) -> int:
	if car in car_data:
		return car_data[car]["position"]
	return 0

func get_laps(car) -> int:
	if car in car_data:
		return car_data[car]["laps"]
	return 0
