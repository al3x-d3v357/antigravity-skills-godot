## 🎥 IsometricCameraRig — câmara ortográfica isométrica anti-jitter.
##
## Skill: godot-isometric-vehicle-physics
##
## REGRA DE OURO: NÃO instalar como filha do carro nem de qualquer
## objetos que rode. Este rig segue apenas a POSIÇÃO do alvo (lerp
## exponencial) e mantém a rotação fixa definida em _ready().
## É isso que elimina a trepidação (jitter) quando o carro roda/derrapa.
class_name IsometricCameraRig
extends Camera3D

@export var target: Node3D

@export_group("Framing")
@export_range(1.0, 30.0) var follow_smoothing: float = 10.0
@export_range(5.0, 90.0) var pitch_degrees: float = 35.264 ## isometria verdadeira (~35.26°)
@export_range(5.0, 90.0) var yaw_degrees: float = 45.0
@export_range(10.0, 200.0) var distance: float = 60.0
@export_range(4.0, 100.0) var ortho_size: float = 20.0

var _offset: Vector3


func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = ortho_size
	current = true

	var view_basis := Basis.from_euler(Vector3(deg_to_rad(-pitch_degrees), deg_to_rad(yaw_degrees), 0.0))
	_offset = (view_basis * Vector3.BACK) * distance

	if target:
		global_position = target.global_position + _offset
		look_at(target.global_position, Vector3.UP)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var goal := target.global_position + _offset
	# Só a posição muda — a rotação jamais acompanha a do carro.
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_smoothing * delta))
