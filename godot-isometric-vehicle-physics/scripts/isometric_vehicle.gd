## 🏎️ IsometricVehicle — carro arcade com drift em perspetiva isométrica.
##
## Skill: godot-isometric-vehicle-physics
## Nó base: CharacterBody3D. A velocidade é decomposta em componente
## longitudinal (avanço) e lateral (derrapagem), com tração lateral
## atenuada por lerp durante o drift.
##
## Colocação na cena:
##   Vehicle (CharacterBody3D + este script)
##   └── CollisionShape3D (chassi)
## A câmara NÃO é filha deste objeto — use IsometricCameraRig
## (scripts/isometric_camera.gd) num nó separado, para evitar jitter.
class_name IsometricVehicle
extends CharacterBody3D

@export_group("Motor")
@export_range(5.0, 80.0) var max_speed: float = 26.0
@export_range(5.0, 120.0) var engine_power: float = 55.0
@export_range(0.5, 10.0) var engine_drag: float = 2.6 ## atrito quando sem acelerador
@export var gravity: float = 30.0

@export_group("Direção")
@export_range(1.0, 20.0) var turn_speed: float = 8.0

@export_group("Drift")
@export_range(0.0, 20.0) var lateral_grip: float = 8.0 ## tração lateral em traçado normal
@export_range(0.0, 20.0) var drift_grip: float = 1.8 ## tração lateral com travão de mão
@export_range(0.5, 10.0) var drift_recovery: float = 3.5 ## velocidade de recuperação de aderência

@export_group("Input (ações do Input Map)")
@export var action_left: StringName = &"move_left"
@export var action_right: StringName = &"move_right"
@export var action_up: StringName = &"move_up"
@export var action_down: StringName = &"move_down"
@export var action_handbrake: StringName = &"handbrake"

## Componentes decompostos da velocidade (eixos locais do chassi).
var velocity_longitudinal := 0.0
var velocity_lateral := 0.0

## 0.0 = aderente · 1.0 = derrapagem total.
var drift_factor := 0.0
var is_drifting: bool = false

var _basis_forward: Vector3
var _basis_right: Vector3


func _physics_process(delta: float) -> void:
	var input := Vector2(
		Input.get_action_strength(action_right) - Input.get_action_strength(action_left),
		Input.get_action_strength(action_down) - Input.get_action_strength(action_up),
	)

	# 1) Rotação a 45°: alinha as setas com a diagonal isométrica da câmara,
	#    de forma a que "para cima" siga a diagonal visual, não o eixo X do mundo.
	var wish := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, deg_to_rad(45.0))

	# 2) Direção: roda o chassi gradualmente para o rumo desejado.
	if wish.length_squared() > 0.01:
		var target_yaw := atan2(-wish.x, -wish.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

	_decompose_velocity()
	_apply_engine(delta, wish)
	_apply_drift(delta)
	_compose_velocity()
	move_and_slide()


## Projeta a velocidade atual nos eixos locais do chassi.
func _decompose_velocity() -> void:
	_basis_forward = -global_transform.basis.z
	_basis_right = global_transform.basis.x
	velocity_longitudinal = velocity.dot(_basis_forward)
	velocity_lateral = velocity.dot(_basis_right)


func _apply_engine(delta: float, wish: Vector3) -> void:
	# O acelerador é a componente do input isométrico alinhada ao nariz do carro:
	# "para cima" faz sempre avançar para onde o carro aponta.
	var throttle := clampf(_basis_forward.dot(wish), -1.0, 1.0)
	velocity_longitudinal += throttle * engine_power * delta

	if absf(throttle) < 0.05:
		velocity_longitudinal = lerpf(velocity_longitudinal, 0.0, clampf(engine_drag * delta, 0.0, 1.0))

	velocity_longitudinal = clampf(
		velocity_longitudinal,
		-max_speed * 0.5,  # marcha-atrás limitada a metade da velocidade máxima
		max_speed
	)


## Núcleo do drift: tração lateral atenuada por lerp.
func _apply_drift(delta: float) -> void:
	var handbrake := Input.is_action_pressed(action_handbrake)
	var speed_ratio := velocity_longitudinal / max_speed
	var wants_drift := handbrake and absf(speed_ratio) > 0.35

	if wants_drift and not is_drifting:
		is_drifting = true
		_emit_drift_event()

	drift_factor = lerpf(drift_factor, 1.0 if wants_drift else 0.0, clampf(drift_recovery * delta, 0.0, 1.0))
	if not handbrake and drift_factor < 0.05:
		is_drifting = false

	# Mais frouxa durante o drift → o carro desliza de lado na curva.
	var grip := lerpf(lateral_grip, drift_grip, drift_factor)
	velocity_lateral = lerpf(velocity_lateral, 0.0, clampf(grip * delta, 0.0, 1.0))


func _compose_velocity() -> void:
	velocity = _basis_forward * velocity_longitudinal + _basis_right * velocity_lateral
	if not is_on_floor():
		velocity.y -= gravity * get_physics_process_delta_time()


## Velocidade longitudinal em "km/h" de arcade (valores de exibição para HUD).
func speed_kph() -> float:
	return absf(velocity_longitudinal) * 3.6


## Emite o sinal global de drift, tolerando ausência do autoload EventBus.
func _emit_drift_event() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("drift_triggered"):
		bus.drift_triggered.emit(self, drift_factor)
