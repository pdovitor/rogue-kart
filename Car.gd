extends VehicleBody3D

# Valores recomendados para comportamento ágil de Kart:
var max_RPM = 600       # Permite uma velocidade final maior antes do motor cortar o torque
var max_torque = 600    # Aumentado para dar arrancada forte e instantânea
var turn_speed = 5      # Velocidade do lerp ao esterçar (maior = resposta mais rápida)
var turn_amount = 0.45  # Ângulo máximo de curva das rodas dianteiras (aproximadamente 25-30 graus)

func _physics_process(delta):
	var dir = Input.get_action_strength("Accelerate") - Input.get_action_strength("Brake")
	var steering_dir = Input.get_action_strength("Steer_Left") - Input.get_action_strength("Steer_Right")
	
	var RPM_left = abs($wheel_back_left.get_rpm())
	var RPM_right = abs($wheel_back_right.get_rpm())
	var RPM = (RPM_left + RPM_right) / 2.0
	
	# Aplica força constante nas rodas se estiver abaixo do RPM máximo
	var torque = dir * max_torque * (1.0 - RPM / max_RPM)
	engine_force = torque
	
	# Suaviza a direção
	steering = lerp(steering, steering_dir * turn_amount, turn_speed * delta)
	
	# Adicione uma força de freio/atrito manual mais forte se soltar o acelerador
	if dir == 0:
		brake = 5.0 # Aumentado para o kart não rolar infinitamente ao soltar o botão
	else:
		brake = 0.0
