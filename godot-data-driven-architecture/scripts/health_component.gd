## ❤️ HealthComponent — fonte de verdade da vida de qualquer entidade.
##
## Skill: godot-data-driven-architecture
## Anexe como filho do gladiador/veículo. Quem dana chama take_damage();
## quem reage subscreve os sinais — ninguém lê/escreve vida diretamente.
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@export var max_health: int = 100
@export var invincible: bool = false

var current_health: int


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	if invincible or current_health <= 0 or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount)
	if current_health <= 0:
		died.emit()


func heal(amount: int) -> void:
	if current_health <= 0 or amount <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	healed.emit(amount)


func is_dead() -> bool:
	return current_health <= 0


func set_max_health(value: int) -> void:
	max_health = maxi(value, 1)
	current_health = clampi(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)


func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
