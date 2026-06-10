extends Node3D

@onready var Ball = $Ball
@onready var Car = $Car
@onready var RightWheel = $"Car/Model/wheel-front-right"
@onready var LeftWheel = $"Car/Model/wheel-front-left"
@onready var CarBody = $Car/Model/body
@onready var DriftTimer = $DriftTimer
@onready var BoostTimer = $BoostTimer
@onready var Anim = $AnimationPlayer

var velocidade_kmh: int = 0

var acceleration = 90.0
var steering = 12.0
var turn_speed = 5
var body_tilt = 30

var speed_input = 0
var rotate_input = 0

var Drifting = false
var DriftDirection = 0
var MinimumDrift = false
var Boost = 1
var DriftBoost = 1.75

func _physics_process(_delta):
	Car.transform.origin = Ball.transform.origin
	Ball.apply_central_force(-Car.global_transform.basis.z * speed_input * Boost)
	
func _process(delta):
	speed_input = (Input.get_action_strength("Accelerate") - Input.get_action_strength("Brake")) * acceleration #
	
	# Captura a intenção de curva do jogador (-1 para direita, 1 para esquerda)
	var steer_direction = Input.get_action_strength("Steer_Left") - Input.get_action_strength("Steer_Right") #
	
	# Se o speed_input for menor que 0, inverte a direção já que esta dando ré
	if speed_input < 0:
		steer_direction = -steer_direction

	rotate_input = deg_to_rad(steering) * steer_direction
	RightWheel.rotation.y = rotate_input
	LeftWheel.rotation.y = rotate_input
	
	if Input.is_action_just_pressed("Drift") and not Drifting and rotate_input != 0 and speed_input > 0:
		StartDrift()

	if Drifting:
		# Captura o comando de direção puro sem a inversão da ré já que não faz drift de ré
		var raw_steer = Input.get_action_strength("Steer_Left") - Input.get_action_strength("Steer_Right")
		
		# quanto maior o driftamount mais fechada é a curva
		var DriftAmount = raw_steer * deg_to_rad(steering * 0.67) #six seven
		
		rotate_input = DriftDirection + DriftAmount

	if Drifting and (Input.is_action_just_released("Drift") or speed_input < 1):
		StopDrift()
		
	var velocidade_atual = Ball.linear_velocity.length()
	velocidade_kmh = round(velocidade_atual * 3.6)
	
	if Ball.linear_velocity.length() > 0.75:
		RotateCar(delta)

func RotateCar(delta):
	var new_basis = Car.global_transform.basis.rotated(Car.global_transform.basis.y, rotate_input)
	Car.global_transform.basis = Car.global_transform.basis.slerp(new_basis, turn_speed * delta)
	Car.global_transform = Car.global_transform.orthonormalized()
	var t = -rotate_input * Ball.linear_velocity.length() / body_tilt
	CarBody.rotation.z = lerp(CarBody.rotation.z, t, 10 * delta)	

func StartDrift():
	Drifting = true
	Anim.play("Hop")
	MinimumDrift = false
	DriftDirection = rotate_input
	DriftTimer.start()

func StopDrift():
	if MinimumDrift:
		Boost = DriftBoost
		BoostTimer.start()
		Anim.play("ZoomOut")
	Drifting = false
	MinimumDrift = false

func _on_drift_timer_timeout(): # -> void
	if Drifting:
		MinimumDrift = true

func _on_boost_timer_timeout(): # -> void
	Boost = 1.0
	Anim.play("ZoomIn")
