extends Node3D

@onready var car1 = $Control/HBoxContainer/SubViewportContainer1/SubViewport/Car
@onready var car2 = $Control/HBoxContainer/SubViewportContainer2/SubViewport/Car
@onready var menu_ui = $CanvasLayer/MenuUI
@onready var main_menu_screen = $CanvasLayer/MenuUI/MainScreen
@onready var controls_screen = $CanvasLayer/MenuUI/ControlsScreen
@onready var settings_screen = $CanvasLayer/MenuUI/SettingsScreen
@onready var pause_screen = $CanvasLayer/MenuUI/PauseScreen
@onready var label_keyboard = $CanvasLayer/MenuUI/SettingsScreen/Controls/Label
@onready var label_gamepad = $CanvasLayer/MenuUI/SettingsScreen/Controls/Label2
@onready var gamepad_check_button = $CanvasLayer/MenuUI/SettingsScreen/Controls/CheckButton
@onready var controls_gamepad = $CanvasLayer/MenuUI/ControlsScreen/Gamepad
@onready var controls_keyboard_only = $CanvasLayer/MenuUI/ControlsScreen/KeyboardOnly
@onready var pause_gamepad = $CanvasLayer/MenuUI/PauseScreen/Gamepad
@onready var pause_keyboard_only = $CanvasLayer/MenuUI/PauseScreen/KeyboardOnly
@onready var volume_slider = $CanvasLayer/MenuUI/SettingsScreen/Volume/HSlider
@onready var soundtrack = $Soundtrack
@onready var hbox = $Control/HBoxContainer
@onready var subviewport1 = $Control/HBoxContainer/SubViewportContainer1
@onready var viewport1 = $Control/HBoxContainer/SubViewportContainer1/SubViewport
@onready var viewport2 = $Control/HBoxContainer/SubViewportContainer2/SubViewport
@onready var subviewport2 = $Control/HBoxContainer/SubViewportContainer2

@onready var race_manager = $RaceManager
@onready var HUDPlayer1 = $CanvasLayer/HUDPlayer1
@onready var HUDPlayer2 = $CanvasLayer/HUDPlayer2
@onready var label_pos1 = $CanvasLayer/HUDPlayer1/LabelPosicao1
@onready var label_laps1 = $CanvasLayer/HUDPlayer1/LabelVoltas1
@onready var label_pos2 = $CanvasLayer/HUDPlayer2/LabelPosicao2
@onready var label_laps2 = $CanvasLayer/HUDPlayer2/LabelVoltas2

var last_position_p1 = 0
var last_position_p2 = 0

const SETTINGS_PATH = "user://settings.cfg"
var master_bus_index = AudioServer.get_bus_index("Master")

func _process(_delta):
	if not race_manager.cars.is_empty():
		_update_hud()

func _update_hud():
	var pos1 = race_manager.get_position(car1)
	var laps1 = race_manager.get_laps(car1)
	var pos2 = race_manager.get_position(car2)
	var laps2 = race_manager.get_laps(car2)

	label_pos1.text = "%dº" % pos1
	label_laps1.text = "%d/%d" % [laps1, race_manager.total_laps]

	label_pos2.text = "%dº" % pos2
	label_laps2.text = "%d/%d" % [laps2, race_manager.total_laps]
	if pos1 != last_position_p1 and last_position_p1 != 0:
		_punch_scale(label_pos1)
	if pos2 != last_position_p2 and last_position_p2 != 0:
		_punch_scale(label_pos2)

	last_position_p1 = pos1
	last_position_p2 = pos2

func _punch_scale(label: Label):
	label.pivot_offset = label.size / 2

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.12)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.18)

func _ready():
	menu_ui.visible = true
	main_menu_screen.visible = true
	controls_screen.visible = false
	settings_screen.visible = false
	viewport1.size = get_viewport().size
	subviewport2.visible = false
	HUDPlayer1.visible = false
	HUDPlayer2.visible = false
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	$SouthLoop.process_mode = Node.PROCESS_MODE_PAUSABLE
	$Control.process_mode = Node.PROCESS_MODE_PAUSABLE
	$RaceManager.process_mode = Node.PROCESS_MODE_PAUSABLE
	pause_screen.visible = false
	_load_settings()
	soundtrack.play()

