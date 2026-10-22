## 🧑‍✈️ DriverComponent — composição modular: gladiador condutor no veículo.
##
## Skill: godot-data-driven-architecture
## Anexe como FILHO do veículo (CharacterBody3D + isometric_vehicle.gd).
## apply_stats() copia um VehicleStats.tres para o controlador via set() —
## os dois jogos partilham o mesmo corpo físico por composição, sem herança.
class_name DriverComponent
extends Node

signal driver_changed(driver: Node)

@export var vehicle_stats: VehicleStats
@export var auto_apply: bool = true

var driver: Node = null

## Propriedades partilhadas entre VehicleStats e IsometricVehicle.
const _SHARED_PROPS: Array[StringName] = [
	&"max_speed",
	&"engine_power",
	&"engine_drag",
	&"turn_speed",
	&"lateral_grip",
	&"drift_grip",
	&"drift_recovery",
	&"gravity",
]


func _ready() -> void:
	if auto_apply:
		apply_stats()


## Injeta o .tres de tuning no veículo pai.
func apply_stats() -> void:
	var body := get_parent()
	if body == null or vehicle_stats == null:
		return
	for prop in _SHARED_PROPS:
		var value: Variant = vehicle_stats.get(prop)
		if value != null:
			body.set(prop, value)


## Liga um gladiador (do auto chess) como condutor do veículo.
func set_driver(gladiator: Node) -> void:
	driver = gladiator
	driver_changed.emit(gladiator)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.toast_requested.emit("Novo condutor a bordo.")
