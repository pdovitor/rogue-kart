extends Node3D

@onready var Ball = $SubViewportContainer/SubViewport/Ball
@onready var Car = $SubViewportContainer/SubViewport/Car
@onready var RightWheel = $"SubViewportContainer/SubViewport/Car/Model/body/wheel-front-right"
@onready var LeftWheel = $"SubViewportContainer/SubViewport/Car/Model/body/wheel-front-left"
@onready var LeftWheelBack = $"SubViewportContainer/SubViewport/Car/Model/body/wheel-back-left"
@onready var RightWheelBack = $"SubViewportContainer/SubViewport/Car/Model/body/wheel-back-right"
@onready var CarBody = $SubViewportContainer/SubViewport/Car/Model/body
@onready var DriftTimer = $SubViewportContainer/SubViewport/DriftTimer
@onready var BoostTimer = $SubViewportContainer/SubViewport/BoostTimer
@onready var Anim = $SubViewportContainer/SubViewport/AnimationPlayer
@onready var SpringArm = $SubViewportContainer/SubViewport/SpringArm3D
@onready var Cam = $SubViewportContainer/SubViewport/SpringArm3D/Camera3D
@onready var GroundRay = $SubViewportContainer/SubViewport/Car/GroundRay
@onready var SmokeParticlesRight = $SubViewportContainer/SubViewport/Car/Model/body/SmokeParticlesRight
@onready var SmokeParticlesLeft = $SubViewportContainer/SubViewport/Car/Model/body/SmokeParticlesLeft
@onready var SparkParticlesLeft = $SubViewportContainer/SubViewport/Car/Model/body/SparkLeft/GPUParticles3D
@onready var SparkParticlesRight = $SubViewportContainer/SubViewport/Car/Model/body/SparkRight/GPUParticles3D

@export var DriftSmokeColor : Gradient
@export var ChargedDriftSmokeColor : Gradient

var standard_scale = Vector3(1, 1, 1)
var squash_scale = Vector3(1.4, 0.5, 1.4) # Achatado no impacto
var stretch_scale = Vector3(0.9, 1.2, 0.9) # Esticado no pulo
var scaling_lerp_speed = 12.0
var was_in_air = false

var velocidade_kmh: int = 0

var acceleration = 60.0
var steering = 12.0
var turn_speed = 5.5
var body_tilt = 70
var hop_force = 2.0

var speed_input = 0
var rotate_input = 0

var Drifting = false
var CanDrift = true
var DriftDirection = 0
var MinimumDrift = false
var Boost = 1
var DriftBoost = 1.75

func _physics_process(delta):
	Car.transform.origin = Ball.transform.origin
	Ball.apply_central_force(-Car.global_transform.basis.z * speed_input * Boost)
	var height_offset = Vector3(0, 1.5, 0) 
	
	var target_pos = Car.global_position + height_offset
	SpringArm.global_position = SpringArm.global_position.lerp(target_pos, 40 * delta)
	
	var target_rotation = Car.global_rotation.y
	SpringArm.rotation.y = lerp_angle(SpringArm.rotation.y, target_rotation, 8.0 * delta)
	if not GroundRay.is_colliding():
		was_in_air = true
		
		# Opcional: Faz o carro tentar voltar a ficar reto aos poucos enquanto cai no ar
		#var upright_basis = Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK)
		#Car.global_transform.basis = Car.global_transform.basis.slerp(upright_basis, 2.0 * delta)
		
	else:
		if was_in_air:
			#CarBody.scale = squash_scale # Esmaga o carro no chão!
			was_in_air = false
		var normal = GroundRay.get_collision_normal()
		var forward = -Car.global_transform.basis.z 
		if abs(normal.dot(forward)) < 0.99:
			var right = forward.cross(normal).normalized()
			var new_forward = normal.cross(right).normalized()
			var target_basis = Basis(right, normal, -new_forward).orthonormalized()
			var current_basis = Car.global_transform.basis.orthonormalized()
			Car.global_transform.basis = current_basis.slerp(target_basis, 15.0 * delta)
	
