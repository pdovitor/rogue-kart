extends CharacterBody3D

@export var speed: float = 5.0
@export var rotation_speed: float = 4.0

var player: Node3D = null

func _ready() -> void:
	# Aguarda um pequeno frame para garantir que tudo carregou na árvore principal
	await get_tree().process_frame
	
	# Método 1: Tenta achar o carro pelo grupo 'player' (Configurado na Solução 1)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Inimigo: Jogador encontrado via Grupo!")
	else:
		# Método 2: Se não achou por grupo, procura na árvore por um nó chamado 'Car'
		# (Godot diferencia maiúsculas/minúsculas, então se na sua main estiver "car", mude para "car")
		player = get_tree().current_scene.find_child("Car", true, false)
		if player:
			print("Inimigo: Jogador encontrado via nome do Nó!")
		else:
			print("AVISO: Inimigo não conseguiu encontrar o jogador na cena!")

func _physics_process(delta: float) -> void:
	# Se não houver jogador na pista, o inimigo não faz nada
	if not player or not is_instance_valid(player):
		return

	# 1. Descobre para onde ir (Posição do Jogador - Posição do Inimigo)
	var direction: Vector3 = player.global_position - global_position
	
	# Zera o eixo Y para o kart inimigo não tentar voar se o jogador pular
	direction.y = 0
	
	# Só se move se a distância for maior que zero
	if direction.length() > 0.5:
		direction = direction.normalized()

		# 2. Faz o inimigo olhar na direção do jogador suavemente
		# O atan2 calcula o ângulo correto no plano 3D (X e Z)
		var target_angle = atan2(direction.x, direction.z)
		
		# Interpola a rotação atual com o ângulo alvo para um giro suave
		rotation.y = rotate_toward(rotation.y, target_angle, rotation_speed * delta)

		# 3. Aplica velocidade nas direções X e Z
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Se estiver muito perto do jogador, para de correr
		velocity.x = 0
		velocity.z = 0

	# Aplica gravidade simples para o inimigo não flutuar caso a pista suba ou desça
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0

	move_and_slide()
