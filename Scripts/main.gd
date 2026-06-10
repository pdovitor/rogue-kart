extends Node3D

@onready var velocidade_label = $CanvasLayer/LabelVelocidade
@onready var carro = $Car

func _process(_delta):
	# verifica se o carro existe na cena para evitar erros
	if carro:
		velocidade_label.text = "Velocidade: " + str(carro.velocidade_kmh) + " km/h"