func _process(delta):
	var gas = Input.get_action_strength("Accelerate")
	var brake = Input.get_action_strength("Brake")
	var vel_atual = Ball.linear_velocity.length()
	
	var target_speed = (gas - brake) * acceleration
	
	var pedal_response = 0.0
	
	if gas > 0 and brake == 0:
		pedal_response = 200.0 # Motor responde rápido
	elif brake > 0:
		pedal_response = 300.0 # Freio forte
	else:
		pedal_response = 40.0  # Inércia - O carro desliza quando solta tudo
	
	speed_input = move_toward(speed_input, target_speed, pedal_response * delta)
	
	var steer_direction = Input.get_action_strength("Steer_Left") - Input.get_action_strength("Steer_Right") #
	
	if speed_input < 0:
		steer_direction = -steer_direction

	var multiplicador_curva = 1.0
	
	if vel_atual < 2.0:
		multiplicador_curva = vel_atual / 2.0 
	else:
		
		var fator_vel = clamp(vel_atual / 30.0, 0.0, 1.0)
		multiplicador_curva = lerp(1.0, 0.6, fator_vel) 

	rotate_input = deg_to_rad(steering) * steer_direction * multiplicador_curva
	
	RightWheel.rotation.y = 1.5 * rotate_input
	LeftWheel.rotation.y = 1.5 * rotate_input
	
	if Input.is_action_just_pressed("Drift") and not Drifting and speed_input > 0 and CanDrift:
		Anim.play("Hop")
		Ball.linear_velocity.y = 0 
		Ball.apply_central_impulse(Vector3.UP * hop_force)
		CarBody.scale = stretch_scale
		
		if rotate_input != 0:
			StartDrift()
	
	var angulo_visual_alvo = 0.0
	
	if Drifting:
		angulo_visual_alvo = deg_to_rad(45.0) * DriftDirection
		
	CarBody.rotation.y = lerp_angle(CarBody.rotation.y, angulo_visual_alvo, 5.0 * delta)

	if Drifting:
		var raw_steer = Input.get_action_strength("Steer_Left") - Input.get_action_strength("Steer_Right")
		
		var forca_automatica = DriftDirection * deg_to_rad(steering * 0.8)
		
		var ajuste_jogador = raw_steer * deg_to_rad(steering * 0.5)
		rotate_input = forca_automatica + ajuste_jogador

	if Drifting and (Input.is_action_just_released("Drift") or speed_input < 0.5):
		StopDrift()
		
	var velocidade_atual = Ball.linear_velocity.length()
	velocidade_kmh = round(velocidade_atual * 3.6)
	
	if Ball.linear_velocity.length() > 0.75:
		RotateCar(delta)
	
	var current_speed = Ball.linear_velocity.length()
	var speed_factor = clamp(current_speed / 15.0, 0.0, 1.0)
	
	var base_fov = 75.0
	var max_fov_add = 25.0
	
	var base_spring_length = 3.5 # Distância normal da câmera
	var max_length_add = 0.1
	
	var target_fov = base_fov + (max_fov_add * speed_factor)
	var target_length = base_spring_length + (max_length_add * speed_factor)
	
	if Boost > 1.0:
		target_fov += 5.0 
		target_length += 1.0
	
	Cam.fov = lerp(Cam.fov, target_fov, 5.0 * delta)
	SpringArm.spring_length = lerp(SpringArm.spring_length, target_length, 3.0 * delta)
	
	if BoostTimer.is_stopped() and Boost > 1.0:
		Boost = lerp(Boost, 1.0, 3.0 * delta)
	
	if Boost > 1.0:
		var shake_intensity = (Boost - 1.0) * 0.08 
		
		Cam.h_offset = randf_range(-shake_intensity, shake_intensity)
		Cam.v_offset = randf_range(-shake_intensity, shake_intensity)
	else:
		Cam.h_offset = lerp(Cam.h_offset, 0.0, 15.0 * delta)
		Cam.v_offset = lerp(Cam.v_offset, 0.0, 15.0 * delta)
	CarBody.scale = CarBody.scale.lerp(standard_scale, scaling_lerp_speed * delta)
	
	
	if Drifting and Ball.linear_velocity.length() > 2.0:
		SmokeParticlesRight.emitting = true
		SmokeParticlesLeft.emitting = true
		
		var speed_for_smoke = Ball.linear_velocity.length()
		var smoke_factor = clamp(speed_for_smoke / 30.0, 0.1, 1.0)
		
		SmokeParticlesRight.amount_ratio = smoke_factor
		SmokeParticlesLeft.amount_ratio = smoke_factor
	else:
		SmokeParticlesRight.emitting = false
		SmokeParticlesLeft.emitting = false
		
	var wheel_direction = 1.0
	if speed_input < 0:
		wheel_direction = -1.0
	var spin = vel_atual * 2.0 * delta * wheel_direction
	
	RightWheel.rotation.x -= spin
	LeftWheel.rotation.x -= spin
	LeftWheelBack.rotation.x -= spin
	RightWheelBack.rotation.x -= spin
	if gas == 0 and brake == 0 and vel_atual < 2.0:
		Ball.linear_damp = 15.0 
		Ball.angular_damp = 15.0
	else:
		Ball.linear_damp = 0.1 
		Ball.angular_damp = 1.0

func RotateCar(delta):
	var new_basis = Car.global_transform.basis.rotated(Car.global_transform.basis.y, rotate_input)
	Car.global_transform.basis = Car.global_transform.basis.slerp(new_basis, turn_speed * delta)
	Car.global_transform = Car.global_transform.orthonormalized()
	var t = -rotate_input * Ball.linear_velocity.length() / body_tilt
	CarBody.rotation.z = lerp(CarBody.rotation.z, t, 5 * delta)	

func StartDrift():
	if CanDrift:
		Drifting = true
		MinimumDrift = false
		DriftTimer.start()
		change_smoke_color(DriftSmokeColor)
		
		var steer_direction = Input.get_action_strength("Steer_Left") - Input.get_action_strength("Steer_Right")
		DriftDirection = sign(steer_direction)
		if DriftDirection == 0:
			DriftDirection = 1

func StopDrift():
	if MinimumDrift:
		Boost = DriftBoost
		BoostTimer.start()
		CanDrift = false
		#CarBody.scale = Vector3(0.7, 0.7, 1.5)
	Drifting = false
	MinimumDrift = false

func _on_drift_timer_timeout(): # -> void
	if Drifting:
		MinimumDrift = true
		change_smoke_color(ChargedDriftSmokeColor)

func _on_boost_timer_timeout(): # -> void
	CanDrift = true

func change_smoke_color(new_gradient: Gradient):
	if not SmokeParticlesLeft.process_material.color_ramp:
		return
		
	var left_ramp = SmokeParticlesLeft.process_material.color_ramp
	var right_ramp = SmokeParticlesRight.process_material.color_ramp
	
	left_ramp.gradient = new_gradient
	right_ramp.gradient = new_gradient
