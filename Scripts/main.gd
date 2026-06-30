extends Node3D

@onready var car1 = $Control/HBoxContainer/SubViewportContainer1/SubViewport/Car
@onready var car2 = $Control/HBoxContainer/SubViewportContainer2/SubViewport/Car
@onready var menu_ui = $CanvasLayer/MenuUI
@onready var hbox = $Control/HBoxContainer
@onready var subviewport1 = $Control/HBoxContainer/SubViewportContainer1
@onready var viewport1 = $Control/HBoxContainer/SubViewportContainer1/SubViewport
@onready var viewport2 = $Control/HBoxContainer/SubViewportContainer2/SubViewport
@onready var subviewport2 = $Control/HBoxContainer/SubViewportContainer2

@onready var race_manager = $RaceManager
@onready var label_pos1 = $CanvasLayer/HUDPlayer1/LabelPosicao1
@onready var label_laps1 = $CanvasLayer/HUDPlayer1/LabelVoltas1
@onready var label_pos2 = $CanvasLayer/HUDPlayer2/LabelPosicao2
@onready var label_laps2 = $CanvasLayer/HUDPlayer2/LabelVoltas2

func _process(_delta):
	if not race_manager.cars.is_empty():
		_update_hud()

func _update_hud():
	var pos1 = race_manager.get_position(car1)
	var laps1 = race_manager.get_laps(car1)
	var pos2 = race_manager.get_position(car2)
	var laps2 = race_manager.get_laps(car2)

	label_pos1.text = "%dº lugar" % pos1
	label_laps1.text = "Volta %d/%d" % [laps1, race_manager.total_laps]

	label_pos2.text = "%dº lugar" % pos2
	label_laps2.text = "Volta %d/%d" % [laps2, race_manager.total_laps]

func _ready():
	menu_ui.visible = true
	viewport1.size = get_viewport().size
	subviewport2.visible = false

func _on_button_pressed():
	menu_ui.visible = false

	viewport1.size = Vector2(get_viewport().size.x / 2, get_viewport().size.y)
	viewport2.size = Vector2(get_viewport().size.x / 2, get_viewport().size.y)
	subviewport2.visible = true

	car1.start_game()
	car2.start_game()