func _input(event):
	var pause_action = "pause_gamepad" if car1.gamepad else "pause"
	if Input.is_action_just_pressed(pause_action) and subviewport2.visible and car1.can_pause:
		toggle_pause()

func toggle_pause():
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	
	pause_screen.visible = new_pause_state
	HUDPlayer1.visible = not new_pause_state
	HUDPlayer2.visible = not new_pause_state

func _on_controls_pressed():
	main_menu_screen.visible = false
	controls_screen.visible = true
	_move_camera_to_showcase()
 
func _on_controls_back_pressed():
	controls_screen.visible = false
	main_menu_screen.visible = true
	_move_camera_to_menu()
 
func _on_settings_pressed():
	main_menu_screen.visible = false
	settings_screen.visible = true
	_move_camera_to_showcase()
 
func _on_settings_back_pressed():
	settings_screen.visible = false
	main_menu_screen.visible = true
	_move_camera_to_menu()

func _move_camera_to_showcase():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)

	tween.tween_property(car1.SpringArm, "rotation:y", deg_to_rad(15.0), 1.5)
	tween.tween_property(car1.SpringArm, "rotation:x", deg_to_rad(2.0), 1.5)
	tween.tween_property(car1.SpringArm, "spring_length", 5.0, 1.5)
	tween.tween_property(car1.Cam, "fov", 60.0, 1.5)

func _move_camera_to_menu():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)

	tween.tween_property(car1.SpringArm, "rotation:y", deg_to_rad(150.0), 1.5)
	tween.tween_property(car1.SpringArm, "rotation:x", 0.0, 1.5)
	tween.tween_property(car1.SpringArm, "spring_length", 7.5, 1.5)
	tween.tween_property(car1.Cam, "fov", 60.0, 1.5)

func _on_button_pressed():
	main_menu_screen.visible = false

	viewport1.size = Vector2(get_viewport().size.x / 2, get_viewport().size.y)
	viewport2.size = Vector2(get_viewport().size.x / 2, get_viewport().size.y)
	subviewport2.visible = true

	car1.start_game()
	await car2.start_game()
	HUDPlayer1.visible = true
	HUDPlayer2.visible = true


func _on_back_pause_pressed() -> void:
	toggle_pause()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_soundtrack_finished() -> void:
	soundtrack.play()


func _on_check_button_toggled(toggled_on: bool) -> void:
	car1.gamepad = toggled_on
	car2.gamepad = toggled_on
	_update_control_visuals(toggled_on)
	_save_settings()

func _on_h_slider_value_changed(value: float) -> void:
	_apply_volume(value)
	_save_settings()

func _apply_volume(value: float) -> void:
	var normalized = value / 100.0
	var db = linear_to_db(normalized) if normalized > 0.0 else -80.0
	AudioServer.set_bus_volume_db(master_bus_index, db)
	AudioServer.set_bus_mute(master_bus_index, normalized <= 0.0)

func _update_control_visuals(gamepad_on: bool) -> void:
	label_keyboard.modulate.a = 0.4 if gamepad_on else 1.0
	label_gamepad.modulate.a = 1.0 if gamepad_on else 0.4
	controls_gamepad.visible = gamepad_on
	controls_keyboard_only.visible = not gamepad_on
	pause_gamepad.visible = gamepad_on
	pause_keyboard_only.visible = not gamepad_on

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("controls", "gamepad", car1.gamepad)
	config.set_value("audio", "volume", volume_slider.value)
	config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config = ConfigFile.new()
	var gamepad_on = false
	var volume = 50.0

	var err = config.load(SETTINGS_PATH)
	if err == OK:
		gamepad_on = config.get_value("controls", "gamepad", false)
		volume = config.get_value("audio", "volume", 100.0)

	car1.gamepad = gamepad_on
	car2.gamepad = gamepad_on
	gamepad_check_button.set_pressed_no_signal(gamepad_on)
	_update_control_visuals(gamepad_on)

	volume_slider.set_value_no_signal(volume)
	_apply_volume(volume)
