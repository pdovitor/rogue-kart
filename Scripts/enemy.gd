extends CharacterBody3D

enum Estado { PATRULHA, PERSEGUICAO }
var estado_atual = Estado.PATRULHA

@export var speed_patrol: float = 3.0       # patrulha
@export var speed_chase: float = 20.0       # perseguicao
@export var rotation_speed: float = 5.0     # rotação
@export var detection_radius: float = 60.0  # distância pra o inimigo avistar o player

var target_node: Node3D = null

# Variáveis para o movimento aleatório (Patrulha)
var direcao_aleatoria: Vector3 = Vector3.ZERO
var tempo_proxima_mudanca: float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	buscar_player()
	gerar_nova_direcao_patrulha()

func buscar_player() -> void:
	var player_root = get_tree().current_scene.find_child("player", true, false)
	if not player_root:
		player_root = get_tree().current_scene.find_child("Car", true, false)
		#procura a raiz player e dpois a Ball dentro dele
	if player_root:
		var ball_node = player_root.find_child("Ball", true, false)
		if ball_node:
			target_node = ball_node

func gerar_nova_direcao_patrulha() -> void:
	# Escolhe um ângulo aleatório em 360 graus
	var angulo = randf_range(0, 2 * PI)
	# Cria um vetor de direção no plano X e Z
	direcao_aleatoria = Vector3(sin(angulo), 0, cos(angulo)).normalized()
	# Define um tempo aleatório (entre 2 e 5 segundos) para andar nessa direção antes de mudar
	tempo_proxima_mudanca = randf_range(2.0, 5.0)

func _physics_process(delta: float) -> void:
	# Se perder a referência do player, tenta buscar novamente
	if not target_node or not is_instance_valid(target_node):
		buscar_player()
		# Enquanto não acha o jogador, continua patrulhando devagar
		processar_patrulha(delta)
		return

	# Calcula a distância exata em linha reta até a bola do jogador
	var distancia_ate_o_player = global_position.distance_to(target_node.global_position)

	# --- MÁQUINA DE ESTADOS (Mudar de comportamento com base na distância) ---
	if estado_atual == Estado.PATRULHA:
		# Se a bola do jogador entrar no raio de detecção, inicia a perseguição!
		if distancia_ate_o_player <= detection_radius:
			estado_atual = Estado.PERSEGUICAO
			print("Inimigo: Jogador detectado! Iniciando perseguição.")
		else:
			processar_patrulha(delta)
			
	elif estado_atual == Estado.PERSEGUICAO:
		# Se o jogador conseguir fugir para muito longe (ex: raio + 5 metros), o inimigo desiste
		if distancia_ate_o_player > (detection_radius + 5.0):
			estado_atual = Estado.PATRULHA
			gerar_nova_direcao_patrulha()
			print("Inimigo: Perdeu o jogador de vista. Voltando a patrulhar.")
		else:
			processar_perseguicao(delta)

	# Aplica a gravidade para o inimigo não flutuar
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0

	move_and_slide()

# --- COMPORTAMENTO 1: PATRULHA ALEATÓRIA ---
func processar_patrulha(delta: float) -> void:
	# Contagem regressiva para mudar de direção
	tempo_proxima_mudanca -= delta
	if tempo_proxima_mudanca <= 0:
		gerar_nova_direcao_patrulha()

	# Faz o inimigo virar suavemente para a direção aleatória que ele escolheu
	var target_angle = atan2(direcao_aleatoria.x, direcao_aleatoria.z)
	rotation.y = rotate_toward(rotation.y, target_angle, rotation_speed * delta)

	# Aplica a velocidade de patrulha (lenta)
	velocity.x = direcao_aleatoria.x * speed_patrol
	velocity.z = direcao_aleatoria.z * speed_patrol

# --- COMPORTAMENTO 2: PERSEGUIÇÃO REAL ---
func processar_perseguicao(delta: float) -> void:
	var direction: Vector3 = target_node.global_position - global_position
	direction.y = 0
	
	var distance = direction.length()
	
	# Só se move em direção ao player se não estiver colado nele
	if distance > 3.0:
		direction = direction.normalized()

		# Gira para encarar a bola do jogador
		var target_angle = atan2(direction.x, direction.z)
		rotation.y = rotate_toward(rotation.y, target_angle, rotation_speed * delta)

		velocity.x = direction.x * speed_chase
		velocity.z = direction.z * speed_chase
	else:
		velocity.x = move_toward(velocity.x, 0, speed_chase * delta)
		velocity.z = move_toward(velocity.z, 0, speed_chase * delta)
