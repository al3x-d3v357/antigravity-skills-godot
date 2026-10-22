## 🏎️ VehicleStats — esquema estático de tuning de veículo isométrico.
##
## Skill: godot-data-driven-architecture
## Espelha os @export de isometric_vehicle.gd (godot-isometric-vehicle-physics).
## Crie .tres em res://data/resources/vehicles/ e aplique via DriverComponent.
class_name VehicleStats
extends Resource

@export var display_name: String = ""

@export_group("Motor")
@export var max_speed: float = 26.0
@export var engine_power: float = 55.0
@export var engine_drag: float = 2.6
@export var gravity: float = 30.0

@export_group("Direção")
@export var turn_speed: float = 8.0

@export_group("Drift")
@export var lateral_grip: float = 8.0
@export var drift_grip: float = 1.8
@export var drift_recovery: float = 3.5
