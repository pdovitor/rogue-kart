extends Node3D

@onready var car1 = $Control/HBoxContainer/SubViewportContainer1/SubViewport/Car
@onready var car2 = $Control/HBoxContainer/SubViewportContainer2/SubViewport/Car
@onready var menu_ui = $CanvasLayer/MenuUI
@onready var hbox = $Control/HBoxContainer
@onready var subviewport1 = $Control/HBoxContainer/SubViewportContainer1
@onready var viewport1 = $Control/HBoxContainer/SubViewportContainer1/SubViewport
@onready var viewport2 = $Control/HBoxContainer/SubViewportContainer2/SubViewport
@onready var subviewport2 = $Control/HBoxContainer/SubViewportContainer2

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
